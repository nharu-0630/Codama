import os

from dotenv import load_dotenv

# 環境変数を.envファイルから読み込み
load_dotenv()


class Settings:
    """アプリケーション設定クラス"""

    # ジオハッシュの精度（デフォルト: 7）
    GEO_HASH_PRECISION: int = int(os.environ.get("GEO_HASH_PRECISION", 7))
    # 投稿の取得件数（デフォルト: 100）
    POSTS_FETCH_LIMIT: int = int(os.environ.get("POSTS_FETCH_LIMIT", 100))
    # 座標にランダムオフセットを追加する際の最大距離（メートル）
    GEO_DELTA_METERS: int = int(os.environ.get("GEO_DELTA_METERS", 100))
    # AI返信の生成数
    CODAMA_AI_COUNT: int = int(os.environ.get("CODAMA_AI_COUNT", 1))
    # 返信の最小数
    CODAMA_MIN_COUNT: int = int(os.environ.get("CODAMA_MIN_COUNT", 3))
    # 返信の最大数
    CODAMA_MAX_COUNT: int = int(os.environ.get("CODAMA_MAX_COUNT", 10))
    # 類似投稿検索の閾値
    CODAMA_THRESHOLD: float = float(os.environ.get("CODAMA_THRESHOLD", 0.7))
    # 関連性判定の時間範囲（時間）
    CODAMA_RELATIONSHIP_HOUR: int = int(os.environ.get("CODAMA_RELATIONSHIP_HOUR", 24))
    # 関連性判定の投稿数
    CODAMA_RELATIONSHIP_COUNT: int = int(os.environ.get("CODAMA_RELATIONSHIP_COUNT", 3))
    # SupabaseのURL
    SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "http://127.0.0.1:54321")
    # SupabaseのAPIキー
    SUPABASE_KEY: str = os.environ.get("SUPABASE_KEY", "")
    # Google Maps APIキー
    GOOGLE_MAPS_API_KEY: str = os.environ.get("GOOGLE_MAPS_API_KEY", "")
    # OpenAI APIキー
    OPENAI_API_KEY: str = os.environ.get("OPENAI_API_KEY", "")


settings = Settings()
