#!/usr/bin/env bash
# Gera as builds localmente. Uso: ./build.sh [windows|linux|android|web|all]
# Requer o Godot 4.7 no PATH (ou GODOT=/caminho/para/godot) e os templates de exportação instalados.
set -euo pipefail
cd "$(dirname "$0")"
GODOT="${GODOT:-godot}"
target="${1:-all}"

"$GODOT" --headless --import >/dev/null 2>&1 || true

build() {
  mkdir -p "$(dirname "$2")"
  echo ">> $1 -> $2"
  # Android sai em modo debug (assinado com a chave de debug) para instalar logo no telemóvel.
  local mode="--export-release"
  [ "$1" = "Android" ] && mode="--export-debug"
  "$GODOT" --headless "$mode" "$1" "$2"
}

case "$target" in
  windows) build "Windows" builds/windows/ArcadeClassico.exe ;;
  linux)   build "Linux" builds/linux/ArcadeClassico.x86_64 ;;
  android) build "Android" builds/android/ArcadeClassico.apk ;;
  web)     build "Web" builds/web/index.html ;;
  all)
    build "Windows" builds/windows/ArcadeClassico.exe
    build "Linux" builds/linux/ArcadeClassico.x86_64
    build "Android" builds/android/ArcadeClassico.apk || echo "!! Android falhou: confirma o SDK/keystore nas Definições do Editor."
    build "Web" builds/web/index.html
    ;;
  *) echo "Alvo desconhecido: $target"; exit 1 ;;
esac
