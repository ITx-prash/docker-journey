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

## 🕵️ Day 3: Processes, Minimal Images, and The Container Lifecycle

Today focuses on the internal mechanics of how containers execute commands, why images behave the way they do, and how Docker operates on different OS kernels under the hood.

### 1. The "Booting" Myth and PID 1

A container does not "boot" like a Virtual Machine. There is no OS startup sequence.

- **The Reality:** A container is simply an isolated Linux process.
- **The PID 1 Rule:** The command we pass to a container (or its default `CMD`) becomes **Process ID 1 (PID 1)** inside that isolated environment.
- **The Lifecycle Rule:** A container lives exactly as long as its PID 1 lives.
  - `docker run ubuntu bash`: `bash` stays open, so the container stays running.
  - `docker run ubuntu ls`: `ls` lists files and exits in 0.1 seconds, so the container instantly dies.
  - `docker run ubuntu ping google.com`: `ping` runs indefinitely, so the container stays alive until we stop it.

### 2. Why `ping` Failed: The Nature of Base Images

Running `docker run ubuntu ping google.com` throws an error: `executable file not found in $PATH`.

- **The Deep Why:** Container images are strictly minimal by design to reduce attack surfaces and download sizes. The official Ubuntu Docker image is stripped of common networking tools.
- **Base Image Variants:**
  - **Ubuntu (~70MB):** A minimal general-purpose distro. Requires `apt update && apt install iputils-ping`.
  - **Alpine (~7MB):** An ultra-lightweight distro using `musl` and `apk`. Built specifically for production containers. Includes `ping` by default.
  - **BusyBox (~2MB):** Not a full OS. It is a single, tiny binary toolkit that bundles core Unix utilities (including `ping` and `sh`). Perfect for debugging.

### 3. Immutability and Overriding Commands

If we run `docker run ubuntu ls`, does it permanently change the image so it always runs `ls`? **Absolutely not.**

- **Inspecting the Blueprint:** We can view an image's default configuration by running `docker image inspect ubuntu`. Inside the JSON, the `Cmd` key is set to `["bash"]`.
- **The Override:** When we add `ls` to the CLI, Docker creates a _container-specific_ configuration overriding the default `Cmd`.
- **Immutability:** Images are strictly read-only. Modifying a command or installing a package inside a container _only_ affects that specific container's invisible writable layer. The base image on our hard drive is never altered.

### 4. Running Pre-made Containers (`run` vs `start`)

The `docker run` command is strictly for creating _brand new_ containers.

- **`docker run`:** Pulls the image (if missing) ➡️ Creates the writable layer ➡️ Starts the process.
- **`docker start [id]`:** Wakes up an existing, stopped container. It re-uses the exact same writable layer and configuration (like an overridden `ls` command) that was generated when it was first created.
- **`docker exec -it [id] bash`:** Teleports into a container that is _already running_ by spawning a secondary process alongside PID 1.

### 5. Essential Management Commands

As containers and images pile up, lifecycle management becomes critical:

| Command                | Action            | The "Deep Why" / Engineering Context                                                                                        |
| :--------------------- | :---------------- | :-------------------------------------------------------------------------------------------------------------------------- |
| `docker image inspect` | View metadata     | Exposes the raw JSON manifest (Env variables, Entrypoints, Cmds).                                                           |
| `docker rm [id]`       | Delete container  | Wipes the container's metadata and its specific writable layer from disk.                                                   |
| `docker rmi [image]`   | Delete image      | Fails if any container (even a stopped one) is currently based on it, as the container relies on that read-only base layer. |
| `docker stop [id]`     | Graceful shutdown | Sends a `SIGTERM` signal to PID 1, allowing the app to save data before exiting.                                            |
| `docker kill [id]`     | Force shutdown    | Sends a `SIGKILL` signal to PID 1, terminating it instantly without warning.                                                |
| `docker system prune`  | Clean up          | Automatically deletes all stopped containers, unused networks, and dangling images to free up disk space.                   |

### 6. Cross-Platform Execution Under the Hood (WSL2 & macOS)

