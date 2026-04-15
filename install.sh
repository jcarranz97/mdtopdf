#!/usr/bin/env bash
# install.sh — install Pandoc, LaTeX (xelatex), and the Eisvogel template
#
# Run this script once before using mdtopdf locally (without Docker):
#   sh <(curl -fsSL https://raw.githubusercontent.com/jcarranz97/mdtopdf/main/install.sh)
#
# Supported platforms:
#   macOS         — installs via Homebrew (brew must be installed)
#   Ubuntu/Debian — installs via apt + downloads the official Pandoc binary

set -euo pipefail

# ── OS / distro detection ─────────────────────────────────────────────────────

OS=""
DISTRO=""

case "$(uname -s)" in
  Darwin)
    OS="macos"
    ;;
  Linux)
    OS="linux"
    if [ -f /etc/os-release ]; then
      # shellcheck source=/dev/null
      . /etc/os-release
      DISTRO="${ID:-unknown}"
    fi
    ;;
  *)
    echo "error: unsupported operating system: $(uname -s)" >&2
    echo "       Supported: macOS, Ubuntu, Debian." >&2
    exit 1
    ;;
esac

if [ "$OS" = "linux" ]; then
  case "$DISTRO" in
    ubuntu|debian) ;;
    *)
      echo "error: unsupported Linux distribution: ${DISTRO:-unknown}" >&2
      echo "       Supported: Ubuntu, Debian." >&2
      echo "       For other distributions, install manually:" >&2
      echo "       https://github.com/jcarranz97/mdtopdf#installation" >&2
      exit 1
      ;;
  esac
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

step() { echo ""; echo "── $* ──"; }
ok()   { echo "  ok      $*"; }
skip() { echo "  skip    $*"; }
info() { echo "  info    $*"; }

# ── Pandoc ────────────────────────────────────────────────────────────────────

step "Pandoc"

if command -v pandoc &>/dev/null; then
  skip "pandoc already installed ($(pandoc --version | head -1))"
else
  if [ "$OS" = "macos" ]; then
    brew install pandoc
    ok "pandoc installed"
  else
    ARCH="$(uname -m)"
    case "$ARCH" in
      x86_64)  PANDOC_ARCH="amd64" ;;
      aarch64) PANDOC_ARCH="arm64" ;;
      *)
        echo "error: unsupported architecture: $ARCH" >&2
        exit 1
        ;;
    esac

    echo "  fetching latest Pandoc release..."
    PANDOC_VERSION="$(curl -fsSL https://api.github.com/repos/jgm/pandoc/releases/latest \
      | grep '"tag_name"' | sed 's/.*"tag_name": *"\(.*\)".*/\1/')"

    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/man/man1"
    curl -fsSL \
      "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-${PANDOC_ARCH}.tar.gz" \
      | tar xz --strip-components=1 -C "$HOME/.local"
    ok "pandoc $PANDOC_VERSION installed to ~/.local/bin/pandoc"

    # Warn if ~/.local/bin is not on PATH
    case ":${PATH}:" in
      *":$HOME/.local/bin:"*) ;;
      *)
        echo ""
        echo "  warning: ~/.local/bin is not on your PATH."
        echo "           Add the following line to your ~/.bashrc or ~/.zshrc:"
        echo "             export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo "           Then reload your shell or run: source ~/.bashrc"
        ;;
    esac
  fi
fi

# ── LaTeX (xelatex) ───────────────────────────────────────────────────────────

step "LaTeX (xelatex)"

if command -v xelatex &>/dev/null; then
  skip "xelatex already installed"
else
  if [ "$OS" = "macos" ]; then
    info "installing MacTeX — this is a large download (~4 GB), please be patient"
    brew install --cask mactex
    ok "MacTeX installed"
  else
    sudo apt-get update -qq
    sudo apt-get install -y texlive-xetex texlive-fonts-recommended texlive-fonts-extra
    ok "texlive-xetex installed"
  fi
fi

# ── Eisvogel template ─────────────────────────────────────────────────────────

step "Eisvogel template"

TEMPLATE_DIR="$HOME/.local/share/pandoc/templates"

if [ -f "$TEMPLATE_DIR/eisvogel.latex" ]; then
  skip "Eisvogel already installed at $TEMPLATE_DIR/eisvogel.latex"
else
  mkdir -p "$TEMPLATE_DIR"
  WORK_DIR="$(mktemp -d)"
  trap 'rm -rf "$WORK_DIR"' EXIT

  echo "  fetching latest Eisvogel release..."
  curl -fsSL \
    https://github.com/Wandmalfarbe/pandoc-latex-template/releases/latest/download/Eisvogel.tar.gz \
    -o "$WORK_DIR/eisvogel.tar.gz"

  tar -xzf "$WORK_DIR/eisvogel.tar.gz" \
    --strip-components=1 \
    --wildcards '*/eisvogel.latex' \
    -C "$WORK_DIR"

  cp "$WORK_DIR/eisvogel.latex" "$TEMPLATE_DIR/eisvogel.latex"
  ok "Eisvogel installed at $TEMPLATE_DIR/eisvogel.latex"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "All dependencies are installed."
echo ""
echo "Next step: copy the project files into your repo with the setup script:"
echo "  sh <(curl -fsSL https://raw.githubusercontent.com/jcarranz97/mdtopdf/main/setup.sh)"
echo ""
echo "Full documentation: https://github.com/jcarranz97/mdtopdf"
