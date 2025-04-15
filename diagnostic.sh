#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Running X-UI Diagnostics${NC}"
echo "============================="

# Check if x-ui is running
echo -e "${YELLOW}Checking if x-ui is running...${NC}"
if pgrep x-ui > /dev/null; then
    echo -e "${GREEN}X-UI is running${NC}"
    PID=$(pgrep x-ui)
    echo "Process ID: $PID"
else
    echo -e "${RED}X-UI is not running${NC}"
fi

# Check database
echo -e "${YELLOW}Checking database...${NC}"
if [ -f "/etc/x-ui/x-ui.db" ]; then
    echo -e "${GREEN}Database exists at /etc/x-ui/x-ui.db${NC}"
    ls -l /etc/x-ui/x-ui.db
else
    echo -e "${RED}Database not found at default location${NC}"
    # Try to find it elsewhere
    DB_PATH=$(find / -name "x-ui.db" 2>/dev/null)
    if [ -n "$DB_PATH" ]; then
        echo -e "${YELLOW}Found database at alternative location: $DB_PATH${NC}"
    else
        echo -e "${RED}Could not find database file${NC}"
    fi
fi

# Check ports
echo -e "${YELLOW}Checking web interface port...${NC}"
netstat -tuln | grep -E '(54321|443)'

# Check logs
echo -e "${YELLOW}Last 20 lines of system log related to x-ui:${NC}"
journalctl -u x-ui --no-pager -n 20

# Check service status
echo -e "${YELLOW}Checking x-ui service status...${NC}"
systemctl status x-ui --no-pager

# Check CGO status
echo -e "${YELLOW}Checking CGO status...${NC}"
go env | grep CGO_ENABLED

echo -e "${GREEN}Diagnostic completed${NC}"
echo "For more detailed logging, restart with verbose mode: x-ui restart -v" 