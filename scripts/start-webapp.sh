#!/bin/bash

echo "🚀 Starting Multi-Agent Observability WebApp"
echo "==========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of scripts)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"


if check_port 5173; then
    echo -e "${YELLOW}⚠️  Port 5173 is already in use. Run ./scripts/reset-system.sh first.${NC}"
    exit 1
fi

# Start client
echo -e "\n${GREEN}Starting client on port 5173...${NC}"
cd "$PROJECT_ROOT/apps/client"
bun run dev &
CLIENT_PID=$!

# Wait for client to be ready
echo -e "${YELLOW}Waiting for client to start...${NC}"
for i in {1..10}; do
    if curl -s http://localhost:5173 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Client is ready!${NC}"
        break
    fi
    sleep 1
done

# Display status
echo -e "\n${BLUE}============================================${NC}"
echo -e "${BLUE}============================================${NC}"
echo
echo -e "🖥️  Client URL: ${GREEN}http://localhost:5173${NC}"
echo
echo -e "📝 Process IDs:"
echo -e "   Client PID: ${YELLOW}$CLIENT_PID${NC}"
echo
echo -e "${BLUE}Press Ctrl+C to stop both processes${NC}"

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Shutting down...${NC}"
    kill $CLIENT_PID 2>/dev/null
    echo -e "${GREEN}✅ Stopped all processes${NC}"
    exit 0
}

# Set up trap to cleanup on Ctrl+C
trap cleanup INT

# Wait for both processes
wait $CLIENT_PID