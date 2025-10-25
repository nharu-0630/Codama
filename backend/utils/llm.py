# """General utilities for LLM interactions."""

# import openai


# async def generate_response(prompt: str) -> str:
#     response = await openai.chat.completions.create(
#         model="gpt-4o", messages=[{"role": "user", "content": prompt}]
#     )
#     return response.choices[0].message.content
