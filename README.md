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
- **The Takeaway:** As a Linux user, using Docker Desktop means you are unnecessarily running a Virtual Machine inside an OS that already has the required kernel. Stick to the pure Native Docker Engine and CLI.

### 2. Images vs. Containers

- **Image (The Blueprint):** A read-only, dead file containing the filesystem, libraries, and tools.
- **Container (The House):** A living, breathing process created from an image blueprint. You can spin up 100 identical containers from a single image.

### 3. Userland vs. The Kernel

If I download an `ubuntu` image from Docker Hub, is it a full OS? **No.**

- **100% Kernel-less:** Images only contain the **Userland** (the file hierarchy, `apt`, `bash`, `glibc`). They do not contain a Linux Kernel. This is why an Ubuntu image is only ~30MB.
- **The Bank Teller Analogy:** No container can touch the hardware. Instead, containers pass request slips (Syscalls) to the **Host's Linux Kernel**.
- **Security & Isolation:** The host kernel uses **Namespaces** (blindfolds) to prevent containers from seeing each other, and **Cgroups** (speed limits) to prevent a single container from hogging 100% of the CPU or RAM.

### 4. Cross-Platform Secrets

Since containers share the host kernel, how does an `ubuntu` container run on a Mac or Windows machine if they don't have a Linux kernel?

- **The Trick:** Docker Desktop runs a tiny, invisible, custom Linux OS (like `LinuxKit` or via `WSL2`) in the background. When you spin up 10 containers on a Mac, they do not run on the Mac's Darwin kernel—they all share the virtual kernel of that single hidden Linux VM.

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

<p align="center" dir="auto">
	<a target="_blank" rel="noopener noreferrer" href="https://github.com/ITx-prash/docker-journey/blob/main/assets/coder.png"><img src="https://raw.githubusercontent.com/ITx-prash/floweave/main/assets/coder.png" height="150" alt="Coder illustration" style="max-width: 100%; height: auto; max-height: 150px;"></a>
	<br>
	<em>Crafted with 💚 on GNU/Linux</em>
	<br>
	Copyright © 2026-present <a href="https://github.com/ITx-prash">Prashant Adhikari</a>
	<br><br>
	<a href="https://github.com/ITx-prash/docker-journey/blob/main/LICENSE"><img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&logoColor=a6e3a1&colorA=1e1e2e&colorB=a6e3a1" style="max-width: 100%;"></a>
</p>
