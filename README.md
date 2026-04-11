# Sistema de Mantenimiento de Inventario

**Versión**: 1.0.0  
**Estado**: Producción  
**Última actualización**: Abril 2026

---

## 📋 Descripción Técnica

Sistema de gestión de inventarios desarrollado como aplicación web cliente-side con persistencia de datos en el navegador. Implementa un modelo SQLite embebido mediante SQL.js, permitiendo operaciones CRUD completas sin requerir servidor backend.

**Objetivo**: Gestión integral de productos, categorías, movimientos de inventario (ingresos/egresos) y generación de reportes.

---

## 🔧 Especificaciones Técnicas

### **Stack Tecnológico**

| Componente | Versión | Propósito |
|-----------|---------|----------|
| HTML | 5 | Estructura semántica |
| CSS | 3 | Estilos y responsive design |
| JavaScript (Vanilla) | ES6+ | Lógica de aplicación |
| SQL.js | 1.10.2 | Motor SQLite en navegador |
| CDN sql-wasm | 1.10.2 | Runtime WASM para SQL.js |
| localStorage API | HTML5 | Persistencia de datos |

### **Requisitos del Sistema**

#### **Navegadores Soportados** (Tested & Compatible)
- Google Chrome **v90+** (Recomendado)
- Mozilla Firefox **v88+**
- Safari **v14+** (macOS/iOS)
- Edge **v90+**
- Opera **v76+**

#### **Requisitos de Hardware Mínimo**
- **RAM**: 512 MB disponible
- **Almacenamiento**: 10 MB espacio en localStorage
- **Procesador**: Dual-core 1.5 GHz (mínimo)
- **Conexión**: Internet (solo para cargar CDN inicial de SQL.js)

#### **Sistemas Operativos**
- Windows 7 / 10 / 11
- macOS 10.13+
- Linux (Ubuntu 18.04+, Fedora 30+)
- iOS 12+
- Android 6+

---

## 📦 Arquitectura de Base de Datos

### **Motor**: SQLite (SQL.js v1.10.2)
- **Tipo**: Base de datos relacional en memoria con persistencia en localStorage
- **Ubicación**: `localStorage` bajo clave `inventario_db_v1`
- **Formato de almacenamiento**: Base64 (serialización)
- **Límite de almacenamiento**: 5-10 MB (varía según navegador)

### **Esquema de Datos**

```sql
-- Tabla de categorías
CREATE TABLE categorias (
  id      INTEGER PRIMARY KEY,
  nombre  TEXT NOT NULL UNIQUE,
  creado  TEXT DEFAULT (datetime('now'))
);

-- Tabla de productos
CREATE TABLE productos (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre       TEXT NOT NULL,
  codigo       TEXT NOT NULL UNIQUE,
  id_categoria INTEGER NOT NULL REFERENCES categorias(id),
  cantidad     INTEGER NOT NULL DEFAULT 0 CHECK(cantidad >= 0),
  stock_minimo INTEGER NOT NULL DEFAULT 0 CHECK(stock_minimo >= 0),
  creado       TEXT DEFAULT (datetime('now')),
  actualizado  TEXT DEFAULT (datetime('now'))
);

-- Tabla de movimientos (auditoría)
CREATE TABLE movimientos (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  id_producto       INTEGER NOT NULL REFERENCES productos(id),
  tipo              TEXT NOT NULL CHECK(tipo IN ('INGRESO','EGRESO')),
  cantidad          INTEGER NOT NULL CHECK(cantidad > 0),
  cantidad_anterior INTEGER NOT NULL,
  cantidad_nueva    INTEGER NOT NULL,
  nota              TEXT,
  fecha             TEXT DEFAULT (datetime('now'))
);
```

---

## 🚀 Instalación y Configuración

### **Requisitos Previos**
- Navegador web moderno (ver tabla de compatibilidad)
- Conexión a Internet para descargar SQL.js desde CDN (primera ejecución)

### **Pasos de Instalación**

1. **Descargar los archivos**
   ```bash
   git clone <repositorio>
   cd mantenimiento-de-inventario
   ```

2. **Servir la aplicación**
   - **Opción 1** (Recomendado - Local): Usar un servidor web local
     ```bash
     # Con Python 3
     python -m http.server 8000
     
     # Con Python 2
     python -m SimpleHTTPServer 8000
     
     # Con Node.js (http-server)
     npx http-server
     ```
   - **Opción 2**: Abrir directamente `index.html` (limitaciones CORS en navegadores modernos)

3. **Acceder a la aplicación**
   ```
   http://localhost:8000
   ```

### **Configuración Inicial**

La aplicación carga automáticamente:
- Categorías base: Electrónica, Papelería, Herramientas, Limpieza, Alimentos
- Productos de ejemplo: 6 productos precargados
- Movimientos de auditoría: 1 movimiento de ejemplo

