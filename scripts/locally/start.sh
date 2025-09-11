#!/bin/bash
# Local Session Manager Starter
# This script starts a lightweight session management system

# Display header
echo "======================"
echo "Local Session Manager"
echo "======================"
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

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Generating configuration..."
    cat > .env << EOF
# Redis configuration
REDIS_HOST=redis
REDIS_PORT=6379
# No password by default for local development
REDIS_PASSWORD=

# Session configuration
SESSION_EXPIRY_MINUTES=60
EOF
    echo "Created configuration in .env file"
fi

# Function to check if containers are already running
check_running() {
    docker ps --format "{{.Names}}" | grep -q "mini_app_redis"
    return $?
}

# Start containers using Docker Compose
start_services() {
    echo "Starting services using Docker Compose..."
    docker-compose up -d

    if [ $? -eq 0 ]; then
        echo "Services started successfully"
        echo
        echo "Available session managers:"
        echo "1. Redis-based (uses Redis container)"
        echo "2. File-based (stores files in ./sessions)"
        echo "3. Memory-only (no persistence)"
        echo
        echo "To use a session manager:"
        echo "docker-compose exec session-runner python redis-session.py"
        echo "or"
        echo "docker-compose exec session-runner python file-session.py"
        echo "or"
        echo "docker-compose exec session-runner python memory-session.py"
    else
        echo "ERROR: Failed to start services"
        exit 1
    fi
}

# Check status and start if needed
if check_running; then
    echo "Services are already running"
    echo
    echo "Available session managers:"
    echo "1. Redis-based (uses Redis container)"
    echo "2. File-based (stores files in ./sessions)"
    echo "3. Memory-only (no persistence)"
    echo
    echo "To use a session manager:"
    echo "docker-compose exec session-runner python redis-session.py"
else
    start_services
fi

# Privacy notice
echo
echo "Privacy Notice: All data is stored locally."
echo "No data is sent to external services. You can delete all data with:"
echo "docker-compose down -v"
