# Distribución de productos para tiendas: inventario, pedidos y agentes de IA

Aplicación móvil (Flutter) de gestión de inventario, pedidos y distribución de productos para tiendas, con agentes de inteligencia artificial que **proponen** acciones al administrador. Sirve para **cualquier tipo de producto** (helados, bebidas, snacks, abarrotes). Caso de ejemplo: distribuidor de helados.

> **Estado:** en desarrollo. Proyecto académico de la Carrera de Computación, sexto semestre, ESPAM MFL.

## Repositorios del proyecto

| Parte | Repositorio | Descripción |
| --- | --- | --- |
| **Backend** | (pega aquí el enlace) | API REST en Node.js + Express, base de datos MySQL y módulo de agentes de IA |
| **Frontend** | (pega aquí el enlace) | Aplicación móvil en Flutter (Dart) |
| **AdminWeb** | (pega aquí el enlace) | Panel web de administración |

## ¿Qué problema resuelve?

Los distribuidores que abastecen tiendas suelen llevar pedidos, entregas y cobros en cuadernos, WhatsApp o Excel. Eso causa errores en los pedidos, stock sin control, productos vencidos sin detectar y cobros olvidados. Esta aplicación centraliza esa información.

## Funcionalidades

- Inicio de sesión con roles: **administrador** y **repartidor**.
- Productos e inventario: categorías y unidades configurables, entradas de mercadería, alertas de stock bajo y de caducidad (opcional por categoría).
- Tiendas clientes con ruta y límite de crédito.
- Pedidos con validación automática de stock y de crédito. Estados: pendiente, despachado, entregado.
- Rutas de reparto, entrega y nota de entrega en PDF.
- Cobros: contado, crédito y abonos, con saldo pendiente por tienda.
- Reportes de ventas, stock y cuentas por cobrar.
- Agentes de IA que sugieren reposición, cobranza y rutas. **Solo proponen: el administrador aprueba.**

## Flujo principal

`Login → Pedido → Validación de stock y crédito → Despacho → Ruta del repartidor → Entrega → Cobro → Reportes`

## Arquitectura

`App Flutter → API REST (Node.js + Express) → MySQL`

El módulo de agentes está dentro del backend y llama a la API del modelo de IA. Las aplicaciones cliente nunca acceden directo a la base de datos ni a la IA.

## Tecnologías

| Uso | Tecnología |
| --- | --- |
| App móvil | Flutter (Dart) |
| Backend | Node.js + Express (patrón MVC) |
| Seguridad | bcrypt y JWT |
| Base de datos | MySQL |
| IA | API de Claude, modelo Claude Haiku 5.5 |
| Herramientas | Git y GitHub, Postman, Figma, draw.io, VS Code |

## Cómo ejecutarlo (backend)

Requisitos: Node.js y MySQL instalados.

```bash
git clone <enlace-del-repositorio-backend>
cd <carpeta-del-repositorio>
npm install
```

Crea un archivo `.env` en la raíz con tus valores (**nunca lo subas a GitHub**):

```
PORT=3000
DB_HOST=localhost
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña
DB_NAME=nombre_de_la_base
JWT_SECRET=una_clave_larga_y_secreta
ANTHROPIC_API_KEY=tu_clave_de_la_api_de_ia
```

Luego inicia el servidor con `npm start` (o el comando definido en el `package.json`).

## Cómo ejecutarlo (app móvil)

Requisitos: Flutter instalado y un emulador de Android o un teléfono real.

```bash
git clone <enlace-del-repositorio-frontend>
cd <carpeta-del-repositorio>
flutter pub get
flutter run
```

### Configuración de la API

La dirección del backend se define con `--dart-define=API_URL=...` (en `lib/config/config_api.dart`). Si no se indica:

| Plataforma | URL por defecto |
| --- | --- |
| Web y Windows | `http://localhost:3000/api` |
| Emulador de Android | `http://10.0.2.2:3000/api` (el emulador ve así el `localhost` del PC) |

Teléfono real: `flutter run --dart-define=API_URL=http://<IP-LAN-del-PC>:3000/api`. El backend escucha en `HOST=0.0.0.0`; hay que permitir el puerto 3000 en el firewall de Windows. En desarrollo (debug y profile) Android permite `http://`; en release se exigirá HTTPS.

### Probar en el navegador (Chrome o Edge)

1. Inicie el backend (`npm run dev` en `App_DistriGo_Backen`). Su `.env` debe incluir el origen de la app web: `CORS_ORIGENES=http://localhost:5173,http://localhost:5175` (reinicie el backend si lo cambia).
2. En esta carpeta: `flutter run -d chrome --web-port 5175` (o `-d edge`). El puerto 5175 es fijo para que coincida con CORS.
3. Para ver el tamaño de un teléfono, abra las herramientas de desarrollo (F12) y active la vista de dispositivo (por ejemplo 390x844).

Flutter web sirve solo para desarrollo y pruebas; el producto objetivo es Android. En web, `flutter_secure_storage` usa WebCrypto y `localStorage`.

### Windows de escritorio

`flutter run -d windows` exige activar el Modo de desarrollador de Windows (los plugins necesitan enlaces simbólicos). Hasta entonces use Chrome o Edge.

### Pruebas

```bash
flutter analyze
flutter test --exclude-tags integracion          # unitarias y de widgets
flutter test --tags integracion                  # contra el backend real (debe estar en marcha)
```

Las pruebas de integración leen las credenciales `TEST_REPARTIDOR_*` y `TEST_ADMIN_*` del `.env` del backend (o de las variables `E2E_*`) y no las imprimen.

### Alcance actual (Módulo 1)

Inicio de sesión del repartidor (la app rechaza cuentas de administrador), cierre de sesión, cierre automático por inactividad (el límite lo entrega el backend, 30 minutos por defecto) y una pantalla provisional "Mi ruta de hoy". La contraseña nunca se guarda; el token se guarda con `flutter_secure_storage`.

## Documentación

- `DERCAS_Sistema_Distribucion.docx`: especificaciones, requerimientos funcionales y criterios de aceptación (metodología DERCAS).
- `AGENTES.md`: contexto y reglas para los asistentes de IA que ayuden en el desarrollo.

## Autor

**Anthony Jossue Soledispa Soledispa**
Facilitador: Ing. Alfonso Tomas Loor
Carrera de Computación, sexto semestre, ESPAM MFL, Calceta, Ecuador.
