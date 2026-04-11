# 📚 Referencia API - Base de Datos

**Para Desarrolladores que implementan o extienden el sistema**

---

## ⚡ Referencia Rápida

```javascript
// Inicializar
await DB.getDB();

// SELECT (Consultar)
DB.qry(sql, params)

// INSERT/UPDATE/DELETE (Modificar)
DB.run(sql, params)

// Guardar manualmente
DB.saveDB()
```

---

## 📖 Referencia Completa

### **1. DB.getDB()**

```javascript
// Firma
async function getDB() → Database

// Descripción
// Obtiene o inicializa la instancia de BD.
// Primera llamada: crea schema + datos iniciales
// Llamadas posteriores: retorna desde caché

// Ejemplo
const db = await DB.getDB();

// En componentes
window.addEventListener('load', async () => {
  await DB.getDB();
  console.log('BD lista');
});
```

---

### **2. DB.qry(sql, params = [])**

```javascript
// Firma
function qry(sql: string, params: any[]) → Array<Object>

// Descripción
// Ejecuta SELECT. Retorna array de objetos.
// Nunca modifica la BD.

// Ejemplo 1: Sin parámetros
const todos = DB.qry("SELECT * FROM productos");
console.log(todos); // [{id: 1, nombre: "Laptop", ...}, ...]

// Ejemplo 2: Con parámetros (SQL Injection safe)
const producto = DB.qry(
  "SELECT * FROM productos WHERE id = ?", 
  [5]
);

// Ejemplo 3: Búsqueda
const resultados = DB.qry(
  "SELECT * FROM productos WHERE nombre LIKE ?",
  ['%Laptop%']
);

// Ejemplo 4: JOIN
const movimientos = DB.qry(`
  SELECT 
    m.id,
    m.tipo,
    m.fecha,
    p.nombre as producto,
    c.nombre as categoria
  FROM movimientos m
  JOIN productos p ON m.id_producto = p.id
  JOIN categorias c ON p.id_categoria = c.id
  WHERE m.fecha >= date('now', '-7 days')
  ORDER BY m.fecha DESC
`);

// Ejemplo 5: Agregaciones
const stats = DB.qry(`
  SELECT 
    COUNT(*) as total_productos,
    SUM(cantidad) as cantidad_total,
    AVG(cantidad) as cantidad_promedio
  FROM productos
`);

// Trampas comunes
const mal = DB.qry(
  "SELECT * FROM productos WHERE nombre = '" + nombre + "'"  // ❌ VULNERABLE
);

const bien = DB.qry(
  "SELECT * FROM productos WHERE nombre = ?",
  [nombre]  // ✅ SEGURO
);
```

---

### **3. DB.run(sql, params = [])**

```javascript
// Firma
function run(sql: string, params: any[]) → void

// Descripción
// Ejecuta INSERT/UPDATE/DELETE
// GUARDA AUTOMÁTICAMENTE en localStorage
// Retorna undefined

// Ejemplo 1: INSERT
DB.run(
  "INSERT INTO productos (nombre, codigo, id_categoria, cantidad, stock_minimo) VALUES (?, ?, ?, ?, ?)",
  ["Monitor LG 27", "ELEC-005", 1, 8, 5]
);

// Ejemplo 2: UPDATE
DB.run(
  "UPDATE productos SET cantidad = ?, actualizado = datetime('now') WHERE id = ?",
  [25, 3]
);

// Ejemplo 3: DELETE
DB.run(
  "DELETE FROM productos WHERE id = ?",
  [10]
);

// Ejemplo 4: INSERT movimiento (registro de auditoría)
const cantidadAnterior = 10;
const cantidadNueva = 15;
DB.run(
  `INSERT INTO movimientos (id_producto, tipo, cantidad, cantidad_anterior, cantidad_nueva) 
   VALUES (?, ?, ?, ?, ?)`,
  [5, 'INGRESO', cantidadNueva - cantidadAnterior, cantidadAnterior, cantidadNueva]
);

// Actualizar stock
DB.run(
  "UPDATE productos SET cantidad = ? WHERE id = ?",
  [cantidadNueva, 5]
);

// Nota: No necesitas llamar a saveDB() después, se hace automáticamente
```

