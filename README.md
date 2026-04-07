# Docker Notes

---

## 0 — Core Concepts

| Term | What it is |
|---|---|
| **Image** | Blueprint of your app (like a class) |
| **Container** | A running instance of an image (like an object) |
| **Dockerfile** | Instructions to build your own image |
| **Docker Hub** | Public registry to pull/push images |

### Architecture

```
        You
         │
    Docker CLI
         │
    Docker Daemon  ──── Docker Hub
         │
   ┌─────┴──────┐
   │  Containers │
   └────────────┘
```

| Component | Role |
|---|---|
| Docker CLI | What you type commands into |
| Docker Daemon | Background service that does the work |
| Docker Hub | Remote registry where images are stored |

---

## 1 — Docker Commands

```bash
# ── System ──────────────────────────────────────────────
docker --version                          # check version
docker info                               # system-wide info
docker help                               # show all commands

# ── Search & Pull Images ────────────────────────────────
docker search <name>                      # find images on Docker Hub
docker pull <image>:<tag>                 # download image

# ── List & Remove Images ────────────────────────────────
docker images                             # list images
docker images -a                          # include intermediate images
docker rmi <imageId>                      # remove image

# ── Create & Start Containers ───────────────────────────
docker create <imageId>                   # create container (not started)
docker start <containerId>                # start container
docker start -ai <containerId>            # start + attach terminal

# ── Run Containers (all-in-one) ─────────────────────────
docker run <image>                        # pull + create + start
docker run -it <image>                    # run interactively
docker run -d -p 8080:80 nginx            # run web app in background

# ── Inspect & Manage Containers ─────────────────────────
docker ps                                 # running containers
docker ps -a                              # all containers
docker pause <containerId>                # freeze container
docker unpause <containerId>              # resume container
docker stop <containerId>                 # graceful shutdown
docker rm <containerId>                   # delete container

# ── Debug & Logs ────────────────────────────────────────
docker logs <containerId>                 # view container output
docker exec -it <containerId> <cmd>       # run command inside container
```

> `docker run` = `pull + create + start` in one command

### Flags

| Flag | Meaning | When to use |
|---|---|---|
| `-i` | Interactive — keep STDIN open | When container expects input |
| `-t` | TTY — allocate a terminal | When you want a shell |
| `-it` | Interactive terminal | Use together for shell access |
| `-a` | Attach — see container output | When you want to see logs |
| `-ai` | Attach + interactive | Start a stopped interactive container |
| `-d` | Detached — run in background | Web apps, servers |

---

## 2 — Running a JDK Container

```bash
# Pull JDK image
docker pull eclipse-temurin:25-jdk-ubi10-minimal

# Run interactively — drops you into a shell inside the container
docker run -it eclipse-temurin:25-jdk-ubi10-minimal

# Inside the container
java -version
jshell

# Exit
exit

# Check state
docker ps -a

# Clean up
docker stop <containerId>
docker rm <containerId>
```

> Container ID can be shortened — the first 2–3 unique characters work.
> For example, `docker start 38f` instead of `docker start 38f89eee8292`.

### Common Mistakes & Fixes

| Problem | Cause | Fix |
|---|---|---|
| `docker start` shows nothing | Output not attached | Add `-a` flag |
| Container exits immediately | No interactive session | Use `docker run -it` |
| `docker rmi` fails | Container still exists | Run `docker rm` first |
| Can't find container | Looking at running only | Use `docker ps -a` |
| `docker start -it` does nothing | Wrong flag for start | Use `docker start -ai` instead |

---

## 3 — Packaging a Spring Boot Web App

### 1. Create the project

