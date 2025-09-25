#!/bin/bash

###############################################
# Python Environment Setup Script
# Sets up Python environment for Gemma Interactive Chat
###############################################

echo "🐍 Setting up Python environment for Gemma Interactive Chat..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.7+ first."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "✅ Python version: $PYTHON_VERSION"

# Create virtual environment (optional)
if [ "$1" = "--venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv gemma_env
    source gemma_env/bin/activate
    echo "✅ Virtual environment activated"
fi

# Install requirements
echo "📥 Installing Python dependencies..."
pip3 install -r requirements.txt

# Make the script executable
chmod +x gemma_interactive.py

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Usage examples:"
echo "  python3 gemma_interactive.py                           # Local connection"
echo "  python3 gemma_interactive.py -H 15.222.244.108        # EC2 IP"
echo "  python3 gemma_interactive.py -H ec2-xxx.amazonaws.com # EC2 hostname"
echo "  python3 gemma_interactive.py -m gemma2:2b             # Different model"
echo ""
echo "Type '/help' in the chat for available commands."
