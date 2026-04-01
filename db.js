// ─── db.js ───────────────────────────────────────────────────────────────────
// Base de datos SQLite en el navegador usando SQL.js
// Los datos se persisten en localStorage como base64.
// ─────────────────────────────────────────────────────────────────────────────

const DB_KEY = 'inventario_db_v1';
let _db = null;

async function getDB() {
  if (_db) return _db;

  const SQL = await initSqlJs({
    locateFile: f => `https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.10.2/${f}`
  });

  // Si ya existe una BD guardada, restaurarla
  const saved = localStorage.getItem(DB_KEY);
  if (saved) {
    const buf = Uint8Array.from(atob(saved), c => c.charCodeAt(0));
    _db = new SQL.Database(buf);
    return _db;
  }

  // Primera vez: crear esquema y datos de ejemplo
  _db = new SQL.Database();

  _db.run(`
    CREATE TABLE IF NOT EXISTS categorias (
      id      INTEGER PRIMARY KEY,
      nombre  TEXT    NOT NULL UNIQUE,
      creado  TEXT    DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS productos (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre       TEXT    NOT NULL,
      codigo       TEXT    NOT NULL UNIQUE,
      id_categoria INTEGER NOT NULL REFERENCES categorias(id),
      cantidad     INTEGER NOT NULL DEFAULT 0  CHECK(cantidad >= 0),
      stock_minimo INTEGER NOT NULL DEFAULT 0  CHECK(stock_minimo >= 0),
      creado       TEXT    DEFAULT (datetime('now')),
      actualizado  TEXT    DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS movimientos (
      id                INTEGER PRIMARY KEY AUTOINCREMENT,
      id_producto       INTEGER NOT NULL REFERENCES productos(id),
      tipo              TEXT    NOT NULL CHECK(tipo IN ('INGRESO','EGRESO')),
      cantidad          INTEGER NOT NULL CHECK(cantidad > 0),
      cantidad_anterior INTEGER NOT NULL,
      cantidad_nueva    INTEGER NOT NULL,
      nota              TEXT,
      fecha             TEXT    DEFAULT (datetime('now'))
    );

    INSERT OR IGNORE INTO categorias (id, nombre) VALUES
      (1,'Electrónica'),(2,'Papelería'),(3,'Herramientas'),(4,'Limpieza'),(5,'Alimentos');

    INSERT OR IGNORE INTO productos (id,nombre,codigo,cantidad,id_categoria,stock_minimo) VALUES
      (1,  'Laptop HP 15"',     'ELEC-001', 10, 1, 5),
      (2,  'Mouse Inalámbrico', 'ELEC-002', 15, 1, 10),
      (3,  'Teclado USB',       'ELEC-003', 12, 1, 10),
      (4,  'Monitor 24"',       'ELEC-004',  5, 1,  5),
      (13, 'Café Molido 500g',  'ALIM-001',  5, 5,  5),
      (14, 'Azúcar 1kg',        'ALIM-002', 16, 5,  5);

    INSERT OR IGNORE INTO movimientos (id,id_producto,tipo,cantidad,cantidad_anterior,cantidad_nueva) VALUES
      (1, 1, 'INGRESO', 10, 5, 15);
  `);

  saveDB();
  return _db;
}

function saveDB() {
  const data = _db.export();
  const b64  = btoa(String.fromCharCode(...data));
  localStorage.setItem(DB_KEY, b64);
}

// ── Helpers de consulta ──────────────────────────────────────────────────────

function qry(sql, params = []) {
  const res = _db.exec(sql, params);
  if (!res.length) return [];
  const { columns, values } = res[0];
  return values.map(r => Object.fromEntries(columns.map((c, i) => [c, r[i]])));
}

function run(sql, params = []) {
  _db.run(sql, params);
  saveDB();
}

// ── API pública ──────────────────────────────────────────────────────────────

window.DB = { getDB, saveDB, qry, run };