Use [Spring Initializr](https://start.spring.io) → Maven → Spring Web.

### 2. Add a controller

```java
@RestController
public class HelloController {
    @GetMapping("/")
    public String helloWorld() { return "Hello World"; }
}
```

### 3. Update `pom.xml`

```xml
<build>
    <finalName>rest-demo</finalName>
</build>
```

### 4. Build the JAR

```bash
mvn clean package
```

### 5. Run the JAR locally

```bash
java -jar target/rest-demo.jar
```

### 6. Test in browser

Open `http://localhost:8080/` → should display `Hello World`.

---

## 4 — Running Spring Boot on Docker

```bash
# 1. Check running containers
docker ps

# 2. List all files in the container's root
docker exec <container_name> ls -a

# 3. Check contents of /tmp
docker exec <container_name> ls /tmp

# 4. Copy the JAR into the container
docker cp target/rest-demo.jar <container_name>:/tmp

# 5. Verify the JAR is present
docker exec <container_name> ls /tmp

# 6. Commit the container as a new image
docker commit <container_name> utk/rest-demo:v1

# 7. Confirm the image was created
docker images

# 8. Run v1 — defaults to JShell
docker run utk/rest-demo:v1
```

### Overriding the default command with `--change`

By default, `utk/rest-demo:v1` opens JShell. Override this when committing:

```bash
# Commit with a default CMD to run the JAR directly
docker commit --change='CMD ["java", "-jar", "/tmp/rest-demo.jar"]' \
  <container_name> utk/rest-demo:v2

# Run v2 — starts the Spring Boot app directly
docker run utk/rest-demo:v2

# Map ports
docker run -p 8081:8081 utk/rest-demo:v2
```

---

## 5 — Dockerfile

Instead of committing containers manually, define the image declaratively with a `Dockerfile`:

```dockerfile
FROM amazoncorretto:26-jdk
LABEL authors="Utkarsh"
ADD target/rest-demo.jar rest-demo.jar
ENTRYPOINT ["java", "-jar", "/rest-demo.jar"]
```

### `docker build` variants

| Command | What it does |
|---|---|
| `docker build .` | Build from Dockerfile in current directory |
| `docker build -t <name>:<tag> .` | Build and tag the image |
| `docker build https://github.com/docker/rootfs.git#container:docker` | Build from a remote Git repo |
| `docker build https://yourserver/file.tar.gz` | Build from a remote tar archive |

```bash
# Build and tag
docker build -t utk/rest-demo:v4 .

# Confirm image exists
docker images

# Run with port mapping
docker run -p 8080:8080 utk/rest-demo:v4
```

---

## 6 — Web App with Postgres

- Added PostgreSQL and JPA dependencies to `pom.xml`
- Added `Student` entity, repository, and REST controller
- Added database initialization and a `/students` endpoint to retrieve students

---

## 7 — Docker Compose

### Key commands

| Command | What it does |
|---|---|
| `docker-compose up` | Create and start all containers |
| `docker-compose up --build` | Rebuild images then start containers |
| `docker-compose down` | Stop and remove all containers |
| `docker-compose ps` | List containers defined in the Compose file |
| `docker-compose logs` | View logs from all containers |

### `docker-compose.yml`

```yaml
services:
  app:
    build: .
    ports:
      - "8090:8080"

  postgres:
    image: postgres:latest
    environment:
      username: root
      password: root
      DB: studentsDkr07042026
    ports:
      - "5433:5432"
```

### Workflow

```bash
# 1. Build the JAR
mvn clean package

# 2. Build images and start containers
docker-compose up --build

# 3. Verify images
docker images
```

# Step 8: Running Multiple Containers

## Objective
Configure the Spring Boot app and PostgreSQL to run together in Docker containers on the **same custom network**, so they can communicate with each other.

---

## 8.1 — Update Database Connection Properties

Update `application.properties` and add two environment-specific property files to handle different runtime contexts:

**`application-postgres-container.properties`** *(used inside Docker)*
```properties
spring.datasource.url=jdbc:postgresql://postgres:5432/studentsDkr07042026
spring.datasource.username=root
spring.datasource.password=root
```
> ⚠️ Notice the hostname is `postgres` — not `localhost`. Inside Docker, containers refer to each other by **service name**, not `localhost`.

**`application-postgres-local.properties`** *(used when running locally)*
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/studentsDkr07042026
spring.datasource.username=root
spring.datasource.password=root
```

---

## 8.2 — Build the Application JAR

```bash
mvn clean package -DskipTests
```

---

## 8.3 — First `docker-compose up` — Containers Start, But Can't Talk

```bash
docker-compose up --build
```

Both containers start successfully:

```
CONTAINER ID   IMAGE                         PORTS                     NAMES
4048c751baad   postgres:latest               0.0.0.0:5433->5432/tcp    docker-containerization-postgres-1
4cdf9743929e   docker-containerization-app   0.0.0.0:8090->8080/tcp    docker-containerization-app-1
```

**Problem:** The app is unreachable from `localhost:8090`.

**Why?** Docker Compose automatically creates a default network (`docker-containerization_default`), but the containers were not explicitly placed on a **shared custom network**, causing communication issues.

```bash
docker network ls
# docker-containerization_default   bridge   local   ← auto-created, but not wired correctly
```

---

## 8.4 — Fix: Define a Custom Network in `docker-compose.yml`

Update `docker-compose.yml` to place both services on the same explicitly defined network:

```yaml
services:
  app:
    build: .
    ports:
      - "8090:8080"
    networks:
      - utk-01-docker-net

  postgres:
    image: postgres:latest
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: root
      POSTGRES_DB: studentsDkr07042026
    ports:
      - "5433:5432"
    networks:
      - utk-01-docker-net

networks:
  utk-01-docker-net:
    driver: bridge
```

---

## 8.5 — Tear Down and Rebuild

```bash
docker-compose down
```
```
✔ Container docker-containerization-app-1      Removed
✔ Container docker-containerization-postgres-1 Removed
```

```bash
docker-compose up --build
```

Verify the custom network now exists:
```bash
docker network ls

# docker-containerization_utk-01-docker-net   bridge   local   ✅
```

---

## 8.6 — Verify It Works

Open your browser or Postman and hit:
```
GET http://localhost:8090/getStudents
```
✅ **Returns data successfully.**

---

## Key Takeaways

| Concept | Explanation |
|---|---|
| `postgres` as hostname | Inside Docker, use the **service name** as the hostname, not `localhost` |
| Custom network | Both containers must be on the **same network** to discover each other |
| `docker-compose down` | Always tear down before rebuilding to avoid stale container/network state |
| Port mapping | `5433:5432` and `8090:8080` expose container ports to your **host machine** |


# Step 9: Docker Volumes

## Objective
Understand why container data is lost on `docker-compose down`, and fix it using a **named volume** so PostgreSQL data persists across restarts.

---

## 9.1 — Add a New Endpoint to Insert a Student

Add this endpoint to your controller to test data persistence:

```java
@RequestMapping("/addStudents")
public void addStudent(Student student) {
    Student s = new Student();
    s.setName("Raj");
    s.setAge(30);
    repository.save(s);
}
```

Rebuild the JAR:
```bash
mvn clean package -DskipTests
```

---

## 9.2 — Demonstrate the Problem: Data Is Lost on Restart

**Cycle 1 — Add data and verify it exists:**

```bash
docker-compose up --build
```

Hit `http://localhost:8090/addStudents`, then check `http://localhost:8090/getStudents`:

```json
[
  { "id": 1, "name": "Navin", "age": 20 },
  { "id": 2, "name": "Kiran", "age": 22 },
  { "id": 3, "name": "Harsh", "age": 30 },
  { "id": 4, "name": "Sushil", "age": 12 },
  { "id": 5, "name": "Raj",   "age": 30 }   ✅ newly added
]
```

**Tear down:**
```bash
docker-compose down
```
```
✔ Container docker-containerization-app-1           Removed
✔ Container docker-containerization-postgres-1      Removed
✔ Network docker-containerization_utk-01-docker-net Removed
```

**Cycle 2 — Bring it back up:**
```bash
docker-compose up --build
```

Check `http://localhost:8090/getStudents` again:

```json
[
  { "id": 1, "name": "Navin",  "age": 20 },
  { "id": 2, "name": "Kiran",  "age": 22 },
  { "id": 3, "name": "Harsh",  "age": 30 },
  { "id": 4, "name": "Sushil", "age": 12 }
]
```

❌ **"Raj" is gone.** The PostgreSQL container was destroyed along with all its data.

**Why?** By default, PostgreSQL stores data *inside the container's filesystem*. When the container is removed, that filesystem — and all the data — is deleted with it.

---

## 9.3 — Fix: Add a Named Volume in `docker-compose.yml`

Update `docker-compose.yml` to mount a **named volume** at PostgreSQL's data directory:

```yaml
services:
  app:
    build: .
    ports:
      - "8090:8080"
    networks:
      - utk-01-docker-net

  postgres:
    image: postgres:latest
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: root
      POSTGRES_DB: studentsDkr07042026
    ports:
      - "5433:5432"
    networks:
      - utk-01-docker-net
    volumes:
      - utk-01-docker-postgres-data:/var/lib/postgres/data  # ← mount here

networks:
  utk-01-docker-net:
    driver: bridge

volumes:
  utk-01-docker-postgres-data:   # ← declare the named volume
```

> ⚠️ The correct PostgreSQL data path is `/var/lib/postgresql/data` (not `/var/lib/postgres/data`). or vice versa

---

## 9.4 — Verify Data Persists Across Restarts

Rebuild and bring everything up:
```bash
mvn clean package -DskipTests
docker-compose down
docker-compose up --build
```

Check `http://localhost:8090/getStudents` — existing seed data is intact. Now hit `http://localhost:8090/addStudents` **twice**, then verify:

```json
[
  { "id": 1, "name": "Navin",  "age": 20 },
  { "id": 2, "name": "Kiran",  "age": 22 },
  { "id": 3, "name": "Harsh",  "age": 30 },
  { "id": 4, "name": "Sushil", "age": 12 },
  { "id": 5, "name": "Raj",    "age": 30 },
  { "id": 6, "name": "Raj",    "age": 30 }
]
```

Now tear down and bring back up again:
```bash
docker-compose down
docker-compose up --build
```

Check `http://localhost:8090/getStudents` — ✅ **all 6 records are still there.** Data survived the restart.

---

## 9.5 — Completely Wipe Data (Including the Volume)

To intentionally destroy the volume and start fresh:

```bash
docker-compose down -v
```

The `-v` flag removes the named volume along with the containers. The next `up` will start with a clean database.

---

## Key Takeaways

| Concept | Explanation |
|---|---|
| No volume | Data lives inside the container — destroyed with `docker-compose down` |
| Named volume | Data lives on the **Docker host** — survives container restarts and rebuilds |
| `/var/lib/postgresql/data` | The directory inside the PostgreSQL container where it stores all DB files |
| `docker-compose down` | Removes containers and networks, but **keeps** named volumes |
| `docker-compose down -v` | Removes containers, networks, **and** named volumes — full clean slate |