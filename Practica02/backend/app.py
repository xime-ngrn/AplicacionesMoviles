import time
from functools import wraps

from flask import Flask, request, jsonify
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity, get_jwt
from sqlalchemy.exc import IntegrityError, OperationalError
from flask_cors import CORS

from config import Config
from models import db, User

bcrypt = Bcrypt()
jwt = JWTManager()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    bcrypt.init_app(app)
    jwt.init_app(app)
    CORS(app)

    register_routes(app)
    return app

def admin_required(fn):
    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        if claims.get('role') != 'admin':
            return jsonify({"message": "Se requieren permisos de administrador."}), 403
        return fn(*args, **kwargs)
    
    return wrapper

def register_routes(app):
    # endpoint para verificar el estado de la API
    @app.get("/")
    def health():
        return jsonify({"message": "API activa."}), 200

    # endpoint para registrar un nuevo usuario
    @app.post("/api/register")
    def register():
        data = request.get_json() or {}
        username = data.get("username")
        email = data.get("email")
        password = data.get("password")

        if not username or not email or not password:
            return jsonify({"message": "Faltan campos requeridos."}), 400
        if User.query.filter_by(username=username).first():
            return jsonify({"message": "El usuario ingresado ya existe."}), 400
        if User.query.filter_by(email=email).first():
            return jsonify({"message": "El correo electrónico ingresado ya existe."}), 400

        pw_hash = bcrypt.generate_password_hash(password).decode('utf-8')
        user = User(username=username, email=email, password_hash=pw_hash, role="user")
        db.session.add(user)
        db.session.commit()

        return jsonify({"message": "Usuario registrado exitosamente.", "user": user.to_dict()}), 201

    # endpoint para verificar el inicio de sesión de un usuario y generar un token JWT
    @app.post("/api/login")
    def login():
        data = request.get_json() or {}
        username = data.get("username")
        password = data.get("password")

        if not username or not password:
            return jsonify({"message": "Faltan campos requeridos."}), 400

        user = User.query.filter_by(username=username).first()
        if not user or not bcrypt.check_password_hash(user.password_hash, password):
            return jsonify({"message": "Credenciales inválidas."}), 401

        access_token = create_access_token(identity=str(user.id), additional_claims={"role": user.role, "username": user.username})
        return jsonify({"access_token": access_token, "user": user.to_dict()}), 200

    # endpoint para obtener información del usuario autenticado
    @app.get("/api/me")
    @jwt_required()
    def me():
        user = db.session.get(User, int(get_jwt_identity()))

        if not user:
            return jsonify({"message": "Usuario no encontrado."}), 404
        return jsonify({"user": user.to_dict()}), 200

    #endpoint para obtener la lista de usuarios (solo accesible por administradores)
    @app.get("/api/users")
    @admin_required
    def get_users():
        users = User.query.all()
        return jsonify({"users": [user.to_dict() for user in users]}), 200

    # endpoint para modificar la información de un usuario
    @app.put("/api/users/<int:user_id>")
    @jwt_required()
    def update_user(user_id):
        is_admin = get_jwt().get("role") == "admin"
        is_self = get_jwt_identity() == str(user_id)

        if not is_admin and not is_self:
            return jsonify({"message": "No tienes permisos para modificar este usuario."}), 403

        user = db.session.get(User, user_id)
        if not user:
            return jsonify({"message": "Usuario no encontrado."}), 404

        data = request.get_json() or {}
        if data.get("username"):
            if User.query.filter_by(username=data["username"]).first():
                return jsonify({"message": "El nombre de usuario ya está en uso."}), 400
            user.username = data["username"]
        if data.get("email"):
            if User.query.filter_by(email=data["email"]).first():
                return jsonify({"message": "El correo electrónico ya está en uso."}), 400
            user.email = data["email"]
        if data.get("password"):
            user.password_hash = bcrypt.generate_password_hash(data["password"]).decode('utf-8')
        if "role" in data and is_admin:
            user.role = data["role"]

        db.session.commit()
        return jsonify({"message": "Usuario actualizado exitosamente.", "user": user.to_dict()}), 200

    @app.delete("/api/users/<int:user_id>")
    @jwt_required()
    def delete_user(user_id):
        is_admin = get_jwt().get("role") == "admin"
        is_self = get_jwt_identity() == str(user_id)

        if not is_admin and not is_self:
            return jsonify({"message": "No tienes permisos para eliminar este usuario."}), 403

        user = db.session.get(User, user_id)
        if not user:
            return jsonify({"message": "Usuario no encontrado."}), 404

        db.session.delete(user)
        db.session.commit()
        return jsonify({"message": "Usuario eliminado exitosamente."}), 200


def init_db(app):
    for attempt in range(1, 11):
        try:
            with app.app_context():
                db.create_all()
                seed_admin(app)
            print("Base de datos inicializada correctamente.")
            return
        except OperationalError:
            print(f"Intento {attempt}: Error al conectar con la base de datos. Reintentando en 5 segundos...")
            time.sleep(5)
    raise RuntimeError("No se pudo conectar a la base de datos después de varios intentos.")

def seed_admin(app):
    if not User.query.filter_by(role="admin").first():
        pw_hash = bcrypt.generate_password_hash(app.config["ADMIN_PASSWORD"]).decode('utf-8')
        admin = User(
            username=app.config["ADMIN_USERNAME"],
            email=app.config["ADMIN_EMAIL"],
            password_hash=pw_hash,
            role="admin"
        )
        db.session.add(admin)
        db.session.commit()
        print("Usuario administrador creado exitosamente.")

app = create_app()

if __name__ == "__main__":
    init_db(app)
    app.run(host="0.0.0.0", port=5000, debug=True)