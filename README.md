# 🚀 ROS 2 Docker Template (Jazzy 2026)

A professional, production-ready boilerplate for ROS 2 Jazzy Jalisco development. This template uses an isolated Docker environment, dynamic VS Code DevContainers, and automated dependency resolution to guarantee that "it works on my machine" means "it works on the robot."

---

## 🏃 Quick Start

**1. Clone the repository** Make sure to include the `--recursive` flag to pull down any third-party ROS drivers or libraries.
```bash
git clone --recursive git@github.com:chcaya/docker_ros2.git
cd docker_ros2
```

**2. Configure your Environment** Edit the `.env` in the root of the project to fit your needs. This is the single source of truth for your workspace.
```bash
# .env
PROJECT_NAME=my_robot_ws
USERNAME=ros
DISPLAY=:0
```

**3. Choose Your Workflow (Two Parallel Paths)**
This template is highly flexible and supports two distinct ways to spin up your environment, depending on your needs.

### Path A: VS Code DevContainers (Recommended for Development)
If you are actively writing code, use the integrated DevContainer.
1. Open the project folder in VS Code.
2. Click **"Reopen in Container"** when prompted (or use the Command Palette: `Dev Containers: Reopen in Container`).
3. The IDE will automatically build the image, read your `.env`, log in as the correct user, install ROS extensions, and run `colcon build` via the `postCreate.sh` script.

### Path B: Terminal Scripts (Recommended for Headless or Deployment)
If you prefer developing purely from the terminal, using a different IDE, or deploying directly to the robot hardware, use the provided bash scripts:
```bash
./scripts/docker_build.sh
./scripts/docker_run.sh
./scripts/docker_connect.sh
```

---

## 📦 Dependency Management

To keep the `Dockerfile` clean and highly cacheable, dependencies are split into distinct files. **Do not put ROS packages in the apt list.**

### 1. System Packages (`docker/apt_packages.txt`)
Add standard Linux tools and libraries here (e.g., `nano`, `htop`, `gdb`, `curl`). These are installed first during the Docker build.

### 2. Python Packages (`docker/requirements.txt`)
Add Python libraries that are not available via standard ROS or Apt channels (e.g., `numpy<2`, `scipy`). Installed via `pip3`.

### 3. ROS Packages (`src/*/package.xml`)
Define your ROS 2 dependencies (e.g., `rclcpp`, `sensor_msgs`, `nav2_bringup`) directly inside the `package.xml` of your custom packages. 
* **How it works:** During the Docker build (and when you open VS Code), `rosdep install` automatically scans the `src/` folder, finds these dependencies, and installs the necessary binaries.

---

## 📂 Workspace & Submodules

Your code lives in the `src/` directory, which is seamlessly mounted into the Docker container. 

### Creating a New Package
To scaffold a new ROS 2 package, use the `ros2 pkg create` command **inside the container**. This will automatically generate your `package.xml`, build files, and a boilerplate node.

**For a C++ Package:**
```bash
cd src
ros2 pkg create --build-type ament_cmake --node-name my_cpp_node --dependencies rclcpp std_msgs my_cpp_pkg
```

**For a Python Package:**
```bash
cd src
ros2 pkg create --build-type ament_python --node-name my_python_node --dependencies rclpy std_msgs my_python_pkg
```
*Note: After creating a package, return to the workspace root (`cd ~/my_robot_ws`) and run the `build` alias to register it.*

### Adding Git Submodules
If you need external ROS packages, add them as submodules **outside the container** on your host machine in the `src` directory. 

```bash
git submodule add <THIRD_PARTY_REPO_URL> src/third_party/third_party_repo
```
Because the `src/` folder is volume-mounted, the container and the build process will automatically see and compile these submodules.

---

## 🛑 Useful Commands (Inside the Container)
Once connected to the container, these aliases are available:
* `build` - Runs optimized `colcon build --symlink-install`
* `sros` - Sources the local workspace (`install/setup.bash`)
* `rt` - Alias for `ros2 topic list`
* `rn` - Alias for `ros2 node list`

---

## 🧹 System Maintenance (Host Machine)
If you rebuild your container frequently (e.g., by updating your `apt_packages.txt` or `requirements.txt`), Docker caches the old image layers. Over time, this can consume a massive amount of hard drive space. 

To avoid system bloat, occasionally run this command on your **host machine** to clean up unused containers and dangling images:
```bash
docker system prune -a
```
*(Note: This clears **all** unused Docker data on your system. It is perfectly safe, but the next time you build other older Docker projects, they will need to download their base layers from the internet again).*

---

## 🤖 Production Deployment

When your robot is ready to run headlessly on boot:
```bash
sudo ./scripts/setup_launch_docker_startup.sh
```
This creates a systemd service that automatically launches your `docker_run.sh` script safely in the background whenever the robot powers on.
