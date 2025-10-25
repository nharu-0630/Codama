"""Embedding utilities for post-processing."""

from openai import OpenAI

client = OpenAI()


async def generate_embedding(text: str) -> list[float]:
    """Generate embedding for the given text using OpenAI API."""
    response = client.embeddings.create(  # type: ignore
        input=text, model="text-embedding-3-small"
    )
    return response.data[0].embedding  # type: ignore
