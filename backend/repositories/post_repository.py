"""Post repository for data access."""

from typing import Any

from config.database import supabase
from postgrest.base_request_builder import APIResponse


def get_post_raw_by_uuid(post_uuid: str) -> dict[str, Any] | None:
    """Get raw post data by UUID from Supabase.

    Args:
        post_uuid: UUID of the post to retrieve

    Returns:
        Raw post data if found, None otherwise
    """
    post_response: APIResponse[Any] = (
        supabase.from_("user_posts")
        .select("*, llm_posts(uuid, content, location, created_at)")
        .eq("uuid", post_uuid)
        .single()
        .execute()
    )

    if not post_response.data:
        return None

    return post_response.data  # type: ignore


def get_posts_raw_by_location(geo_hash: str) -> list[dict[str, Any]]:
    """Get raw posts data by location using geohash.

    Args:
        geo_hash: Geohash string for location matching

    Returns:
        List of raw post data
    """
    posts: APIResponse[Any] = (
        supabase.from_("user_posts")
        .select(
            "*, cells!inner(id, geo_hash, location), llm_posts(uuid, content, location, created_at)"
        )
        .like("cells.geo_hash", f"{geo_hash}%")
        .execute()
    )

    return posts.data  # type: ignore


def get_posts_raw_by_uuids(post_uuids: list[str]) -> list[dict[str, Any]]:
    """Get raw posts data by their UUIDs.

    Args:
        post_uuids: List of post UUIDs to retrieve

    Returns:
        List of raw post data
    """
    if not post_uuids:
        return []

    posts: APIResponse[Any] = (
        supabase.from_("user_posts")
        .select("*, llm_posts(uuid, content, location, created_at)")
        .in_("uuid", post_uuids)
        .execute()
    )

    return posts.data  # type: ignore
