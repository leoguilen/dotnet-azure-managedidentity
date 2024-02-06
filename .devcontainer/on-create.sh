## Install additional apt packages ##
sudo apt update -y \
    && sudo apt upgrade -y \
    && sudo apt clean -y \
    && sudo rm -rf /var/lib/apt/lists/*