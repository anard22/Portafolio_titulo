-- ============================================================
-- Smart Arena Experience - Modelo de datos (Avance Semana 5)
-- MySQL 8, normalizado en 3FN.
-- Contiene: DDL de tablas, procedimientos almacenados y triggers.
-- ============================================================

CREATE DATABASE IF NOT EXISTS smart_arena_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE smart_arena_db;

-- ------------------------------------------------------------
-- Tablas base
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS usuario (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  nombre         VARCHAR(120) NOT NULL,
  email          VARCHAR(150) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  rol            ENUM('cliente','operador','administrador') NOT NULL DEFAULT 'cliente',
  activo         TINYINT(1) NOT NULL DEFAULT 1,
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS evento (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  nombre     VARCHAR(150) NOT NULL,
  fecha      DATE NOT NULL,
  hora       TIME NOT NULL,
  recinto    VARCHAR(120) NOT NULL,
  capacidad  INT NOT NULL,
  estado     ENUM('programado','en_curso','finalizado','cancelado') NOT NULL DEFAULT 'programado',
  creado_por INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_evento_usuario FOREIGN KEY (creado_por) REFERENCES usuario(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS producto (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(120) NOT NULL,
  descripcion VARCHAR(255) NULL,
  precio      DECIMAL(10,2) NOT NULL,
  stock       INT NOT NULL DEFAULT 0,
  activo      TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pedido (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id     INT NOT NULL,
  evento_id      INT NULL,
  modalidad      ENUM('click_collect') NOT NULL DEFAULT 'click_collect',
  punto_retiro   VARCHAR(80) NULL,
  estado         ENUM('recibido','en_preparacion','listo','entregado','cancelado') NOT NULL DEFAULT 'recibido',
  total          DECIMAL(10,2) NOT NULL DEFAULT 0,
  fecha_pedido   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pedido_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id),
  CONSTRAINT fk_pedido_evento  FOREIGN KEY (evento_id)  REFERENCES evento(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pedido_detalle (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id  INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad   INT NOT NULL,
  subtotal   DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_det_pedido   FOREIGN KEY (pedido_id)   REFERENCES pedido(id),
  CONSTRAINT fk_det_producto FOREIGN KEY (producto_id) REFERENCES producto(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ticket (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id     INT NOT NULL,
  evento_id      INT NOT NULL,
  codigo_acceso  VARCHAR(20) NOT NULL UNIQUE,
  zona           VARCHAR(40) NOT NULL,
  asiento        VARCHAR(20) NULL,
  estado         ENUM('activo','usado','anulado') NOT NULL DEFAULT 'activo',
  fecha_compra   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ticket_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id),
  CONSTRAINT fk_ticket_evento  FOREIGN KEY (evento_id)  REFERENCES evento(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reserva (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id    INT NOT NULL,
  espacio       VARCHAR(80) NOT NULL,
  fecha_inicio  DATETIME NOT NULL,
  fecha_fin     DATETIME NOT NULL,
  estado        ENUM('pendiente','confirmada','cancelada') NOT NULL DEFAULT 'pendiente',
  comentario    VARCHAR(255) NULL,
  CONSTRAINT fk_reserva_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Procedimientos almacenados (avance inicial)
-- ------------------------------------------------------------

DELIMITER $$

-- Registrar un nuevo usuario con contraseña cifrada (bcrypt) desde la app.
CREATE PROCEDURE sp_registrar_usuario(
  IN p_nombre VARCHAR(120),
  IN p_email VARCHAR(150),
  IN p_password_hash VARCHAR(255),
  IN p_rol ENUM('cliente','operador','administrador')
)
BEGIN
  INSERT INTO usuario (nombre, email, password_hash, rol)
  VALUES (p_nombre, p_email, p_password_hash, p_rol);
END$$

-- Autenticación: retorna el usuario cuyo email coincide y está activo.
CREATE PROCEDURE sp_autenticar_usuario(IN p_email VARCHAR(150))
BEGIN
  SELECT id, nombre, email, password_hash, rol
  FROM usuario
  WHERE email = p_email AND activo = 1
  LIMIT 1;
END$$

-- Crear un evento (lógica de negocio en BD).
CREATE PROCEDURE sp_crear_evento(
  IN p_nombre VARCHAR(150), IN p_fecha DATE, IN p_hora TIME,
  IN p_recinto VARCHAR(120), IN p_capacidad INT, IN p_creado_por INT
)
BEGIN
  INSERT INTO evento (nombre, fecha, hora, recinto, capacidad, creado_por)
  VALUES (p_nombre, p_fecha, p_hora, p_recinto, p_capacidad, p_creado_por);
END$$

-- Consultar disponibilidad: tickets vendidos vs capacidad.
CREATE PROCEDURE sp_consulta_ocupacion_evento(IN p_evento_id INT)
BEGIN
  SELECT e.id, e.nombre, e.capacidad,
         COUNT(t.id) AS tickets_vendidos,
         (e.capacidad - COUNT(t.id)) AS disponibles
  FROM evento e
  LEFT JOIN ticket t ON t.evento_id = e.id AND t.estado <> 'anulado'
  WHERE e.id = p_evento_id
  GROUP BY e.id, e.nombre, e.capacidad;
END$$

-- Crear pedido Click & Collect y calcular total.
CREATE PROCEDURE sp_crear_pedido(
  IN p_usuario_id INT, IN p_evento_id INT,
  IN p_punto_retiro VARCHAR(80),
  IN p_producto_id INT, IN p_cantidad INT
)
BEGIN
  DECLARE v_precio DECIMAL(10,2);
  DECLARE v_pedido_id INT;
  DECLARE v_subtotal DECIMAL(10,2);

  SELECT precio INTO v_precio FROM producto WHERE id = p_producto_id AND activo = 1;
  SET v_subtotal = v_precio * p_cantidad;

  INSERT INTO pedido (usuario_id, evento_id, modalidad, punto_retiro, total)
  VALUES (p_usuario_id, p_evento_id, 'click_collect', p_punto_retiro, v_subtotal);

  SET v_pedido_id = LAST_INSERT_ID();

  INSERT INTO pedido_detalle (pedido_id, producto_id, cantidad, subtotal)
  VALUES (v_pedido_id, p_producto_id, p_cantidad, v_subtotal);

  SELECT v_pedido_id AS pedido_id, v_subtotal AS total;
END$$

-- Cambiar estado de un pedido (gestión del operador).
CREATE PROCEDURE sp_cambiar_estado_pedido(
  IN p_pedido_id INT,
  IN p_estado ENUM('recibido','en_preparacion','listo','entregado','cancelado')
)
BEGIN
  UPDATE pedido SET estado = p_estado WHERE id = p_pedido_id;
END$$

-- Ventas diarias (base para reportes).
CREATE PROCEDURE sp_reporte_ventas_diarias(IN p_fecha DATE)
BEGIN
  SELECT DATE(fecha_pedido) AS dia,
         COUNT(DISTINCT id) AS pedidos,
         SUM(total)         AS ingresos
  FROM pedido
  WHERE DATE(fecha_pedido) = p_fecha AND estado <> 'cancelado'
  GROUP BY DATE(fecha_pedido);
END$$

-- Afluencia por evento (tickets emitidos).
CREATE PROCEDURE sp_reporte_afluencia_evento(IN p_evento_id INT, IN p_desde DATE, IN p_hasta DATE)
BEGIN
  SELECT DATE(fecha_compra) AS dia, COUNT(*) AS asistentes
  FROM ticket
  WHERE evento_id = p_evento_id
    AND DATE(fecha_compra) BETWEEN p_desde AND p_hasta
    AND estado <> 'anulado'
  GROUP BY DATE(fecha_compra)
  ORDER BY dia;
END$$

-- ------------------------------------------------------------
-- Triggers (avance inicial)
-- ------------------------------------------------------------

-- 1) Impide vender tickets por sobre la capacidad del recinto.
CREATE TRIGGER trg_control_capacidad_tickets
BEFORE INSERT ON ticket
FOR EACH ROW
BEGIN
  DECLARE v_cap INT DEFAULT 0;
  DECLARE v_vent INT DEFAULT 0;
  SELECT capacidad INTO v_cap FROM evento WHERE id = NEW.evento_id;
  SELECT COUNT(*)  INTO v_vent FROM ticket WHERE evento_id = NEW.evento_id AND estado <> 'anulado';
  IF v_vent >= v_cap THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Capacidad del recinto agotada para este evento.';
  END IF;
END$$

-- 2) Disminuye el stock al confirmar un pedido.
CREATE TRIGGER trg_descontar_stock
AFTER INSERT ON pedido_detalle
FOR EACH ROW
BEGIN
  UPDATE producto
     SET stock = stock - NEW.cantidad
   WHERE id = NEW.producto_id;
END$$

-- 3) Evita stock negativo.
CREATE TRIGGER trg_evitar_stock_negativo
BEFORE INSERT ON pedido_detalle
FOR EACH ROW
BEGIN
  DECLARE v_stock INT DEFAULT 0;
  SELECT stock INTO v_stock FROM producto WHERE id = NEW.producto_id;
  IF NEW.cantidad > v_stock THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Stock insuficiente para el producto solicitado.';
  END IF;
END$$

-- 4) Registra auditoría de cambios de estado del pedido.
CREATE TABLE IF NOT EXISTS auditoria_pedido (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id       INT NOT NULL,
  estado_anterior VARCHAR(30) NULL,
  estado_nuevo    VARCHAR(30) NOT NULL,
  registrado_en   DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TRIGGER trg_auditoria_pedido
AFTER UPDATE ON pedido
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_pedido (pedido_id, estado_anterior, estado_nuevo, registrado_en)
  VALUES (NEW.id, OLD.estado, NEW.estado, NOW());
END$$

DELIMITER ;