---

### **4. DB.saveDB()**

```javascript
// Firma
function saveDB() → void

// Descripción
// Persiste la BD actual en localStorage
// SE LLAMA AUTOMÁTICAMENTE en cada run()
// Rara vez necesitas llamarla manualmente

// Método privado usado internamente
function saveDB() {
  const data = _db.export();
  const b64 = btoa(String.fromCharCode(...data));
  localStorage.setItem(DB_KEY, b64);
}

// Casos para llamarla manualmente:
// 1. Después de múltiples operaciones sin DB.run()
// 2. Antes de cerrar la ventana (por si acaso)

// Ejemplo
window.addEventListener('beforeunload', () => {
  DB.saveDB();
});
```

---

## 🗄️ Queries Útiles

### **Inventario**

```javascript
// Productos con stock bajo
DB.qry(`
  SELECT * FROM productos 
  WHERE cantidad <= stock_minimo 
  ORDER BY cantidad ASC
`);

// Productos agrupados por categoría
DB.qry(`
  SELECT c.nombre as categoria, COUNT(*) as num_productos, SUM(p.cantidad) as stock_total
  FROM productos p
  JOIN categorias c ON p.id_categoria = c.id
  GROUP BY c.id
  ORDER BY c.nombre
`);

// Búsqueda por código o nombre
const termino = "laptop";
DB.qry(
  "SELECT * FROM productos WHERE nombre LIKE ? OR codigo LIKE ?",
  [`%${termino}%`, `%${termino}%`]
);
```

### **Movimientos**

```javascript
// Últimos 30 días
DB.qry(`
  SELECT * FROM movimientos 
  WHERE fecha >= datetime('now', '-30 days')
  ORDER BY fecha DESC
`);

// Ingresos vs Egresos
DB.qry(`
  SELECT tipo, COUNT(*) as total, SUM(cantidad) as cant_total
  FROM movimientos
  GROUP BY tipo
`);

// Historial de producto específico
DB.qry(
  `SELECT m.* FROM movimientos m
   WHERE m.id_producto = ?
   ORDER BY m.fecha DESC`,
  [idProducto]
);

// Producto más movido
DB.qry(`
  SELECT 
    p.id, p.nombre, COUNT(*) as num_movimientos,
    SUM(CASE WHEN m.tipo='INGRESO' THEN m.cantidad ELSE 0 END) as total_ingreso,
    SUM(CASE WHEN m.tipo='EGRESO' THEN m.cantidad ELSE 0 END) as total_egreso
  FROM movimientos m
  JOIN productos p ON m.id_producto = p.id
  GROUP BY p.id
  ORDER BY num_movimientos DESC
  LIMIT 10
`);
```

---

## 🔍 Operaciones CRUD Completas

### **Create (Crear Producto)**

```javascript
function crearProducto(nombre, codigo, idCategoria, cantidadInicial = 0) {
  // Validar
  if (!nombre || !codigo) throw new Error('Nombre y código requeridos');
  
  // Insertar
  DB.run(
    `INSERT INTO productos (nombre, codigo, id_categoria, cantidad) 
     VALUES (?, ?, ?, ?)`,
    [nombre, codigo, idCategoria, cantidadInicial]
  );
  
  // Retornar último ID insertado
  const resultado = DB.qry("SELECT last_insert_rowid() as id");
  return resultado[0].id;
}

// Uso
const nuevoId = crearProducto('Mouse Gamer', 'ELEC-006', 1);
console.log('Creado ID:', nuevoId);
```

### **Read (Leer Producto)**

