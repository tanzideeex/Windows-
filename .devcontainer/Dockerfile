# Start from a standard Ubuntu base image provided by GitHub
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install all necessary packages for QEMU, VNC, and a minimal desktop
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    openbox \
    tigervnc-standalone-server \
    git \
    wget \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
