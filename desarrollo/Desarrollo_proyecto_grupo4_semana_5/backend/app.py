"""Smart Arena Experience - Backend (avance Semana 5).

Aplicación Flask con autenticación por roles (bcrypt) y endpoints
básicos. En sprints posteriores se agregan los módulos CRUD completos.
"""
import functools

import bcrypt
from flask import Flask, jsonify, redirect, render_template, request, session, url_for

from db import autenticar_usuario

app = Flask(__name__)
app.config.from_object("config.Config")


def requiere_login(rol):
    """Decorador que controla acceso por sesión y rol (admin/operador/cliente)."""

    def decorador(f):
        @functools.wraps(f)
        def wrapper(*args, **kwargs):
            if "usuario_id" not in session:
                return redirect(url_for("login"))
            if rol and session.get("rol") != rol:
                return jsonify({"error": "No tiene permisos para esta operación."}), 403
            return f(*args, **kwargs)
        return wrapper
    return decorador


@app.route("/")
def index():
    return render_template_index()


def render_template_index():
    return ("Smart Arena Experience API activa. "
            "Usa /login, /register o los endpoints /api/*.")


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "GET":
        return "Página de login (frontend en /frontend/login.html)"
    email = request.form.get("email")
    password = request.form.get("password")
    usuario = autenticar_usuario(email)
    if usuario and bcrypt.checkpw(password.encode("utf-8"),
                                  usuario["password_hash"].encode("utf-8")):
        session["usuario_id"] = usuario["id"]
        session["rol"] = usuario["rol"]
        session["nombre"] = usuario["nombre"]
        return redirect(url_for("inicio"))
    return jsonify({"error": "Credenciales incorrectas."}), 401


@app.route("/register", methods=["POST"])
def register():
    nombre = request.form.get("nombre")
    email = request.form.get("email")
    password = request.form.get("password")
    if not all([nombre, email, password]):
        return jsonify({"error": "Faltan campos obligatorios."}), 400
    hash_password = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
    # Llamar a sp_registrar_usuario con hash_password
    return jsonify({"mensaje": "Usuario registrado (avance).",
                    "password_hash": hash_password.decode("utf-8")}), 201


@app.route("/inicio")
@requiere_login(None)
def inicio():
    return jsonify({
        "mensaje": f"Hola {session.get('nombre')}",
        "rol": session.get("rol"),
    })


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/api/health")
def health():
    return jsonify({"estado": "ok", "proyecto": "Smart Arena Experience",
                    "semana": 5})


if __name__ == "__main__":
    app.run(debug=True, port=5000)