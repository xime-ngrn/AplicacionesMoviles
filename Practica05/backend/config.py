import os

class Config:
    MYSQL_USER = os.getenv("MYSQL_USER", "appuser")
    MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "apppassword")
    MYSQL_HOST = os.getenv("MYSQL_HOST", "mysql") # Nombre del servicio en la red de Docker Compose
    MYSQL_PORT = os.getenv("MYSQL_PORT", 3306)
    MYSQL_DB = os.getenv("MYSQL_DB", "logindb")

    SQLALCHEMY_DATABASE_URI = (f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}")

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-change-me")
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "dev-jwt-secret-change-me")

    # Usuario por defecto para la administración de la aplicación
    ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
    ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")
    ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@example.com")
