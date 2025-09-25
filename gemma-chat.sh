#!/bin/bash

###############################################
# Interactive Gemma Chat Script
# Simple command-line interface to chat with Gemma
###############################################

# Configuration
EC2_HOST="15.222.244.108"  # Actual EC2 public IP
OLLAMA_PORT="11434"
MODEL="gemma2:9b"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

OLLAMA_URL="http://$EC2_HOST:$OLLAMA_PORT"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Gemma Interactive Chat${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Connected to: $EC2_HOST${NC}"
echo -e "${GREEN}Model: $MODEL${NC}"
echo -e "${YELLOW}Type 'quit' or 'exit' to end the session${NC}"
echo -e "${YELLOW}Type 'clear' to clear the conversation${NC}"
echo ""

# Function to send message to Gemma
send_to_gemma() {
    local prompt="$1"
    local json_payload="{\"model\": \"$MODEL\", \"prompt\": \"$prompt\", \"stream\": false}"
    
    curl -s -X POST "$OLLAMA_URL/api/generate" \
        -H "Content-Type: application/json" \
        -d "$json_payload" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data['response'])
except Exception as e:
    print(f'Error: {e}')
    print('Raw response:', sys.stdin.read())
" 2>/dev/null
}

# Main chat loop
while true; do
    echo -e -n "${GREEN}You: ${NC}"
    read -r user_input
    
    # Check for exit commands
    if [[ "$user_input" == "quit" || "$user_input" == "exit" ]]; then
        echo -e "${YELLOW}Goodbye! 👋${NC}"
        break
    fi
    
    # Check for clear command
    if [[ "$user_input" == "clear" ]]; then
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}  Gemma Interactive Chat${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo -e "${GREEN}Connected to: $EC2_HOST${NC}"
        echo -e "${GREEN}Model: $MODEL${NC}"
        echo ""
        continue
    fi
    
    # Skip empty input
    if [[ -z "$user_input" ]]; then
        continue
    fi
    
    # Send to Gemma and display response
    echo -e "${BLUE}Gemma: ${NC}"
    send_to_gemma "$user_input"
    echo ""
done
