#!/usr/bin/env python3
"""
Interactive Gemma Chat Interface
A Python-based interactive chat interface for Ollama Gemma on AWS EC2

Author: Dang Hoang, AI Eng.
"""

import requests
import json
import time
import sys
import os
from typing import Dict, Any, Optional
import argparse
from datetime import datetime

class GemmaChat:
    def __init__(self, host: str = "localhost", port: int = 11434, model: str = "gemma2:9b"):
        """
        Initialize the Gemma chat interface
        
        Args:
            host: EC2 instance hostname or IP
            port: Ollama service port (default: 11434)
            model: Model name to use (default: gemma2:9b)
        """
        self.host = host
        self.port = port
        self.model = model
        self.base_url = f"http://{host}:{port}"
        self.conversation_history = []
        self.session_start = datetime.now()
        
        # Colors for terminal output
        self.colors = {
            'user': '\033[92m',      # Green
            'gemma': '\033[94m',     # Blue
            'system': '\033[93m',    # Yellow
            'error': '\033[91m',     # Red
            'info': '\033[96m',      # Cyan
            'reset': '\033[0m'       # Reset
        }
    
    def print_colored(self, text: str, color: str = 'reset') -> None:
        """Print colored text to terminal"""
        print(f"{self.colors[color]}{text}{self.colors['reset']}")
    
    def check_connection(self) -> bool:
        """Check if Ollama service is accessible"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            if response.status_code == 200:
                return True
        except requests.exceptions.RequestException:
            pass
        return False
    
    def get_available_models(self) -> list:
        """Get list of available models"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=10)
            if response.status_code == 200:
                data = response.json()
                return [model['name'] for model in data.get('models', [])]
        except requests.exceptions.RequestException:
            pass
        return []
    
    def send_message(self, prompt: str, stream: bool = False) -> Optional[str]:
        """
        Send a message to Gemma and get response
        
        Args:
            prompt: User's message
            stream: Whether to stream the response
            
        Returns:
            Gemma's response or None if error
        """
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": stream
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=60,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get('response', '')
            else:
                self.print_colored(f"Error: HTTP {response.status_code}", 'error')
                return None
                
        except requests.exceptions.Timeout:
            self.print_colored("Error: Request timeout - model might be loading", 'error')
            return None
        except requests.exceptions.RequestException as e:
            self.print_colored(f"Error: {str(e)}", 'error')
            return None
    
    def stream_message(self, prompt: str) -> None:
        """Stream Gemma's response in real-time"""
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": True
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=60,
                headers={"Content-Type": "application/json"},
                stream=True
            )
            
            if response.status_code == 200:
                self.print_colored("Gemma: ", 'gemma', end='')
                
                for line in response.iter_lines():
                    if line:
                        try:
                            data = json.loads(line.decode('utf-8'))
                            if 'response' in data:
                                print(data['response'], end='', flush=True)
                            if data.get('done', False):
                                break
                        except json.JSONDecodeError:
                            continue
                print()  # New line after streaming
            else:
                self.print_colored(f"Error: HTTP {response.status_code}", 'error')
                
        except requests.exceptions.RequestException as e:
            self.print_colored(f"Error: {str(e)}", 'error')
    
    def save_conversation(self, filename: Optional[str] = None) -> None:
        """Save conversation history to file"""
        if not filename:
            timestamp = self.session_start.strftime("%Y%m%d_%H%M%S")
            filename = f"gemma_conversation_{timestamp}.json"
        
        conversation_data = {
            "session_start": self.session_start.isoformat(),
            "model": self.model,
            "host": self.host,
            "conversation": self.conversation_history
        }
        
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(conversation_data, f, indent=2, ensure_ascii=False)
            self.print_colored(f"Conversation saved to: {filename}", 'info')
        except Exception as e:
            self.print_colored(f"Error saving conversation: {str(e)}", 'error')
    
    def load_conversation(self, filename: str) -> bool:
        """Load conversation history from file"""
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            self.conversation_history = data.get('conversation', [])
            self.print_colored(f"Loaded {len(self.conversation_history)} messages from {filename}", 'info')
            return True
        except Exception as e:
            self.print_colored(f"Error loading conversation: {str(e)}", 'error')
            return False
    
    def show_help(self) -> None:
        """Show help information"""
        help_text = """
Available commands:
  /help, /h          - Show this help message
  /models            - List available models
  /model <name>      - Switch to a different model
  /save [filename]   - Save conversation to file
  /load <filename>   - Load conversation from file
  /clear             - Clear conversation history
  /stats             - Show session statistics
  /quit, /exit, /q   - Exit the chat
  /stream            - Toggle streaming mode
  /history           - Show conversation history

Regular messages will be sent to Gemma for processing.
        """
        self.print_colored(help_text, 'info')
    
    def show_stats(self) -> None:
        """Show session statistics"""
        duration = datetime.now() - self.session_start
        stats = f"""
Session Statistics:
  Duration: {duration}
  Messages exchanged: {len(self.conversation_history)}
  Model: {self.model}
  Host: {self.host}:{self.port}
  Session started: {self.session_start.strftime('%Y-%m-%d %H:%M:%S')}
        """
        self.print_colored(stats, 'info')
    
    def show_history(self) -> None:
        """Show conversation history"""
        if not self.conversation_history:
            self.print_colored("No conversation history yet.", 'info')
            return
        
        self.print_colored("\n--- Conversation History ---", 'system')
        for i, msg in enumerate(self.conversation_history, 1):
            role = msg['role']
            content = msg['content'][:100] + "..." if len(msg['content']) > 100 else msg['content']
            color = 'user' if role == 'user' else 'gemma'
            self.print_colored(f"{i}. {role}: {content}", color)
        self.print_colored("--- End History ---\n", 'system')
    
    def run_interactive(self) -> None:
        """Run the interactive chat session"""
        # Check connection
        self.print_colored("Connecting to Ollama service...", 'system')
        if not self.check_connection():
            self.print_colored(f"Error: Cannot connect to Ollama at {self.base_url}", 'error')
            self.print_colored("Please check:", 'error')
            self.print_colored("1. EC2 instance is running", 'error')
            self.print_colored("2. Ollama service is started", 'error')
            self.print_colored("3. Security group allows port 11434", 'error')
            self.print_colored("4. Host/IP address is correct", 'error')
            return
        
        # Check if model is available
        models = self.get_available_models()
        if not models:
            self.print_colored("Warning: No models found. Ollama might still be initializing.", 'error')
        elif self.model not in models:
            self.print_colored(f"Warning: Model '{self.model}' not found.", 'error')
            self.print_colored(f"Available models: {', '.join(models)}", 'info')
            if models:
                self.model = models[0]
                self.print_colored(f"Switched to: {self.model}", 'info')
        
        # Welcome message
        self.print_colored("=" * 60, 'system')
        self.print_colored("🤖 Gemma Interactive Chat Interface", 'system')
        self.print_colored("=" * 60, 'system')
        self.print_colored(f"Connected to: {self.host}:{self.port}", 'info')
        self.print_colored(f"Model: {self.model}", 'info')
        self.print_colored("Type '/help' for commands or start chatting!", 'info')
        self.print_colored("=" * 60, 'system')
        
        streaming_mode = False
        
        try:
            while True:
                # Get user input
                try:
                    user_input = input(f"\n{self.colors['user']}You: {self.colors['reset']}").strip()
                except KeyboardInterrupt:
                    self.print_colored("\n\nGoodbye! 👋", 'system')
                    break
                
                if not user_input:
                    continue
                
                # Handle commands
                if user_input.startswith('/'):
                    command = user_input.lower().split()
                    
                    if command[0] in ['/quit', '/exit', '/q']:
                        self.print_colored("Goodbye! 👋", 'system')
                        break
                    elif command[0] in ['/help', '/h']:
                        self.show_help()
                    elif command[0] == '/models':
                        models = self.get_available_models()
                        if models:
                            self.print_colored(f"Available models: {', '.join(models)}", 'info')
                        else:
                            self.print_colored("No models available", 'error')
                    elif command[0] == '/model' and len(command) > 1:
                        new_model = command[1]
                        models = self.get_available_models()
                        if new_model in models:
                            self.model = new_model
                            self.print_colored(f"Switched to model: {self.model}", 'info')
                        else:
                            self.print_colored(f"Model '{new_model}' not found", 'error')
                    elif command[0] == '/save':
                        filename = command[1] if len(command) > 1 else None
                        self.save_conversation(filename)
                    elif command[0] == '/load' and len(command) > 1:
                        self.load_conversation(command[1])
                    elif command[0] == '/clear':
                        self.conversation_history = []
                        self.print_colored("Conversation history cleared", 'info')
                    elif command[0] == '/stats':
                        self.show_stats()
                    elif command[0] == '/stream':
                        streaming_mode = not streaming_mode
                        status = "enabled" if streaming_mode else "disabled"
                        self.print_colored(f"Streaming mode {status}", 'info')
                    elif command[0] == '/history':
                        self.show_history()
                    else:
                        self.print_colored(f"Unknown command: {command[0]}", 'error')
                        self.print_colored("Type '/help' for available commands", 'info')
                    continue
                
                # Add user message to history
                self.conversation_history.append({
                    'role': 'user',
                    'content': user_input,
                    'timestamp': datetime.now().isoformat()
                })
                
                # Get response from Gemma
                self.print_colored("Gemma is thinking...", 'system')
                start_time = time.time()
                
                if streaming_mode:
                    self.stream_message(user_input)
                else:
                    response = self.send_message(user_input)
                    if response:
                        self.print_colored(f"Gemma: {response}", 'gemma')
                    else:
                        self.print_colored("Sorry, I couldn't get a response from Gemma.", 'error')
                        continue
                
                # Add response to history
                if not streaming_mode and response:
                    self.conversation_history.append({
                        'role': 'assistant',
                        'content': response,
                        'timestamp': datetime.now().isoformat()
                    })
                
                # Show response time
                response_time = time.time() - start_time
                self.print_colored(f"[Response time: {response_time:.2f}s]", 'system')
                
        except Exception as e:
            self.print_colored(f"Unexpected error: {str(e)}", 'error')
        
        # Save conversation on exit
        if self.conversation_history:
            save = input("\nSave conversation? (y/N): ").strip().lower()
            if save in ['y', 'yes']:
                self.save_conversation()

def main():
    """Main function with command line argument parsing"""
    parser = argparse.ArgumentParser(
        description="Interactive Gemma Chat Interface for AWS EC2 Ollama",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python gemma_interactive.py                           # Use localhost
  python gemma_interactive.py -H 15.222.244.108        # Use specific IP
  python gemma_interactive.py -H ec2-xxx.amazonaws.com # Use EC2 hostname
  python gemma_interactive.py -m gemma2:2b             # Use different model
        """
    )
    
    parser.add_argument(
        '-H', '--host',
        default='localhost',
        help='EC2 instance hostname or IP (default: localhost)'
    )
    
    parser.add_argument(
        '-p', '--port',
        type=int,
        default=11434,
        help='Ollama service port (default: 11434)'
    )
    
    parser.add_argument(
        '-m', '--model',
        default='gemma2:9b',
        help='Model name to use (default: gemma2:9b)'
    )
    
    parser.add_argument(
        '--version',
        action='version',
        version='Gemma Interactive Chat v1.0 - Dang Hoang, AI Eng.'
    )
    
    args = parser.parse_args()
    
    # Create and run chat interface
    chat = GemmaChat(host=args.host, port=args.port, model=args.model)
    chat.run_interactive()

if __name__ == "__main__":
    main()