Because containers _require_ a Linux kernel (for Namespaces, Cgroups, and OverlayFS), Docker uses deeply integrated Hypervisors on Mac and Windows to fake a native environment.

- **Windows (WSL2):** Docker uses Microsoft's _Lightweight Utility VM_. It boots a highly optimized Linux kernel in <1 second via Hyper-V. The `dockerd` daemon and your container's OverlayFS files live inside hidden, dedicated WSL2 distros (`docker-desktop-data`).
- **macOS:** Uses Apple's native `Virtualization.framework`. Docker boots a highly secretive, ultra-minimalist Linux distribution called **LinuxKit** in the background. It uses **VirtioFS** to share files between the Mac hard drive and the Linux VM at near-native speeds.

---

## 🏗️ Day 4: Custom Images, Dockerfiles, and Layer Architecture

Today’s focus shifted from consuming existing images to engineering custom ones. We explored how file systems are modified, how changes are saved, and the step-by-step process of translating a recipe into a built image.

### 1. Modifying Containers: The "Amateur" vs. The "Professional" Way

When we pull a base image (like `ubuntu` or `kali-rolling`) and install new packages inside its container, those packages are saved in the container's temporary Writable Layer. How do we save them permanently?

- **The Amateur Way (`docker commit`):**
  We can freeze a container's writable layer into a brand new image using `docker commit <container_id> custom-name`.
  - _Pros:_ Great for quickly saving a personalized Pentesting Lab (like a Kali setup with gigabytes of manually installed tools).
  - _Cons:_ It creates a **Black Box**. No other developer knows exactly what commands you ran to build it, making it impossible to reproduce reliably.

- **The Professional Way (`Dockerfile`):**
  Instead of manually modifying a running container, we write a **Recipe** (Infrastructure as Code). A `Dockerfile` is a plain text file containing the exact steps needed to build the image. This guarantees that anyone, anywhere, can build the exact same environment.

### 2. The Kali Linux Experiment: Hardware & Bare-Metal Speed

Running a full `kali-linux-default` installation inside a Docker container on a Linux Mint host revealed two critical architectural truths:

1.  **Bare-Metal Performance:** Running `fastfetch` inside the Kali container showed the host machine's physical CPU and Linux Mint kernel. Because containers do not emulate hardware (like VirtualBox does), Kali runs at 100% bare-metal speed.
2.  **Hardware Isolation:** By default, the container is "blindfolded" via Network Namespaces. It cannot see physical Wi-Fi adapters (meaning tools like `wifite2` will fail).
    - _The Fix:_ To pierce the namespace and give the container hardware access, it must be run with special flags: `docker run -it --net=host --privileged kali-image bash`.

### 3. Anatomy of a Dockerfile

Here is the layout for a custom Node.js runtime environment built on top of Ubuntu:

```dockerfile
# 1. The Base Image (The Foundation)
FROM ubuntu

# 2. Execute commands in the temporary writable layer
RUN apt update
RUN apt install -y curl
RUN curl -sL https://deb.nodesource.com/setup_24.x -o /tmp/nodesource_setup.sh
RUN bash /tmp/nodesource_setup.sh
RUN apt install -y nodejs

# 3. Copy source code from the Host OS into the Container Image
COPY index.js /home/app/index.js
COPY package-lock.json /home/app/package-lock.json
COPY package.json  /home/app/package.json

# 4. Change the default directory for future commands
WORKDIR /home/app/

# 5. Install app dependencies
RUN npm install
```

### 4. Building and Running the Custom Image

With the Dockerfile written, we use `docker build` to execute every instruction and produce a final image.

```bash
docker build -t my-node-app .
```

- **`-t my-node-app`:** Tags the resulting image with a human-readable name. Without this, we would have to reference the image by its raw SHA-256 hash.
- **`.` (The Build Context):** This tells Docker to send the _current directory_ (and all its files) to the Docker Engine. The `COPY` instructions inside the Dockerfile can only access files within this context. Think of it as the "ingredient box" that the Engine's builder can pull from.