```javascript
function obtenerProducto(id) {
  const resultado = DB.qry(
    `SELECT p.*, c.nombre as categoria_nombre
     FROM productos p
     JOIN categorias c ON p.id_categoria = c.id
     WHERE p.id = ?`,
    [id]
  );
  return resultado[0]; // undefined si no existe
}

// Uso
const producto = obtenerProducto(1);
console.log(producto);
// {id: 1, nombre: "Laptop HP", codigo: "ELEC-001", categoria_nombre: "Electrónica", ...}
```

### **Update (Modificar Producto)**

```javascript
function actualizarProducto(id, campos) {
  // campos = {nombre, codigo, stock_minimo, ...}
  const updates = [];
  const valores = [];
  
  for (const [key, value] of Object.entries(campos)) {
    if (value !== undefined) {
      updates.push(`${key} = ?`);
      valores.push(value);
    }
  }
  
  if (updates.length === 0) return;
  
  valores.push(id);
  const sql = `UPDATE productos SET ${updates.join(', ')}, actualizado = datetime('now') WHERE id = ?`;
  
  DB.run(sql, valores);
}

// Uso
actualizarProducto(1, {
  nombre: 'Laptop HP 15" Actualizada',
  stock_minimo: 10
});
```

### **Delete (Eliminar Producto)**

```javascript
function eliminarProducto(id) {
  // Validar que no tenga movimientos
  const movimientos = DB.qry(
    "SELECT COUNT(*) as cnt FROM movimientos WHERE id_producto = ?",
    [id]
  );
  
  if (movimientos[0].cnt > 0) {
    throw new Error('No se puede eliminar, hay movimientos asociados');
  }
  
  DB.run("DELETE FROM productos WHERE id = ?", [id]);
}

// Uso
try {
  eliminarProducto(1);
  console.log('Eliminado');
} catch (e) {
  console.error(e.message);
}
```

---

## 🚨 Errores y Excepciones

```javascript
// SQL.js no lanza excepciones por defecto,
// pero sí valida restricciones:

try {
  // Violación de UNIQUE
  DB.run(
    "INSERT INTO productos (nombre, codigo, id_categoria, cantidad) VALUES (?, ?, ?, ?)",
    ["Laptop", "ELEC-001", 1, 5]  // ELEC-001 ya existe
  );
} catch (e) {
  console.error("Error:", e.message);
}

// CHECK constraints se validan silenciosamente
// Si cantidad = -5, se rechaza silenciosamente
```

---

## 🧪 Testing

```javascript
// Función para resetear BD en tests
function resetearBD() {
  localStorage.removeItem('inventario_db_v1');
  _db = null;
  return getDB();
}

// Uso en tests
beforeEach(async () => {
  await resetearBD();
});

test('Crear producto y verificar', async () => {
  await DB.getDB();
  
  const id = crearProducto('Test', 'TEST-001', 1);
  const p = obtenerProducto(id);
  
  expect(p.nombre).toBe('Test');
  expect(p.codigo).toBe('TEST-001');
});
```

---

## 📊 Rendimiento

| Operación | Tiempo típico | Notas |
|-----------|---------------|-------|
| SELECT 1000 registros | 5-10ms | Rápido |
| INSERT 100 registros | 50-100ms | Con múltiples saveDB() |
| JOIN de 3 tablas | 10-20ms | Depende tamaño datos |
| Full scan 10,000 registros | 20-50ms | Sin índices |

**Recomendación**: Para >50,000 registros, considerar backend SQLite real.

---

## 📄 Ejemplos de Uso Real

Ver archivos HTML adjuntos:
- `index.html` - Dashboard (lectura)
- `agregar-producto.html` - CRUD (creación)
- `ingreso-producto.html` - Movimientos (actualización)
- `generar-reporte.html` - Reportes (lectura compleja)

---

**Última actualización**: Abril 2026  
**Versión API**: 1.0  
**SQL.js**: 1.10.2
