# 📚 Sistema de Gestión de Biblioteca de Libros Electrónicos

**Proyecto integrador — Programación Orientada a Objetos 2**

Aplicación web REST para administrar libros electrónicos, usuarios y préstamos, desarrollada con la librería estándar de Go (`net/http`, `encoding/json`, `sync`, etc.), sin dependencias de terceros.

---

## 🎯 Objetivo

Desarrollar un sistema de gestión de biblioteca de libros electrónicos capaz de administrar libros, usuarios y préstamos, exponiendo sus funcionalidades mediante servicios web REST y manteniendo seguridad frente a solicitudes concurrentes.

---

## 🧩 Arquitectura

El sistema se organiza en cuatro capas:

| Capa | Responsabilidad |
|---|---|
| `modelo/` | Entidades del dominio y validaciones (encapsulamiento) |
| `repositorio/` | Interfaces + almacenamiento en memoria con `sync.RWMutex` |
| `servicio/` | Reglas de negocio e inyección de dependencias |
| `web/` | HTTP/JSON, handlers, router y logging asíncrono |

---

## 🛠️ Servicios REST

El proyecto cuenta con **9 endpoints REST**, superando el mínimo de 8 servicios web solicitado para el proyecto final:

| Método | Endpoint | Función |
|---|---|---|
| POST | `/api/libros` | Agregar libro |
| GET | `/api/libros` | Listar libros |
| GET | `/api/libros/genero/{genero}` | Filtrar por género |
| POST | `/api/libros/importar` | Importar libros en paralelo |
| POST | `/api/usuarios` | Registrar usuario |
| GET | `/api/usuarios/{id}` | Consultar usuario |
| GET | `/api/usuarios/{id}/historial` | Consultar historial |
| POST | `/api/prestamos` | Registrar préstamo |
| POST | `/api/prestamos/{id}/devolver` | Registrar devolución |

Los datos de entrada y salida se serializan mediante **JSON**.

---

## 🔄 Funcionamiento

El sistema permite realizar el siguiente flujo:

1. Registrar un usuario.
2. Registrar un libro.
3. Consultar el catálogo.
4. Solicitar un préstamo.
5. Validar la disponibilidad del libro.
6. Consultar el historial del usuario.
7. Devolver el libro.
8. Volver a prestar el libro.

El sistema también controla conflictos como intentar prestar un libro que ya se encuentra prestado.

---

## 🔐 Manejo de errores

Los errores de negocio se traducen a códigos HTTP:

- **400** — Datos inválidos (`DATOS_INVALIDOS`, `JSON_INVALIDO`, `ID_INVALIDO`).
- **404** — Recurso no encontrado (libro, usuario o préstamo).
- **409** — Conflicto (libro no disponible, préstamo ya devuelto).
- **500** — Error interno del servidor.

---

## ⚡ Concurrencia

El sistema utiliza:

- **Goroutines** — Para ejecutar tareas concurrentes (cada solicitud HTTP y la importación de libros).
- **Channels** — Para implementar comunicación entre goroutines y logging asíncrono (patrón productor/consumidor).
- **sync.RWMutex** — Para proteger los repositorios en memoria.
- **sync.WaitGroup** — Para esperar la finalización de los procesos concurrentes.

Las pruebas de concurrencia se ejecutan mediante:

```bash
go test ./... -race
```

---

## 🧪 Pruebas

El proyecto contiene tres niveles de pruebas:

- **Pruebas unitarias** — Validan la lógica de negocio de forma aislada.
- **Pruebas de integración** — Validan la comunicación entre HTTP, handlers, servicios y repositorios.
- **Prueba de aceptación** — Valida el flujo completo: registro → publicación → préstamo → historial → devolución → nuevo préstamo.

---

## 🚀 Instalación

### Requisitos

- [Go](https://go.dev/dl/) 1.22 o superior
- [Git](https://git-scm.com/)

### Clonar el repositorio

```bash
git clone https://github.com/Rm-Angel/Sistema-de-Gestion-de-Libros-electronicos.git
```

### Entrar al proyecto

```bash
cd Sistema-de-Gestion-de-Libros-electronicos
```

### Ejecutar el proyecto

```bash
go run main.go
```

El servidor estará disponible en:

```
http://localhost:8080
```

### Ejecutar pruebas

```bash
go test ./...
```

```bash
go test ./... -v
```

```bash
go test ./... -race
```

---

## 📂 Estructura del proyecto

```text
.
├── main.go
├── go.mod
├── README.md
├── .gitignore
├── modelo/
├── repositorio/
├── servicio/
├── web/
├── docs/
├── presentacion/
└── video/
```

---

## 🔮 Visualización del futuro

El proyecto puede evolucionar en diferentes etapas:

| Etapa | Tecnologías |
|---|---|
| **Actualmente** | Go, REST, JSON, almacenamiento en memoria, concurrencia |
| **Próximo paso** | PostgreSQL, Docker, persistencia de datos |
| **Mediano plazo** | Kubernetes, autoescalado, múltiples instancias |
| **Futuro** | IA (recomendación de libros), gRPC, GraphQL, arquitectura basada en microservicios |

---

## 🎓 Aplicaciones prácticas

El modelo desarrollado puede aplicarse en:

- Bibliotecas educativas.
- Universidades.
- Colegios.
- Gestión de activos empresariales.
- Reservas de equipos.
- Servicios gubernamentales digitales.

---

## 👨‍💻 Autor

**Angel Josue Ramirez Mora**

Programación Orientada a Objetos 2 — SOF-3A

UIDE — Agosto 2026

---

## 📄 Documentación

La carpeta `docs/` contiene la documentación complementaria del proyecto:

- `informe_etapa2.docx` — informe del proyecto integrador.
- `visualizacion_futuro.md` — introducción, criterio de selección, aplicaciones prácticas y visión a futuro.
- `integracion_unidades.md` — integración de las cuatro unidades de la asignatura.

---

## 🎥 Video demostrativo

El video demostrativo presenta:

- Repositorio de GitHub.
- Ejecución del servidor.
- Registro de usuario.
- Registro de libro.
- Consulta del catálogo.
- Préstamo.
- Intento de segundo préstamo (conflicto 409).
- Consulta del historial.
- Devolución.
- Pruebas de concurrencia.
- Ejecución de pruebas.

> Enlace del video: *(PEGAR_AQUI_EL_ENLACE)*

---

## 📌 Estado del proyecto

Proyecto integrador finalizado.

**Fecha:** Agosto 2026