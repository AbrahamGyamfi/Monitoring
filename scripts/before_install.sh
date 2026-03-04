#!/bin/bash
set -e

echo "BeforeInstall: Stopping existing containers..."
cd /home/ec2-user/taskflow || mkdir -p /home/ec2-user/taskflow

if [ -f docker-compose.prod.yml ]; then
    docker-compose -f docker-compose.prod.yml down || true
elif [ -f docker-compose.yml ]; then
    docker-compose down || true
fi

echo "BeforeInstall: Cleaning up old files..."
rm -rf /home/ec2-user/taskflow/* 2>/dev/null || true

echo "BeforeInstall: Complete"
