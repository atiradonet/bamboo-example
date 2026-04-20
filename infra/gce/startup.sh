#!/bin/bash
set -e

# Install Docker
apt-get update
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Run Bamboo server container
# Port 8085: Bamboo UI
# Port 54663: Remote agent communication
docker run -d \
  --name bamboo \
  --restart unless-stopped \
  -p 8085:8085 \
  -p 54663:54663 \
  -v bamboo-data:/var/atlassian/application-data/bamboo \
  atlassian/bamboo
