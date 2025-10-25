"""
Post-related API endpoints.
"""

from fastapi import APIRouter, Query, status

from app.schemas import NearbyPostsResponse, PostCreate, PostResponse

router = APIRouter(
    prefix="/posts",
    tags=["posts"],
)


@router.post(
    "",
    response_model=PostResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new post",
    description="Create a new post with location information",
)
async def create_post(post: PostCreate) -> PostResponse:
    """
    Create a new post with the following information:

    - **username**: Name of the user creating the post
    - **text**: Content of the post
    - **latitude**: Latitude coordinate of the post location
    - **longitude**: Longitude coordinate of the post location

    Returns the created post with an assigned ID and timestamp.
    """
    # TODO: Implement database insertion
    # For now, this is a placeholder that needs to be implemented with Supabase
    raise NotImplementedError("Post creation not yet implemented")


@router.get(
    "/nearby",
    response_model=NearbyPostsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get nearby posts",
    description="Retrieve posts within a specified radius from a given location",
)
async def get_nearby_posts(
    latitude: float = Query(..., ge=-90, le=90, description="Center latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Center longitude"),
    radius: float = Query(1.0, gt=0, le=100, description="Search radius in kilometers"),
) -> NearbyPostsResponse:
    """
    Get posts near a specific location.

    - **latitude**: Center point latitude
    - **longitude**: Center point longitude
    - **radius**: Search radius in kilometers (default: 1.0km, max: 100km)

    Returns a list of posts within the specified radius, ordered by distance.
    """
    # TODO: Implement database query with geospatial search
    # For now, this is a placeholder that needs to be implemented with Supabase
    raise NotImplementedError("Nearby posts search not yet implemented")
