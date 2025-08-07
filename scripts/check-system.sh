#!/bin/bash

echo "🔍 Checking Multi-Agent Observability System Status"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
client_running=true
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

# echo -e "\n${BLUE}Client Status (Port 5173):${NC}"
# if check_port 5173; then
#     client_running=true
#     echo -e "${GREEN}✅ Client dev server is running on port 5173${NC}"
    
#     # Check client endpoint
#     if check_endpoint "http://localhost:5173" 3; then
#         echo -e "${GREEN}✅ Client is responding${NC}"
#     else
#         echo -e "${YELLOW}⚠️  Client is running but not responding${NC}"
#     fi
    
#     # Show client PID
#     CLIENT_PID=$(lsof -ti :5173 2>/dev/null | head -1)
#     if [ -n "$CLIENT_PID" ]; then
#         echo -e "${BLUE}   Process ID: ${CLIENT_PID}${NC}"
#     fi
# else
#     echo -e "${RED}❌ No client dev server found on port 5173${NC}"
# fi

# Check for any bun processes related to our apps
echo -e "\n${BLUE}Related Processes:${NC}"
BUN_PROCESSES=$(ps aux | grep -E "bun.*(apps/(server|client))" | grep -v grep)
if [ -n "$BUN_PROCESSES" ]; then
    echo -e "${GREEN}Found bun processes:${NC}"
    echo "$BUN_PROCESSES" | while read line; do
        echo -e "${BLUE}   $line${NC}"
    done
else
    echo -e "${YELLOW}No bun processes found for apps${NC}"
fi

# Overall status summary
echo -e "\n${BLUE}===============================================${NC}"
if $server_running && $client_running && $server_healthy; then
    echo -e "${GREEN}🎉 System Status: FULLY OPERATIONAL${NC}"
    # echo -e "${GREEN}🖥️  Client: http://localhost:5173${NC}"
    echo -e "${GREEN}🔌 Server: http://localhost:4000${NC}"
    echo -e "${GREEN}📡 WebSocket: ws://localhost:4000/stream${NC}"
    exit 0
elif $server_running && $client_running; then
    echo -e "${YELLOW}⚠️  System Status: PARTIALLY OPERATIONAL${NC}"
    echo -e "${YELLOW}   Both services are running but server health check failed${NC}"
    exit 1
elif $server_running || $client_running; then
    echo -e "${YELLOW}⚠️  System Status: PARTIALLY RUNNING${NC}"
    if ! $server_running; then
        echo -e "${RED}   Server is not running${NC}"
    fi
    # if ! $client_running; then
    #     echo -e "${RED}   Client is not running${NC}"
    # fi
    exit 1
else
    echo -e "${RED}❌ System Status: NOT RUNNING${NC}"
    echo -e "${YELLOW}   Run ./scripts/start-system.sh to start the system${NC}"
    exit 2
fi