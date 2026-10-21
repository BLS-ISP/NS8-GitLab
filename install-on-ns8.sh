#!/bin/bash

#
# Direct Build & Install Script for NethServer 8 (NS8)
# Run this script as root directly on your NethServer 8 leader/worker node.
# Usage:
#   bash install-on-ns8.sh [NODE_ID] [VERSION_TAG]
#

set -e

NODE_ID="${1:-1}"
export REPOBASE="${REPOBASE:-ghcr.io/bls-isp}"
export IMAGETAG="${2:-1.0.0}"
IMAGE_URL="${REPOBASE}/gitlab:${IMAGETAG}"

echo "============================================================"
echo " Building NethServer 8 GitLab Module (${IMAGE_URL})"
echo "============================================================"

for cmd in buildah podman add-module; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: '$cmd' not found. Please run this script as root on your NethServer 8 node." >&2
        exit 1
    fi
done

# Remove previous local module image if present so add-module picks up the fresh build
podman rmi -f "${IMAGE_URL}" "${REPOBASE}/gitlab:latest" 2>/dev/null || true

# Build the module image locally and tag with SemVer
bash ./build-images.sh
podman tag "${REPOBASE}/gitlab:latest" "${IMAGE_URL}"

echo "============================================================"
echo " Installing GitLab Module (${IMAGE_URL}) on Node ${NODE_ID}..."
echo "============================================================"

add-module "${IMAGE_URL}" "${NODE_ID}"

echo "============================================================"
echo " Installation complete!"
echo " Open your NethServer 8 Cluster Admin UI -> Settings -> GitLab"
echo " to configure your hostname, Let's Encrypt, LDAP, Registry, and Runner."
echo "============================================================"
