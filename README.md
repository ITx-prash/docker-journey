<div align="center">

<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/docker/docker-original.svg" width="90" alt="Docker" />

<h1>Docker Journey</h1>

<p><em>Deep-diving into how Docker actually works —<br>from Linux internals to production-ready Dockerfiles.</em></p>

<p>
    <a href="https://github.com/ITx-prash/docker-journey/issues">
      <img src="https://img.shields.io/static/v1?style=for-the-badge&message=Report%20Issue&colorA=1e1e2e&colorB=89dceb&logo=gitbook&logoColor=89dceb" alt="Report Issue">
    </a>
    <a href="https://docs.docker.com/engine/">
      <img src="https://img.shields.io/badge/Architecture-Deep%20Dive-2496ED?style=for-the-badge&logo=docker&logoColor=white&colorA=1e1e2e" alt="Docker Architecture">
    </a>
    <a href="https://www.kernel.org/">
      <img src="https://img.shields.io/badge/OS-Linux%20Native-FCC624?style=for-the-badge&logo=linux&logoColor=black&colorA=1e1e2e" alt="Linux Native">
    </a>
  </p>

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

### 💡 Did You Know?

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

## 🌐 Day 6: Networking, Port Mapping, and Ephemeral Containers

By default, a Docker container is a completely isolated environment. Today, I explored how to punch holes through that isolation to allow outside traffic in, and how to manage the lifecycle of background server processes.

### 1. The Network Namespace Problem (`-p`)

If we run a Node.js server listening on port 8000 inside a container, we cannot access it by typing `localhost:8000` in our host machine's web browser.

- **The Deep Why:** Because of Linux Network Namespaces, the container has its own private IP address and network stack. `localhost` inside the container is completely separate from `localhost` on our physical machine.
- **The Solution:** We use manual port mapping with the `-p` (lowercase) flag to bridge the two worlds.

```bash
# Syntax: -p <HOST_PORT>:<CONTAINER_PORT>
docker run -it -p 3000:8000 alpine-node-base:latest
```

This tells the Docker Engine: _"Listen on port 3000 on my host machine. If any traffic arrives there, instantly teleport it to port 8000 inside this specific container."_
_(We can also chain multiple ports: `-p 8000:8000 -p 2000:4000 -p 2001:5000`)_.

### 2. The `EXPOSE` Keyword (The Documentation Myth)

We updated our `Dockerfile` to include the `EXPOSE` keyword:

```dockerfile
# ... previous steps ...
COPY index.js .

# Documenting the listening port
EXPOSE 8000
CMD["npm", "start"]
```

- **The Truth About `EXPOSE`:** Writing `EXPOSE 8000` does absolutely _nothing_ to the host network. It does not magically open ports or breach security.
- **Why use it?** It is simply a piece of JSON metadata embedded in the image. It serves as documentation so other developers don't have to read our source code to guess which port the app runs on.

### 3. Automatic Port Mapping (`-P`)

