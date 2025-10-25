import os
from typing import Any

import googlemaps  # type: ignore
import pygeohash as gh  # type: ignore
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from shapely import wkb
from supabase import create_client

from model import (
    Area,
    Cell,
    CreatePostResponse,
    CurrentResponse,
    Post,
    SignupResponse,
)

load_dotenv()

GEO_HASH_PRECISION: int = int(os.environ.get("GEO_HASH_PRECISION", 7))
SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "http://127.0.0.1:54321")
SUPABASE_KEY: str = os.environ.get("SUPABASE_KEY", "")
GOOGLE_MAPS_API_KEY: str = os.environ.get("GOOGLE_MAPS_API_KEY", "")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
gmaps = googlemaps.Client(key=GOOGLE_MAPS_API_KEY)

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def parse_point_geometry(wkt: str) -> tuple[float, float]:
    """Parse WKT POINT geometry string to (lat, lon) tuple.

    Args:
        wkt: WKT format string like "POINT(139.7 35.6)" or "0101000020E6100000..."

    Returns:
        Tuple of (latitude, longitude)
    """
    # If it's a hex string (WKB format), we need to handle it differently
    if wkt.startswith("0101"):
        # This is WKB format, for now we'll raise an error
        raise ValueError("WKB format not supported, please use WKT")

    # Parse WKT format: "POINT(lon lat)"
    if wkt.startswith("POINT"):
        coords = wkt.replace("POINT(", "").replace(")", "").strip()
        lon, lat = coords.split()
        return (float(lat), float(lon))

    raise ValueError(f"Unknown geometry format: {wkt}")


async def get_current_user(authorization: str = Header(...)):
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header")
        token = authorization.replace("Bearer ", "")
        user_response = supabase.auth.get_user(token)
        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")
        return user_response.user
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")


@app.get("/", tags=["health"])
async def health():
    return {"status": "ok"}


@app.post("/signup", tags=["auth"], response_model=SignupResponse)
async def signup():
    try:
        auth_response = supabase.auth.sign_in_anonymously()
        if not auth_response.session:
            raise HTTPException(
                status_code=500, detail="Failed to create anonymous session"
            )
        if not auth_response.user:
            raise HTTPException(
                status_code=500, detail="Failed to create anonymous user"
            )
        return SignupResponse(
            access_token=auth_response.session.access_token,
            refresh_token=auth_response.session.refresh_token,
            user_id=auth_response.user.id,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to sign up: {str(e)}")


@app.get("/areas", tags=["areas"], response_model=list[Area])
async def get_areas():
    areas = supabase.from_("areas").select("*").execute()
    return [
        Area(id=area["id"], name=area["name"], created_at=area["created_at"])  # type: ignore
        for area in areas.data
    ]


@app.get("/current", tags=["current"], response_model=CurrentResponse)
async def get_current(
    lat: float,
    lon: float,
    authorization: str = Header(...),
):
    await get_current_user(authorization)
    geo_hash = gh.encode(lat, lon, precision=GEO_HASH_PRECISION)
    center_pos = gh.decode(geo_hash)
    cell = (
        supabase.from_("cells")
        .select("id, geo_hash, area_id, created_at, location")
        .like("geo_hash", f"{geo_hash}%")
        .execute()
    )
    if not cell.data:
        area_name: str | None = None
        geo_code = gmaps.reverse_geocode((lat, lon), language="ja")  # type: ignore
        if geo_code and len(geo_code) > 0:  # type: ignore
            for component in geo_code[0].get("address_components", []):  # type: ignore
                if "sublocality_level_1" in component.get("types", []):  # type: ignore
                    area_name = str(component.get("short_name"))  # type: ignore
                    break
        if not area_name:
            raise HTTPException(status_code=404, detail="Area not found from geocode")
        area = supabase.from_("areas").select("*").eq("name", area_name).execute()
        if not area.data:
            raise HTTPException(status_code=404, detail="Area not found")
        new_cell: dict[str, Any] = {
            "geo_hash": geo_hash,
            "location": f"POINT({center_pos.longitude} {center_pos.latitude})",
            "area_id": int(area.data[0]["id"]),  # type: ignore
        }
        supabase.from_("cells").insert(new_cell).execute()
        cell = (
            supabase.from_("cells")
            .select("id, geo_hash, area_id, created_at, location")
            .like("geo_hash", f"{geo_hash}%")
            .execute()
        )
        if not cell.data:
            raise HTTPException(status_code=404, detail="Cell not found")
    location_wkt = str(cell.data[0]["location"])  # type: ignore
    point = wkb.loads(location_wkt, hex=True)
    print(point.xy)
    area_id = int(cell.data[0]["area_id"])  # type: ignore
    area = supabase.from_("areas").select("*").eq("id", area_id).execute()
    if not area.data:
        raise HTTPException(status_code=404, detail="Area not found")
    return CurrentResponse(
        area=Area(
            id=area.data[0]["id"],  # type: ignore
            name=area.data[0]["name"],  # type: ignore
        ),
        cell=Cell(
            id=cell.data[0]["id"],  # type: ignore
            geo_hash=cell.data[0]["geo_hash"],  # type: ignore
            location=(point.xy[1][0], point.xy[0][0]),  # type: ignore
        ),
    )


@app.get("/posts", tags=["posts"], response_model=list[Post])
async def get_posts(
    lat: float,
    lon: float,
    authorization: str = Header(...),
):
    await get_current_user(authorization)
    geo_hash = gh.encode(lat, lon, precision=GEO_HASH_PRECISION)
    posts = (
        supabase.from_("user_posts")
        .select("*, cells!inner(id, geo_hash)")
        .like("cells.geo_hash", f"{geo_hash}%")
        .execute()
    )
    return [
        Post(
            id=post["id"],  # type: ignore
            content=post["content"],  # type: ignore
            cell_id=post["cell_id"],  # type: ignore
            created_at=post["created_at"],  # type: ignore
            cells={
                "id": post["cells"]["id"],  # type: ignore
                "geo_hash": post["cells"]["geo_hash"],  # type: ignore
            },
        )
        for post in posts.data
    ]


@app.post("/posts", tags=["posts"], response_model=CreatePostResponse)
async def create_post(
    content: str,
    lat: float,
    lon: float,
    authorization: str = Header(...),
):
    await get_current_user(authorization)

    geo_hash = gh.encode(lat, lon, precision=GEO_HASH_PRECISION)
    cell_response = (
        supabase.from_("cells").select("*").like("geo_hash", f"{geo_hash}%").execute()
    )
    if not cell_response.data:
        raise HTTPException(status_code=404, detail="Cell not found")
    cell_id = int(cell_response.data[0]["id"])  # type: ignore
    new_post: dict[str, Any] = {
        "content": content,
        "cell_id": cell_id,
    }
    created_post = supabase.from_("user_posts").insert(new_post).execute()
    if not created_post.data:
        raise HTTPException(status_code=500, detail="Failed to create post")
    return CreatePostResponse(
        success=True,
        user_post_id=created_post.data[0]["id"],  # type: ignore
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
