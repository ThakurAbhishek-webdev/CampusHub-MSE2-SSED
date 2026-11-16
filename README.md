# CampusHub – Dockerized Multi-Service Application

CampusHub is a containerized college event management application built using Docker and Docker Compose. It uses multiple independent services for frontend delivery, API processing, background jobs, database storage, caching, messaging, and file uploads.

## 1. Architecture

The application consists of nine services:

| Service | Technology | Purpose |
|---|---|---|
| Gateway | Nginx | Routes incoming requests |
| Frontend | React + Vite | User interface |
| API | Node.js + Express | Backend REST API |
| Worker | Node.js | Processes background email jobs |
| Database | PostgreSQL | Persistent application data |
| Cache | Redis | Event caching |
| Message Broker | RabbitMQ | Registration email queue |
| Object Storage | MinIO-compatible Silo | Image storage |
| Email Testing | MailHog | Captures outgoing emails |

### Request Flow

- `/` → Frontend
- `/api/` → Backend API
- `/storage/` → Object storage

The Gateway is the only publicly exposed application entry point.

## 2. Project Structure

```text
MSE-2-mock-SSED/
├── app/
│   ├── api/
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── .dockerignore
│   ├── frontend/
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── .dockerignore
│   ├── Dockerfile.gateway
│   └── nginx.conf
├── docker-compose.yml
├── .env
├── .env.example
├── README.md
└── task.md
```

## 3. Prerequisites

Install the following:

- Docker Desktop
- Docker Compose
- Git

Ensure Docker Desktop is running before executing commands.

## 4. Environment Configuration

Create a local environment file:

```powershell
Copy-Item .env.example .env
```

Update the environment variables in `.env` as required.

Do not commit `.env` or expose real credentials in the repository.

## 5. Build and Run

Build all images and start the services:

```bash
docker compose up -d --build --wait
```

Check running containers:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs -f
```

Stop the application:

```bash
docker compose down
```

Restart without deleting persistent data:

```bash
docker compose up -d
```

## 6. Application Access

| Component | URL |
|---|---|
| CampusHub Application | http://localhost:8083 |
| API Health Endpoint | http://localhost:8083/api/health |
| MailHog Dashboard | http://localhost:8025 |

MailHog is bound to localhost for development and testing.

## 7. Docker Design Decisions

### Multi-stage Frontend Build
The frontend uses a Node.js build stage and an unprivileged Nginx runtime image. This keeps build dependencies out of the final image.

### Shared API and Worker Image
The API and Worker use the same Docker image. The Worker runs using the `npm run worker` command, avoiding unnecessary image duplication.

### Network Isolation
Docker Compose uses separate frontend, backend, and data networks to organize service communication.

### Persistent Storage
Named Docker volumes preserve PostgreSQL, Redis, and object-storage data across container restarts.

### Non-root Containers
Frontend, API, Worker, and Gateway processes run without root privileges.

## 8. Verification and Testing

The following checks were performed:

- All nine services started successfully.
- Docker health checks passed for the configured services.
- API health endpoint returned a successful response.
- Redis caching returned `MISS` on the first request and `HIT` on a subsequent request.
- RabbitMQ successfully queued registration email jobs.
- Worker processed email jobs and MailHog captured the emails.
- Image uploads were stored and retrieved through the Gateway.
- Database and uploaded image data persisted after restarting the Compose stack.
- Only the Gateway was exposed on the public host interface.
- API image size was approximately 223 MB, below the 250 MB target.

## 9. Useful Docker Commands

```bash
# List containers
docker compose ps

# View API logs
docker compose logs api

# View Worker logs
docker compose logs worker

# Inspect images
docker images

# Inspect networks
docker network ls

# Inspect volumes
docker volume ls

# Stop and remove containers
docker compose down

# Rebuild and restart
docker compose up -d --build
```

## 10. Conclusion

CampusHub demonstrates multi-service application containerization using Docker and Docker Compose. The setup includes service isolation, health checks, persistent volumes, caching, asynchronous job processing, object storage, and centralized request routing through Nginx.

The project was tested locally using Docker Desktop.