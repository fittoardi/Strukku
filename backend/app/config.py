import os
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DB_HOST: str = "127.0.0.1"
    DB_PORT: int = 5432
    DB_NAME: str = "strukku"
    DB_USER: str = "postgres"
    DB_PASSWORD: str = "postgres"

    SERVER_HOST: str = "0.0.0.0"
    SERVER_PORT: int = 8000

    LLM_PROVIDER: str = "gemini"
    ANTHROPIC_API_KEY: str = ""
    GEMINI_API_KEY: str = ""

    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def database_url(self) -> str:
        return f"postgresql+psycopg2://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    @property
    def default_postgres_url(self) -> str:
        # Digunakan untuk koneksi awal sebelum database `strukku` dibuat
        return f"postgresql+psycopg2://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/postgres"


settings = Settings()