If we are deploying 100 containers, writing `-p` manually for each one will cause port collisions (we can't map two containers to host port 3000).

- **The Solution:** We use the `-P` (capital P) flag combined with the `EXPOSE` keyword.

```bash
docker run -it -P alpine-node-base:latest
```

- **How it works:** When Docker sees `-P`, it reads the image metadata, finds `EXPOSE 8000`, and automatically assigns a random, high-numbered ephemeral port from our host machine (e.g., `32768`) and maps it to the container's `8000`. We can view the dynamically assigned port by running `docker ps`.
  _(Note: We can also expose ranges in the Dockerfile, such as `EXPOSE 8000-8009`)._

### 4. Ephemeral Containers (`--rm` and `-d`)

When developing server applications, our terminals can quickly become cluttered, and our hard drives can fill up with stopped "dead" containers. We solve this by combining specific lifecycle flags:

```bash
docker run -itd -P --rm alpine-node-base:latest
```

- **`-d` (Detached Mode):** Instead of the server logs hijacking our terminal, the container runs invisibly in the background as a daemon. We immediately get our terminal prompt back to do other work.
- **`--rm` (Auto-Cleanup):** Normally, when a container stops, its metadata and writable layer stay on the hard drive forever until we run `docker rm`. The `--rm` flag tells Docker: _"This container is ephemeral (temporary). The exact second it stops, automatically delete all traces of it from the system."_

---

## 🚀 Day 7: Container Registries and Multi-Stage Builds

Up until now, our images have lived entirely on our local hard drive. Today, I explored how to share our images with the world and how to drastically reduce their size for production deployment using Multi-Stage Builds.

### 1. Docker Hub: The GitHub of Containers

Just as we push source code to GitHub, we push Docker images to a **Container Registry**. The default public registry is Docker Hub.

To avoid naming collisions across millions of developers, images are strictly namespaced using the format `username/repository:tag`.

**The Publishing Workflow:**

1.  **Authenticate:** We link our CLI to our registry account via `docker login`.
2.  **Tag the Image:** We can tag an image during the build process, or tag an existing local image:

    ```bash
    # Method A: Build and tag directly
    docker build -t itxprash/node-app:latest .

    # Method B: Tag an existing local image with a specific version
    docker tag my-local-node:latest itxprash/node-app:v1.1
    ```

3.  **Push to Registry:** We upload the frozen image layers to the cloud:
    `bash
docker push itxprash/node-app:v1.1
`
    Once pushed, anyone in the world can run `docker run -it -P itxprash/node-app:v1.1`, and their Docker Engine will automatically download the image and spin up the container.

### 2. The "Build Locally" Trap

When deploying applications (like a TypeScript or Rust app), we need to compile the source code into a binary or a `/dist` folder.

- _The Amateur Question:_ "Why can't we just run `npm run build` on our host machine, and then use `COPY dist/ /app/dist` in the Dockerfile?"
- _The Deep Why:_ If Developer A is on an M3 Mac (ARM architecture) and Developer B is on Windows (x86), building locally creates inconsistent, machine-specific artifacts. By moving the build process _inside_ the Dockerfile, we guarantee the code is always compiled in the exact same pristine Linux environment, regardless of whose laptop triggered the build.

### 3. Multi-Stage Builds (The Production Standard)

Building inside the container creates a new problem: **Image Bloat**.
If we build a TypeScript or Rust app inside Docker, our final image is polluted with the source code, development dependencies (`node_modules`), and heavy compilers. This makes the image massive and increases the security attack surface.

**The Solution:** We use Multi-Stage Builds to separate the "Building" environment from the "Running" environment.

#### The Implementation

```dockerfile
FROM node:24-alpine3.23 as base

# ==========================================
# Stage 1: The Builder (Heavy, Dev Environment)
# ==========================================
FROM base as builder
WORKDIR /home/build

# Install ALL dependencies (including dev tools like TypeScript)
COPY package*.json .
COPY tsconfig.json .
RUN npm install

# Copy source code and compile the artifact
COPY src/ src/
RUN npm run build

# ==========================================
# Stage 2: The Runner (Lightweight, Prod Environment)
# ==========================================
FROM base as runner
WORKDIR /home/app

# Magic Step: Copy ONLY the compiled artifacts from Stage 1
COPY --from=builder /home/build/dist dist/
COPY --from=builder /home/build/package*.json .

# Install ONLY production dependencies
RUN npm install --omit=dev

CMD["npm", "start"]
```

#### The Internal Mechanics (How the Magic Works)

This is exactly what happens under the hood during a multi-stage build:

1.  **Stage 1 (`builder`)** creates a temporary container. It holds our source code, compilers, and all development dependencies. It does the heavy lifting to generate the `/dist` folder.
2.  **Stage 2 (`runner`)** spawns a **brand new, completely fresh container**.
3.  The `COPY --from=builder` command reaches back into the Stage 1 container and extracts _only_ the compiled `/dist` folder.
4.  **The Discard:** Docker completely throws away Stage 1. The source code, the TypeScript compiler, and the intermediate layers are instantly deleted. They never make it into the final exported image.

This pattern is especially powerful in compiled languages like Rust or Go. Stage 1 downloads gigabytes of compilers and source code to build a single executable file. Stage 2 is an empty image that _only_ contains that final 10MB executable. The result is a lightning-fast, highly secure production image!

---

## 🔐 Day 8: Secure User Management and Environment Variables

Multi-stage builds give us a lean image, but there is still a critical gap: **who is running our application inside the container?** Today, the main focus was on hardening the runtime with proper user management and making configurations dynamic via environment variables.

### 1. The Root Problem — Why Running as Root Is Dangerous

By default, processes inside a Docker container run as the **`root` user** (UID 0). Isolation does not make root safe.

- **Container Breakout:** If an attacker exploits a Remote Code Execution vulnerability in our app, they gain root access inside the container. Combined with a kernel exploit, they could break out and take over the **host machine**.
- **Principle of Least Privilege:** A web server has no legitimate reason to install packages or modify system files.
- **Mounted Volume Risk:** A root process inside a container has root-level write permissions on `-v` mounted host directories.
- **Compliance:** Production security audits (like CIS Docker Benchmarks) explicitly forbid running container processes as root.

> **The Golden Rule: We must never run the final application as root. Always drop to a non-privileged user before the `CMD` instruction.**

---

### 2. Creating a Locked-Down System User

Every Linux process is owned by a User (UID) and a Group (GID). To secure our container, we need to create a **System User** — a digital "ghost" account designed purely to run background services, with no password, no home directory, and no ability to open a terminal shell.

In Alpine Linux, we do this using `busybox` applets:

```dockerfile
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs
```

**The Deep Why: Naming and Numbering**

- **Why name the user and group the same (`nodejs`)?** This is a Linux security standard called **User Private Groups (UPG)**. Giving the service its own dedicated group ensures strict isolation and prevents accidental permission sharing with other services.
- **Why use ID `1001` instead of `1-999`?** Typically, system accounts use IDs 1-999. However, the official Node.js Docker image already ships with a default human user named `node` at UID `1000`. By explicitly pinning our custom user to `1001`, we mathematically guarantee no collisions. The `--system` flag still does the heavy lifting of stripping away the login shell and password.

---

### 3. The `USER` Instruction

After creating our locked-down user, we hand over ownership using the `USER` directive:

```dockerfile
USER nodejs
```

Everything _after_ this line (including the final `CMD`) runs as `nodejs` instead of `root`.
_(Note: We place this instruction at the very end of our Dockerfile, immediately after `npm install` and file copying, as those setup steps still require root privileges to execute)._

---

### 4. Environment Variables — Dynamic Configuration

We should never hardcode configurations (like ports, database URLs, or API keys) into our images. Instead, we use environment variables.

#### Setting Defaults (`ENV`)

```dockerfile
EXPOSE 8000
ENV PORT=8000
```

While `EXPOSE` is just documentation, `ENV PORT=8000` actually injects a default variable into the container. Our Node.js app can securely read this via `process.env.PORT`.

#### Overriding at Runtime (`-e` & `--env-file`)

We can instantly change our app's configuration without rebuilding the image:

```bash
# Override a single variable (tells the app to listen on 3000)
docker run -it -p 3000:3000 -e PORT=3000 ts-app

# Load bulk secrets from a local file
docker run -it -p 3000:3000 --env-file=./.env ts-app
```

> **Security Note:** We must never `COPY` a `.env` file containing production secrets directly into the Docker image. Doing so permanently bakes the secrets into a read-only layer that anyone can extract. We always inject secrets at runtime.

---

### 5. The Production-Ready Dockerfile

Combining multi-stage builds, non-root users, and dynamic environments gives us a hardened, production-ready recipe:

```dockerfile
FROM node:24-alpine3.23 as base

# ==========================================
# Stage 1: The Builder (Heavy, Dev Environment)
# ==========================================
FROM base as builder
WORKDIR /home/build

COPY package*.json .
COPY tsconfig.json .
RUN npm install

COPY src/ src/
RUN npm run build

# ==========================================
# Stage 2: The Runner (Lightweight, Secure Environment)
# ==========================================
FROM base as runner
WORKDIR /home/app

# Extract ONLY the compiled artifacts
COPY --from=builder /home/build/dist dist/
COPY --from=builder /home/build/package*.json .

# Install ONLY production dependencies
RUN npm install --omit=dev

# Create the locked-down system user/group
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

# Drop root privileges
USER nodejs

EXPOSE 8000
ENV PORT=8000

CMD ["npm", "start"]
```

#### The Security Layers at a Glance

| Mechanism              | What It Prevents                                                          |
| :--------------------- | :------------------------------------------------------------------------ |
| **Stage 1 Discarded**  | Source code and development dependencies never reach production.          |
| **`--omit=dev`**       | Heavy compilation tools are excluded from the final image.                |
| **`adduser --system`** | The executing process has no shell, no password, and minimal permissions. |
| **`USER nodejs`**      | Drops root privileges, preventing catastrophic container breakouts.       |
| **`--env-file`**       | Keeps hardcoded secrets out of our source code and image layers.          |

---

## 🌐 Day 9: Docker Networking, The Default Bridge, and NAT

Today, the black box of Docker Networking was opened. When we spin up an isolated container, how does it instantly have an IP address, a MAC address, and access to the public internet? We explored the mechanics of the "Default Bridge" and the underlying Linux routing tables.

### 1. The Anatomy of the Default Bridge (`docker0`)

When we install Docker on a Linux host, it automatically creates a virtual network interface called `docker0`. This acts as a virtual Network Switch.

Unless we explicitly specify otherwise, every new container connects to this default switch. But how does the physical connection work?

- **The Virtual Cable (`veth` pair):** Docker creates a Virtual Ethernet Pair. Think of it as an invisible Ethernet cable. End A plugs into the container's isolated network card (`eth0`), and End B plugs into the host's `docker0` switch.
- **IP Allocation:** The Docker Daemon acts as a mini DHCP server, automatically assigning a private IP (e.g., `172.17.0.2/16`) to the container.
- **The MAC Address Trick:** To prevent network collisions, Docker dynamically generates the container's MAC address directly from its assigned IP address. (For example, an IP of `172.17.0.2` becomes a MAC address of `02:42:ac:11:00:02`).

### 2. Internal Routing (Container-to-Container)

We spun up two background `busybox` containers and inspected the network using `docker network inspect bridge`. We found their internal IPs:

- `my-container` -> `172.17.0.2`
- `my-container-2` -> `172.17.0.3`

When we executed a ping from the first container:

```bash
docker exec my-container ping 172.17.0.3
```

The ping succeeded perfectly. Because both containers are plugged into the exact same `docker0` virtual switch, they have unrestricted, private access to each other.

**The Catch:** When we tried `ping my-container-2`, it failed with `bad address`. The default bridge network **does not support automatic DNS resolution**. We are forced to use raw IP addresses to communicate.

### 3. External Routing and NAT (Container-to-Internet)

When we run `docker exec my-container ping google.com`, the container successfully reaches the internet. How does a fake, private IP address (`172.17.0.2`) talk to Google?

- **The Default Gateway:** The container doesn't know where Google is, so it sends the packet to the `docker0` bridge (the Gateway).
- **NAT (Network Address Translation):** Private IPs (`172.17.x.x`) are non-routable on the public internet. Before the packet leaves our host machine's physical Wi-Fi card, the Linux Kernel uses `iptables` to erase the container's private IP and replace it with our host router's real public IP. When Google replies, the Linux Kernel remembers the swap and forwards the packet back into the container.

> **⚠️ Security Realization: Isolation is NOT Anonymity**
> Because Docker uses NAT, any traffic leaving the container uses our host machine's real public IP address. Docker isolates the _filesystem and CPU_, but it does not hide our network identity. To achieve true network anonymity, we would have to route the container's traffic through a secondary VPN container.

### 4. The Microservices Architecture Use-Case

Why do we need this internal bridge network? In a modern Microservices architecture, we might have a Node.js API, a Redis cache, and a PostgreSQL database.

- We use port mapping (`-p 8000:8000`) **only** for the Node.js container so the public internet can access our API.
- We **do not** expose ports for Redis or PostgreSQL. They remain completely hidden from the outside world, communicating securely with the Node.js container using the private internal bridge network.

### 5. The Limitations of the Default Bridge (Looking Ahead)

The fact that `ping my-container-2` failed exposed a massive flaw in the default bridge: it lacks DNS resolution. Hardcoding IP addresses like `172.17.0.3` in our application code is dangerous because container IPs change every time they restart.

To solve this, Docker provides **User-Defined Bridge Networks**. These custom networks are far superior to the default bridge because they provide:

1.  **Automatic DNS Resolution:** We can ping and connect to containers using their names instead of IPs.
2.  **Better Isolation:** We can group specific containers together securely.
3.  **On-the-Fly Management:** We can attach and detach running containers without restarting them.

---

### 💡 Did You Know?

**Detaching vs. Stopping (`-d` vs `--rm`)**

When we run: `docker run -itd --rm --name=test busybox`, we might expect the `--rm` flag to delete the container the moment we return to our host terminal. However, running `docker ps` shows the container is still running. Why?

Developers often confuse **Detaching** with **Stopping**.

- **`-d` (Detached):** This tells Docker to shove the process into the background and give us our terminal back. _It does not stop the process._ Because we used `-it`, the `busybox` shell is still open in the background, patiently waiting for input.
- **`--rm` (Auto-Cleanup):** This flag acts as a grim reaper that only triggers on one specific event: **when PID 1 actually dies**.

Because `-d` only hid the terminal, PID 1 is still alive. The container will only be deleted when we explicitly kill it via `docker stop test` or by attaching to it and typing `exit`.

---

## 🌉 Day 10: User-Defined Bridges and Network Drivers

Today, we moved beyond the limitations of Docker's default network. We explored how to create custom, isolated network topologies, how automatic DNS works, and how to utilize alternative network drivers for specialized performance and security needs. To prove these concepts, we built a hands-on network lab.

### 1. Creating a User-Defined Bridge Network

The default `bridge` (`docker0`) is great for quick tests, but it lacks a critical feature for production microservices: **DNS Resolution**. Hardcoding IP addresses is dangerous because container IPs change dynamically upon restart.

To solve this, we created our own **User-Defined Bridge Network** named `andromeda`:

```bash
docker network create andromeda
```

Running `docker network ls` confirms our new custom bridge is active alongside the defaults:

```text
NETWORK ID     NAME        DRIVER    SCOPE
dbddbec39cf7   andromeda   bridge    local
b3efe4b96ea4   bridge      bridge    local
86f9a884f4b3   host        host      local
29574a26f1a7   none        null      local
```

### 2. Spinning Up the Lab (The Setup)

Next, we spun up three containers (`milkyway`, `milkyway2`, `milkyway3`) and explicitly attached them to our new `andromeda` network using `--network andromeda`:

```bash
docker run -itd --network andromeda --rm --name=milkyway busybox
docker run -itd --network andromeda --rm --name=milkyway2 busybox
docker run -itd --network andromeda --rm --name=milkyway3 nginx
```

To test network isolation, we spun up a fourth container (`my-container`), but let it fall back to the **default bridge**:

```bash
docker run -itd --rm --name=my-container busybox
```

Our current system state (`docker ps`):

```text
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS     NAMES
d34192c94470   busybox   "sh"                     17 seconds ago   Up 16 seconds             my-container
b58c58291fd8   nginx     "/docker-entrypoint.…"   4 hours ago      Up 4 hours      80/tcp    milkyway3
7e2c8eaca4f1   busybox   "sh"                     5 hours ago      Up 5 hours                milkyway2
0365033f92f8   busybox   "sh"                     7 hours ago      Up 7 hours                milkyway
```

### 3. The Power of Automatic DNS Resolution

If we inspect our custom network (`docker network inspect andromeda`), we can see Docker assigned internal IPs to our containers (e.g., `milkyway` is `172.18.0.2`, `milkyway2` is `172.18.0.3`).

But because we are on a user-defined network, **we don't need to memorize these IPs.** We can ping the containers directly by their names:

```bash
⚡prash ❯❯ docker exec milkyway ping milkyway2
PING milkyway2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.056 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.061 ms

⚡prash ❯❯ docker exec milkyway ping milkyway3
PING milkyway3 (172.18.0.4): 56 data bytes
64 bytes from 172.18.0.4: seq=0 ttl=64 time=0.044 ms
```

- **The Deep Why:** For user-defined networks, the Docker Daemon spins up an embedded DNS server at `127.0.0.11` inside the container's network namespace. When `milkyway` tries to ping `milkyway3`, this embedded DNS server catches the request, looks up `milkyway3` in its internal registry, and translates it to `172.18.0.4` instantly.

### 4. Network Isolation Proof

What happens if `milkyway` (on the `andromeda` network) tries to ping `my-container` (on the default `bridge` network)?

```bash
⚡prash ❯❯ docker exec milkyway ping my-container
ping: bad address 'my-container'
```

Even if we inspect the default bridge, find `my-container`'s exact IP (`172.17.0.2`), and ping it directly, it fails:

```bash
⚡prash ❯❯ docker exec milkyway ping 172.17.0.2
^C⏎
```

- **The Deep Why:** The Linux kernel's `iptables` explicitly drop packets attempting to cross different virtual switches. They are in completely isolated environments.

### 5. On-the-Fly Connections and Disconnections

Unlike the default bridge, user-defined networks allow us to dynamically patch cables between running containers without stopping them.

**Connecting a running container:**

```bash
docker network connect andromeda my-container
```

Now, `my-container` is attached to _both_ the default bridge and `andromeda`. If we try the ping again:

```bash
⚡prash ❯❯ docker exec milkyway ping my-container
PING my-container (172.18.0.5): 56 data bytes
64 bytes from 172.18.0.5: seq=0 ttl=64 time=0.106 ms
```

It works instantly!

**Disconnecting a running container:**

```bash
docker network disconnect andromeda milkyway3
```

If we try to ping `milkyway3` now, it immediately fails:

```bash
⚡prash ❯❯ docker exec milkyway ping milkyway3
ping: bad address 'milkyway3'
```

### 6. The `docker inspect` Mystery: HostConfig vs. NetworkSettings

After disconnecting `milkyway3` from `andromeda`, we ran `docker inspect milkyway3`. The output was confusing: it still showed `"NetworkMode": "andromeda"`! Did the disconnect fail?

```json
"HostConfig": {
    "NetworkMode": "andromeda",
    ...
}
```

**No, the disconnect succeeded perfectly.** This exposes a deep architectural quirk of how Docker stores metadata:

- **`HostConfig` (The History):** The `"NetworkMode": "andromeda"` we saw is located under the `HostConfig` JSON object. This object is a permanent, immutable record of the exact flags we typed when we originally ran `docker run`. It _never_ changes.
- **`NetworkSettings` (The Live State):** To see the _actual_, current, live networking state of the container, we must look at the `NetworkSettings.Networks` object at the very bottom of the JSON. When we disconnected `milkyway3`, that object became empty (`{}`), proving the container was successfully unplugged!

### 7. Other Docker Network Drivers

While bridge networks (default and user-defined) cover 90% of use cases, Docker provides other network drivers for specialized scenarios:

- **`host` (Performance Mode):**
  Removes network isolation between the container and the Docker host. The container does not get its own IP address allocated. If we run a container on port 80 using host networking, it directly occupies port 80 on our physical machine's IP address. No `-p` port mapping is needed.
- **`none` (The Lockdown Mode):**
  Completely isolates a container from the host and other containers. It cannot reach the internet, and no one can reach it. Useful for highly secure, offline processing tasks.
- **Advanced Drivers (`overlay`, `macvlan`, `ipvlan`):** Complex drivers for enterprise deployments. `overlay` connects containers across multiple physical servers (Docker Swarm), while `macvlan` assigns a real, physical MAC address to a container so legacy physical network routers can interact with it directly.

---

### 💡 Did You Know?

**The POSIX CLI Standard: Space vs. Equals**

When we connected our containers to our custom network, we used the syntax `--network andromeda`. However, we will often see other developers or tutorials use `--network=andromeda`. Is there a difference?

**No, they are 100% identical.** This is not a Docker-specific feature; it is a fundamental rule of how modern Linux command-line tools (like Docker, Git, and Kubernetes) are engineered, governed by the **POSIX standard**.

- **Long Flags (`--`):** Flags with two dashes (like `--network` or `--name`) accept both a space and an equals sign. Many engineers prefer the `=` format because it visually binds the key and the value together, making massive multi-line commands much easier to read and debug.
- **Short Flags (`-`):** Single-letter flags (like `-p`, `-e`, or `-v`) _must_ use a space. If we try to use an equals sign (e.g., `-p=8000:8000`), the underlying C/Go CLI parser will instantly throw a syntax error!

---

## 💾 Day 11: Data Persistence and Bind Mounts

Containers are ephemeral by design. When a container stops or is removed, any data written inside it is permanently destroyed. Today, we explored how to break this rule and make our container data persistent by bridging the container's file system with our physical host machine.

### 1. The Ephemeral Storage Problem

To prove that containers have amnesia, we spun up a temporary Ubuntu container:

```bash
docker run -it --rm ubuntu
```

Inside, we created a secret file:

```bash
cat > secret.txt
I am a secret XD..
^C
```

_(When we exited, the `--rm` flag deleted the container. The `secret.txt` file was completely wiped from existence because it was stored in the container's temporary Writable Layer)._

> **📝 Quick Note: The Magic of `cat`**
> How did we create that file without a text editor? The `>` and `>>` symbols are Linux redirect operators.
>
> - `cat > filename.txt`: Takes whatever we type in the terminal and **overwrites** (or creates) the file.
> - `cat >> filename.txt`: **Appends** our typed text to the very bottom of an existing file without deleting what is already there.

### 2. What exactly is a "Volume"?

In Docker, a "Volume" is a broad term for a storage mechanism that completely bypasses the container's temporary OverlayFS (Copy-on-Write) file system. Instead of writing data into the container's fragile top layer, a volume creates a direct wormhole to a safe, permanent folder sitting on the physical host machine's hard drive.

### 3. The Solution: Bind Mounts (`-v`)

If we have a folder on our host machine (e.g., `/home/prash/Desktop/docker-journey`), we can mount it directly inside the container. We use the `-v` (volume) flag, mapping the paths exactly like we map ports: `<absolute-host-path>:<absolute-container-path>`.

```bash
docker run -it -v /home/prash/Desktop/docker-journey:/home/ubuntu/my-docker ubuntu
```

#### The Real-Time Sync Experiment

Once inside the container, we navigated to our mapped folder and created a file:

```bash
root@c51d15d98a4a:/home/ubuntu/my-docker# cat > temp.txt
hello
^C
root@c51d15d98a4a:/home/ubuntu/my-docker# cat temp.txt
hello
```

**The Result:** The moment we pressed `Ctrl+C`, `temp.txt` instantly appeared on our host machine's desktop folder. It is a real-time, bi-directional sync. If we delete the container, `temp.txt` remains perfectly safe on our host machine.

### 4. Engineering Use-Cases (The "Deep Why")

Why is this simple mounting mechanism so powerful in DevOps?

1.  **Cross-OS Tooling:** We might need to run a highly specific tool that _only_ works on Linux (like certain C++ compilers or pentesting scripts). Even if our host is a Mac or Windows machine, we can mount our local code into a Linux container, let the Linux container process the files, and the finished results will magically output directly back to our Mac/Windows hard drive.
2.  **Live Code Editing:** For web development, we can mount our source code into a Node.js container. When we edit `index.js` in VS Code on our host laptop, the container instantly sees the changes and restarts the server. No rebuilding images required!
3.  **Shared State:** A single host folder can be mounted into _multiple_ containers at the same time. Container A can write data to a file, and Container B can instantly read that exact same file.

---

## 🗄️ Day 12: Named Volumes and Managed Storage

Yesterday, we used **Bind Mounts** to link a specific folder on our physical host machine (`/home/prash/...`) to a container. Today, we explored **Named Volumes**, which completely decouple our data from our host machine's file system and hand storage management entirely over to Docker.

### 1. The Bind Mount Problem

Bind mounts are great for local development, but they have a fatal flaw for production: they are **OS-dependent**. A bind mount path like `/home/ubuntu/...` works on Linux, but if another developer pulls our code on Windows, the container will crash because that path does not exist.

To fix this, we use **Named Volumes**.

### 2. Creating a Managed Volume

We can ask Docker to carve out a permanent, secure chunk of storage for us without ever telling it exactly _where_ to put it on the host hard drive:

```bash
docker volume create custom_data

# Verify it exists
docker volume ls
```

- **The Deep Why:** When we create a named volume, Docker silently provisions a highly optimized directory deep inside Linux (usually at `/var/lib/docker/volumes/custom_data/_data`). We never interact with this folder directly; Docker manages the permissions and storage mechanics for us.

### 3. Data Sharing Between Containers

To prove that volumes are independent of the containers that use them, we spun up multiple different containers and attached them to the same volume pool.

**Step A: The Ubuntu Writer**

```bash
docker run -it --rm -v custom_data:/server ubuntu
```

Inside this container, we navigated to `/server` and created a file:

```bash
cat >> ubuntu.txt
This is the file created by ubuntu...
```

**Step B: The Busybox Reader/Writer**
We destroyed the Ubuntu container and spun up a completely different OS (`busybox`), attaching the exact same volume:

```bash
docker run -it --rm -v custom_data:/server busybox
```

Running `ls /server` revealed `ubuntu.txt` was still perfectly intact! We then added a second file: `busybox.txt`.

### 4. Path Independence

A volume is just a floating pool of data. It does not care _where_ it gets mounted inside a container. We proved this by spinning up a third container and mounting `custom_data` to a completely different internal directory:

```bash
docker run -it --rm -v custom_data:/home/ubuntu/custom ubuntu
```

When we ran `ls /home/ubuntu/custom`, both `ubuntu.txt` and `busybox.txt` were sitting right there. Multiple containers can mount the exact same volume simultaneously, even if they mount it to completely different internal folder paths.

---

### 💡 Did You Know? (CLI Parsing & Anonymous Volumes)

When we originally typed our command today, we made a tiny typo that revealed a massive underlying mechanic in Docker's CLI:

```bash
# What we typed:
docker run -it -v --rm -v custom_data:/server ubuntu
```

When we ran `ls` inside the container, a weird folder literally named `--rm` appeared at the root of the file system! Furthermore, when we ran `docker volume ls` later, a massive random hash (`d2429299a519...`) had mysteriously appeared in our volume list alongside `custom_data`.

**The Deep Why:**
Docker parses commands exactly as they are written. By writing `-v --rm`, we accidentally triggered the creation of an **Anonymous Volume**.

- Because we didn't include a colon (like `<host>:<container>`), Docker assumed `--rm` was the destination path _inside_ the container.
- It automatically generated a random hashed volume (the long string we saw in `docker volume ls`) and mounted it to a literal folder named `/--rm` inside our container!

_(The correct syntax simply moves the flag: `docker run -it --rm -v custom_data:/server ubuntu`)_. This quirk perfectly demonstrates how Docker handles incomplete volume declarations on the fly!


## 🐙 Day 13: Docker Compose and Infrastructure as Code

Up until today, we managed containers imperatively—typing long, complex `docker run` commands one by one. Today, we explored **Docker Compose**, a tool that allows us to define and orchestrate entire multi-container applications declaratively using a single YAML file.

### 1. The Local Development Nightmare (The "Deep Why")
To understand why we need Docker Compose, we wrote a Node.js server that connects to both Redis and PostgreSQL:

```typescript
// Excerpt from our Node.js App
const redis = new Redis("redis://redis:6379");
const client = new Client({ host: "db", port: 5432, database: "postgres" });
```

When we tried to run this locally (`npm run start`), the application crashed immediately:
```text
[ioredis] Unhandled error event: Error: getaddrinfo ENOTFOUND redis
Error Starting Server Error: Connection is closed.
```
**The Problem:** Our host machine does not have Redis or PostgreSQL installed. 
Without Docker, we would have to manually install these databases on our physical laptop. If a new developer joined our team, we would have to write a complex guide telling them exactly which versions of Postgres and Redis to install. This causes the classic "It works on my machine" problem.

### 2. The Docker Compose Solution
Instead of installing databases locally or typing multiple messy `docker run` commands, we define our infrastructure as code in a `docker-compose.yml` file. 

In Compose terminology, every container is referred to as a **Service**.

We started by defining just our PostgreSQL database:
```yaml
name: e-commerce

services:
  db:
    image: postgres:16
    container_name: postgres
    environment:
      POSTGRES_PASSWORD: "1234"
      POSTGRES_USER: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
```
*   *Note:* This YAML block is the exact, 1-to-1 equivalent of typing: `docker run -it --name postgres -p 5432:5432 -e POSTGRES_PASSWORD="1234" ... postgres:16`.

### 3. Scaling the Infrastructure
Next, we added our Redis cache to the same file. We also introduced the `depends_on` keyword to control the startup order, ensuring our cache only starts after our database is initialized.

```yaml
name: e-commerce

services:
  db:
    image: postgres:16
    container_name: postgres
    environment:
      POSTGRES_PASSWORD: "1234"
      POSTGRES_USER: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    container_name: redis
    depends_on:
      - db
    ports:
      - "6379:6379"
```

### 4. The Magic Commands (`up` and `down`)
With our infrastructure defined, we can spin up the entire database stack with a single command:

```bash
⚡prash ❯❯ docker compose up -d

[+] Running 14/14
 ✔ Image redis:7-alpine       Pulled                             8.8s
 ✔ Network e-commerce_default Created                            0.0s
 ✔ Container postgres         Started                            0.6s
 ✔ Container redis            Started                            0.7s
```
Now, when we run our Node.js app locally, it successfully connects to the Dockerized databases:
```text
⚡prash ❯❯ npm run build && npm start

Connecting Redis...
Redis Connection Success...
Connecting Postgres...
Postgres Connection Success...
Http server is listening on PORT 8000
```

When we are done working for the day, we simply run:
```bash
docker compose down
```
This safely stops the containers, destroys the default network, and leaves our host machine perfectly clean.

### 5. Architectural Insight: Networks and Port Mapping
When we ran `docker compose up`, Docker automatically created a custom bridge network for us (named `e-commerce_default`). Because both `db` and `redis` are inside this same network, they can communicate with each other privately without any port mapping.

**Why did we use `ports: - "5432:5432"`?**
We only mapped the ports because our Node.js application is currently running *outside* of the Docker network (directly on our host machine). If we were to also containerize our Node.js application and add it as a third service in our `docker-compose.yml`, we could completely remove the `ports` mappings for Redis and Postgres, hiding them securely from the host machine and the outside world!

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
