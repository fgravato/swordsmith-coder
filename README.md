<p align="center">
  <h1 align="center">⚔️ Swordsmith-Coder</h1>
</p>
<p align="center">An AI coding agent powered by OpenRouter.</p>
<p align="center">
  <a href="https://github.com/fgravato/swordsmith-coder"><img alt="GitHub" src="https://img.shields.io/github/stars/fgravato/swordsmith-coder?style=flat-square" /></a>
</p>

---

Swordsmith-Coder is a fork of [OpenCode](https://github.com/sst/opencode) that uses **OpenRouter** as its single LLM provider, giving you access to 500+ models through one unified API.

## Features

- 🌐 **OpenRouter-powered** - Access Claude, GPT, Gemini, Grok, DeepSeek, Qwen and 500+ more models
- 🎯 **Optimized for coding** - Default models tuned for software development
- 📝 **Smart agent selection** - GPT-5.2 for planning, Gemini 2.5 Pro for documentation
- 🚀 **Simplified setup** - One API key, all models

## Installation

```bash
# Clone the repository
git clone https://github.com/fgravato/swordsmith-coder.git
cd swordsmith-coder

# Install dependencies
bun install

# Run
bun run dev
```

## Configuration

Set your OpenRouter API key:

```bash
export OPENROUTER_API_KEY="your-key-here"
```

Get your API key from [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys).

### Config File

Create `~/.config/swordsmith-coder/swordsmith-coder.json`:

```json
{
  "model": "openrouter/anthropic/claude-sonnet-4.5",
  "small_model": "openrouter/google/gemini-2.5-flash",
  "agent": {
    "plan": { "model": "openrouter/openai/gpt-5.2" },
    "docs": { "model": "openrouter/google/gemini-2.5-pro" }
  }
}
```

## Default Models

### Coding (Priority Order)
1. `xai/grok-code-fast-1` - Top coding model
2. `anthropic/claude-sonnet-4.5` - Anthropic's latest
3. `openai/gpt-5` - OpenAI's flagship
4. `google/gemini-2.5-pro` - Google's best
5. `xai/grok-4-fast` - Fast reasoning
6. `deepseek/deepseek-r1` - DeepSeek reasoning
7. `qwen/qwen3-235b` - Qwen large

### Fast/Small Models
1. `google/gemini-2.5-flash`
2. `openai/gpt-4o-mini`
3. `anthropic/claude-3.5-haiku`
4. `xai/grok-3-mini-fast`
5. `deepseek/deepseek-chat`

### Agent-Specific Models
| Agent | Model | Purpose |
|-------|-------|---------|
| `plan` | `openai/gpt-5.2` | Project planning, task breakdown |
| `docs` | `google/gemini-2.5-pro` | Documentation, markdown, specs |
| `summary` | `google/gemini-2.5-pro` | Conversation summaries |

## Agents

Swordsmith-Coder includes built-in agents you can switch between using `Tab`:

- **build** - Default, full access agent for development work
- **plan** - Read-only agent for analysis and planning (uses GPT-5.2)
- **docs** - Documentation agent for markdown and specs (uses Gemini 2.5 Pro)
- **explore** - Fast agent for codebase exploration

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENROUTER_API_KEY` | Your OpenRouter API key (required) |
| `SWORDSMITH_CONFIG` | Path to config file |
| `SWORDSMITH_CONFIG_DIR` | Config directory path |

Legacy `OPENCODE_*` variables are supported for backwards compatibility.

## Credits

Swordsmith-Coder is based on [OpenCode](https://github.com/sst/opencode) by SST.

## License

MIT
