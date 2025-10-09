#!/usr/bin/env python3
"""
Phi Interactive Chat Interface
Default model: phi4-mini:3.8b
(Adapted from previous Gemma interface)
"""

import requests
import json
import time
import argparse
from datetime import datetime

class PhiChat:
    def __init__(self, host: str = "localhost", port: int = 11434, model: str = "phi4-mini:3.8b"):
        self.host = host
        self.port = port
        self.model = model
        self.base_url = f"http://{host}:{port}"
        self.conversation_history = []
        self.session_start = datetime.now()
        self.colors = {
            'user': '\033[92m',
            'model': '\033[94m',
            'system': '\033[93m',
            'error': '\033[91m',
            'info': '\033[96m',
            'reset': '\033[0m'
        }

    def cprint(self, text: str, color: str = 'reset', end: str = '\n'):
        print(f"{self.colors[color]}{text}{self.colors['reset']}", end=end)

    def check_connection(self) -> bool:
        try:
            r = requests.get(f"{self.base_url}/api/tags", timeout=5)
            return r.status_code == 200
        except requests.exceptions.RequestException:
            return False

    def get_models(self):
        try:
            r = requests.get(f"{self.base_url}/api/tags", timeout=10)
            if r.status_code == 200:
                data = r.json()
                return [m['name'] for m in data.get('models', [])]
        except requests.exceptions.RequestException:
            pass
        return []

    def send_message(self, prompt: str):
        payload = {"model": self.model, "prompt": prompt, "stream": False}
        try:
            r = requests.post(f"{self.base_url}/api/generate",
                              json=payload,
                              timeout=120,
                              headers={"Content-Type": "application/json"})
            if r.status_code == 200:
                return r.json().get('response', '')
            self.cprint(f"Error: HTTP {r.status_code}", 'error')
        except requests.exceptions.RequestException as e:
            self.cprint(f"Error: {e}", 'error')
        return None

    def stream_message(self, prompt: str):
        payload = {"model": self.model, "prompt": prompt, "stream": True}
        try:
            with requests.post(f"{self.base_url}/api/generate",
                               json=payload,
                               timeout=120,
                               headers={"Content-Type": "application/json"},
                               stream=True) as r:
                if r.status_code != 200:
                    self.cprint(f"Error: HTTP {r.status_code}", 'error')
                    return
                self.cprint("Phi: ", 'model', end='')
                for line in r.iter_lines():
                    if line:
                        try:
                            data = json.loads(line.decode('utf-8'))
                            if 'response' in data:
                                print(data['response'], end='', flush=True)
                            if data.get('done'):
                                break
                        except json.JSONDecodeError:
                            continue
                print()
        except requests.exceptions.RequestException as e:
            self.cprint(f"Error: {e}", 'error')

    def save(self, filename=None):
        if not filename:
            filename = f"phi_conversation_{self.session_start.strftime('%Y%m%d_%H%M%S')}.json"
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump({
                    "session_start": self.session_start.isoformat(),
                    "model": self.model,
                    "host": self.host,
                    "conversation": self.conversation_history
                }, f, indent=2)
            self.cprint(f"Saved to {filename}", 'info')
        except Exception as e:
            self.cprint(f"Save error: {e}", 'error')

    def load(self, filename):
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                data = json.load(f)
            self.conversation_history = data.get('conversation', [])
            self.cprint(f"Loaded {len(self.conversation_history)} messages", 'info')
        except Exception as e:
            self.cprint(f"Load error: {e}", 'error')

    def stats(self):
        duration = datetime.now() - self.session_start
        self.cprint(
            f"\nSession Stats:\n  Duration: {duration}\n  Messages: {len(self.conversation_history)}\n  Model: {self.model}\n  Host: {self.host}:{self.port}",
            'info'
        )

    def history(self):
        if not self.conversation_history:
            self.cprint("No history.", 'info')
            return
        self.cprint("\n--- History ---", 'system')
        for i, msg in enumerate(self.conversation_history, 1):
            preview = msg['content'][:80] + ('...' if len(msg['content']) > 80 else '')
            self.cprint(f"{i}. {msg['role']}: {preview}", 'model' if msg['role'] == 'assistant' else 'user')
        self.cprint("--- End ---\n", 'system')

    def help(self):
        self.cprint("""
Commands:
/help /h        Show help
/models         List models
/model <name>   Switch model
/save [file]    Save conversation
/load <file>    Load conversation
/clear          Clear history
/stats          Session stats
/stream         Toggle streaming
/history        Show history
/quit /exit /q  Exit
""", 'info')

    def run(self):
        self.cprint("Connecting to Ollama...", 'system')
        if not self.check_connection():
            self.cprint(f"Cannot connect: {self.base_url}", 'error')
            return
        available = self.get_models()
        if available and self.model not in available:
            self.cprint(f"Model '{self.model}' not found. Using {available[0]}", 'error')
            self.model = available[0]
        self.cprint("=" * 60, 'system')
        self.cprint("Phi-4-Mini Interactive Chat", 'system')
        self.cprint("=" * 60, 'system')
        self.cprint(f"Host: {self.host}:{self.port}", 'info')
        self.cprint(f"Model: {self.model}", 'info')
        self.cprint("Type /help for commands.", 'info')
        self.cprint("=" * 60, 'system')

        streaming = False
        try:
            while True:
                user_input = input(f"\n{self.colors['user']}You: {self.colors['reset']}").strip()
                if not user_input:
                    continue
                if user_input.startswith('/'):
                    parts = user_input.split()
                    cmd = parts[0].lower()
                    if cmd in ['/quit', '/exit', '/q']:
                        self.cprint("Goodbye! 👋", 'system')
                        break
                    elif cmd in ['/help', '/h']:
                        self.help()
                    elif cmd == '/models':
                        m = self.get_models()
                        self.cprint(f"Models: {', '.join(m)}" if m else "No models.", 'info')
                    elif cmd == '/model' and len(parts) > 1:
                        new_model = parts[1]
                        if new_model in self.get_models():
                            self.model = new_model
                            self.cprint(f"Switched to {self.model}", 'info')
                        else:
                            self.cprint("Model not found.", 'error')
                    elif cmd == '/save':
                        self.save(parts[1] if len(parts) > 1 else None)
                    elif cmd == '/load' and len(parts) > 1:
                        self.load(parts[1])
                    elif cmd == '/clear':
                        self.conversation_history = []
                        self.cprint("History cleared.", 'info')
                    elif cmd == '/stats':
                        self.stats()
                    elif cmd == '/history':
                        self.history()
                    elif cmd == '/stream':
                        streaming = not streaming
                        self.cprint(f"Streaming {'enabled' if streaming else 'disabled'}", 'info')
                    else:
                        self.cprint("Unknown command. /help for list.", 'error')
                    continue

                # Record user input
                self.conversation_history.append({
                    "role": "user",
                    "content": user_input,
                    "timestamp": datetime.now().isoformat()
                })

                self.cprint("Phi is thinking...", 'system')
                start = time.time()
                if streaming:
                    self.stream_message(user_input)
                    # No single response text captured in streaming mode
                else:
                    response = self.send_message(user_input)
                    if response:
                        self.cprint(f"Phi: {response}", 'model')
                        self.conversation_history.append({
                            "role": "assistant",
                            "content": response,
                            "timestamp": datetime.now().isoformat()
                        })
                    else:
                        self.cprint("No response.", 'error')
                        continue
                elapsed = time.time() - start
                self.cprint(f"[Response time: {elapsed:.2f}s]", 'system')
        except KeyboardInterrupt:
            self.cprint("\nInterrupted. Goodbye! 👋", 'system')

        if self.conversation_history:
            save = input("Save conversation? (y/N): ").strip().lower()
            if save in ('y', 'yes'):
                self.save()

def main():
    parser = argparse.ArgumentParser(description="Phi Interactive Chat (phi4-mini:3.8b default)")
    parser.add_argument('-H', '--host', default='localhost')
    parser.add_argument('-p', '--port', type=int, default=11434)
    parser.add_argument('-m', '--model', default='phi4-mini:3.8b')
    parser.add_argument('--version', action='version', version='Phi Chat v1.0')
    args = parser.parse_args()
    PhiChat(host=args.host, port=args.port, model=args.model).run()

if __name__ == "__main__":
    main()