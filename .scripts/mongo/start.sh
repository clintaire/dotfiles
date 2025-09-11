#!/bin/bash
# MongoDB Start Script
# This script starts MongoDB using Docker Compose

# Display header
echo "==============="
echo "MongoDB Starter"
echo "==============="
echo

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    echo "Please install Docker before continuing"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose is not installed or not in PATH"
    echo "Please install Docker Compose before continuing"
    exit 1
fi

# Create .env file with secure random password if it doesn't exist
if [ ! -f .env ]; then
    echo "Generating secure credentials..."
    RANDOM_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-16)
    cat > .env << EOF
MONGO_USER=admin
MONGO_PASSWORD=${RANDOM_PASSWORD}
MONGO_DATA_DIR=./data
MONGO_PORT=27017
MONGO_DB_NAME=session_db
ENABLE_ADMIN_INTERFACE=false
EOF
    echo "Created secure configuration in .env file"
fi

# Function to check if MongoDB is already running
check_mongodb_running() {
    docker ps --format "{{.Names}}" | grep -q "mini_app_mongodb"
    return $?
}

# Start MongoDB using Docker Compose
start_mongodb() {
    echo "Starting MongoDB using Docker Compose..."
    docker-compose up -d

    if [ $? -eq 0 ]; then
        echo "MongoDB started successfully"
        echo
        echo "MongoDB is available at: localhost:27017"
        echo
        echo "Connection details are in the .env file"
        echo
        echo "Privacy mode: No admin interface exposed by default"
        echo "To enable admin interface, set ENABLE_ADMIN_INTERFACE=true in .env"
    else
        echo "ERROR: Failed to start MongoDB"
        exit 1
    fi
}

# Check status and start if needed
if check_mongodb_running; then
    echo "MongoDB is already running"
    echo
    echo "MongoDB is available at: localhost:27017"
    echo
    echo "Connection details are in the .env file"
else
    start_mongodb
fi

# Privacy notice
echo
echo "Privacy Notice: All data is stored locally in an isolated Docker volume."
echo "No data is sent to external services. You can delete all data with:"
echo "docker-compose down -v"
