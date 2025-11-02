from openai import OpenAI

from config.settings import settings


class OpenAIClient:
    """OpenAI クライアントの抽象化"""

    def __init__(self):
        self._openai = None

    @property
    def openai(self):
        """OpenAI クライアントを取得"""
        if self._openai is None:
            self._openai = OpenAI(api_key=settings.OPENAI_API_KEY)
        return self._openai


# シングルトンインスタンス
openai_client = OpenAIClient()
