# Start with Jazzy Desktop (Ubuntu 24.04 Noble)
FROM osrf/ros:jazzy-desktop

# 1. Environment & Non-interactive setup
ENV DEBIAN_FRONTEND=noninteractive
ENV QT_X11_NO_MITSHM=1

# 2. Base Skeleton (Required for bootstrap and user management)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-dev-tools \
    sudo \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# 3. User & Project Configuration
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG PROJECT_NAME=docker_template

# BAKE THESE INTO THE IMAGE SO ENTRYPOINT CAN SEE THEM
ENV USERNAME=${USERNAME}
ENV PROJECT_NAME=${PROJECT_NAME}
ENV USER_UID=${USER_UID}

RUN if id -u $USER_UID >/dev/null 2>&1; then userdel -r $(id -un $USER_UID); fi \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && usermod -aG dialout,video $USERNAME

# 4. Install System & Python Dependencies
COPY ./docker/apt_packages.txt /tmp/apt_packages.txt
RUN apt-get update && xargs -a /tmp/apt_packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY ./docker/requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt

# 5. Rosdep Install (The "ROS Logic" Layer)
# We copy ONLY the package.xml files first to cache the dependency install
USER $USERNAME
WORKDIR /home/${USERNAME}/${PROJECT_NAME}
RUN rosdep update

# This trick finds all package.xml files and installs their deps without needing the full source code yet
COPY --chown=$USERNAME:$USERNAME ./src ./src
USER root
RUN apt-get update && \
    rosdep install --from-paths src --ignore-src -y -r --rosdistro jazzy \
    && rm -rf /var/lib/apt/lists/*

# 6. Infrastructure Files
USER root
# Copy all scripts from the docker folder to a known location
COPY --chown=$USER_UID:$USER_GID ./docker/entrypoint.sh /entrypoint.sh
COPY --chown=$USER_UID:$USER_GID ./docker/bashrc /home/${USERNAME}/.bashrc
# Adding the postCreate script
COPY --chown=$USER_UID:$USER_GID ./docker/postCreate.sh /home/${USERNAME}/postCreate.sh

RUN chmod +x /entrypoint.sh /home/${USERNAME}/postCreate.sh \
    && echo "source /opt/ros/jazzy/setup.bash" >> /home/${USERNAME}/.bashrc

# 7. Final handoff
WORKDIR /home/${USERNAME}/${PROJECT_NAME}
USER $USERNAME

# Execute the postCreate script to bake the compiled ROS workspace into the image
RUN PROJECT_NAME=${PROJECT_NAME} /home/${USERNAME}/postCreate.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
