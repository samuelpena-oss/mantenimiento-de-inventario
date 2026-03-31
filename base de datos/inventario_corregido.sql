-- ============================================================
--  BASE DE DATOS: inventario1  (corregida)
-- ============================================================

CREATE DATABASE IF NOT EXISTS inventario1;
USE inventario1;

-- ── TABLAS ──────────────────────────────────────────────────

CREATE TABLE categorias (
    id      INTEGER      PRIMARY KEY,
    nombre  VARCHAR(100) NOT NULL UNIQUE,
    creado  DATETIME     DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE productos (
    id           INTEGER      PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    codigo       VARCHAR(100) NOT NULL UNIQUE,
    id_categoria INTEGER      NOT NULL REFERENCES categorias(id),
    cantidad     INTEGER      NOT NULL DEFAULT 0  CHECK(cantidad     >= 0),
    stock_minimo INTEGER      NOT NULL DEFAULT 0  CHECK(stock_minimo >= 0),
    creado       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    actualizado  DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- Historial de ingresos y egresos
CREATE TABLE movimientos (
    id                INTEGER      PRIMARY KEY,
    id_producto       INTEGER      NOT NULL REFERENCES productos(id),
    tipo              VARCHAR(100) NOT NULL CHECK(tipo IN ('INGRESO','EGRESO')),  -- solo estos dos valores son válidos
    cantidad          INTEGER      NOT NULL CHECK(cantidad > 0),
    cantidad_anterior INTEGER      NOT NULL,
    cantidad_nueva    INTEGER      NOT NULL,
    nota              TEXT,
    fecha             DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- ── VISTAS ──────────────────────────────────────────────────

-- Inventario completo con estado de stock
CREATE VIEW v_inventario AS
SELECT
    p.id,
    p.codigo,
    p.nombre,
    c.nombre AS categoria,
    p.cantidad,
    p.stock_minimo,
    CASE
        WHEN p.cantidad <= p.stock_minimo THEN 'Bajo Stock'
        ELSE 'Normal'
    END      AS estado,
    p.actualizado
FROM productos  p
JOIN categorias c ON c.id = p.id_categoria;

-- Reporte resumen
CREATE VIEW v_reporte AS
SELECT
    COUNT(*)                                                  AS total_productos,
    SUM(cantidad)                                             AS cantidad_total,
    SUM(CASE WHEN cantidad <= stock_minimo THEN 1 ELSE 0 END) AS productos_bajo_stock
FROM productos;

-- Historial detallado de movimientos
CREATE VIEW v_movimientos AS
SELECT
    m.id,
    m.fecha,
    p.codigo,
    p.nombre         AS producto,
    c.nombre         AS categoria,
    m.tipo,
    m.cantidad,
    m.cantidad_anterior,
    m.cantidad_nueva,
    m.nota
FROM movimientos m
JOIN productos   p ON p.id = m.id_producto
JOIN categorias  c ON c.id = p.id_categoria;   -- ← faltaba el punto y coma

-- ── DATOS DE EJEMPLO ────────────────────────────────────────

INSERT INTO categorias (id, nombre) VALUES
    (1, 'Electrónica'),
    (2, 'Papelería'),
    (3, 'Herramientas'),
    (4, 'Limpieza'),
    (5, 'Alimentos');

-- CORRECCIÓN: id_categoria ahora apunta a categorías que existen
--   Laptop, Mouse, Teclado, Monitor → Electrónica (id=1)
--   Café, Azúcar                    → Alimentos   (id=5)
INSERT INTO productos (id, nombre, codigo, cantidad, id_categoria, stock_minimo) VALUES
    (1,  'Laptop HP 15"',     'ELEC-001', 10, 1, 5),
    (2,  'Mouse Inalámbrico', 'ELEC-002', 15, 1, 10),
    (3,  'Teclado USB',       'ELEC-003', 12, 1, 10),
    (4,  'Monitor 24"',       'ELEC-004',  5, 1,  5),
    (13, 'Café Molido 500g',  'ALIM-001',  5, 5,  5),
    (14, 'Azúcar 1kg',        'ALIM-002', 16, 5,  5);

-- CORRECCIÓN: tipo cambiado a 'INGRESO' (valor permitido por el CHECK)
INSERT INTO movimientos (id, id_producto, tipo, cantidad, cantidad_anterior, cantidad_nueva) VALUES
    (1, 1, 'INGRESO', 10, 5, 15);

-- ── CONSULTAS DE USO FRECUENTE ──────────────────────────────

SELECT * FROM categorias;
SELECT * FROM productos;
SELECT * FROM movimientos;

-- Ver todo el inventario:
SELECT * FROM v_inventario;

-- Ver solo productos con bajo stock:
SELECT * FROM v_inventario WHERE estado = 'Bajo Stock';

-- Generar reporte resumen:
SELECT * FROM v_reporte;

-- Buscar por nombre, categoría o código:
SELECT * FROM v_inventario
WHERE nombre   LIKE '%mouse%'
   OR categoria LIKE '%mouse%'
   OR codigo    LIKE '%mouse%';

-- Ver historial de movimientos de un producto:
SELECT * FROM v_movimientos WHERE codigo = 'ELEC-003';
