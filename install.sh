#!/usr/bin/env bash
set -euo pipefail

# Swordsmith-Coder Installer
# https://github.com/fgravato/swordsmith-coder

REPO="fgravato/swordsmith-coder"
BINARY_NAME="swordsmith-coder"
INSTALL_DIR="${SWORDSMITH_INSTALL_DIR:-${XDG_BIN_DIR:-$HOME/.local/bin}}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/swordsmith-coder"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║                                                           ║"
    echo "  ║   ⚔️  SWORDSMITH-CODER                                     ║"
    echo "  ║   AI Coding Agent powered by OpenRouter                   ║"
    echo "  ║                                                           ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

detect_os() {
    case "$(uname -s)" in
        Linux*)  OS="linux" ;;
        Darwin*) OS="darwin" ;;
        MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
        *) error "Unsupported operating system: $(uname -s)" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) ARCH="x64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
        *) error "Unsupported architecture: $(uname -m)" ;;
    esac
}

detect_shell() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        SHELL_NAME="zsh"
        PROFILE_FILE="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ]; then
        SHELL_NAME="bash"
        if [ -f "$HOME/.bash_profile" ]; then
            PROFILE_FILE="$HOME/.bash_profile"
        else
            PROFILE_FILE="$HOME/.bashrc"
        fi
    elif [ -n "${FISH_VERSION:-}" ]; then
        SHELL_NAME="fish"
        PROFILE_FILE="$HOME/.config/fish/config.fish"
    else
        # Fallback to checking $SHELL
        case "$SHELL" in
            */zsh) SHELL_NAME="zsh"; PROFILE_FILE="$HOME/.zshrc" ;;
            */bash) SHELL_NAME="bash"; PROFILE_FILE="$HOME/.bashrc" ;;
            */fish) SHELL_NAME="fish"; PROFILE_FILE="$HOME/.config/fish/config.fish" ;;
            *) SHELL_NAME="unknown"; PROFILE_FILE="$HOME/.profile" ;;
        esac
    fi
}

check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_deps+=("curl or wget")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v bun &> /dev/null && ! command -v node &> /dev/null; then
        warn "Neither bun nor node found. You'll need to install one of them."
        echo ""
        echo "  Install bun (recommended):"
        echo "    curl -fsSL https://bun.sh/install | bash"
        echo ""
        echo "  Or install Node.js:"
        echo "    https://nodejs.org/"
        echo ""
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
    fi
}

create_directories() {
    info "Creating directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
}

clone_repository() {
    info "Cloning Swordsmith-Coder repository..."
    
    local clone_dir="$HOME/.swordsmith-coder"
    
    if [ -d "$clone_dir" ]; then
        info "Updating existing installation..."
        cd "$clone_dir"
        git pull origin main
    else
        git clone "https://github.com/$REPO.git" "$clone_dir"
        cd "$clone_dir"
    fi
}

install_dependencies() {
    info "Installing dependencies..."
    
    cd "$HOME/.swordsmith-coder"
    
    if command -v bun &> /dev/null; then
        bun install
    elif command -v npm &> /dev/null; then
        npm install
    else
        warn "No package manager found. Please install bun or npm and run 'bun install' manually."
    fi
}

create_launcher() {
    info "Creating launcher script..."
    
    cat > "$INSTALL_DIR/$BINARY_NAME" << 'EOF'
#!/usr/bin/env bash
cd "$HOME/.swordsmith-coder"
if command -v bun &> /dev/null; then
    exec bun run dev "$@"
else
    exec npm run dev "$@"
fi
EOF
    
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
}

setup_openrouter_key() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  OpenRouter API Key Setup${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Swordsmith-Coder uses OpenRouter to access 500+ AI models."
    echo ""
    echo "Get your API key at: ${BLUE}https://openrouter.ai/settings/keys${NC}"
    echo ""
    
    # Check if key already exists
    if [ -n "${OPENROUTER_API_KEY:-}" ]; then
        echo -e "${GREEN}✓ OPENROUTER_API_KEY already set in environment${NC}"
        return 0
    fi
    
    read -p "Do you want to configure your OpenRouter API key now? [Y/n] " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        read -p "Enter your OpenRouter API key: " -r OPENROUTER_KEY
        echo ""
        
        if [ -n "$OPENROUTER_KEY" ]; then
            add_to_profile "$OPENROUTER_KEY"
        else
            warn "No API key entered. You can set it later with:"
            echo "  export OPENROUTER_API_KEY=\"your-key-here\""
        fi
    else
        echo ""
        info "Skipping API key setup. Set it later with:"
        echo "  export OPENROUTER_API_KEY=\"your-key-here\""
    fi
}

