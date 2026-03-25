 create database inventario1
 go 
 use inventario1
 go

 CREATE TABLE  categorias (
    id      INTEGER PRIMARY KEY ,
    nombre  varchar (100)   NOT NULL UNIQUE,
    creado  DATETIME DEFAULT CURRENT_TIMESTAMP
);
 
CREATE TABLE  productos (
    id           INTEGER PRIMARY KEY ,
    nombre       varchar (100)    NOT NULL,
    codigo       varchar (100)    NOT NULL UNIQUE,
    id_categoria INTEGER NOT NULL REFERENCES categorias(id),
    cantidad     INTEGER NOT NULL DEFAULT 0  CHECK(cantidad     >= 0),
    stock_minimo INTEGER NOT NULL DEFAULT 0  CHECK(stock_minimo >= 0),
    creado       DATETIME DEFAULT CURRENT_TIMESTAMP,
    actualizado  DATETIME DEFAULT CURRENT_TIMESTAMP
);
 
-- Historial de ingresos y egresos
CREATE TABLE  movimientos (
    id                INTEGER PRIMARY KEY ,
    id_producto       INTEGER NOT NULL REFERENCES productos(id),
    tipo              varchar (100)    NOT NULL CHECK(tipo IN ('INGRESO','EGRESO')),
    cantidad          INTEGER NOT NULL CHECK(cantidad > 0),
    cantidad_anterior INTEGER NOT NULL,
    cantidad_nueva    INTEGER NOT NULL,
    nota              TEXT,
    fecha             DATETIME DEFAULT CURRENT_TIMESTAMP
);
 
-- ── VISTAS ──────────────────────────────────────────────────
 
-- Inventario completo con estado de stock
CREATE VIEW  v_inventario AS
SELECT
    p.id,
    p.codigo,
    p.nombre,
    c.nombre    AS categoria,
    p.cantidad,
    p.stock_minimo,
    CASE
        WHEN p.cantidad <= p.stock_minimo THEN 'Bajo Stock'
        ELSE 'Normal'
    END         AS estado,
    p.actualizado
FROM productos  p
JOIN categorias c ON c.id = p.id_categoria;
 
-- Reporte resumen (equivale a la página generar-reporte.html)
CREATE VIEW   v_reporte AS
SELECT
    COUNT(*)                                                       AS total_productos,
    SUM(cantidad)                                                  AS cantidad_total,
    SUM(CASE WHEN cantidad <= stock_minimo THEN 1 ELSE 0 END)      AS productos_bajo_stock
FROM productos;
 
-- Historial detallado de movimientos
CREATE VIEW  v_movimientos AS
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
JOIN categorias  c ON c.id = p.id_categoria
 
-- ── DATOS DE EJEMPLO ────────────────────────────────────────
 
INSERT  INTO categorias (nombre) VALUES 
    ('Electrónica'),
    ('Papelería'),
    ('Herramientas'),
    ('Limpieza'),
    ('Alimentos');
 
INSERT  INTO productos (nombre, codigo, cantidad, stock_minimo) VALUES
    ('Laptop HP 15"',        'ELEC-001', 1, 12, 5),
    ('Mouse Inalámbrico',    'ELEC-002', 1, 35, 10),
    ('Teclado USB',          'ELEC-003', 1,  8, 10),
    ('Monitor 24"',          'ELEC-004', 1,  4,  5),
    ('Resma Papel A4',       'PAP-001',  2, 50, 20),
    ('Bolígrafos (caja x12)','PAP-002',  2, 15, 10),
    ('Carpetas AZ',          'PAP-003',  2,  6,  5),
    ('Martillo 16oz',        'HERR-001', 3,  9,  3),
    ('Destornillador Set',   'HERR-002', 3,  2,  3),
    ('Taladro Eléctrico',    'HERR-003', 3,  5,  2),
    ('Desengrasante 1L',     'LIMP-001', 4, 20,  8),
    ('Escoba Industrial',    'LIMP-002', 4,  3,  5),
    ('Café Molido 500g',     'ALIM-001', 5, 10,  5),
    ('Azúcar 1kg',           'ALIM-002', 5,  2,  5);
 
INSERT INTO movimientos (id_producto, tipo, cantidad, cantidad_anterior, cantidad_nueva, nota) VALUES
    (1,  'INGRESO', 12, 0,  12, 'Stock inicial'),
    (2,  'INGRESO', 35, 0,  35, 'Stock inicial'),
    (3,  'INGRESO', 10, 0,  10, 'Stock inicial'),
    (3,  'EGRESO',   2, 10,  8, 'Entrega área IT'),
    (5,  'INGRESO', 50, 0,  50, 'Compra mensual'),
    (5,  'EGRESO',   5, 50, 45, 'Uso interno'),
    (9,  'INGRESO',  5, 0,   5, 'Stock inicial'),
    (9,  'EGRESO',   3, 5,   2, 'Mantenimiento'),
    (14, 'INGRESO',  5, 0,   5, 'Stock inicial'),
    (14, 'EGRESO',   3, 5,   2, 'Cafetería');
 
-- ── CONSULTAS DE USO FRECUENTE ──────────────────────────────
 
-- Ver todo el inventario:
   SELECT * FROM v_inventario;
 
-- Ver solo productos con bajo stock:
   SELECT * FROM v_inventario WHERE estado = 'Bajo Stock';
 
-- Generar reporte resumen:
   SELECT * FROM v_reporte;
 
-- Buscar por nombre, categoría o código:
   SELECT * FROM v_inventario
   WHERE nombre LIKE '%mouse%'
      OR categoria LIKE '%mouse%'
      OR codigo LIKE '%mouse%';
 
-- Ver historial de movimientos de un producto:
   SELECT * FROM v_movimientos WHERE codigo = 'ELEC-003';
 
-- Registrar un INGRESO:
  INSERT INTO movimientos (id_producto, tipo, cantidad, cantidad_anterior, cantidad_nueva, nota)
   VALUES (3, 'INGRESO', 10, 8, 18, 'Reposición de stock');
  
-- Registrar un EGRESO:
   INSERT INTO movimientos (id_producto, tipo, cantidad, cantidad_anterior, cantidad_nueva, nota)
   VALUES (3, 'EGRESO', 2, 18, 16, 'Entrega área sistemas');
  