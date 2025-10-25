"""Post repository for data access."""

from typing import Any, cast
from uuid import UUID

from config.database import supabase
from schemas.db import DBLLMPost, DBUserPost


def get_user_post_by_uuid(post_uuid: str) -> DBUserPost | None:
    post_response = (
        supabase.from_("user_posts")
        .select("*")
        .eq("uuid", post_uuid)
        .single()
        .execute()
    )
    if not post_response.data:
        return None
    data = cast(dict[str, Any], post_response.data)
    return DBUserPost(**data)


def get_llm_posts_by_user_post_uuid(user_post_uuid: str) -> list[DBLLMPost]:
    response = (
        supabase.from_("llm_posts")
        .select("*")
        .eq("user_post_uuid", user_post_uuid)
        .execute()
    )
    data = cast(list[dict[str, Any]], response.data)
    return [DBLLMPost(**item) for item in data]


def get_user_posts_by_location(geo_hash: str) -> list[DBUserPost]:
    posts = (
        supabase.from_("user_posts")
        .select("*, cells!inner(id, geo_hash)")
        .like("cells.geo_hash", f"{geo_hash}%")
        .execute()
    )
    data = cast(list[dict[str, Any]], posts.data)
    return [DBUserPost(**item) for item in data]


def get_user_posts_by_uuids(post_uuids: list[str]) -> list[DBUserPost]:
    if not post_uuids:
        return []
    posts = supabase.from_("user_posts").select("*").in_("uuid", post_uuids).execute()
    data = cast(list[dict[str, Any]], posts.data)
    return [DBUserPost(**item) for item in data]


def create_user_post(
    content: str, cell_id: int, user_uuid: UUID, location_wkt: str
) -> DBUserPost:
    post_data: dict[str, Any] = {
        "content": content,
        "cell_id": cell_id,
        "user_uuid": str(user_uuid),
        "location": location_wkt,
    }
    response = supabase.from_("user_posts").insert(post_data).execute()
    data = cast(list[dict[str, Any]], response.data)
    return DBUserPost(**data[0])


def get_user_posts_by_cell_ids_after_date(
    cell_ids: list[int], after_date: str
) -> list[DBUserPost]:
    """Get user posts by cell IDs after a specific date.

    Args:
        cell_ids: List of cell IDs
        after_date: ISO format datetime string (e.g., "1970-01-01T00:00:00Z")

    Returns:
        List of DBUserPost
    """
    if not cell_ids:
        return []

    posts = (
        supabase.from_("user_posts")
        .select("*")
        .in_("cell_id", cell_ids)
        .filter("created_at", "gt", after_date)
        .execute()
    )

    data = cast(list[dict[str, Any]], posts.data)
    return [DBUserPost(**item) for item in data]


def get_recent_user_posts_by_cell_ids(
    cell_ids: list[int], limit: int = 5
) -> list[DBUserPost]:
    """Get recent user posts by cell IDs.

    Args:
        cell_ids: List of cell IDs
        limit: Maximum number of posts to return (default: 5)

    Returns:
        List of DBUserPost ordered by created_at descending
    """
    if not cell_ids:
        return []

    posts = (
        supabase.from_("user_posts")
        .select("*")
        .in_("cell_id", cell_ids)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )

    data = cast(list[dict[str, Any]], posts.data)
    return [DBUserPost(**item) for item in data]


def create_llm_post(content: str, user_post_uuid: UUID, location_wkt: str) -> DBLLMPost:
    post_data: dict[str, Any] = {
        "content": content,
        "user_post_uuid": str(user_post_uuid),
        "location": location_wkt,
    }
    response = supabase.from_("llm_posts").insert(post_data).execute()
    data = cast(list[dict[str, Any]], response.data)
    return DBLLMPost(**data[0])
