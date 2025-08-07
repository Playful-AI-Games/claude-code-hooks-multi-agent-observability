#!/bin/bash

echo "🛑 Stopping Multi-Agent Observability System"
echo "============================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to kill processes on a port
kill_port() {
    local port=$1
    local name=$2
    
    echo -e "\n${YELLOW}Stopping $name on port $port...${NC}"
    
    # Find PIDs using the port
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        PIDS=$(lsof -ti :$port 2>/dev/null)
    else
        # Linux
        PIDS=$(lsof -ti :$port 2>/dev/null || fuser -n tcp $port 2>/dev/null | awk '{print $2}')
    fi
    
    if [ -n "$PIDS" ]; then
        echo -e "${RED}Found $name processes on port $port: $PIDS${NC}"
        for PID in $PIDS; do
            # Try graceful shutdown first
            kill $PID 2>/dev/null
            sleep 2
            # Check if process is still running
            if kill -0 $PID 2>/dev/null; then
                # Force kill if still running
                kill -9 $PID 2>/dev/null && echo -e "${GREEN}✅ Stopped $name process $PID${NC}" || echo -e "${RED}❌ Failed to stop process $PID${NC}"
            else
                echo -e "${GREEN}✅ Gracefully stopped $name process $PID${NC}"
            fi
        done
    else
        echo -e "${GREEN}✅ No $name processes found on port $port${NC}"
    fi
}

# Stop server processes (port 4000)
kill_port 4000 "server"

# Stop client dev server (port 5173)
kill_port 5173 "client"

# Stop any remaining bun processes related to our apps
echo -e "\n${YELLOW}Checking for remaining bun processes...${NC}"
REMAINING=$(ps aux | grep -E "bun.*(apps/(server|client))" | grep -v grep | awk '{print $2}')
if [ -n "$REMAINING" ]; then
    echo "$REMAINING" | while read PID; do
        if [ -n "$PID" ]; then
            kill -9 $PID 2>/dev/null && echo -e "${GREEN}✅ Stopped bun process $PID${NC}"
        fi
    done
else
    echo -e "${GREEN}✅ No remaining bun processes found${NC}"
fi

echo -e "\n${GREEN}🎉 Multi-Agent Observability System stopped!${NC}"
echo -e "\nTo start again, run: ${YELLOW}./scripts/start-system.sh${NC}"