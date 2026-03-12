# 🚀 ROS 2 Docker Template (Jazzy 2026)

A professional, production-ready boilerplate for ROS 2 Jazzy Jalisco development. This template uses an isolated Docker environment and automated dependency resolution to guarantee that "it works on my machine" means "it works on the robot."

---

## 🏃 Quick Start

**1. Clone the repository** ```bash
git clone --recursive git@github.com:chcaya/docker_ros2.git
cd docker_ros2
```

**2. Configure your Environment** ```bash
# .env
PROJECT_NAME=docker_project
USERNAME=docker_user
DISPLAY=:0
```

**3. Build and Start the Container**
```bash
./scripts/docker_build.sh
./scripts/docker_run.sh
```

**4. First-Time Setup (Crucial)**
Because your host machine mounts over the container's workspace, the folders built during the Docker image creation are "shadowed." You must run an initial build inside the container to generate these folders on your host machine:
1. Connect via VS Code or Terminal.
2. Run the `build` command.
3. Once finished, `build/`, `install/`, and `log/` will appear in your project root.

---

## 💻 Development Workflows

Once the container is running in the background, you can connect to it using your preferred method:

### Path A: VS Code "Attach" (Recommended for Development)
This method gives you full IDE features without the instability of automated DevContainers.

1. Ensure the container is running (`./scripts/docker_run.sh`).
2. Install the **Dev Containers** extension in VS Code.
3. Open VS Code and press `Ctrl + Shift + P` to open the Command Palette.
4. Type and select **`Dev Containers: Attach to Running Container...`**.
5. Select your running container (e.g., `/docker_project`) from the dropdown list.
6. Click **File > Open Folder** and navigate to `/home/docker_user/docker_project`.
7. **Run `build`** in the integrated terminal to initialize the workspace.

### Path B: Terminal / Command Line
```bash
./scripts/docker_connect.sh
# Then run:
build
```

---

## 📦 Dependency Management

To keep the `Dockerfile` clean and highly cacheable, dependencies are split into distinct files. **Do not put ROS packages in the apt list.**

### 1. System Packages (`docker/apt_packages.txt`)
Add standard Linux tools and libraries here (e.g., `nano`, `htop`, `curl`).

### 2. Python Packages (`docker/requirements.txt`)
Add Python libraries not available via standard ROS channels.

### 3. ROS Packages (`src/*/package.xml`)
Define your ROS 2 dependencies (e.g., `rclcpp`, `sensor_msgs`) directly inside the `package.xml` of your custom packages. 
* **How it works:** `rosdep install` scans the `src/` folder and installs necessary binaries.

---

## 📂 Workspace & Submodules

Your code lives in the `src/` directory, which is seamlessly mounted into the Docker container. 



### Creating a New Package
To scaffold a new ROS 2 package, use the `ros2 pkg create` command **inside the container**.

**For a C++ Package:**
```bash
cd src
ros2 pkg create --build-type ament_cmake --node-name my_cpp_node --dependencies rclcpp std_msgs my_cpp_pkg
```

### Adding Git Submodules
Add submodules **outside the container** on your host machine in the `src` directory. 
```bash
git submodule add <URL> src/third_party/repo_name
```

---

## 🛑 Useful Commands (Inside the Container)
Once connected to the container, these custom utilities are available:

| Command | Description |
| :--- | :--- |
| `build` | **Safe Mode Build:** Automatically calculates available RAM to prevent system freezes. Uses sequential execution for stability. |
| `clean_build` | Nukes the `build/`, `install/`, and `log/` folders. Essential if you change usernames or project names. |
| `sros` | Quickly sources the local workspace (`install/setup.bash`). |
| `cbp` | Alias for `colcon build --packages-select` (builds only one package). |
| `rt` / `rn` | Quick aliases for `ros2 topic list` and `ros2 node list`. |

---

## 🧹 System Maintenance (Host Machine)
To reclaim disk space from old image layers:
```bash
docker system prune -a
```

---

## 🤖 Production Deployment

When your robot is ready to run headlessly on boot:
```bash
sudo ./scripts/setup_launch_docker_startup.sh
```
This creates a systemd service that automatically launches your `docker_run.sh` script whenever the robot powers on.
