#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# lib.sh — Fungsi bantu untuk note_app
# ============================================

# Warna
export C_RESET="\033[0m"
export C_RED="\033[1;31m"
export C_GREEN="\033[1;32m"
export C_YELLOW="\033[1;33m"
export C_BLUE="\033[1;34m"
export C_CYAN="\033[1;36m"
export C_MAGENTA="\033[1;35m"
export C_BOLD="\033[1m"

# Pesan
ok()    { echo -e "${C_GREEN}[✅ OK]${C_RESET} $*"; }
err()   { echo -e "${C_RED}[❌ ERR]${C_RESET} $*"; }
info()  { echo -e "${C_YELLOW}[ℹ️  INFO]${C_RESET} $*"; }
warn()  { echo -e "${C_YELLOW}[⚠️  WARN]${C_RESET} $*"; }

# Step header
step() {
  echo -e "${C_CYAN}╔══════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_CYAN}║  🚀 $1${C_RESET}"
  echo -e "${C_CYAN}╚══════════════════════════════════════════╝${C_RESET}"
}

# Spinner — jalankan PID di background, tampilkan animasi
spinner_run() {
  local pid=$1
  local msg="${2:-Loading...}"
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % 10 ))
    printf "\r${C_CYAN}${spin:$i:1}${C_RESET} ${msg} "
    sleep 0.1
  done
  printf "\r\033[K"
}

# Footer
footer_success() {
  local dur="${1:-0}"
  local size="${2:-0}"
  echo -e "${C_GREEN}══════════════════════════════════════════${C_RESET}"
  echo -e "${C_GREEN}✅ SELESAI — ${dur}s — ${size} MB${C_RESET}"
  echo -e "${C_GREEN}══════════════════════════════════════════${C_RESET}"
}

footer_fail() {
  echo -e "${C_RED}══════════════════════════════════════════${C_RESET}"
  echo -e "${C_RED}❌ PROSES GAGAL${C_RESET}"
  echo -e "${C_RED}══════════════════════════════════════════${C_RESET}"
}
