#!/usr/bin/env bash
# Installe eve-telnets pour l'utilisateur courant (pas de sudo).
#
#   ./install.sh                 copie eve-telnets dans ~/.local/bin
#   ./install.sh --url-handler   idem + ouvre les liens telnet:// d'EVE-NG
#                                (console native) avec eve-telnets
#   ./install.sh --uninstall     retire tout ce qui a été posé
#
# Relançable sans risque.
set -euo pipefail

ICI=$(cd "$(dirname "$0")" && pwd)
BIN=${PREFIX:-$HOME/.local}/bin
APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
DESKTOP=$APPS/eve-telnets.desktop

case ${1:-} in
  --uninstall)
    rm -f "$BIN/eve-telnets" "$DESKTOP"
    command -v update-desktop-database > /dev/null && update-desktop-database "$APPS" 2> /dev/null || true
    echo "✓ eve-telnets retiré (le gestionnaire telnet:// revient au précédent, ou à aucun)"
    exit ;;
  "" | --url-handler) ;;
  *) echo "usage : $0 [--url-handler | --uninstall]" >&2; exit 1 ;;
esac

install -Dm755 "$ICI/eve-telnets" "$BIN/eve-telnets"
echo "✓ $BIN/eve-telnets"
case ":$PATH:" in *":$BIN:"*) ;; *) echo "⚠ $BIN n'est pas dans le PATH : l'ajouter dans ~/.bashrc" ;; esac

# Dépendances : seulement signalées, pour ne rien installer sans accord
manque=()
for outil in socat ncat ssh; do command -v "$outil" > /dev/null || manque+=("$outil"); done
if ! command -v sshs > /dev/null && ! command -v fzf > /dev/null; then manque+=("fzf (ou sshs)"); fi
if [ ${#manque[@]} -gt 0 ]; then
  echo "⚠ à installer : ${manque[*]}"
  echo "    Arch : sudo pacman -S socat nmap fzf    (ncat est dans nmap)"
  echo "    Debian/Ubuntu : sudo apt install socat ncat fzf"
  echo "    Fedora : sudo dnf install socat nmap-ncat fzf"
fi

if [ "${1:-}" = --url-handler ]; then
  # Le navigateur lance le lien sans terminal : il faut en ouvrir un
  if command -v xdg-terminal-exec > /dev/null; then
    exec_ligne="xdg-terminal-exec $BIN/eve-telnets %u" terminal=false
  else
    exec_ligne="$BIN/eve-telnets %u" terminal=true
  fi
  mkdir -p "$APPS"
  cat > "$DESKTOP" << EOF
[Desktop Entry]
Type=Application
Name=eve-telnets
Comment=Console des nœuds EVE-NG (Ctrl+D pour quitter)
Exec=$exec_ligne
Terminal=$terminal
NoDisplay=true
MimeType=x-scheme-handler/telnet;
EOF
  avant=$(xdg-mime query default x-scheme-handler/telnet 2> /dev/null || true)
  xdg-mime default eve-telnets.desktop x-scheme-handler/telnet
  command -v update-desktop-database > /dev/null && update-desktop-database "$APPS" 2> /dev/null || true
  echo "✓ liens telnet:// → eve-telnets${avant:+ (avant : $avant)}"
  echo "    Dans EVE-NG : choisir « Native console » sur la page de connexion."
fi

echo "→ ensuite : clé SSH sur la VM EVE-NG (voir le README), puis eve-telnets"
