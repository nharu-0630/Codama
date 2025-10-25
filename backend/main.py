import os

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from supabase import Client, create_client

load_dotenv()

url: str = os.environ.get("SUPABASE_URL", "http://127.0.0.1:54321")
key: str = os.environ.get("SUPABASE_KEY", "")
supabase: Client = create_client(url, key)

app = FastAPI(title="codama backend")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["health"])
async def health():
    return {"status": "ok"}


@app.get("/areas", tags=["areas"])
async def get_areas():
    areas = supabase.from_("areas").select("*").execute()
    return areas


@app.get("/posts", tags=["posts"])
async def get_posts():
    posts = supabase.from_("user_posts").select("*").execute()
    return posts


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
