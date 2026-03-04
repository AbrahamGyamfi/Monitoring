#!/bin/bash
set -e

echo "BeforeInstall: Stopping existing containers..."
cd /home/ec2-user/taskflow || exit 0

if [ -f docker-compose.yml ]; then
    docker-compose down || true
fi

echo "BeforeInstall: Cleaning up old files..."
rm -rf /home/ec2-user/taskflow/*
