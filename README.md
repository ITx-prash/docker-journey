<div align="center">
  <img src="https://www.vectorlogo.zone/logos/docker/docker-ar21.svg" width="250" alt="Docker Logo"><br>
  <h1>Docker Journey</h1>
  <p><em>Documenting my deep-dive into the core architecture, concepts, and internal workings of Docker from the ground up.</em></p>

  <a href="https://github.com/ITx-prash/docker-journey/issues">
    <img src="https://img.shields.io/static/v1?style=for-the-badge&label=&message=Report%20Issue&colorA=1e1e2e&colorB=89dceb&logo=gitbook&logoColor=89dceb" alt="Report Issue">
  </a>
</div>

---

## 📖 The Deep Why: Core Concepts

This repository serves as a personal knowledge base for understanding how Docker _actually_ works, moving past surface-level commands and diving into the underlying Linux architecture.

### 1. Why Linux Users shouldn't use Docker Desktop

Many developers confuse Docker Desktop with Docker itself. Here is the architectural reality:

- **Docker Engine (The Brain):** The native background daemon (`dockerd`) and the CLI (`docker`). On Linux, this runs directly on the metal, utilizing the host OS kernel. It is incredibly fast and lightweight.
- **Docker Desktop:** A GUI wrapper built for Windows and Mac. Because Docker requires a Linux kernel, Docker Desktop secretly spins up a **hidden Linux Virtual Machine** (VM).
- **The Takeaway:** As a Linux user, using Docker Desktop means we are unnecessarily running a Virtual Machine inside an OS that already has the required kernel. Stick to the pure Native Docker Engine and CLI.

### 2. Images vs. Containers

- **Image (The Blueprint):** A read-only, dead file containing the filesystem, libraries, and tools.
- **Container (The House):** A living, breathing process created from an image blueprint. We can spin up 100 identical containers from a single image.

### 3. Userland vs. The Kernel

If I download an `ubuntu` image from Docker Hub, is it a full OS? **No.**

- **100% Kernel-less:** Images only contain the **Userland** (the file hierarchy, `apt`, `bash`, `glibc`). They do not contain a Linux Kernel. This is why an Ubuntu image is only ~30MB.
- **The Bank Teller Analogy:** No container can touch the hardware. Instead, containers pass request slips (Syscalls) to the **Host's Linux Kernel**.
- **Security & Isolation:** The host kernel uses **Namespaces** (blindfolds) to prevent containers from seeing each other, and **Cgroups** (speed limits) to prevent a single container from hogging 100% of the CPU or RAM.

### 4. Cross-Platform Secrets

Since containers share the host kernel, how does an `ubuntu` container run on a Mac or Windows machine if they don't have a Linux kernel?

- **The Trick:** Docker Desktop runs a tiny, invisible, custom Linux OS (like `LinuxKit` or via `WSL2`) in the background. When we spin up 10 containers on a Mac, they do not run on the Mac's Darwin kernel—they all share the virtual kernel of that single hidden Linux VM.

---

## 🚀 Native Installation on Debian

To install Docker the professional way, we bypass the default `apt` repositories (which often contain outdated versions) and connect directly to Docker's "Official Factory Store."

### Step 1: Set up Docker's apt Repository

```bash
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

### Step 2: Install Docker Engine

Now, `apt` will automatically pull the newest version directly from the Docker developers.

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

> [!NOTE]
> The Docker service starts automatically after installation. To verify that Docker is running, use:
>
> ```bash
> sudo systemctl status docker
> ```
>
> Some systems may have this behavior disabled and will require a manual start:
>
> ```bash
> sudo systemctl start docker
> ```

Verify that the installation is successful by running the `hello-world` image:

```bash
sudo docker run hello-world
```

This command downloads a test image and runs it in a container. When the container runs, it prints a confirmation message and exits.

---

## 🕹️ Day 2: The CLI, Engine APIs, and Lifecycle

Moving from installation to actual container management, it is crucial to understand _how_ commands execute under the hood.

### 1. The Client-Server Architecture

When we type a command in our terminal, the Docker CLI doesn't actually do the heavy lifting.

- **The Docker Engine (Daemon):** Runs constantly in the background as a system service. It listens for REST API requests to create, modify, or destroy containers.
- **The CLI:** Acts as a pure messenger. It takes our terminal command, translates it into an API request, and sends it to the Engine.
- **Linux Systemd Control:** Because the Engine is a background daemon, it is controlled by Linux's system manager (`systemd`). We can manage the Engine itself with standard Linux commands:
  ```bash
  sudo systemctl status docker  # Check if the brain is awake
  sudo systemctl stop docker    # Put the brain to sleep
  sudo systemctl start docker   # Wake it back up
  ```

### 2. Revisiting Images vs. Containers

To lock in the mental model:

- An **Image** is a static, shared configuration blueprint.
- A **Container** is an isolated runtime environment.
  When we use `docker run`, Docker takes that single, shared image configuration and spins up a brand new, strictly isolated runtime environment. We can have 100 isolated containers safely running off the exact same configuration image.

### 3. Decrypting `docker run -it`

The command `docker run -it ubuntu` is the standard way to "teleport" inside a container. But what do those flags actually do?
First, the `run` command checks if the `ubuntu` image exists locally. If not, it pulls it from Docker Hub, creates a new container, and starts it.

- `-i` (**Interactive**): Tells Docker to keep **STDIN** (Standard Input) open even if not attached. This allows us to actually type commands into the container.
- `-t` (**TTY**): Allocates a pseudo-TTY (Teletype). This tells Docker to format the output with standard terminal UI features (like command prompts, text coloring, and line wrapping) so it seamlessly blends into our host terminal.

### 4. The Command Evolution (Aliases)

We will often see tutorials use different commands to do the exact same thing (e.g., `docker ps` vs `docker container ls`).

**The Deep Why:** In older versions of Docker, commands were thrown together randomly (`docker ps`, `docker rm`). In Docker 1.13, the developers decided to professionally restructure the CLI to be grouped by object (`docker container ...`, `docker image ...`, `docker network ...`).

However, to prevent breaking scripts written by millions of developers, they kept the old commands as permanent **Aliases**. They are identical features, just different ways to type them:

| Classic Command (Alias) | Modern Management Command  | Action                                  |
| :---------------------- | :------------------------- | :-------------------------------------- |
| `docker ps`             | `docker container ls`      | List running containers                 |
| `docker ps -a`          | `docker container ls -a`   | List all containers (running & stopped) |
| `docker rm [id]`        | `docker container rm [id]` | Delete a container                      |
| `docker images`         | `docker image ls`          | List locally downloaded images          |

---

<p align="center" dir="auto">
	<a target="_blank" rel="noopener noreferrer" href="https://github.com/ITx-prash/docker-journey/blob/main/assets/coder.png"><img src="https://raw.githubusercontent.com/ITx-prash/floweave/main/assets/coder.png" height="150" alt="Coder illustration" style="max-width: 100%; height: auto; max-height: 150px;"></a>
	<br>
	<em>Crafted with 💚 on GNU/Linux</em>
	<br>
	Copyright © 2026-present <a href="https://github.com/ITx-prash">Prashant Adhikari</a>
	<br><br>
	<a href="https://github.com/ITx-prash/docker-journey/blob/main/LICENSE"><img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&logoColor=a6e3a1&colorA=1e1e2e&colorB=a6e3a1" style="max-width: 100%;"></a>
</p>
