FROM mcr.microsoft.com/devcontainers/base:bullseye

RUN apt update -y && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install --no-install-recommends build-essential \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*