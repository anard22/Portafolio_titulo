import mysql.connector
from config import Config


def get_connection():
    """Retorna una conexión a MySQL usando la configuración de la app."""
    return mysql.connector.connect(
        host=Config.DB_HOST,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
    )


def autenticar_usuario(email):
    """Invoca el procedimiento sp_autenticar_usuario."""
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.callproc("sp_autenticar_usuario", [email])
        for result in cursor.stored_results():
            rows = result.fetchall()
            return rows[0] if rows else None
        return None
    finally:
        conn.close()