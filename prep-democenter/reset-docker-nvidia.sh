#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# Reset Docker, uninstall & reinstall Docker,
# optionally install NVIDIA Container Toolkit,
# and validate GPU container run.
#
# Options:
#   --yes                    Run non-interactively (assume "yes" to prompts)
#   --with-nvidia            Install NVIDIA Container Toolkit (default)
#   --without-nvidia         Skip NVIDIA Container Toolkit install
#   --nvidia-version <ver>   Pin NVIDIA toolkit packages to this version (default: 1.17.8-1)
#
# Example:
#   sudo bash reset-docker-and-nvidia.sh --yes --with-nvidia --nvidia-version 1.17.8-1
# ==========================================

YES=0
WITH_NVIDIA=1
NVIDIA_VERSION_DEFAULT="1.17.8-1"
NVIDIA_VERSION="$NVIDIA_VERSION_DEFAULT"

function usage() {
  echo "Usage: $0 [--yes] [--with-nvidia|--without-nvidia] [--nvidia-version <version>]"
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) YES=1; shift ;;
    --with-nvidia) WITH_NVIDIA=1; shift ;;
    --without-nvidia) WITH_NVIDIA=0; shift ;;
    --nvidia-version)
      [[ $# -ge 2 ]] || usage
      NVIDIA_VERSION="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

function confirm() {
  local prompt="$1"
  if [[ $YES -eq 1 ]]; then
    echo "[auto-yes] $prompt"
    return 0
  fi
  read -r -p "$prompt [y/N]: " ans
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}

function info() { echo -e "\n\033[1;34m[INFO]\033[0m $*"; }
function warn() { echo -e "\n\033[1;33m[WARN]\033[0m $*"; }
function err()  { echo -e "\n\033[1;31m[ERROR]\033[0m $*" >&2; }

# Require apt-based distro
if ! command -v apt-get >/dev/null 2>&1; then
  err "This script expects an apt-based system (Debian/Ubuntu). Aborting."
  exit 1
fi

# Ensure running with sudo/root
if [[ "$(id -u)" -ne 0 ]]; then
  err "Please run as root, e.g., with: sudo $0 $*"
  exit 1
fi

# 1) Stop and remove all Docker data (if docker exists)
if command -v docker >/dev/null 2>&1; then
  warn "About to STOP and REMOVE ALL Docker containers, images, volumes, and prune system cache."
  if confirm "Proceed with full Docker cleanup?"; then
    info "Stopping all running containers (if any)..."
    docker ps -q | xargs -r docker stop || true

    info "Removing all containers (if any)..."
    docker ps -a -q | xargs -r docker rm -f || true

    info "Pruning Docker system (images, networks, build cache)..."
    docker system prune -a -f || true
  else
    warn "Skipped Docker cleanup (containers/images may remain)."
  fi
else
  warn "Docker CLI not found—skipping container/image cleanup step."
fi

# 2) Uninstall Docker packages
warn "About to purge Docker packages."
if confirm "Purge Docker packages (docker-ce, docker.io, etc.)?"; then
  info "Purging Docker packages..."
  apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras || true
  apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-compose-plugin || true
  apt-get autoremove -y --purge docker-engine docker docker.io docker-ce docker-compose-plugin || true
else
  warn "Skipped purging Docker packages."
fi

# 3) Remove leftover Docker files
warn "About to remove leftover Docker files and groups (irreversible)."
if confirm "Remove /var/lib/docker, /etc/docker, /var/lib/containerd, ~/.docker, and docker group/socket?"; then
  info "Removing Docker directories and files..."
  rm -rf /var/lib/docker /etc/docker || true
  rm -f /etc/apparmor.d/docker || true
  groupdel docker || true
  rm -f /var/run/docker.sock || true
  rm -rf /var/lib/containerd || true
  # Remove user-level config for the invoking (sudo) user when possible
  if [[ -n "${SUDO_USER:-}" ]]; then
    sudo -u "$SUDO_USER" rm -rf "/home/$SUDO_USER/.docker" || true
  fi
else
  warn "Skipped removal of leftover Docker files."
fi

# 4) Remove NVIDIA Container Toolkit (if present)
if [[ $WITH_NVIDIA -eq 1 ]]; then
  warn "About to purge NVIDIA Container Toolkit packages (if installed)."
  if confirm "Purge NVIDIA Container Toolkit packages?"; then
    info "Purging NVIDIA Container Toolkit packages..."
    apt-get purge -y \
      nvidia-container-toolkit \
      nvidia-container-toolkit-base \
      libnvidia-container-tools \
      libnvidia-container1 || true
  else
    warn "Skipped purging NVIDIA Container Toolkit."
  fi
fi

# 5) Install Docker (official convenience script)
info "Installing Docker using the official convenience script..."
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh

# Ensure docker group exists and add user
if ! getent group docker >/dev/null; then
  info "Creating docker group..."
  groupadd docker
fi

if [[ -n "${SUDO_USER:-}" ]]; then
  info "Adding user '$SUDO_USER' to docker group..."
  usermod -aG docker "$SUDO_USER" || true
else
  warn "SUDO_USER not set; skipping usermod for docker group."
fi

# 6) Install NVIDIA Container Toolkit (optional)
if [[ $WITH_NVIDIA -eq 1 ]]; then
  info "Configuring NVIDIA Container Toolkit repository..."
  # Create keyring & list (idempotent)
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

  info "Updating apt package list..."
  apt-get update -y

  info "Installing NVIDIA Container Toolkit packages (version: ${NVIDIA_VERSION})..."
  apt-get install -y \
    "nvidia-container-toolkit=${NVIDIA_VERSION}" \
    "nvidia-container-toolkit-base=${NVIDIA_VERSION}" \
    "libnvidia-container-tools=${NVIDIA_VERSION}" \
    "libnvidia-container1=${NVIDIA_VERSION}"

  info "Configuring Docker runtime for NVIDIA..."
  nvidia-ctk runtime configure --runtime=docker

  info "Restarting Docker daemon..."
  systemctl restart docker
else
  warn "Skipping NVIDIA Container Toolkit installation (--without-nvidia)."
fi

# 7) Reset docker credentials for a clean start
warn "About to reset Docker client credentials (~/.docker/config.json) for the invoking user."
if confirm "Reset Docker credentials (remove ~/.docker/config.json)?"; then
  info "Stopping Docker service..."
  systemctl stop docker || service docker stop || true

  if [[ -n "${SUDO_USER:-}" ]]; then
    sudo -u "$SUDO_USER" rm -f "/home/$SUDO_USER/.docker/config.json" || true
  fi

  info "Starting Docker service..."
  systemctl start docker || service docker start
else
  warn "Skipped resetting Docker credentials."
fi

# 8) Validation
info "Docker version:"
docker version || true

if [[ $WITH_NVIDIA -eq 1 ]]; then
  info "Validating NVIDIA runtime with a sample container (ubuntu + nvidia-smi)..."
  # Using ubuntu; nvidia-smi comes from host driver mapped via runtime
  # If this fails, ensure NVIDIA driver is installed on the host.
  if docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi; then
    info "NVIDIA GPU is accessible inside Docker container."
  else
    warn "Failed to run 'nvidia-smi' in a container. Ensure NVIDIA GPU drivers are installed on the host and compatible with the toolkit."
  fi
else
  info "NVIDIA validation skipped."
fi

echo
info "All done!"
if [[ -n "${SUDO_USER:-}" ]]; then
  echo "Note: You may need to log out and back in for docker group changes to take effect for user '$SUDO_USER'."
fi
``