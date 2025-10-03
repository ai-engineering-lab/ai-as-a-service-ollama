#!/bin/bash

###############################################
# Test Script for Terraformed EC2 Ollama with Gemma
# Tests connectivity and Gemma model functionality
###############################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EC2_HOST="15.222.252.193"  # Actual EC2 public IP
OLLAMA_PORT="11434"
SSH_KEY="YourKeyName3.pem"  # Update this with your actual key file
SSH_USER="ubuntu"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Ollama Gemma EC2 Test Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
if ! command_exists curl; then
    echo -e "${RED}Error: curl is not installed${NC}"
    exit 1
fi

if ! command_exists ssh; then
    echo -e "${RED}Error: ssh is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

# Test 1: Check EC2 connectivity
echo -e "${YELLOW}Test 1: Checking EC2 connectivity...${NC}"
if ping -c 3 $EC2_HOST >/dev/null 2>&1; then
    echo -e "${GREEN}✓ EC2 instance is reachable${NC}"
else
    echo -e "${RED}✗ EC2 instance is not reachable${NC}"
    echo "Please check your IP restrictions and security group settings"
    exit 1
fi
echo ""

# Test 2: Check Ollama service
echo -e "${YELLOW}Test 2: Checking Ollama service...${NC}"
OLLAMA_URL="http://$EC2_HOST:$OLLAMA_PORT"
if curl -s --connect-timeout 10 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama service is running${NC}"
    
    # Get available models
    echo -e "${BLUE}Available models:${NC}"
    curl -s "$OLLAMA_URL/api/tags" | python3 -m json.tool 2>/dev/null || curl -s "$OLLAMA_URL/api/tags"
else
    echo -e "${RED}✗ Ollama service is not responding${NC}"
    echo "Service might still be starting up. Wait a few minutes and try again."
    exit 1
fi
echo ""

# Test 3: Test Gemma model with a simple prompt
echo -e "${YELLOW}Test 3: Testing Gemma model...${NC}"
echo -e "${BLUE}Running test prompt: 'Hello, can you introduce yourself?'${NC}"
echo ""

# Create test prompt
TEST_PROMPT='{"model": "gemma2:9b", "prompt": "Hello, can you introduce yourself? Please keep your response brief.", "stream": false}'

echo -e "${YELLOW}Response from Gemma2:9b:${NC}"
echo -e "${BLUE}----------------------------------------${NC}"

# Send request to Ollama
RESPONSE=$(curl -s -X POST "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d "$TEST_PROMPT")

# Extract and display response
if echo "$RESPONSE" | grep -q '"response"'; then
    echo "$RESPONSE" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data['response'])
except:
    print('Error parsing response')
" 2>/dev/null || echo "$RESPONSE"
else
    echo -e "${RED}Error: No response received from model${NC}"
    echo "Raw response: $RESPONSE"
fi

echo -e "${BLUE}----------------------------------------${NC}"
echo ""

# Test 4: Performance test
echo -e "${YELLOW}Test 4: Performance test...${NC}"
echo -e "${BLUE}Testing response time for a simple question...${NC}"

PERF_PROMPT='{"model": "gemma2:9b", "prompt": "What is 2+2?", "stream": false}'

START_TIME=$(date +%s.%N)
PERF_RESPONSE=$(curl -s -X POST "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d "$PERF_PROMPT")
END_TIME=$(date +%s.%N)

DURATION=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null || echo "N/A")

if echo "$PERF_RESPONSE" | grep -q '"response"'; then
    echo -e "${GREEN}✓ Performance test completed${NC}"
    echo -e "${BLUE}Response time: ${DURATION}s${NC}"
else
    echo -e "${RED}✗ Performance test failed${NC}"
fi
echo ""

# Test 5: SSH connectivity (optional)
echo -e "${YELLOW}Test 5: SSH connectivity test...${NC}"
if [ -f "$SSH_KEY" ]; then
    echo -e "${BLUE}Testing SSH connection...${NC}"
    if ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$EC2_HOST" "echo 'SSH connection successful'" 2>/dev/null; then
        echo -e "${GREEN}✓ SSH connection successful${NC}"
        
        # Check Ollama service status via SSH
        echo -e "${BLUE}Checking Ollama service status...${NC}"
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$EC2_HOST" "systemctl status ollama --no-pager -l" 2>/dev/null || echo "Could not check service status"
    else
        echo -e "${RED}✗ SSH connection failed${NC}"
        echo "Make sure your SSH key ($SSH_KEY) exists and has correct permissions"
    fi
else
    echo -e "${YELLOW}⚠ SSH key file ($SSH_KEY) not found - skipping SSH test${NC}"
    echo "To test SSH, place your .pem key file in this directory"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ EC2 Instance: $EC2_HOST${NC}"
echo -e "${GREEN}✓ Ollama Service: http://$EC2_HOST:$OLLAMA_PORT${NC}"
echo -e "${GREEN}✓ Model: gemma2:9b${NC}"
echo ""
echo -e "${YELLOW}To interact with Gemma manually:${NC}"
echo -e "${BLUE}curl -X POST http://$EC2_HOST:$OLLAMA_PORT/api/generate \\${NC}"
echo -e "${BLUE}  -H 'Content-Type: application/json' \\${NC}"
echo -e "${BLUE}  -d '{\"model\": \"gemma2:9b\", \"prompt\": \"Your question here\"}'${NC}"
echo ""
echo -e "${YELLOW}To SSH into the instance:${NC}"
echo -e "${BLUE}ssh -i $SSH_KEY $SSH_USER@$EC2_HOST${NC}"
echo ""
echo -e "${GREEN}Test completed! 🚀${NC}"