Every `RUN`, `COPY`, and `ADD` instruction in the Dockerfile produces a new **read-only layer**. Docker stacks these layers one by one, from top to bottom, to form the final image. _(Note: We will explore the massive performance implications of how Docker caches these layers in Day 5!)_

Once the build completes, the new image appears in our local registry:

```bash
docker images
```

To spin up a container from the freshly built image:

```bash
docker run -it my-node-app
```

---

## ⚡ Day 5: Build Optimization, Caching, and Terminal Internals

Writing a `Dockerfile` that works is easy. Writing a `Dockerfile` that builds in milliseconds requires understanding how the Docker Engine hashes and caches layers. Today's focus was on optimizing image size and build speed.

### 1. Base Image Selection (Shedding the Weight)

Our initial Dockerfile used `ubuntu` as the base image. While effective, it required manual installation of `curl`, setup scripts, and `nodejs`, resulting in a heavy image.

- **The Optimization:** We switched the base image to `FROM node:24-alpine3.23`.
- **The Deep Why:** Alpine Linux is an ultra-lightweight distribution built specifically for containers (the base OS is only ~5MB). By using the official Node/Alpine image, we instantly remove the need to manually install dependencies. It drastically reduces the image size, download time, and security attack surface.

### 2. The Golden Rule of Layer Caching

Every instruction in a Dockerfile (`FROM`, `COPY`, `RUN`) creates a new layer. Docker caches these layers to speed up future builds. However, there is a strict rule: **If a layer's cache is invalidated (because a file changed), every single layer below it is also invalidated and forced to rebuild.**

#### The "Amateur" Structure (Slow Builds)

```dockerfile
# ❌ BAD: Copying everything at once
COPY . /app
WORKDIR /app
RUN npm install
```

- _Why it fails:_ If you fix a single typo in `index.js`, the `COPY . /app` layer changes. Docker invalidates the cache, forcing `npm install` to run again, which could take minutes just to download `node_modules`.

#### The "Professional" Structure (Instant Builds)

```dockerfile
# ✅ GOOD: Strategic Ordering
FROM node:24-alpine3.23
WORKDIR /home/app/

# 1. Copy ONLY the package files first
COPY package*.json ./
# 2. Install dependencies
RUN npm install
# 3. Copy the source code LAST
COPY index.js .

CMD["npm", "start"]
```

- _The Deep Why:_ Source code changes 100x more frequently than dependencies. By placing `COPY package*.json ./` and `RUN npm install` at the top, they remain safely cached. When you modify `index.js`, Docker skips the `npm install` step entirely and only takes 0.1 seconds to create the final source code layer. **Order matters immensely.**

### 3. `RUN` vs. `CMD`

- **`RUN npm install`:** Executes _during the build process_. Its output gets permanently frozen into a Read-Only Image Layer.
- **`CMD ["npm", "start"]`:** Does _nothing_ during the build process. It simply adds a metadata tag to the Image telling Docker: _"When someone spins up a container from this image, make this command PID 1."_

---

### 💡 Did You Know? (Engineering Trivia)

**Terminals vs. Shells vs. The Kernel**

Developers often use the words "Terminal" and "Shell" interchangeably, but they are completely different layers of the OS architecture:

1.  **The Kernel (The Brain):** Understands only binary and C System Calls. It manages the actual CPU and RAM.
2.  **The Shell (The Backend/Translator):** Programs like `bash`, `zsh`, or `fish`. They take human text commands (`mkdir`), translate them into Kernel System Calls, and return the result.
3.  **The Terminal (The Frontend UI):** Programs like GNOME Terminal, Alacritty, or Windows Terminal. They are simply graphical text boxes. They capture your physical keystrokes and draw pixels on your screen.

**How it connects to Docker (`-it`):**
When you run `docker run -it ubuntu bash`, you are wiring these layers across isolated environments:

- `-i` (Interactive): Plugs the `stdin` (Standard Input) pipe of your host's Terminal directly into the container's Shell.
- `-t` (TTY / Teletype): Tells Docker to create a Pseudo-Terminal (PTY) connection. This ensures the container's Shell formats its text output correctly so your host's Terminal UI can render colors and prompts perfectly.

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
