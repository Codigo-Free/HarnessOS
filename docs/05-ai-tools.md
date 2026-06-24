# AI Tools

HarnessOS ships with a curated set of AI coding tools pre-configured and ready to use.

## harness ai — System-aware AI assistant

`harness ai` is HarnessOS's built-in AI chat powered by Ollama. Unlike running `ollama run` directly, `harness ai` injects live system context into every conversation — the AI knows your machine before you type a single word.

**Launch:**
```bash
harness ai              # Interactive chat
harness ai -m llama3.2  # Specify model
harness ai --explain "sudo rm -rf /var/cache/pacman/pkg"   # Explain a command
# or from Hyprland: SUPER + A
```

**What the AI sees at startup:**
```
OS      : HarnessOS (Arch Linux)
Kernel  : 7.0.12-zen1-1-zen
Uptime  : up 2 hours, 14 minutes
GPU     : NVIDIA RTX 3080, driver 550.x

Memory  : 15Gi total, 4.2Gi used

Disk    :
  /        used 24G  avail 180G  (12%)
  /home    used 8G   avail 196G  (4%)

Failed services: (none)

Running Docker containers:
  postgres-dev (postgres:16)
  redis-cache  (redis:7)

Recent shell commands (last 20):
  docker compose up -d
  git push origin main
  npm run dev
  ...
```

**Example session:**
```
you › why is my node dev server crashing?
AI  › Looking at your recent commands, you ran `npm run dev` after `docker compose up -d`.
      Your docker-compose likely exposes port 3000, which conflicts with your dev server.
      Try:
      ```bash
      lsof -i :3000
      docker compose down
      npm run dev
      ```

Run command [1] lsof -i :3000? [y/n] y
$ lsof -i :3000
COMMAND  PID   USER   ...
node    1234  harness ...
```

**Command execution:** When the AI suggests shell commands in ` ```bash ``` ` blocks, `harness ai` offers to run them one by one. You approve each before execution — the AI never runs anything without your confirmation.

**Session persistence:** Conversations are saved to `~/.local/share/harness/ai-sessions/TIMESTAMP.json` automatically.

**Model configuration:** Set your preferred model in `~/.config/harness/config.toml`:
```toml
model = "llama3.2"
```

**Waybar widget:** The top bar shows the active Ollama model name in green when running. Click it to open `harness ai`.

---

## Claude CLI

Claude Code is Anthropic's official CLI for the Claude AI assistant. It provides an interactive terminal interface for AI-assisted coding.

**Install** (auto-installed on first boot with internet):
```bash
npm install -g @anthropic-ai/claude-code
```

**Launch:**
```bash
claude
# or from Hyprland: SUPER + C
```

**First run:** Claude will prompt you to log in with your Anthropic account at `claude.ai`.

**Common usage:**
```bash
claude                    # Interactive session
claude "explain this"     # One-shot query
claude --help             # All options
```

## Ollama (Local LLMs)

Ollama runs large language models locally — no internet required after downloading.

**Service:** `ollama.service` is enabled and starts automatically.

**Pull a model** (first run, requires internet):
```bash
ollama pull llama3.2       # ~2 GB, recommended for most hardware
ollama pull codellama      # Specialized for code generation
ollama pull deepseek-coder # Strong code model
```

**Run a model:**
```bash
ollama run llama3.2
# or from Hyprland: SUPER + O
```

**List installed models:**
```bash
ollama list
```

**API:** Ollama exposes a REST API at `http://localhost:11434`. Compatible with OpenAI API format.

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Write a Python function to sort a list"
}'
```

## GitHub Copilot CLI

Copilot in the terminal via the `gh` CLI extension.

**Install** (auto-installed on first boot):
```bash
gh extension install github/gh-copilot
```

**Authenticate:**
```bash
gh auth login
```

**Usage:**
```bash
gh copilot suggest "list all docker containers sorted by size"
gh copilot explain "$(cat script.sh)"
```

## Docker with GPU support

Docker is pre-configured with NVIDIA container runtime support (when NVIDIA GPU is detected by the installer).

```bash
# Run a container with GPU access
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi

# Run Ollama in Docker with GPU
docker run -d --gpus all -p 11434:11434 ollama/ollama
```

## Recommended workflow

```
┌─────────────────────────────────────────────┐
│  Your project directory                      │
│                                              │
│  $ claude          ← AI pair programmer     │
│  $ ollama run ...  ← Local reasoning        │
│  $ code .          ← VS Code editor         │
│  $ git commit      ← Version control        │
└─────────────────────────────────────────────┘
```
