## step0: Docker

| Term | What it is |
|---|---|
| **Image** | Blueprint of your app (like a class) |
| **Container** | A running instance of an image (like an object) |
| **Dockerfile** | Instructions to build your own image |
| **Docker Hub** | Public registry to pull/push images |

Docker Architecture

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
- **Docker CLI** — what you type commands into
- **Docker Daemon** — the background service that does the work
- **Docker Hub** — remote registry where images are stored

---
## step1:Docker Commands
Step1:Docker commands

```
==============================
        DOCKER CHEAT SHEET
==============================

# 1. Check Docker
docker info                              # system-wide Docker info
docker --version                          # check version

# 2. Explore CLI
docker help                               # show commands

# 3. Search & Pull Images
docker search <name>                      # find images on Docker Hub
docker pull <image>:<tag>                 # download image

# 4. List & Remove Images
docker images                             # list images
docker images -a                          # include intermediate images
docker rmi <imageId>                      # remove image

# 5. Create & Start Containers
docker create <imageId>                   # create container (not started)
docker start <containerId>                # start container
docker start -ai <containerId>           # start + attach terminal

# 6. Run Containers (all-in-one)
docker run <image>                        # pull + create + start
docker run -it <image>                    # run interactively
docker run -d -p 8080:80 nginx            # run web app in background

# 7. Inspect Containers
docker ps                                 # running containers
docker ps -a                              # all containers

# 8. Manage Containers
docker pause <containerId>                # freeze container
docker unpause <containerId>              # resume container
docker stop <containerId>                 # graceful shutdown
docker rm <containerId>                   # delete container

# 9. Debug & Logs
docker logs <containerId>                 # view container output
docker exec -it <containerId> <cmd>      # run command inside container

# ============================
# Docker Flags Explained
# ============================
# -i       : Interactive — keep STDIN open (when container expects input)
# -t       : TTY — allocate a terminal (when you want a shell)
# -it      : Interactive terminal — combine -i and -t for shell access
# -a       : Attach — see container output (live logs)
# -ai      : Attach + interactive — start a stopped interactive container
# -d       : Detached — run container in background (web apps, servers)

# Example Usage:
# docker run -it ubuntu bash       # interactive shell
# docker start -ai <containerId>   # attach to stopped container
# docker run -d -p 8080:80 nginx   # run nginx in background
```
> `docker run` = `pull + create + start` in one command

### Flags Explained

| Flag | Meaning | When to use |
|------|---------|-------------|
| `-i` | Interactive — keep STDIN open | When container expects input |
| `-t` | TTY — allocate a terminal | When you want a shell |
| `-it` | Interactive terminal | Use together always for shell access |
| `-a` | Attach — see container output | When you want to see logs |
| `-ai` | Attach + interactive | Start a stopped interactive container |
| `-d` | Detached — run in background | Web apps, servers |

---
## step2:Running JDK Docker Container
```bash
# pull JDK image
docker pull eclipse-temurin:25-jdk-ubi10-minimal
 
# run interactively — drops you into a shell inside the container
docker run -it eclipse-temurin:25-jdk-ubi10-minimal
 
# inside container you can run
java -version
jshell
 
# exit
exit
 
# check state
docker ps -a
 
# clean up
docker stop <containerId>
docker rm <containerId>
```

> Container ID can be shortened — first 2–3 unique characters work.
> `docker start 38f` works instead of `docker start 38f89eee8292`
 
---

### Common Mistakes & Fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| `docker start` shows nothing | Output not attached | Add `-a` flag |
| Container exits immediately | No interactive session | Use `docker run -it` |
| `docker rmi` fails | Container still exists | `docker rm` container first |
| Can't find container | Looking at running only | Use `docker ps -a` |
| `docker start -it` does nothing | Wrong flag for start | Use `docker start -ai` instead |
 
---

---

## step3:Packing The Spring Boot Web App

1. **Create Project**

    * Use Spring Initializr → Maven → Spring Web.

2. **Add Controller**

   ```java
   @RestController
   public class HelloController {
       @GetMapping("/")
       public String helloWorld() { return "Hello World"; }
   }
   ```

    * Commit: `Add initial Spring Boot REST controller for "Hello World"`

3. **Update `pom.xml`**

   ```xml
   <build>
       <finalName>SprWebDkr</finalName>
   </build>
   ```

4. **Build Jar**

   ```bash
   mvn clean package
   ```

5. **Run Jar**

   ```bash
   java -jar target/SprWebDkr.jar
   ```

6. **Test in Browser**

    * Open: `http://localhost:8080/` → Should display `Hello World`.

---


## step4:Running Spring Boot Web App On Docker

### Check Running Containers

```bash
docker ps
```

### List All Files in the Container (JDK Environment)

```bash
docker exec <container_name> ls -a
```
> Lists all folders and files in the container's root directory.

### Check Contents of /tmp Directory

```bash
docker exec <container_name> ls /tmp
```
> It will contain only one file in /tmp at the initial stage.


###  Copy the Spring Boot JAR File into the Container

```bash
docker cp target/rest-demo.jar <container_name>:/tmp
```
> This copies the `rest-demo.jar` into the container’s /tmp directory.


### Verify the JAR File is Present

```bash
docker exec <container_name> ls /tmp
```
> The `rest-demo.jar` file will be available in addition to the existing content.


###  Commit the Container to Create a New Docker Image

```bash
docker commit <container_name> telusko/rest-demo:v1
```
> Creates a new Docker image named `telusko/rest-demo` with tag `v1` from the current container state.


### List Docker Images

```bash
docker images
```
> Verifies that `telusko/rest-demo:v1` image has been created successfully.


### Default Behavior: JShell

When running telusko/rest-demo:v1, the container defaults to JShell:

```bash
docker run telusko/rest-demo:v1
```


### Set Default Command to Run JAR Using --change

To override the default JShell behavior, the `--change` flag is used while committing:

```bash
docker commit --change='CMD ["java", "-jar", "/tmp/rest-demo.jar"]' <container_name> telusko/rest-demo:v2
```
> This sets the default command to run the JAR directly when the image is run.


### Run the Updated Image (v2)

```bash
docker run telusko/rest-demo:v2
```
> This will now run the Spring Boot application from the JAR instead of entering JShell.


### Map Ports While Running the Container

```bash
docker run -p 8081:8081 telusko/rest-demo:v2
```
> Maps port `8081` of the container to `8081` on the host machine.

