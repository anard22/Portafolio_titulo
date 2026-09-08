# Smart Arena Experience – Avance de desarrollo (Semana 5)

Repositorio inicial con el avance del desarrollo del sistema de acuerdo a la
planificación de la Fase I del Proyecto APT (Semanas 3 a 5):

- Configuración del entorno y del repositorio (S3) ✔
- Diseño del modelo de datos relacional en MySQL (S3-S4) ✔
- Prototipos y mockups (S4-S5) en Figma ✔
- Implementación de autenticación y seguridad (S5) ✔ (en curso)

## Stack tecnológico
- **Backend:** Python + Flask, cifrado de contraseñas con `bcrypt`.
- **Base de datos:** MySQL (modelo normalizado en 3FN, procedimientos almacenados y triggers).
- **Frontend:** HTML, CSS y JavaScript (responsive web-first).

## Estructura
```
desarrollo/
├── README.md
├── bd/
│   └── smart_arena_db.sql      # DDL + procedimientos almacenados + triggers
├── backend/
│   ├── app.py                  # Aplicación Flask (login + endpoints básicos)
│   ├── config.py               # Configuración de la BD
│   ├── db.py                   # Conexión a MySQL
│   └── requirements.txt
└── frontend/
    ├── index.html
    ├── login.html
    ├── css/estilos.css
    └── js/app.js
```

## Próximos sprints (S6-S9)
- CRUD de usuarios, eventos, reservas y productos con lógica de negocio en la BD.
- Reportes de ventas, ocupación y afluencia con datos sintéticos (mínimo 10.000 registros).
- Pruebas funcionales y de seguridad (checklist OWASP Top 10, ≥95% de aprobación).