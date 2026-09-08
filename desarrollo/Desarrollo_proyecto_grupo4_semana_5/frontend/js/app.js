/* Smart Arena Experience - frontend JS (avance Semana 5) */

const API_BASE = "/"; // por defecto misma app Flask

document.addEventListener("DOMContentLoaded", () => {
  const formLogin = document.getElementById("form-login");
  if (formLogin) {
    formLogin.addEventListener("submit", async (e) => {
      e.preventDefault();
      const msg = document.getElementById("mensaje");
      const data = new FormData(formLogin);
      try {
        const res = await fetch(`${API_BASE}login`, { method: "POST", body: data });
        if (res.redirected) {
          window.location.href = res.url;
        } else {
          const json = await res.json();
          msg.hidden = false;
          msg.textContent = json.error || "Error al iniciar sesión.";
        }
      } catch (err) {
        msg.hidden = false;
        msg.textContent = "No se pudo conectar con el servidor.";
      }
    });
  }

  cargarEventos();
});

async function cargarEventos() {
  const contenedor = document.getElementById("lista-eventos");
  if (!contenedor) return;
  try {
    const res = await fetch(`${API_BASE}api/eventos`);
    const eventos = await res.json();
    if (!Array.isArray(eventos) || eventos.length === 0) {
      contenedor.innerHTML = "<p>No hay eventos publicados por ahora.</p>";
      return;
    }
    contenedor.innerHTML = "";
    eventos.forEach((ev) => {
      const tarjeta = document.createElement("article");
      tarjeta.className = "tarjeta-evento";
      tarjeta.innerHTML = `
        <h3>${escapeHtml(ev.nombre)}</h3>
        <p>${ev.fecha} · ${ev.hora}</p>
        <p>${escapeHtml(ev.recinto)}</p>`;
      contenedor.appendChild(tarjeta);
    });
  } catch {
    contenedor.innerHTML = "<p>No se pudieron cargar los eventos.</p>";
  }
}

function escapeHtml(texto) {
  const div = document.createElement("div");
  div.textContent = texto || "";
  return div.innerHTML;
}