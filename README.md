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

La dirección del backend se configura en el archivo de configuración de la app.

## Documentación

- `DERCAS_Sistema_Distribucion.docx`: especificaciones, requerimientos funcionales y criterios de aceptación (metodología DERCAS).
- `AGENTES.md`: contexto y reglas para los asistentes de IA que ayuden en el desarrollo.

## Autor

**Anthony Jossue Soledispa Soledispa**
Facilitador: Ing. Alfonso Tomas Loor
Carrera de Computación, sexto semestre, ESPAM MFL, Calceta, Ecuador.
