import os


class Config:
    """Configuración de la aplicación Smart Arena Experience."""

    SECRET_KEY = os.environ.get("SA_SECRET_KEY", "cambiar-esta-clave-en-produccion")
    DB_HOST = os.environ.get("DB_HOST", "localhost")
    DB_USER = os.environ.get("DB_USER", "root")
    DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
    DB_NAME = os.environ.get("DB_NAME", "smart_arena_db")