#!/bin/bash
###############################################
# Phi-4-Mini Interactive Chat (Shell)
# Replaces previous gemma-chat.sh
###############################################

EC2_HOST="35.182.154.119"   # Update as needed
OLLAMA_PORT="11434"
MODEL="phi4-mini:3.8b"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

OLLAMA_URL="http://$EC2_HOST:$OLLAMA_PORT"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Phi-4-Mini Interactive Chat${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Connected to: $EC2_HOST${NC}"
echo -e "${GREEN}Model: $MODEL${NC}"
echo -e "${YELLOW}Type 'quit' or 'exit' to end${NC}"
echo -e "${YELLOW}Type 'clear' to reset screen${NC}"
echo ""

send_to_model() {
  local prompt="$1"
  local json_payload="{\"model\": \"$MODEL\", \"prompt\": \"$prompt\", \"stream\": false}"
  curl -s -X POST "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d "$json_payload" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('response',''))
except Exception as e:
    print(f'Error: {e}')
"
}

while true; do
  echo -ne "${GREEN}You: ${NC}"
  read -r user_input
  [[ -z \"$user_input\" ]] && continue
  if [[ \"$user_input\" == quit || \"$user_input\" == exit ]]; then
    echo -e \"${YELLOW}Goodbye! 👋${NC}\"
    break
  fi
  if [[ \"$user_input\" == clear ]]; then
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Phi-4-Mini Interactive Chat${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Connected to: $EC2_HOST${NC}"
    echo -e "${GREEN}Model: $MODEL${NC}"
    echo ""
    continue
  fi
  echo -e "${BLUE}Model:${NC}"
  send_to_model "$user_input"
  echo ""
done