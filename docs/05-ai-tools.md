# AI Tools

HarnessOS ships with a curated set of AI coding tools pre-configured and ready to use.

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