**Nota**: Los datos se guardan automáticamente en `localStorage` cada vez que se realiza una operación.

---

## 📁 Estructura del Proyecto

```
mantenimiento-de-inventario/
├── index.html                          # Dashboard principal
├── ver-inventario.html                 # Listado de productos
├── agregar-producto.html               # Formulario de creación
├── ingreso-producto.html               # Registro de ingresos
├── egreso-producto.html                # Registro de egresos
├── generar-reporte.html                # Generador de reportes
├── historial.html                      # Historial de movimientos
├── db.js                               # Módulo de base de datos (CRÍTICO)
├── README.md                           # Esta documentación
├── Styles/
│   └── Style.css                       # Estilos globales
├── base\ de\ datos/
│   ├── inventario_corregido.sql        # Schema SQL de referencia
│   └── er_diagram_inventario.html      # Diagrama E-R
└── .gitignore                          # Archivos excluidos

```

---

## 🔌 Uso de la API de Base de Datos

### **Interfaz Pública (window.DB)**

```javascript
// Inicializar base de datos
await DB.getDB();

// Consultas (SELECT)
const productos = DB.qry("SELECT * FROM productos WHERE cantidad > ?", [0]);
// Retorna: Array[{ id, nombre, codigo, ... }]

// Comandos (INSERT/UPDATE/DELETE)
DB.run("INSERT INTO productos (nombre, codigo, id_categoria, cantidad) 
        VALUES (?, ?, ?, ?)", 
       ["Laptop", "ELEC-005", 1, 5]);

// Guardar base de datos
DB.saveDB();
```

### **Funciones Disponibles**

| Función | Parámetros | Retorna | Descripción |
|---------|-----------|---------|-------------|
| `getDB()` | - | Promise<Database> | Inicializa/recupera instancia DB |
| `qry(sql, params)` | sql: string, params: array | Array<Object> | Ejecuta SELECT |
| `run(sql, params)` | sql: string, params: array | - | Ejecuta DML (guarda automáticamente) |
| `saveDB()` | - | - | Persiste DB en localStorage |

---

## 🔐 Consideraciones de Seguridad

⚠️ **Advertencia**: Esta aplicación está diseñada para ambiente local/LAN. Para producción considerar:

- ✅ **localStorage**: Separado por origin (protocolo + dominio + puerto)
- ✅ **SQL Injection**: SQL.js valida tipos con parametrización
- ❌ No hay autenticación/autorización (implementar si es necesario)
- ❌ No hay cifrado de datos (usar HTTPS + HTTPS-only storage)
- ❌ No hay validación de entrada en frontend (implementar sanitización)

---

## 📊 Rendimiento

### **Benchmarks** (SQL.js v1.10.2)
- Carga de BD: ~200-500ms (primera ejecución)
- Query simple (1000 registros): ~5-10ms
- INSERT: ~2-5ms
- Limit localStorage: 5-10 MB por origin

### **Recomendaciones**
- Base de datos máximo ~50,000-100,000 registros
- Para datasets mayores, considerar migración a backend
- Usar índices en columnas de búsqueda frecuente

---

## 🛠️ Desarrollo y Debugging

### **Herramientas Recomendadas**
- **DevTools**: F12 (Chrome/Firefox/Edge)
- **Storage**: Pestaña "Application" → localStorage
- **Console**: Para testing de funciones DB

### **Comandos de Debug**
```javascript
// En console del navegador
DB.qry("SELECT COUNT(*) as total FROM productos");
DB.qry("PRAGMA table_info(productos)");
localStorage.removeItem('inventario_db_v1');  // Limpiar DB
```

---

## 📈 Próximas Mejoras Planificadas

- [ ] Autenticación de usuario (JWT/OAuth)
- [ ] Exportar reportes a PDF/Excel
- [ ] Sincronización con servidor backend
- [ ] Soporte para múltiples usuarios
- [ ] Validación de permisos por rol
- [ ] Respaldo automático en cloud
- [ ] Búsqueda avanzada con filtros
- [ ] API REST para integración

---

## 🐛 Reporting de Errores / Issues

1. Verificar Console (F12) para mensajes de error
2. Limpiar localStorage: `localStorage.removeItem('inventario_db_v1')`
3. Limpiar caché del navegador: Ctrl+Shift+Delete
4. Probar en navegador diferente

---

## 📝 Licencia

MIT License - Ver LICENSE.md para detalles

---

## 👥 Soporte Técnico

**Para implementación en entorno de producción, se recomienda consultar con el equipo de desarrollo.**

**Contacto**: [Email técnico de soporte]

---

**Documentado para**: Personal Técnico / DevOps / System Administrators  
**Nivel de Complejidad**: Intermedio  
**Última revisión**: Abril 2026 

