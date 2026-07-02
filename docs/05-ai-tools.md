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

## The local AI brain (v2026.07.02.1)

Since v2026.07.02.1, Ollama is wired into the whole system as a single local brain: one model-routing config, one system-context server, every tool connected. Everything runs locally — no API key, no cost, nothing leaves your machine.

### Shell AI — wtf, ask, Ctrl+X Ctrl+A

| Command | What it does |
|---------|--------------|
| `wtf` | Diagnoses the **last failed command** — sends the exact command, its exit code and live system context to the local model |
| `ask "question"` | One-shot answer with real system context (kernel, services, disk, recent commands) |
| `Ctrl+X Ctrl+A` | Explains the command currently typed at the prompt (risks included) without losing your input |

When a command fails with a "real" error (exit code > 1), the shell prints a hint:

```
❯ systemctl statuss ollama
Unknown command verb 'statuss', did you mean 'status'?
↯ exit 2 — escribe 'wtf' para diagnóstico con IA
❯ wtf
```

If the answer contains commands, you get an approval menu (`[1] [2] a=all n=skip`) before anything runs.

### Hardware-tuned models — harness-tune-ai

On first boot, `harness-tune-ai` detects GPU VRAM and system RAM and writes the optimal model tier to `~/.config/harness/config.toml`:

| Tier | Hardware | Example models |
|------|----------|----------------|
| high | ≥ 20 GB VRAM | qwen3:27b, deepseek-r1:14b |
| mid | ≥ 10 GB VRAM | qwen2.5-coder:14b |
| base | ≥ 5 GB VRAM / ≥ 14 GB RAM | qwen2.5-coder:7b, llama3.2 |
| low | anything else | qwen2.5-coder:3b, llama3.2 |

Machines without a dedicated GPU get a `+cpu` variant: interactive diagnosis modes (`doctor`, `logs`) use fast non-reasoning models — a chain-of-thought model on CPU takes 6+ minutes per answer. The chosen models are pre-pulled in the background so the first `wtf` doesn't stall on a download. Re-run after a hardware change: `harness-tune-ai --force`.

### System MCP server — harness-mcp

`/usr/local/bin/harness-mcp` is a zero-dependency MCP (Model Context Protocol) server that exposes **read-only** system tools to any AI agent:

| Tool | What the agent sees |
|------|---------------------|
| `system_overview` | kernel, uptime, memory, disk, failed units, GPU |
| `journal` | systemd journal (filter by unit, errors only, current boot) |
| `service_status` | full `systemctl status` of one unit |
| `pacman` | package info, file ownership, orphans, pending updates |
| `docker_ps` | containers and their state |
| `ollama_models` | local models + the routing config |

Claude Code gets it registered automatically on first boot (`claude mcp add --scope user harness`); OpenCode loads it from `~/.config/opencode/opencode.json`. Any other MCP client can use it: `command = /usr/local/bin/harness-mcp`. Since every tool is read-only, agents can *see* the machine but any mutation still goes through your normal command approval.

### Editors, preconfigured

- **OpenCode** (`opencode`) — ships with the local Ollama provider (llama3.2, qwen2.5-coder, deepseek-r1) and `harness-mcp` already configured. Just `cd` into a project and run `opencode`, then pick a model with `/models`.
- **VS Code + Continue** — the Continue extension (installed from Open VSX on first boot) auto-detects every local Ollama model for chat, edit and autocomplete.

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
