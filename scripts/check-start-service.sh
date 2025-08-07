#!/bin/bash

echo "🔍 Checking Server Status and Auto-Starting if Needed"
echo "===================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to check HTTP endpoint
check_endpoint() {
    local url=$1
    local timeout=${2:-5}
    if curl -s --max-time $timeout "$url" >/dev/null 2>&1; then
        return 0  # Endpoint is responding
    else
        return 1  # Endpoint is not responding
    fi
}

# Initialize status flags
server_running=false
server_healthy=false

echo -e "\n${BLUE}Server Status (Port 4000):${NC}"
if check_port 4000; then
    server_running=true
    echo -e "${GREEN}✅ Server process is running on port 4000${NC}"
    
    # Check server health endpoints
    if check_endpoint "http://localhost:4000/health"; then
        server_healthy=true
        echo -e "${GREEN}✅ Server health endpoint responding${NC}"
    elif check_endpoint "http://localhost:4000/events/filter-options"; then
        server_healthy=true
        echo -e "${GREEN}✅ Server API endpoint responding${NC}"
    else
        echo -e "${YELLOW}⚠️  Server is running but not responding to health checks${NC}"
    fi
    
    # Show server PID
    SERVER_PID=$(lsof -ti :4000 2>/dev/null | head -1)
    if [ -n "$SERVER_PID" ]; then
        echo -e "${BLUE}   Process ID: ${SERVER_PID}${NC}"
    fi
else
    echo -e "${RED}❌ No server process found on port 4000${NC}"
fi

# If server is not running or not healthy, start the system
if ! $server_running || ! $server_healthy; then
    echo -e "\n${YELLOW}🚀 Server is not running properly. Starting the system...${NC}"
    echo -e "${BLUE}===============================================${NC}"
    
    # Run the start-system.sh script
    if [ -f "$SCRIPT_DIR/start-system.sh" ]; then
        exec "$SCRIPT_DIR/start-system.sh"
    else
        echo -e "${RED}❌ Could not find start-system.sh script${NC}"
        echo -e "${YELLOW}   Expected location: $SCRIPT_DIR/start-system.sh${NC}"
        exit 1
    fi
else
    # Server is running and healthy
    echo -e "\n${BLUE}===============================================${NC}"
    echo -e "${GREEN}🎉 Server Status: OPERATIONAL${NC}"
    echo -e "${GREEN}🔌 Server: http://localhost:4000${NC}"
    echo -e "${GREEN}📡 WebSocket: ws://localhost:4000/stream${NC}"
    
    # Show any related processes
    echo -e "\n${BLUE}Related Processes:${NC}"
    BUN_PROCESSES=$(ps aux | grep -E "bun.*(apps/server)" | grep -v grep)
    if [ -n "$BUN_PROCESSES" ]; then
        echo -e "${GREEN}Found server bun processes:${NC}"
        echo "$BUN_PROCESSES" | while read line; do
            echo -e "${BLUE}   $line${NC}"
        done
    else
        echo -e "${YELLOW}No bun processes found for server app${NC}"
    fi
    
    exit 0
fi