add_to_profile() {
    local api_key="$1"
    
    info "Adding OPENROUTER_API_KEY to $PROFILE_FILE..."
    
    # Check if already in profile
    if grep -q "OPENROUTER_API_KEY" "$PROFILE_FILE" 2>/dev/null; then
        warn "OPENROUTER_API_KEY already exists in $PROFILE_FILE"
        read -p "Do you want to update it? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Remove old entry
            if [[ "$OS" == "darwin" ]]; then
                sed -i '' '/OPENROUTER_API_KEY/d' "$PROFILE_FILE"
            else
                sed -i '/OPENROUTER_API_KEY/d' "$PROFILE_FILE"
            fi
        else
            return 0
        fi
    fi
    
    # Add to profile based on shell
    echo "" >> "$PROFILE_FILE"
    echo "# Swordsmith-Coder - OpenRouter API Key" >> "$PROFILE_FILE"
    
    if [ "$SHELL_NAME" = "fish" ]; then
        echo "set -gx OPENROUTER_API_KEY \"$api_key\"" >> "$PROFILE_FILE"
    else
        echo "export OPENROUTER_API_KEY=\"$api_key\"" >> "$PROFILE_FILE"
    fi
    
    success "API key added to $PROFILE_FILE"
    
    # Also export for current session
    export OPENROUTER_API_KEY="$api_key"
}

add_path_to_profile() {
    # Check if INSTALL_DIR is already in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        return 0
    fi
    
    info "Adding $INSTALL_DIR to PATH in $PROFILE_FILE..."
    
    # Check if already added
    if grep -q "$INSTALL_DIR" "$PROFILE_FILE" 2>/dev/null; then
        return 0
    fi
    
    echo "" >> "$PROFILE_FILE"
    echo "# Swordsmith-Coder PATH" >> "$PROFILE_FILE"
    
    if [ "$SHELL_NAME" = "fish" ]; then
        echo "fish_add_path $INSTALL_DIR" >> "$PROFILE_FILE"
    else
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$PROFILE_FILE"
    fi
}

create_default_config() {
    local config_file="$CONFIG_DIR/swordsmith-coder.json"
    
    if [ -f "$config_file" ]; then
        info "Config file already exists at $config_file"
        return 0
    fi
    
    info "Creating default configuration..."
    
    cat > "$config_file" << 'EOF'
{
  "$schema": "https://swordsmith-coder.example.com/config.json",
  "model": "openrouter/anthropic/claude-sonnet-4.5",
  "small_model": "openrouter/google/gemini-2.5-flash",
  "agent": {
    "plan": {
      "model": "openrouter/openai/gpt-5.2"
    },
    "docs": {
      "model": "openrouter/google/gemini-2.5-pro"
    }
  }
}
EOF
    
    success "Created config at $config_file"
}

print_success() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ Swordsmith-Coder installed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  To get started:"
    echo ""
    echo "    1. Reload your shell or run:"
    echo -e "       ${CYAN}source $PROFILE_FILE${NC}"
    echo ""
    echo "    2. Run Swordsmith-Coder:"
    echo -e "       ${CYAN}swordsmith-coder${NC}"
    echo ""
    echo "  Configuration:"
    echo "    Config file: $CONFIG_DIR/swordsmith-coder.json"
    echo "    Install dir: $HOME/.swordsmith-coder"
    echo ""
    echo "  Documentation:"
    echo "    https://github.com/fgravato/swordsmith-coder"
    echo ""
    echo "  Get more models at:"
    echo "    https://openrouter.ai/models"
    echo ""
}

main() {
    print_banner
    
    info "Starting Swordsmith-Coder installation..."
    echo ""
    
    detect_os
    detect_arch
    detect_shell
    
    info "Detected: $OS ($ARCH) with $SHELL_NAME shell"
    echo ""
    
    check_dependencies
    create_directories
    clone_repository
    install_dependencies
    create_launcher
    add_path_to_profile
    create_default_config
    setup_openrouter_key
    
    print_success
}

# Run main
main "$@"
