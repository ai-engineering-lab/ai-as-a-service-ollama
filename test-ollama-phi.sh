#!/bin/bash
###############################################
# Test Script for EC2 Ollama with Phi-4-Mini
# Replaces test-ollama-gemma.sh
###############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

EC2_HOST="15.222.252.193"   # Update to your instance
OLLAMA_PORT="11434"
SSH_KEY="YourKeyName3.pem"
SSH_USER="ubuntu"
MODEL="phi4-mini:3.8b"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Ollama Phi Test Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

command_exists() { command -v "$1" >/dev/null 2>&1; }

echo -e "${YELLOW}Checking prerequisites...${NC}"
for c in curl ssh; do
  if ! command_exists "$c"; then
    echo -e "${RED}Error: $c not installed${NC}"
    exit 1
  fi
done
echo -e "${GREEN}✓ All prerequisites present${NC}"
echo ""

echo -e "${YELLOW}Test 1: Ping EC2...${NC}"
if ping -c 2 "$EC2_HOST" >/dev/null 2>&1; then
  echo -e "${GREEN}✓ Reachable${NC}"
else
  echo -e "${RED}✗ Not reachable${NC}"
  exit 1
fi
echo ""

echo -e "${YELLOW}Test 2: Ollama service...${NC}"
BASE_URL="http://$EC2_HOST:$OLLAMA_PORT"
if curl -s --connect-timeout 10 "$BASE_URL/api/tags" >/dev/null 2>&1; then
  echo -e "${GREEN}✓ Service responding${NC}"
  echo -e "${BLUE}Available models:${NC}"
  curl -s "$BASE_URL/api/tags" | python3 -m json.tool 2>/dev/null || curl -s "$BASE_URL/api/tags"
else
  echo -e "${RED}✗ Service not responding${NC}"
  exit 1
fi
echo ""

echo -e "${YELLOW}Test 3: Basic inference...${NC}"
PROMPT_PAYLOAD=$(cat <<JSON
{"model":"$MODEL","prompt":"Hello, can you introduce yourself briefly?","stream":false}
JSON
)
RESP=$(curl -s -X POST "$BASE_URL/api/generate" -H "Content-Type: application/json" -d "$PROMPT_PAYLOAD")
if echo "$RESP" | grep -q '"response"'; then
  echo -e "${GREEN}✓ Inference succeeded${NC}"
  echo "$RESP" | python3 -c "import json,sys;print(json.load(sys.stdin)['response'])"
else
  echo -e "${RED}✗ Inference failed${NC}"
  echo "Raw: $RESP"
fi
echo ""

echo -e "${YELLOW}Test 4: Performance (latency)...${NC}"
PERF_PAYLOAD="{\"model\":\"$MODEL\",\"prompt\":\"What is 2+2?\",\"stream\":false}"
START=$(date +%s.%N)
curl -s -X POST "$BASE_URL/api/generate" -H "Content-Type: application/json" -d "$PERF_PAYLOAD" >/dev/null
END=$(date +%s.%N)
LAT=$(echo "$END - $START" | bc 2>/dev/null || echo "N/A")
echo -e "${BLUE}Latency: ${LAT}s${NC}"
echo ""

echo -e "${YELLOW}Test 5: SSH (optional)...${NC}"
if [ -f "$SSH_KEY" ]; then
  if ssh -i "$SSH_KEY" -o ConnectTimeout=8 -o StrictHostKeyChecking=no "$SSH_USER@$EC2_HOST" "echo 'SSH OK'" 2>/dev/null; then
    echo -e "${GREEN}✓ SSH successful${NC}"
    echo -e "${BLUE}Checking service status...${NC}"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$EC2_HOST" "systemctl is-active ollama" 2>/dev/null
  else
    echo -e "${RED}✗ SSH failed${NC}"
  fi
else
  echo -e "${YELLOW}SSH key ($SSH_KEY) not found - skipping${NC}"
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}EC2: $EC2_HOST${NC}"
echo -e "${GREEN}Model: $MODEL${NC}"
echo -e "${GREEN}Ollama: $BASE_URL${NC}"
echo ""
echo -e "${YELLOW}Sample curl:${NC}"
echo -e "${BLUE}curl -X POST $BASE_URL/api/generate -H 'Content-Type: application/json' -d '{\"model\":\"$MODEL\",\"prompt\":\"Your question\"}'${NC}"
echo ""
echo -e "${GREEN}Tests completed 🚀${NC}"