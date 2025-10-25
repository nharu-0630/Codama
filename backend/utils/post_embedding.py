from openai import OpenAI

# OpenAIクライアントを初期化
client = OpenAI()


async def generate_embedding(text: str) -> list[float]:
    """OpenAI APIを使用してテキストのembeddingベクトルを生成"""
    # text-embedding-3-smallモデルを使用してembeddingを生成
    response = client.embeddings.create(  # type: ignore
        input=text, model="text-embedding-3-small"
    )
    # 生成されたembeddingベクトルを返却
    return response.data[0].embedding  # type: ignore
