# 🔧 Guía Técnica de Instalación y Configuración

**Dirigida a**: Desarrolladores, Administradores de Sistemas, Personal de IT  
**Nivel**: Intermedio-Avanzado

---

## 📌 Tabla de Contenidos

1. [Inicio Rápido](#inicio-r%C3%A1pido)
2. [Configuración Detallada](#configuraci%C3%B3n-detallada)
3. [Conexión de Base de Datos](#conexi%C3%B3n-de-base-de-datos)
4. [Troubleshooting](#troubleshooting)
5. [Deployment](#deployment)

---

## 🚀 Inicio Rápido

### Opción 1: Python (Recomendado)
```bash
# Navegar a la carpeta del proyecto
cd c:\Users\aleja\OneDrive\Desktop\1\mantenimiento-de-inventario

# Python 3
python -m http.server 8000

# Python 2 (discontinued)
python -m SimpleHTTPServer 8000
```

### Opción 2: Node.js
```bash
# Instalar http-server globalmente (una sola vez)
npm install -g http-server

# Inicia servidor en puerto 8000
http-server -p 8000 -c-1
```

### Opción 3: Visual Studio Code
```bash
# Instalar extensión "Live Server"
# Click derecho en index.html → Open with Live Server
# Se abre automáticamente en http://localhost:5500
```

---

## 🗂️ Configuración Detallada

### **Directorio de Proyecto**

El servidor web debe servir desde la raíz del proyecto:

```
mantenimiento-de-inventario/        ← Raíz del servidor
├── index.html                      ← Página inicial
├── db.js                           ← Motor de BD (CRÍTICO)
├── Styles/
│   └── Style.css
└── ...archivos HTML...
```

**Verificación**: Acceder a `http://localhost:8000/index.html` en el navegador.

### **Variables de Entorno**

No se requieren variables de entorno. La aplicación usa configuración hardcoded en `db.js`:

```javascript
const DB_KEY = 'inventario_db_v1';  // Clave en localStorage
```

### **Permisos de Archivos**

En Linux/macOS, asegurar permisos de lectura:

```bash
chmod -R 644 mantenimiento-de-inventario/
chmod 755 mantenimiento-de-inventario/
```

---

## 🔌 Conexión de Base de Datos

### **Arquitectura Actual**

```
┌─────────────────────────────────────────────┐
│        Navegador (Cliente)                  │
│  ┌─────────────────────────────────────┐  │
│  │  Aplicación HTML/CSS/JavaScript     │  │
│  │  ┌───────────────────────────────┐  │  │
│  │  │  db.js (Módulo BD)            │  │  │
│  │  │  - Inicializa SQL.js          │  │  │
│  │  │  - Gestiona localStorage      │  │  │
│  │  └───────────────────────────────┘  │  │
│  └─────────────────────────────────────┘  │
│              ↓                             │
│  ┌─────────────────────────────────────┐  │
│  │  HTML5 localStorage (5-10 MB)       │  │
│  │  Almacena BD en Base64              │  │
│  └─────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### **Flujo de Inicialización**

```
1. Usuario abre index.html
                 ↓
2. Se carga db.js automáticamente
   - Importa SQL.js desde CDN
   - Valida localStorage
                 ↓
3. getDB() busca BD existente
   │
   ├─ SI EXISTE: Recupera del localStorage
   │            ↓
   │           Deserializa Base64 → SQLite
   │
   └─ NO EXISTE: Crea BD nueva
                ↓
               Schema inicial (categorías, productos)
               Datos precargados
                ↓
4. Guarda en localStorage con saveDB()
```

### **Código de Conexión (db.js)**

```javascript
// Obtener instancia de BD
async function getDB() {
  if (_db) return _db;  // Caché en memoria

  const SQL = await initSqlJs({
    locateFile: f => `https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.10.2/${f}`
  });

  // Intenta recuperar BD guardada
  const saved = localStorage.getItem(DB_KEY);
  if (saved) {
    const buf = Uint8Array.from(atob(saved), c => c.charCodeAt(0));
    _db = new SQL.Database(buf);
    return _db;
  }

  // Crea BD nueva en primera ejecución
  _db = new SQL.Database();
  _db.run(`CREATE TABLE productos (...)`);
  saveDB();
  return _db;
}

// Guardar cambios en localStorage
function saveDB() {
  const data = _db.export();
  const b64 = btoa(String.fromCharCode(...data));
  localStorage.setItem(DB_KEY, b64);
}
```

### **Verificar Conexión en Consola**

Abrir DevTools (F12) → Console y ejecutar:

```javascript
// Verificar que módulo DB está disponible
console.log(window.DB);

// Inicializar BD
await DB.getDB();

// Probar consulta
const productos = DB.qry("SELECT * FROM productos LIMIT 5");
console.table(productos);

// Ver espacio usado en localStorage
const data = localStorage.getItem('inventario_db_v1');
console.log("Tamaño BD:", (data.length / 1024 / 1024).toFixed(2), "MB");
```

---

## 🔄 Migración desde Base de Datos SQL

Si tienes un archivo `.sql` y quieres importarlo:

### Opción 1: Usar `inventario_corregido.sql`

El archivo `base de datos/inventario_corregido.sql` contiene el schema completo. Para usarlo:

1. **Extraer SQL original** (si proviene de MySQL/PostgreSQL):
   ```sql
   -- Adaptar a SQL.js (compatible con SQLite)
   -- Cambios necesarios:
   -- - AUTO_INCREMENT → AUTOINCREMENT
   -- - INT → INTEGER
   -- - NOW() → datetime('now')
   ```

2. **Importar manualmente**:
   ```javascript
   const sqlScript = `
     CREATE TABLE categorias (...);
     INSERT INTO categorias VALUES (...);
   `;
   
   const statements = sqlScript.split(';');
   statements.forEach(stmt => {
     if (stmt.trim()) DB.run(stmt);
   });
   ```

### Opción 2: Crear migración automática

Archivo: `migrations/import-sql.js`

```javascript
async function importFromSQL(sqlContent) {
  const db = await DB.getDB();
  const lines = sqlContent.split('\n');
  let currentSQL = '';

  for (let line of lines) {
    currentSQL += line + '\n';
    if (line.trim().endsWith(';')) {
      db.run(currentSQL);
      currentSQL = '';
    }
  }
  DB.saveDB();
}

// Uso:
const sql = await fetch('inventario_corregido.sql').then(r => r.text());
await importFromSQL(sql);
```

---

## 🌐 Acceso Remoto (LAN)

Para acceder desde otra máquina en la misma red:

### Windows (Command Prompt)
```bash
ipconfig
# Buscar "IPv4 Address" (ej: 192.168.1.100)

# Luego en otra máquina:
# http://192.168.1.100:8000
```

### Linux/macOS
```bash
ifconfig
# Buscar inet address

# O simplemente:
hostname -I
```

### Configurar Firewall (Windows)
```powershell
# Permitir puerto 8000
netsh advfirewall firewall add rule name="HTTP 8000" dir=in action=allow protocol=tcp localport=8000

# Verificar
netsh advfirewall firewall show rule name="HTTP 8000"
```

---

## 🆘 Troubleshooting

### Problema: "Loading base de datos..." infinito

**Causa**: CDN de SQL.js no se carga (sin internet)

**Solución**:
```javascript
// En db.js, descargar wasm localmente:
locateFile: f => '/js/sql-wasm/' + f  // Servir desde /js/sql-wasm/
```

---

### Problema: localStorage quota exceeded

**Causa**: BD supera 5-10 MB

**Solución**:
```javascript
// Limpiar datos antiguos
DB.run("DELETE FROM movimientos WHERE fecha < date('now', '-30 days')");

// O exportar a archivo y crear BD nueva
function exportDB() {
  const data = localStorage.getItem('inventario_db_v1');
  const blob = new Blob([data], {type: 'text/plain'});
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'backup_' + new Date().toISOString() + '.txt';
  a.click();
}
```

---

### Problema: Cambios no persisten

**Causa**: No se llamó a `DB.saveDB()`

**Solución**: Verificar que cada `DB.run()` sea seguido por `saveDB()`:
```javascript
// ❌ MALO - Los cambios se pierden
DB.run("INSERT INTO productos...");

// ✅ BIEN - Se guarda automáticamente
DB.run("INSERT INTO productos...");  // saveDB() se llama dentro
```

---

### Problema: Caché del navegador previene actualizaciones

**Solución**:
```bash
# Limpiar caché
Ctrl+Shift+Delete  # Windows
Cmd+Shift+Delete   # Mac

# O deshabilitar caché en DevTools
F12 → Network → Disable cache
```

---

## 📦 Deployment

### Opción 1: Servidor Compartido (SMB/NFS)

```bash
# En Windows, compartir carpeta como red
# Luego acceder desde: \\IP\compartido\index.html
```

### Opción 2: Docker

Archivo: `Dockerfile`

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY . .
EXPOSE 8000
CMD ["python", "-m", "http.server", "8000"]
```

```bash
# Build
docker build -t inventario-app .

# Run
docker run -p 8000:8000 inventario-app
```

### Opción 3: IIS (Internet Information Services)

1. Abrir IIS Manager
2. Agregar sitio web → Seleccionar carpeta del proyecto
3. Configurar permisos: Users → Lectura, Ejecución
4. Permitir archivos estáticos en MIME types

### Opción 4: Apache

```apache
# /etc/apache2/sites-available/inventario.conf
<VirtualHost *:80>
    DocumentRoot /var/www/mantenimiento-de-inventario
    <Directory /var/www/mantenimiento-de-inventario>
        Require all granted
    </Directory>
</VirtualHost>
```

---

## 🔐 Producción - Checklist de Seguridad

- [ ] Usar HTTPS (certificado SSL/TLS)
- [ ] Configurar CORS si es necesario
- [ ] Validación de entrada en Frontend + Backend
- [ ] Sanitizar datos antes de guardar
- [ ] Implementar autenticación
- [ ] Backup automático de localStorage
- [ ] Rate limiting en API (si existe backend)
- [ ] Logs de auditoría para cambios críticos
- [ ] Encriptación de datos sensibles

---

## 📞 Soporte Técnico

Para problemas avanzados:

1. Verificar logs en DevTools (F12)
2. Revisar archivo `inventario_corregido.sql` para consistencia
3. Ejecutar: `DB.qry("PRAGMA integrity_check;")` en consola
4. Hacer backup de localStorage antes de cambios masivos

---

**Última actualización**: Abril 2026  
**Versión**: 1.0.0  
**Mantenedor**: [Tu equipo técnico]
