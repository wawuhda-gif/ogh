#!/bin/bash
# =================================================================
#   NEXUS VPS PANEL v3.1
#   TAMBAHAN: VMess TLS (WS+TLS), VMess nTLS (WS tanpa TLS)
#             VLess TLS, VLess nTLS, Trojan TLS, Trojan nTLS
#   Semua berjalan di Xray-core v26.2.6
#   Gabungkan bagian _inst_xray dan menu_xray dari file ini
#   ke dalam nexus-panel-v3.sh untuk hasil penuh
# =================================================================

R='\033[0;31m'  O='\033[0;33m'  Y='\033[1;33m'
G='\033[0;32m'  GB='\033[1;32m' C='\033[0;36m'
CB='\033[1;36m' B='\033[0;34m'  M='\033[0;35m'
MB='\033[1;35m' W='\033[1;37m'  D='\033[0;90m'
NC='\033[0m'    BOLD='\033[1m'
RB=("$R" "$O" "$Y" "$GB" "$CB" "$B" "$MB")

rainbow(){ local t="$1" o="" l=${#t}
  for((i=0;i<l;i++)); do o+="${RB[$((i%7))]}${t:$i:1}"; done
  echo -e "${o}${NC}"; }
rb_line(){
  echo -e "${R}═${O}═${Y}═${GB}═${CB}═${B}═${MB}═${R}═${O}═${Y}═${GB}═${CB}═${B}═${MB}═${R}═${O}═${Y}═${GB}═${CB}═${B}═${MB}═${R}═${O}═${Y}═${GB}═${CB}═${B}═${MB}═${R}═${O}═${Y}═${GB}═${CB}═${B}═${MB}═${R}═${O}═${Y}═${NC}"; }
rb_line2(){
  echo -e "${R}─${O}─${Y}─${GB}─${CB}─${B}─${MB}─${R}─${O}─${Y}─${GB}─${CB}─${B}─${MB}─${R}─${O}─${Y}─${GB}─${CB}─${B}─${MB}─${R}─${O}─${Y}─${GB}─${CB}─${B}─${MB}─${R}─${O}─${Y}─${GB}─${CB}─${B}─${MB}─${R}─${O}─${Y}─${NC}"; }

PANEL_DIR="/etc/nexus-panel"
XRAY_DIR="/usr/local/etc/xray"
XRAY_BIN="/usr/local/bin/xray"
XRAY_CFG="$XRAY_DIR/config.json"
XRAY_DB="$PANEL_DIR/xray_users.db"
LOG_FILE="/var/log/nexus-panel.log"
THEME_FILE="$PANEL_DIR/theme.conf"
DOMAIN_FILE="$PANEL_DIR/domain.conf"
USERS_DB="$PANEL_DIR/users.db"
UDPC_DB="$PANEL_DIR/udpc_users.db"
ZIVPN_DB="$PANEL_DIR/zivpn_users.db"

XRAY_VER="v26.2.6"
XRAY_ZIP_AMD64="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-64.zip"
XRAY_ZIP_ARM64="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-arm64-v8a.zip"
XRAY_INSTALL_URL="https://github.com/XTLS/Xray-install/raw/main/install-release.sh"
UDPC_BIN_AMD64="https://raw.githubusercontent.com/feely666/udp-custom/main/udp-custom-linux-amd64"
UDPC_CFG_URL="https://raw.githubusercontent.com/feely666/udp-custom/main/config.json"
ZIVPN_AMD64="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
ZIVPN_ARM64="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
BADVPN_AMD64="https://github.com/idtunnel/UDPGW-SSH/raw/master/badvpn-udpgw64"
BADVPN_ARM="https://github.com/idtunnel/UDPGW-SSH/raw/master/badvpn-udpgw"

check_root(){ [[ $EUID -ne 0 ]] && echo -e "${R}ERROR: Harus root!${NC}" && exit 1; }
log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null; }
get_ip(){ curl -s https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}'; }
get_dom(){ [[ -f "$DOMAIN_FILE" ]] && cat "$DOMAIN_FILE" || get_ip; }
get_arch(){ uname -m | grep -qE "aarch64|arm64" && echo "arm64" || echo "amd64"; }
gen_uuid(){ cat /proc/sys/kernel/random/uuid 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())"; }
ok()  { echo -e "  ${GB}[✔]${NC} $*"; }
err() { echo -e "  ${R}[✘]${NC} $*"; }
info(){ echo -e "  ${CB}[•]${NC} $*"; }
warn(){ echo -e "  ${Y}[!]${NC} $*"; }
press_enter(){ echo ""; read -rp "$(echo -e "  ${CB}Tekan ${W}[Enter]${CB} untuk kembali...${NC}")"; }
svc_stat(){ systemctl is-active --quiet "$1" 2>/dev/null && echo -e "${GB}● AKTIF${NC}" || echo -e "${R}● MATI${NC}"; }

load_tema(){
  TEMA="rainbow"; [[ -f "$THEME_FILE" ]] && TEMA=$(cat "$THEME_FILE")
  case "$TEMA" in
    rainbow) HC="$MB";AC="$CB";SC="$Y" ;; merah) HC="$R";AC="$R";SC="$O" ;;
    hijau)   HC="$GB";AC="$GB";SC="$G" ;; biru) HC="$CB";AC="$CB";SC="$B" ;;
    kuning)  HC="$Y";AC="$Y";SC="$O"   ;; magenta) HC="$MB";AC="$MB";SC="$M" ;;
    cyan)    HC="$CB";AC="$CB";SC="$C"  ;; gelap) HC="$D";AC="$W";SC="$D" ;;
    neon)    HC="$GB";AC="$Y";SC="$CB"  ;; ungu) HC="$M";AC="$MB";SC="$B" ;;
    *)       HC="$MB";AC="$CB";SC="$Y"  ;;
  esac
}

header(){
  clear; load_tema
  local IP=$(get_ip)
  local DOM=$(get_dom)
  local NOW=$(date '+%d/%m/%Y %H:%M:%S')
  local OS=$(lsb_release -ds 2>/dev/null | tr -d '"' || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
  local UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
  local CPU=$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{printf "%.1f", $2+$4}')
  local RAM_USED=$(free -h 2>/dev/null | awk '/^Mem:/{print $3}')
  local RAM_TOTAL=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}')
  local DISK=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}')
  local IFACE=$(ip -4 route ls 2>/dev/null | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
  local LOAD=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null)
  local CONN=$(ss -tnp 2>/dev/null | grep -c ESTAB || echo "0")
  local XSTAT=""; systemctl is-active --quiet xray 2>/dev/null && XSTAT="${GB}ON${NC}" || XSTAT="${R}OFF${NC}"
  local SSTAT=""; systemctl is-active --quiet ssh 2>/dev/null && SSTAT="${GB}ON${NC}" || SSTAT="${R}OFF${NC}"
  local USTAT=""; systemctl is-active --quiet udp-custom 2>/dev/null && USTAT="${GB}ON${NC}" || USTAT="${R}OFF${NC}"
  local ZSTAT=""; systemctl is-active --quiet zivpn 2>/dev/null && ZSTAT="${GB}ON${NC}" || ZSTAT="${R}OFF${NC}"

  # ── LOGO OGH-PANELL — gaya slant /|\_  jelas terbaca ──────
  local C1="${RB[0]}" C2="${RB[1]}" C3="${RB[2]}"
  local C4="${RB[3]}" C5="${RB[4]}" C6="${RB[5]}" C7="${RB[6]}"
  [[ "$TEMA" != "rainbow" ]] && \
    C1="$HC" && C2="$HC" && C3="$HC" && C4="$HC" && \
    C5="$HC" && C6="$HC" && C7="$HC"

  echo -e "${C1}---------------------------------------------------------${NC}"
  echo -e "${C1}  ____  ____  _  _      ____  ____  _  _  ____  __    __  ${NC}"
  echo -e "${C2} / __ \/ ___|| || |    |  _ \| __ || \| || ___|| |   | |  ${NC}"
  echo -e "${C3}| |  | | |  _| __ | -- | |_) | |__||  \ || |_  | |   | |  ${NC}"
  echo -e "${C4}| |__| | |_| | || |    |  __/| |__ | |\ \|| |__ | |___| |__${NC}"
  echo -e "${C5} \____/ \____\_|| |    |_|   |____||_| \_||____||_____|____|${NC}"
  echo -e "${C5}---------------------------------------------------------${NC}"
  echo ""
  if [[ "$TEMA" == "rainbow" ]]; then
    rainbow "      ===  Selamat Datang di OGH-PANELL Manager  ==="
    rainbow "       SSH + UDP + VMess + VLess + Trojan  | v3.1  "
  else
    echo -e "${AC}      ===  Selamat Datang di OGH-PANELL Manager  ===${NC}"
    echo -e "${SC}       SSH + UDP + VMess + VLess + Trojan  | v3.1  ${NC}"
  fi

  # ── INFO VPS BLOCK ──────────────────────────────────────────
  echo -e "  ${D}┌─────────────────────────────────────────────────────────┐${NC}"
  echo -e "  ${D}│${NC}  ${Y}${BOLD}INFO SERVER${NC}                                             ${D}│${NC}"
  echo -e "  ${D}├──────────────────────────┬──────────────────────────────┤${NC}"
  printf "  ${D}│${NC}  ${D}IP Publik   :${NC} ${CB}%-14s${NC}${D}│${NC}  ${D}Domain    :${NC} ${CB}%-18s${NC}${D}│${NC}\n" "$IP" "$DOM"
  printf "  ${D}│${NC}  ${D}OS          :${NC} ${W}%-14s${NC}${D}│${NC}  ${D}Uptime    :${NC} ${W}%-18s${NC}${D}│${NC}\n" "${OS:0:14}" "${UPTIME:0:18}"
  printf "  ${D}│${NC}  ${D}CPU Usage   :${NC} ${Y}%-5s %%${NC}        ${D}│${NC}  ${D}Load Avg  :${NC} ${Y}%-18s${NC}${D}│${NC}\n" "$CPU" "$LOAD"
  printf "  ${D}│${NC}  ${D}RAM         :${NC} ${G}%-14s${NC}${D}│${NC}  ${D}Disk /    :${NC} ${G}%-18s${NC}${D}│${NC}\n" "${RAM_USED}/${RAM_TOTAL}" "${DISK:0:18}"
  printf "  ${D}│${NC}  ${D}Interface   :${NC} ${W}%-14s${NC}${D}│${NC}  ${D}Koneksi   :${NC} ${W}%-18s${NC}${D}│${NC}\n" "$IFACE" "${CONN} aktif"
  echo -e "  ${D}├──────────────────────────┴──────────────────────────────┤${NC}"
  printf "  ${D}│${NC}  ${D}Waktu :${NC} ${SC}%-20s${NC}  ${D}Tema :${NC} ${AC}%-20s${NC}           ${D}│${NC}\n" "$NOW" "$TEMA"
  echo -e "  ${D}├─────────────────────────────────────────────────────────┤${NC}"
  printf "  ${D}│${NC}  ${D}SSH :${NC}%b  ${D}Xray :${NC}%b  ${D}UDP Custom :${NC}%b  ${D}ZIVPN :${NC}%b              ${D}│${NC}\n" \
    "$SSTAT" "$XSTAT" "$USTAT" "$ZSTAT"
  echo -e "  ${D}└─────────────────────────────────────────────────────────┘${NC}"
  rb_line2
  echo ""
}

sub_hdr(){ rb_line2; echo -e "  ${1}${BOLD}[ ${2} ]${NC}"; rb_line2; echo ""; }

# =================================================================
#   INSTALL XRAY — semua protokol lengkap (TLS + nTLS)
# =================================================================

_inst_xray(){
  info "Xray-core ${XRAY_VER} (VMess/VLess/Trojan — TLS & nTLS)..."
  apt-get install -y openssl nginx > /dev/null 2>&1

  # Install binary Xray via script resmi
  if ! bash -c "$(curl -Ls "$XRAY_INSTALL_URL")" @ install -u root > /dev/null 2>&1; then
    ARCH=$(get_arch)
    apt-get install -y unzip > /dev/null 2>&1
    [[ "$ARCH" == "amd64" ]] && wget -q "$XRAY_ZIP_AMD64" -O /tmp/xray.zip || \
      wget -q "$XRAY_ZIP_ARM64" -O /tmp/xray.zip
    unzip -q /tmp/xray.zip -d /tmp/xb && cp /tmp/xb/xray "$XRAY_BIN" && chmod +x "$XRAY_BIN"
    rm -rf /tmp/xray.zip /tmp/xb
  fi

  mkdir -p "$XRAY_DIR" /var/log/xray
  local UUID=$(gen_uuid)
  echo "$UUID" > "$PANEL_DIR/xray_master_uuid"

  # Buat self-signed TLS cert untuk Xray
  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=US/ST=CA/L=LA/O=Nexus/CN=$(get_dom)" \
    -keyout "$XRAY_DIR/xray.key" \
    -out "$XRAY_DIR/xray.crt" > /dev/null 2>&1

  # ── CONFIG XRAY LENGKAP — 8 inbound ─────────────────────────
  cat > "$XRAY_CFG" <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [

    {
      "tag": "vmess-ws-ntls",
      "port": 8443,
      "protocol": "vmess",
      "settings": { "clients": [{"id":"$UUID","alterId":0,"email":"default@nexus"}] },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vmess-ntls"}
      }
    },

    {
      "tag": "vmess-ws-tls",
      "port": 8553,
      "protocol": "vmess",
      "settings": { "clients": [{"id":"$UUID","alterId":0,"email":"default@nexus"}] },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile":"$XRAY_DIR/xray.crt","keyFile":"$XRAY_DIR/xray.key"}]
        },
        "wsSettings": {"path": "/vmess-tls"}
      }
    },

    {
      "tag": "vmess-tcp-ntls",
      "port": 1194,
      "protocol": "vmess",
      "settings": { "clients": [{"id":"$UUID","alterId":0,"email":"default@nexus"}] },
      "streamSettings": {"network": "tcp"}
    },

    {
      "tag": "vmess-tcp-tls",
      "port": 2083,
      "protocol": "vmess",
      "settings": { "clients": [{"id":"$UUID","alterId":0,"email":"default@nexus"}] },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile":"$XRAY_DIR/xray.crt","keyFile":"$XRAY_DIR/xray.key"}]
        }
      }
    },

    {
      "tag": "vless-ws-ntls",
      "port": 8444,
      "protocol": "vless",
      "settings": { "clients": [{"id":"$UUID","email":"default@nexus"}], "decryption":"none" },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vless-ntls"}
      }
    },

    {
      "tag": "vless-ws-tls",
      "port": 8554,
      "protocol": "vless",
      "settings": { "clients": [{"id":"$UUID","email":"default@nexus"}], "decryption":"none" },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile":"$XRAY_DIR/xray.crt","keyFile":"$XRAY_DIR/xray.key"}]
        },
        "wsSettings": {"path": "/vless-tls"}
      }
    },

    {
      "tag": "trojan-ntls",
      "port": 8445,
      "protocol": "trojan",
      "settings": { "clients": [{"password":"nexus-trojan","email":"default@nexus"}] },
      "streamSettings": {"network": "tcp"}
    },

    {
      "tag": "trojan-tls",
      "port": 8446,
      "protocol": "trojan",
      "settings": { "clients": [{"password":"nexus-trojan","email":"default@nexus"}] },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile":"$XRAY_DIR/xray.crt","keyFile":"$XRAY_DIR/xray.key"}]
        }
      }
    }

  ],
  "outbounds": [
    {"protocol":"freedom","tag":"direct"},
    {"protocol":"blackhole","tag":"block"}
  ],
  "routing": {
    "rules": [
      {"type":"field","ip":["geoip:private"],"outboundTag":"block"}
    ]
  }
}
EOF

  cat > /etc/systemd/system/xray.service <<'EOF'
[Unit]
Description=Xray Service - VMess/VLess/Trojan TLS & nTLS
After=network.target nss-lookup.target
[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now xray > /dev/null 2>&1
  ok "Xray ${XRAY_VER} — 8 inbound aktif (TLS & nTLS)"
}

# =================================================================
#   MENU XRAY LENGKAP v3.1
# =================================================================

menu_xray(){
  while true; do
    header; sub_hdr "$MB" "MANAJEMEN XRAY — VMess / VLess / Trojan (TLS & nTLS)"
    local XSTAT=$(svc_stat xray)
    local MUUID=$([[ -f "$PANEL_DIR/xray_master_uuid" ]] && cat "$PANEL_DIR/xray_master_uuid" || echo "-")
    echo -e "  ${D}Status:${NC} $XSTAT   ${D}Master UUID:${NC} ${Y}${MUUID:0:20}...${NC}"; echo ""; rb_line2

    echo -e "  ${R}[${W}01${R}]${NC} ${W}Tambah VMess nTLS (WS:8443)${NC}   ${D}│${NC}  ${M}[${W}10${M}]${NC} ${W}Tambah VMess TLS (WS:8553)${NC}"
    echo -e "  ${R}[${W}02${R}]${NC} ${W}Tambah VMess nTLS (TCP:1194)${NC}  ${D}│${NC}  ${M}[${W}11${M}]${NC} ${W}Tambah VMess TLS (TCP:2083)${NC}"
    rb_line2
    echo -e "  ${O}[${W}03${O}]${NC} ${W}Tambah VLess nTLS (WS:8444)${NC}   ${D}│${NC}  ${Y}[${W}12${Y}]${NC} ${W}Tambah VLess TLS (WS:8554)${NC}"
    rb_line2
    echo -e "  ${CB}[${W}04${CB}]${NC} ${W}Tambah Trojan nTLS (TCP:8445)${NC} ${D}│${NC}  ${GB}[${W}13${GB}]${NC} ${W}Tambah Trojan TLS (TCP:8446)${NC}"
    rb_line2
    echo -e "  ${D}[${W}05${D}]${NC} ${W}Daftar Semua User Xray${NC}        ${D}│${NC}  ${D}[${W}14${D}]${NC} ${W}Hapus User Xray${NC}"
    echo -e "  ${D}[${W}06${D}]${NC} ${W}Info Koneksi VMess nTLS${NC}       ${D}│${NC}  ${D}[${W}15${D}]${NC} ${W}Info Koneksi VMess TLS${NC}"
    echo -e "  ${D}[${W}07${D}]${NC} ${W}Info Koneksi VLess nTLS${NC}       ${D}│${NC}  ${D}[${W}16${D}]${NC} ${W}Info Koneksi VLess TLS${NC}"
    echo -e "  ${D}[${W}08${D}]${NC} ${W}Info Koneksi Trojan nTLS${NC}      ${D}│${NC}  ${D}[${W}17${D}]${NC} ${W}Info Koneksi Trojan TLS${NC}"
    echo -e "  ${D}[${W}09${D}]${NC} ${W}Ubah Port Xray${NC}                ${D}│${NC}  ${D}[${W}18${D}]${NC} ${W}Renew SSL Cert Xray${NC}"
    rb_line2
    echo -e "  ${D}[${W}19${D}]${NC} ${W}Restart Xray${NC}   ${D}[${W}20${D}]${NC} ${W}Lihat Config${NC}   ${D}[${W}21${D}]${NC} ${W}Log Xray${NC}"
    rb_line2
    echo -e "  ${M}[${W}00${M}]${NC} ${W}Kembali${NC}"; rb_line2; echo ""
    read -rp "$(echo -e "  ${MB}Pilih [00-21] : ${NC}")" CH

    case "$CH" in
      01|1)  _xray_add "vmess" "ntls" "ws" "8443" "/vmess-ntls" ;;
      02|2)  _xray_add "vmess" "ntls" "tcp" "1194" "" ;;
      03|3)  _xray_add "vless" "ntls" "ws" "8444" "/vless-ntls" ;;
      04|4)  _xray_add_trojan "ntls" "8445" ;;
      10)    _xray_add "vmess" "tls" "ws" "8553" "/vmess-tls" ;;
      11)    _xray_add "vmess" "tls" "tcp" "2083" "" ;;
      12)    _xray_add "vless" "tls" "ws" "8554" "/vless-tls" ;;
      13)    _xray_add_trojan "tls" "8446" ;;
      05|5)  _xray_list ;;
      06|6)  _xray_info_detail "vmess" "ntls" "8443" "ws" "/vmess-ntls" ;;
      07|7)  _xray_info_detail "vless" "ntls" "8444" "ws" "/vless-ntls" ;;
      08|8)  _xray_info_detail "trojan" "ntls" "8445" "tcp" "" ;;
      09|9)  _xray_ubah_port ;;
      14)    _xray_del ;;
      15)    _xray_info_detail "vmess" "tls" "8553" "ws" "/vmess-tls" ;;
      16)    _xray_info_detail "vless" "tls" "8554" "ws" "/vless-tls" ;;
      17)    _xray_info_detail "trojan" "tls" "8446" "tcp" "" ;;
      18)    _xray_renew_ssl ;;
      19)    systemctl restart xray > /dev/null 2>&1 && ok "Xray di-restart." && sleep 1 ;;
      20)    cat "$XRAY_CFG" 2>/dev/null; press_enter ;;
      21)    tail -50 /var/log/xray/access.log 2>/dev/null; journalctl -u xray -n 30 --no-pager; press_enter ;;
      00|0)  return ;;
      *)     warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

# ── Tambah user VMess / VLess (universal) ───────────────────────
_xray_add(){
  local PROTO="$1" TLSMODE="$2" NET="$3" PORT="$4" PATH_WS="$5"
  local LABEL_TLS=""; [[ "$TLSMODE" == "tls" ]] && LABEL_TLS=" (TLS)" || LABEL_TLS=" (nTLS/Plain)"
  local PNAME="${PROTO^^}${LABEL_TLS} — ${NET^^}:${PORT}"

  header; sub_hdr "$GB" "TAMBAH USER $PNAME"
  read -rp "$(echo -e "  ${MB}Email/nama user : ${NC}")" EMAIL
  read -rp "$(echo -e "  ${MB}Expired (hari)  : ${NC}")" DAYS
  [[ -z "$EMAIL" ]] && err "Email wajib!" && press_enter && return

  local UUID=$(gen_uuid)
  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")

  # Tentukan tag inbound berdasarkan protokol + tls + network
  local TAG=""
  if   [[ "$PROTO" == "vmess" && "$TLSMODE" == "ntls" && "$NET" == "ws"  ]]; then TAG="vmess-ws-ntls"
  elif [[ "$PROTO" == "vmess" && "$TLSMODE" == "ntls" && "$NET" == "tcp" ]]; then TAG="vmess-tcp-ntls"
  elif [[ "$PROTO" == "vmess" && "$TLSMODE" == "tls"  && "$NET" == "ws"  ]]; then TAG="vmess-ws-tls"
  elif [[ "$PROTO" == "vmess" && "$TLSMODE" == "tls"  && "$NET" == "tcp" ]]; then TAG="vmess-tcp-tls"
  elif [[ "$PROTO" == "vless" && "$TLSMODE" == "ntls" ]]; then TAG="vless-ws-ntls"
  elif [[ "$PROTO" == "vless" && "$TLSMODE" == "tls"  ]]; then TAG="vless-ws-tls"
  fi

  python3 - <<PYEOF
import json
try:
    with open('$XRAY_CFG','r') as f: c=json.load(f)
    for ib in c.get('inbounds',[]):
        if ib.get('tag')=='$TAG':
            entry={'id':'$UUID','alterId':0,'email':'$EMAIL'} if '$PROTO'=='vmess' else {'id':'$UUID','email':'$EMAIL'}
            ib['settings']['clients'].append(entry)
    with open('$XRAY_CFG','w') as f: json.dump(c,f,indent=2)
    print("OK")
except Exception as e: print(f"ERR:{e}")
PYEOF

  echo "$EMAIL|$PROTO|$TLSMODE|$NET|$UUID|$EXP|$(date +%Y-%m-%d)" >> "$XRAY_DB"
  systemctl restart xray > /dev/null 2>&1

  local IP=$(get_ip) DOM=$(get_dom)
  echo ""; rb_line
  ok "User ${PNAME} berhasil ditambah!"; rb_line
  echo -e "  ${D}Email    :${NC} ${Y}$EMAIL${NC}"
  echo -e "  ${D}UUID     :${NC} ${Y}$UUID${NC}"
  echo -e "  ${D}Expired  :${NC} ${Y}$EXP${NC}"
  echo -e "  ${D}Server   :${NC} ${Y}$IP${NC}"
  echo -e "  ${D}Port     :${NC} ${Y}$PORT${NC}"
  echo -e "  ${D}Network  :${NC} ${Y}$NET${NC}"
  [[ -n "$PATH_WS" ]] && echo -e "  ${D}Path     :${NC} ${Y}$PATH_WS${NC}"
  echo -e "  ${D}TLS      :${NC} ${Y}$TLSMODE${NC}"
  rb_line

  # Generate link/config
  if [[ "$PROTO" == "vmess" ]]; then
    local TLS_VAL=""; [[ "$TLSMODE" == "tls" ]] && TLS_VAL="tls"
    local JSON_OBJ="{\"v\":\"2\",\"ps\":\"$EMAIL\",\"add\":\"$IP\",\"port\":\"$PORT\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"$NET\",\"path\":\"$PATH_WS\",\"type\":\"none\",\"tls\":\"$TLS_VAL\"}"
    local B64=$(echo -n "$JSON_OBJ" | base64 -w0)
    echo -e "  ${CB}VMess Link:${NC}"
    echo -e "  ${Y}vmess://${B64}${NC}"
  elif [[ "$PROTO" == "vless" ]]; then
    local TLS_PARAM=""; [[ "$TLSMODE" == "tls" ]] && TLS_PARAM="&security=tls" || TLS_PARAM="&security=none"
    echo -e "  ${CB}VLess Link:${NC}"
    echo -e "  ${Y}vless://${UUID}@${IP}:${PORT}?type=${NET}&path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$PATH_WS'))")${TLS_PARAM}#${EMAIL}${NC}"
  fi
  rb_line; press_enter
}

# ── Tambah user Trojan TLS / nTLS ──────────────────────────────
_xray_add_trojan(){
  local TLSMODE="$1" PORT="$2"
  local LABEL=""; [[ "$TLSMODE" == "tls" ]] && LABEL="TLS" || LABEL="nTLS/Plain"
  local TAG=""; [[ "$TLSMODE" == "tls" ]] && TAG="trojan-tls" || TAG="trojan-ntls"

  header; sub_hdr "$GB" "TAMBAH USER TROJAN ${LABEL} (TCP:${PORT})"
  read -rp "$(echo -e "  ${MB}Email/nama user : ${NC}")" EMAIL
  read -rp "$(echo -e "  ${MB}Password Trojan : ${NC}")" TPASS
  read -rp "$(echo -e "  ${MB}Expired (hari)  : ${NC}")" DAYS
  [[ -z "$EMAIL" || -z "$TPASS" ]] && err "Wajib diisi!" && press_enter && return

  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")

  python3 - <<PYEOF
import json
try:
    with open('$XRAY_CFG','r') as f: c=json.load(f)
    for ib in c.get('inbounds',[]):
        if ib.get('tag')=='$TAG':
            ib['settings']['clients'].append({'password':'$TPASS','email':'$EMAIL'})
    with open('$XRAY_CFG','w') as f: json.dump(c,f,indent=2)
    print("OK")
except Exception as e: print(f"ERR:{e}")
PYEOF

  echo "$EMAIL|trojan|$TLSMODE|tcp|$TPASS|$EXP|$(date +%Y-%m-%d)" >> "$XRAY_DB"
  systemctl restart xray > /dev/null 2>&1

  local IP=$(get_ip)
  echo ""; rb_line; ok "User Trojan ${LABEL} berhasil ditambah!"; rb_line
  echo -e "  ${D}Email    :${NC} ${Y}$EMAIL${NC}"
  echo -e "  ${D}Password :${NC} ${Y}$TPASS${NC}"
  echo -e "  ${D}Port     :${NC} ${Y}$PORT${NC}"
  echo -e "  ${D}TLS      :${NC} ${Y}$TLSMODE${NC}"
  echo -e "  ${D}Expired  :${NC} ${Y}$EXP${NC}"
  rb_line
  echo -e "  ${CB}Trojan Link:${NC}"
  local TLS_PARAM=""; [[ "$TLSMODE" == "tls" ]] && TLS_PARAM="?security=tls&allowInsecure=1" || TLS_PARAM=""
  echo -e "  ${Y}trojan://${TPASS}@${IP}:${PORT}${TLS_PARAM}#${EMAIL}${NC}"
  rb_line; press_enter
}

# ── Info koneksi detail per protokol ───────────────────────────
_xray_info_detail(){
  local PROTO="$1" TLSMODE="$2" PORT="$3" NET="$4" PATHWS="$5"
  local LABEL=""; [[ "$TLSMODE" == "tls" ]] && LABEL="${MB}[TLS — Terenkripsi]${NC}" || LABEL="${Y}[nTLS — Plain/Tanpa Enkripsi]${NC}"
  local IP=$(get_ip)

  header; sub_hdr "$MB" "INFO KONEKSI ${PROTO^^} ${TLSMODE^^}"
  echo ""; rb_line
  echo -e "  $LABEL"
  rb_line
  echo -e "  ${D}Protokol  :${NC} ${Y}${PROTO^^}${NC}"
  echo -e "  ${D}Server/IP :${NC} ${Y}$IP${NC}"
  echo -e "  ${D}Port      :${NC} ${Y}$PORT${NC}"
  echo -e "  ${D}Network   :${NC} ${Y}$NET${NC}"
  [[ -n "$PATHWS" ]] && echo -e "  ${D}Path      :${NC} ${Y}$PATHWS${NC}"
  if [[ "$TLSMODE" == "tls" ]]; then
    echo -e "  ${D}TLS       :${NC} ${GB}Aktif (self-signed cert)${NC}"
    echo -e "  ${D}allowInsecure :${NC} ${Y}true${NC}  ${D}(karena self-signed)${NC}"
  else
    echo -e "  ${D}TLS       :${NC} ${R}Tidak aktif (plain/non-TLS)${NC}"
  fi
  rb_line
  echo -e "  ${CB}Users ${PROTO^^} ${TLSMODE^^}:${NC}"
  grep "|${PROTO}|${TLSMODE}|" "$XRAY_DB" 2>/dev/null | while IFS='|' read -r em pr tls net uid exp cr; do
    if [[ "$PROTO" == "trojan" ]]; then
      echo -e "  ${D}•${NC} ${W}$em${NC}  Pass: ${Y}$uid${NC}  Exp: ${C}$exp${NC}"
    else
      echo -e "  ${D}•${NC} ${W}$em${NC}  UUID: ${Y}${uid:0:22}...${NC}  Exp: ${C}$exp${NC}"
    fi
  done || echo -e "  ${D}(belum ada user)${NC}"
  rb_line; press_enter
}

# ── Daftar semua user Xray ─────────────────────────────────────
_xray_list(){
  header; sub_hdr "$MB" "SEMUA USER XRAY"
  printf "  ${Y}%-18s %-7s %-5s %-4s %-26s %-12s %s${NC}\n" \
    "EMAIL" "PROTO" "TLS" "NET" "UUID/PASS" "EXPIRED" "DIBUAT"
  rb_line2
  if [[ ! -s "$XRAY_DB" ]]; then echo -e "  ${D}(Belum ada user)${NC}"
  else
    while IFS='|' read -r em pr tls net uid exp cr; do
      local TCOL=""; [[ "$tls" == "tls" ]] && TCOL="${GB}TLS${NC}" || TCOL="${Y}nTLS${NC}"
      printf "  ${W}%-18s${NC} ${M}%-7s${NC} %b  ${C}%-4s${NC} ${D}%-26s${NC} ${Y}%-12s${NC} ${D}%s${NC}\n" \
        "${em:0:18}" "$pr" "$TCOL" "$net" "${uid:0:24}" "$exp" "${cr:-?}"
    done < "$XRAY_DB"
  fi
  rb_line2; press_enter
}

# ── Hapus user Xray ────────────────────────────────────────────
_xray_del(){
  header; sub_hdr "$R" "HAPUS USER XRAY"; _xray_list; echo ""
  read -rp "$(echo -e "  ${MB}Email user : ${NC}")" EMAIL
  local LINE=$(grep "^$EMAIL|" "$XRAY_DB" | head -1)
  [[ -z "$LINE" ]] && err "User tidak ditemukan!" && press_enter && return
  IFS='|' read -r em pr tls net uid _ <<< "$LINE"

  python3 - <<PYEOF
import json
try:
    with open('$XRAY_CFG','r') as f: c=json.load(f)
    for ib in c.get('inbounds',[]):
        proto=ib.get('protocol','')
        if proto in ('vmess','vless'):
            ib['settings']['clients']=[x for x in ib['settings']['clients']
                if x.get('email')!='$EMAIL' and x.get('id')!='$uid']
        elif proto=='trojan':
            ib['settings']['clients']=[x for x in ib['settings']['clients']
                if x.get('email')!='$EMAIL' and x.get('password')!='$uid']
    with open('$XRAY_CFG','w') as f: json.dump(c,f,indent=2)
    print("OK")
except Exception as e: print(f"ERR:{e}")
PYEOF

  sed -i "/^$EMAIL|/d" "$XRAY_DB"
  systemctl restart xray > /dev/null 2>&1
  ok "User ${W}$EMAIL${NC} dihapus dari Xray."; press_enter
}

# ── Ubah port Xray ────────────────────────────────────────────
_xray_ubah_port(){
  header; sub_hdr "$Y" "UBAH PORT XRAY"; echo ""
  echo -e "  ${CB}Port saat ini:${NC}"
  echo -e "  ${W}[1]${NC} VMess nTLS WS  : ${Y}8443${NC}   ${W}[5]${NC} VMess TLS WS  : ${Y}8553${NC}"
  echo -e "  ${W}[2]${NC} VMess nTLS TCP : ${Y}1194${NC}   ${W}[6]${NC} VMess TLS TCP : ${Y}2083${NC}"
  echo -e "  ${W}[3]${NC} VLess nTLS WS  : ${Y}8444${NC}   ${W}[7]${NC} VLess TLS WS  : ${Y}8554${NC}"
  echo -e "  ${W}[4]${NC} Trojan nTLS    : ${Y}8445${NC}   ${W}[8]${NC} Trojan TLS    : ${Y}8446${NC}"
  echo -e "  ${W}[0]${NC} Kembali"; echo ""
  read -rp "$(echo -e "  ${Y}Pilih : ${NC}")" C2
  local TAGS=("" "vmess-ws-ntls" "vmess-tcp-ntls" "vless-ws-ntls" "trojan-ntls" "vmess-ws-tls" "vmess-tcp-tls" "vless-ws-tls" "trojan-tls")
  [[ "$C2" == "0" ]] && return
  [[ "$C2" -ge 1 && "$C2" -le 8 ]] || { warn "Tidak valid"; press_enter; return; }
  local SEL_TAG="${TAGS[$C2]}"
  read -rp "$(echo -e "  ${CB}Port baru untuk ${SEL_TAG} : ${NC}")" NP
  [[ ! "$NP" =~ ^[0-9]+$ ]] && err "Port tidak valid!" && press_enter && return
  python3 - <<PYEOF
import json
with open('$XRAY_CFG','r') as f: c=json.load(f)
for ib in c['inbounds']:
    if ib.get('tag')=='$SEL_TAG': ib['port']=$NP
with open('$XRAY_CFG','w') as f: json.dump(c,f,indent=2)
PYEOF
  ufw allow "$NP" > /dev/null 2>&1
  systemctl restart xray > /dev/null 2>&1
  ok "Port ${SEL_TAG} diubah ke ${Y}$NP${NC}"; press_enter
}

# ── Renew SSL cert Xray ────────────────────────────────────────
_xray_renew_ssl(){
  header; sub_hdr "$Y" "RENEW SSL CERT XRAY"
  info "Membuat ulang sertifikat self-signed..."
  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=US/ST=CA/L=LA/O=Nexus/CN=$(get_dom)" \
    -keyout "$XRAY_DIR/xray.key" \
    -out "$XRAY_DIR/xray.crt" > /dev/null 2>&1
  systemctl restart xray > /dev/null 2>&1
  ok "SSL cert Xray diperbarui (3650 hari)."; press_enter
}

# =================================================================
#   INFO LENGKAP SERVER (termasuk semua Xray port)
# =================================================================
_show_all_info(){
  local IP=$(get_ip) DOM=$(get_dom)
  echo ""; rb_line
  echo -e "  ${CB}${BOLD}═══ INFO LENGKAP SERVER & PORT ═══${NC}"; rb_line
  echo -e "\n  ${W}━━━ SSH ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  OpenSSH    : ${Y}$IP${NC}:${CB}22${NC} / ${CB}2222${NC}"
  echo -e "  Dropbear   : ${Y}$IP${NC}:${CB}109${NC} / ${CB}143${NC} / ${CB}69${NC}"
  echo -e "  Websocket  : ${Y}$IP${NC}:${CB}80${NC} / ${CB}8880${NC} / ${CB}8008${NC}"
  echo -e "  SSL/Stunnel: ${Y}$IP${NC}:${CB}443${NC} / ${CB}444${NC} / ${CB}554${NC} / ${CB}777${NC}"
  echo -e "\n  ${W}━━━ XRAY — nTLS (Plain, tanpa enkripsi) ━━━━${NC}"
  echo -e "  ${Y}VMess WS nTLS ${NC}: ${Y}$IP${NC}:${CB}8443${NC}  path: /vmess-ntls  net: ws"
  echo -e "  ${Y}VMess TCP nTLS${NC} : ${Y}$IP${NC}:${CB}1194${NC}  net: tcp"
  echo -e "  ${Y}VLess WS nTLS ${NC}: ${Y}$IP${NC}:${CB}8444${NC}  path: /vless-ntls  net: ws"
  echo -e "  ${Y}Trojan nTLS   ${NC}: ${Y}$IP${NC}:${CB}8445${NC}  net: tcp"
  echo -e "\n  ${W}━━━ XRAY — TLS (Terenkripsi self-signed) ━━━${NC}"
  echo -e "  ${GB}VMess WS TLS  ${NC}: ${Y}$IP${NC}:${CB}8553${NC}  path: /vmess-tls  net: ws  tls: on"
  echo -e "  ${GB}VMess TCP TLS ${NC}: ${Y}$IP${NC}:${CB}2083${NC}  net: tcp  tls: on"
  echo -e "  ${GB}VLess WS TLS  ${NC}: ${Y}$IP${NC}:${CB}8554${NC}  path: /vless-tls  net: ws  tls: on"
  echo -e "  ${GB}Trojan TLS    ${NC}: ${Y}$IP${NC}:${CB}8446${NC}  net: tcp  tls: on"
  echo -e "  ${D}(Semua TLS menggunakan self-signed cert — aktifkan allowInsecure di client)${NC}"
  echo -e "\n  ${W}━━━ UDP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  BadVPN     : ${CB}127.0.0.1:7100${NC} / ${CB}7200${NC} / ${CB}7300${NC}"
  local UP=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25525').lstrip(':'))" 2>/dev/null || echo "25525")
  echo -e "  UDP Custom : ${Y}$IP${NC}:${CB}$UP${NC}  (all UDP)"
  local ZP=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5667').lstrip(':'))" 2>/dev/null || echo "5667")
  echo -e "  ZIVPN UDP  : ${Y}$IP${NC}:${CB}$ZP${NC}  (range 5000-9999)  obfs: zivpn"
  echo -e "\n  ${W}━━━ PROXY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  Squid      : ${Y}$IP${NC}:${CB}3128${NC} / ${CB}8080${NC} / ${CB}8000${NC}"
  rb_line
}

# =================================================================
#   SISA FUNGSI (SSH / UDP / Service / dll.)
#   SALIN DARI nexus-panel-v3.sh bagian yang belum ada di sini
# =================================================================

menu_ssh(){
  while true; do
    header; sub_hdr "$CB" "MANAJEMEN AKUN SSH"
    local TOT=$(wc -l < "$USERS_DB" 2>/dev/null || echo 0)
    echo -e "  ${D}Total akun :${NC} ${Y}${TOT}${NC}"; echo ""
    rb_line2
    echo -e "  ${R}[${W}01${R}]${NC} Buat Akun SSH    ${D}│${NC}  ${R}[${W}06${R}]${NC} Ganti Password"
    echo -e "  ${R}[${W}02${R}]${NC} Hapus Akun SSH   ${D}│${NC}  ${R}[${W}07${R}]${NC} Cek User Online"
    echo -e "  ${R}[${W}03${R}]${NC} Daftar Akun SSH  ${D}│${NC}  ${R}[${W}08${R}]${NC} Kick User"
    echo -e "  ${R}[${W}04${R}]${NC} Info Akun SSH    ${D}│${NC}  ${R}[${W}09${R}]${NC} Lock Akun"
    echo -e "  ${R}[${W}05${R}]${NC} Perpanjang Akun  ${D}│${NC}  ${R}[${W}10${R}]${NC} Unlock Akun"
    rb_line2; echo -e "  ${R}[${W}00${R}]${NC} Kembali"; rb_line2; echo ""
    read -rp "$(echo -e "  ${CB}Pilih [00-10] : ${NC}")" CH
    case "$CH" in
      01|1) _ssh_buat ;;   02|2) _ssh_hapus ;;  03|3) _ssh_daftar ;;
      04|4) _ssh_info ;;   05|5) _ssh_panjang ;; 06|6) _ssh_pass ;;
      07|7) _ssh_online ;; 08|8) _ssh_kick ;;   09|9) _ssh_lock ;;
      10)   _ssh_unlock ;; 00|0) return ;;
      *) warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

_ssh_buat(){
  header; sub_hdr "$GB" "BUAT AKUN SSH"
  read -rp "$(echo -e "  ${CB}Username      : ${NC}")" USR
  read -rsp "$(echo -e "  ${CB}Password      : ${NC}")" PASS; echo ""
  read -rp "$(echo -e "  ${CB}Expired (hari): ${NC}")" DAYS
  read -rp "$(echo -e "  ${CB}Limit IP (0=∞): ${NC}")" LIM
  [[ -z "$USR" || -z "$PASS" || -z "$DAYS" ]] && err "Kolom wajib!" && press_enter && return
  id "$USR" &>/dev/null && err "Username ada!" && press_enter && return
  local EXP=$(date -d "+${DAYS} days" +"%Y-%m-%d")
  useradd -e "$EXP" -s /bin/false -M "$USR" 2>/dev/null
  echo "$USR:$PASS" | chpasswd
  echo "$USR|$PASS|$EXP|$(date +%Y-%m-%d)|${LIM:-0}" >> "$USERS_DB"
  log "Buat SSH: $USR"
  local IP=$(get_ip)
  echo ""; rb_line; ok "Akun SSH dibuat!"; rb_line
  echo -e "  ${D}Username :${NC} ${Y}$USR${NC}  ${D}Password :${NC} ${Y}$PASS${NC}"
  echo -e "  ${D}Expired  :${NC} ${Y}$EXP${NC}"
  rb_line; press_enter
}

_ssh_hapus(){
  header; sub_hdr "$R" "HAPUS AKUN SSH"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CB}Username : ${NC}")" USR
  ! id "$USR" &>/dev/null && err "Tidak ada!" && press_enter && return
  pkill -u "$USR" 2>/dev/null; userdel -r "$USR" 2>/dev/null
  sed -i "/^$USR|/d" "$USERS_DB"; ok "$USR dihapus."; press_enter
}

_ssh_daftar(){
  header; sub_hdr "$CB" "DAFTAR AKUN SSH"
  printf "  ${Y}%-16s %-12s %-12s %s${NC}\n" "USERNAME" "EXPIRED" "DIBUAT" "STATUS"; rb_line2
  [[ ! -s "$USERS_DB" ]] && echo -e "  ${D}(kosong)${NC}" || {
    local TODAY=$(date +%Y-%m-%d)
    while IFS='|' read -r u p exp cr lim; do
      local SISA ST
      [[ "$exp" < "$TODAY" ]] && ST="${R}EXPIRED${NC}" && SISA=0 || {
        SISA=$(( ($(date -d "$exp" +%s)-$(date +%s))/86400 )); ST="${GB}AKTIF${NC}"; }
      printf "  ${W}%-16s${NC} ${Y}%-12s${NC} ${D}%-12s${NC} %b ${D}(${SISA}h)${NC}\n" "$u" "$exp" "${cr:-?}" "$ST"
    done < "$USERS_DB"; }
  rb_line2; press_enter
}

_ssh_info(){
  header; sub_hdr "$CB" "INFO AKUN SSH"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CB}Username : ${NC}")" USR
  ! id "$USR" &>/dev/null && err "Tidak ada!" && press_enter && return
  local LINE=$(grep "^$USR|" "$USERS_DB")
  IFS='|' read -r u p exp cr lim <<< "$LINE"
  local SISA=$(( ($(date -d "$exp" +%s)-$(date +%s))/86400 ))
  echo ""; rb_line
  echo -e "  ${D}Password :${NC} ${Y}$p${NC}  Exp: ${Y}$exp${NC}  Sisa: ${Y}${SISA}h${NC}"
  rb_line; press_enter
}

_ssh_panjang(){
  header; sub_hdr "$GB" "PERPANJANG AKUN"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CB}Username : ${NC}")" USR
  read -rp "$(echo -e "  ${CB}Tambah (hari) : ${NC}")" DAYS
  ! id "$USR" &>/dev/null && err "Tidak ada!" && press_enter && return
  local NE=$(date -d "+${DAYS} days" +"%Y-%m-%d")
  chage -E "$NE" "$USR" 2>/dev/null
  sed -i "s/^$USR|\([^|]*\)|\([^|]*\)|/$USR|\1|$NE|/" "$USERS_DB"
  ok "Diperpanjang → $NE"; press_enter
}

_ssh_pass(){
  header; sub_hdr "$Y" "GANTI PASSWORD"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CB}Username : ${NC}")" USR
  read -rsp "$(echo -e "  ${CB}Password baru : ${NC}")" NP; echo ""
  ! id "$USR" &>/dev/null && err "Tidak ada!" && press_enter && return
  echo "$USR:$NP" | chpasswd
  sed -i "s/^$USR|[^|]*|/$USR|$NP|/" "$USERS_DB"
  ok "Password $USR diubah."; press_enter
}

_ssh_online(){
  header; sub_hdr "$MB" "USER ONLINE"
  printf "  ${Y}%-16s %-12s %-20s %s${NC}\n" "USER" "TERMINAL" "WAKTU" "IP"; rb_line2
  who | while read u t d1 d2 rest; do
    printf "  ${W}%-16s${NC} ${C}%-12s${NC} ${D}%-20s${NC} ${G}%s${NC}\n" \
      "$u" "$t" "$d1 $d2" "$(echo "$rest"|tr -d '()')"
  done; rb_line2; press_enter
}

_ssh_kick(){
  header; sub_hdr "$R" "KICK USER"; _ssh_online; echo ""
  read -rp "$(echo -e "  ${CB}Username : ${NC}")" USR
  pkill -u "$USR" && ok "$USR diputuskan." || warn "Tidak ada sesi."; press_enter
}

_ssh_lock(){
  header; sub_hdr "$R" "LOCK AKUN"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CB}Username : ${NC}")" USR
  usermod -e 1 "$USR" 2>/dev/null; ok "$USR di-LOCK."; press_enter
}

_ssh_unlock(){
  header; sub_hdr "$GB" "UNLOCK AKUN"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CB}Username : ${NC}")" USR
  local EXP=$(grep "^$USR|" "$USERS_DB" | cut -d'|' -f3)
  usermod -e "$EXP" "$USR" 2>/dev/null; ok "$USR di-UNLOCK."; press_enter
}

_ssh_list_s(){
  echo -e "  ${Y}Akun:${NC}"
  [[ -s "$USERS_DB" ]] && while IFS='|' read -r u p exp _; do
    echo -e "  ${D}•${NC} ${W}$u${NC} ${D}exp:${NC} ${C}$exp${NC}"; done < "$USERS_DB" || echo -e "  ${D}(kosong)${NC}"
}

# ── UDP Custom (compact) ──────────────────────────────────────
menu_udpc(){
  while true; do
    header; sub_hdr "$O" "MANAJEMEN UDP CUSTOM"
    local UPORT=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25525').lstrip(':'))" 2>/dev/null||echo "25525")
    echo -e "  ${D}Status:${NC} $(svc_stat udp-custom)  ${D}Port:${NC} ${Y}$UPORT${NC}"; echo ""; rb_line2
    echo -e "  ${R}[1]${NC} Buat  ${R}[2]${NC} Hapus  ${R}[3]${NC} Daftar  ${R}[4]${NC} Info  ${R}[5]${NC} Ganti Port  ${R}[0]${NC} Kembali"
    rb_line2; echo ""
    read -rp "$(echo -e "  ${CB}Pilih : ${NC}")" CH
    case "$CH" in
      1) _udpc_buat ;;  2) _udpc_hapus ;; 3) _udpc_daftar ;;
      4) _udpc_info ;;  5) _udpc_port ;;  0) return ;;
    esac
  done
}

_udpc_buat(){
  read -rp "$(echo -e "  ${CB}Password : ${NC}")" PASS
  read -rp "$(echo -e "  ${CB}Expired (hari) : ${NC}")" DAYS
  python3 -c "
import json
with open('/etc/udp-custom/config.json','r') as f: d=json.load(f)
if 'auth' not in d: d['auth']={'mode':'passwords','config':[]}
if '$PASS' not in d['auth']['config']: d['auth']['config'].append('$PASS')
with open('/etc/udp-custom/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")
  echo "$PASS|$EXP|$(date +%Y-%m-%d)" >> "$UDPC_DB"
  systemctl restart udp-custom > /dev/null 2>&1
  ok "Akun UDP Custom: ${Y}$PASS${NC} exp: ${Y}$EXP${NC}"; press_enter
}

_udpc_hapus(){
  _udpc_list_s; echo ""
  read -rp "$(echo -e "  ${CB}Password : ${NC}")" PASS
  python3 -c "
import json
with open('/etc/udp-custom/config.json','r') as f: d=json.load(f)
d['auth']['config']=[p for p in d['auth']['config'] if p!='$PASS']
with open('/etc/udp-custom/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  sed -i "/^$PASS|/d" "$UDPC_DB"
  systemctl restart udp-custom > /dev/null 2>&1; ok "$PASS dihapus."; press_enter
}

_udpc_daftar(){
  header; sub_hdr "$CB" "DAFTAR UDP CUSTOM"
  local i=1
  python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));[print(p) for p in d['auth']['config']]" 2>/dev/null | while read P; do
    local E=$(grep "^$P|" "$UDPC_DB" | cut -d'|' -f2||echo "-")
    printf "  ${W}%-3s${NC} ${C}%-22s${NC} ${Y}%s${NC}\n" "$i." "$P" "$E"; ((i++))
  done; press_enter
}

_udpc_info(){
  local IP=$(get_ip)
  local PORT=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25525').lstrip(':'))" 2>/dev/null)
  local PASS=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(', '.join(d['auth']['config']))" 2>/dev/null)
  echo ""; rb_line
  echo -e "  ${O}UDP CUSTOM${NC}: ${Y}$IP:$PORT${NC}  Pass: ${Y}$PASS${NC}  Range: all UDP"
  rb_line; press_enter
}

_udpc_port(){
  local OLD=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25525').lstrip(':'))" 2>/dev/null)
  read -rp "$(echo -e "  ${CB}Port baru (sekarang: $OLD): ${NC}")" NEW
  python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));d['listen']=f':$NEW';json.dump(d,open('/etc/udp-custom/config.json','w'),indent=2)" 2>/dev/null
  IFACE=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)
  iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 1:65535 -j DNAT --to-destination :"$OLD" 2>/dev/null
  iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 1:65535 -j DNAT --to-destination :"$NEW" 2>/dev/null
  systemctl restart udp-custom > /dev/null 2>&1; ok "Port → $NEW"; press_enter
}

_udpc_list_s(){
  python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));[print(f'  • {p}') for p in d['auth']['config']]" 2>/dev/null
}

# ── ZIVPN (compact) ──────────────────────────────────────────
menu_zivpn(){
  while true; do
    header; sub_hdr "$MB" "MANAJEMEN ZIVPN UDP"
    local ZPORT=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5667').lstrip(':'))" 2>/dev/null||echo "5667")
    echo -e "  ${D}Status:${NC} $(svc_stat zivpn)  ${D}Port:${NC} ${Y}$ZPORT${NC}"; echo ""; rb_line2
    echo -e "  ${M}[1]${NC} Buat  ${M}[2]${NC} Hapus  ${M}[3]${NC} Daftar  ${M}[4]${NC} Info  ${M}[5]${NC} Ganti Port  ${M}[0]${NC} Kembali"
    rb_line2; echo ""
    read -rp "$(echo -e "  ${MB}Pilih : ${NC}")" CH
    case "$CH" in
      1) _zivpn_buat ;; 2) _zivpn_hapus ;; 3) _zivpn_daftar ;;
      4) _zivpn_info ;; 5) _zivpn_port ;;  0) return ;;
    esac
  done
}

_zivpn_buat(){
  read -rp "$(echo -e "  ${MB}Password : ${NC}")" PASS
  read -rp "$(echo -e "  ${MB}Expired (hari) : ${NC}")" DAYS
  python3 -c "
import json
with open('/etc/zivpn/config.json','r') as f: d=json.load(f)
if '$PASS' not in d['auth']['config']: d['auth']['config'].append('$PASS')
with open('/etc/zivpn/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")
  echo "$PASS|$EXP|$(date +%Y-%m-%d)" >> "$ZIVPN_DB"
  systemctl restart zivpn > /dev/null 2>&1; ok "ZIVPN: ${Y}$PASS${NC} exp: ${Y}$EXP${NC}"; press_enter
}

_zivpn_hapus(){
  _zivpn_list_s; echo ""
  read -rp "$(echo -e "  ${MB}Password : ${NC}")" PASS
  python3 -c "
import json
with open('/etc/zivpn/config.json','r') as f: d=json.load(f)
d['auth']['config']=[p for p in d['auth']['config'] if p!='$PASS']
with open('/etc/zivpn/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  sed -i "/^$PASS|/d" "$ZIVPN_DB"; systemctl restart zivpn > /dev/null 2>&1
  ok "$PASS dihapus."; press_enter
}

_zivpn_daftar(){
  header; sub_hdr "$MB" "DAFTAR ZIVPN"
  local i=1
  python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));[print(p) for p in d['auth']['config']]" 2>/dev/null | while read P; do
    local E=$(grep "^$P|" "$ZIVPN_DB"|cut -d'|' -f2||echo "-")
    printf "  ${W}%-3s${NC} ${M}%-22s${NC} ${Y}%s${NC}\n" "$i." "$P" "$E"; ((i++))
  done; press_enter
}

_zivpn_info(){
  local IP=$(get_ip)
  local PORT=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5667').lstrip(':'))" 2>/dev/null)
  local PASS=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(', '.join(d['auth']['config']))" 2>/dev/null)
  echo ""; rb_line
  echo -e "  ${MB}ZIVPN${NC}: ${Y}$IP:$PORT${NC}  Pass: ${Y}$PASS${NC}  Obfs: zivpn"
  echo -e "  Range: 5000-9999 → $PORT"
  rb_line; press_enter
}

_zivpn_port(){
  local OLD=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5667').lstrip(':'))" 2>/dev/null)
  read -rp "$(echo -e "  ${MB}Port baru (sekarang: $OLD): ${NC}")" NEW
  python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));d['listen']=f':$NEW';json.dump(d,open('/etc/zivpn/config.json','w'),indent=2)" 2>/dev/null
  IFACE=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)
  iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 5000:9999 -j DNAT --to-destination :"$OLD" 2>/dev/null
  iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 5000:9999 -j DNAT --to-destination :"$NEW" 2>/dev/null
  systemctl restart zivpn > /dev/null 2>&1; ok "Port → $NEW"; press_enter
}

_zivpn_list_s(){
  python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));[print(f'  • {p}') for p in d['auth']['config']]" 2>/dev/null
}

# ── Service / Monitor / Speedtest / Log / Setting (compact) ───
menu_service(){
  while true; do
    header; sub_hdr "$CB" "KELOLA SERVICE"; echo ""
    for SVC in ssh dropbear ws-ssh-80 ws-ssh-8880 stunnel4 badvpn-7100 badvpn-7300 udp-custom zivpn xray squid nginx; do
      printf "  %-30s %b\n" "$SVC" "$(svc_stat $SVC)"
    done; echo ""; rb_line2
    echo -e "  ${R}[1]${NC} Restart Semua  ${R}[2]${NC} Restart SSH  ${R}[3]${NC} Restart UDP  ${R}[4]${NC} Restart Xray  ${R}[0]${NC} Kembali"
    rb_line2; echo ""
    read -rp "$(echo -e "  ${CB}Pilih : ${NC}")" CH
    case "$CH" in
      1) for S in ssh dropbear ws-ssh-80 ws-ssh-8880 ws-ssh-8008 stunnel4 \
           badvpn-7100 badvpn-7200 badvpn-7300 udp-custom zivpn xray squid nginx; do
           systemctl restart "$S" > /dev/null 2>&1; done; ok "Semua di-restart."; sleep 1 ;;
      2) systemctl restart ssh dropbear ws-ssh-80 ws-ssh-8880 stunnel4 > /dev/null 2>&1; ok "SSH."; sleep 1 ;;
      3) systemctl restart badvpn-7100 badvpn-7200 badvpn-7300 udp-custom zivpn > /dev/null 2>&1; ok "UDP."; sleep 1 ;;
      4) systemctl restart xray > /dev/null 2>&1; ok "Xray."; sleep 1 ;;
      0) return ;;
    esac
  done
}

menu_speedtest(){
  header; sub_hdr "$GB" "SPEEDTEST VPS"; echo ""
  echo -e "  ${R}[1]${NC} speedtest-cli  ${R}[2]${NC} Ookla  ${R}[3]${NC} Download test  ${R}[0]${NC} Kembali"
  rb_line2; echo ""
  read -rp "$(echo -e "  ${GB}Pilih : ${NC}")" CH
  case "$CH" in
    1) command -v speedtest-cli &>/dev/null && speedtest-cli --simple || \
         (pip3 install speedtest-cli -q && speedtest-cli --simple) ;;
    2) command -v speedtest &>/dev/null && speedtest || warn "Ookla belum install." ;;
    3) wget -O /dev/null --progress=dot:mega http://speedtest.tele2.net/100MB.zip 2>&1 | \
         grep -Eo '[0-9]+(\.[0-9]+)? [KMG]B/s' | tail -1 | \
         xargs -I{} echo -e "  ${GB}Kecepatan: {}${NC}" ;;
    0) return ;;
  esac; press_enter
}

menu_monitor(){
  header; sub_hdr "$C" "MONITORING SERVER"
  local IP=$(get_ip) IFACE=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)
  echo -e "  ${D}OS:${NC} $(lsb_release -ds 2>/dev/null|tr -d '"')  Kernel: $(uname -r)"
  echo -e "  ${D}Uptime:${NC} $(uptime -p)"
  echo -e "  ${D}CPU:${NC} ${Y}$(top -bn1|grep 'Cpu(s)'|awk '{printf "%.1f",$2+$4}')%${NC}  RAM: ${Y}$(free -h|awk '/^Mem:/{print $3"/"$2}')${NC}"
  echo -e "  ${D}IP:${NC} ${Y}$IP${NC}  Koneksi: ${Y}$(ss -tnp 2>/dev/null|grep -c ESTAB)${NC}"
  echo ""; echo -e "  ${CB}Status Port:${NC}"
  for P in 22 80 443 8443 8444 8445 8446 8553 8554 1194 2083 25525 5667; do
    ss -tlnp 2>/dev/null | grep -q ":$P " && \
      printf "  ${Y}%-6s${NC}:${GB}OPEN${NC}  " "$P" || printf "  ${Y}%-6s${NC}:${R}CLOS${NC}  " "$P"
  done; echo ""
  rb_line2; press_enter
}

menu_log(){
  while true; do
    header; sub_hdr "$D" "LOG & RIWAYAT"; echo ""
    echo -e "  ${R}[1]${NC} Log Panel  ${R}[2]${NC} Log SSH  ${R}[3]${NC} Log Xray  ${R}[4]${NC} Log ZIVPN  ${R}[5]${NC} Realtime  ${R}[0]${NC} Kembali"
    rb_line2; echo ""
    read -rp "$(echo -e "  ${CB}Pilih : ${NC}")" CH
    case "$CH" in
      1) tail -50 "$LOG_FILE" 2>/dev/null; press_enter ;;
      2) journalctl -u ssh -n 80 --no-pager; press_enter ;;
      3) tail -50 /var/log/xray/access.log 2>/dev/null; journalctl -u xray -n 30 --no-pager; press_enter ;;
      4) journalctl -u zivpn -n 50 --no-pager; press_enter ;;
      5) warn "Ctrl+C keluar"; sleep 1; journalctl -f -u ssh -u xray -u zivpn -u udp-custom ;;
      0) return ;;
    esac
  done
}

menu_setting(){
  while true; do
    header; sub_hdr "$Y" "PENGATURAN PANEL"; echo ""
    echo -e "  ${R}[1]${NC} Pilih Tema    ${R}[2]${NC} Port SSH      ${R}[3]${NC} Port Dropbear"
    echo -e "  ${R}[4]${NC} Renew SSL     ${R}[5]${NC} Setup Domain  ${R}[6]${NC} Auto-Reboot"
    echo -e "  ${R}[7]${NC} Auto-Kill     ${R}[8]${NC} Backup        ${R}[9]${NC} Restore"
    echo -e "  ${R}[0]${NC} Kembali"; rb_line2; echo ""
    read -rp "$(echo -e "  ${Y}Pilih : ${NC}")" CH
    case "$CH" in
      1) menu_tema ;;
      2) read -rp "  Port SSH baru: " P; sed -i "s/^Port [0-9]*/Port $P/" /etc/ssh/sshd_config
         systemctl restart ssh > /dev/null 2>&1; ok "Port SSH → $P"; press_enter ;;
      3) read -rp "  Port Dropbear baru: " P; sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=$P/" /etc/default/dropbear
         systemctl restart dropbear > /dev/null 2>&1; ok "Port Dropbear → $P"; press_enter ;;
      4) openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
           -subj "/C=US/ST=CA/L=LA/O=Nexus/CN=nexus" \
           -keyout /etc/stunnel/stunnel.key -out /etc/stunnel/stunnel.crt > /dev/null 2>&1
         cat /etc/stunnel/stunnel.crt /etc/stunnel/stunnel.key > /etc/stunnel/stunnel.pem
         systemctl restart stunnel4 > /dev/null 2>&1; ok "SSL Stunnel diperbarui."; press_enter ;;
      5) read -rp "  Domain: " D; [[ -n "$D" ]] && echo "$D" > "$DOMAIN_FILE"; ok "Domain: $D"; press_enter ;;
      6) read -rp "  Jam reboot (00-23): " H
         (crontab -l 2>/dev/null|grep -v nexus-reboot; echo "0 $H * * * /sbin/reboot # nexus-reboot")|crontab -
         ok "Auto-reboot jam $H:00"; press_enter ;;
      7) read -rp "  Max login/user: " MAX
         printf '#!/bin/bash\nMAX=%s\nwho|awk '"'"'{print $1}'"'"'|sort|uniq -c|while read C U; do\n  [[ $C -gt $MAX ]] && pkill -u "$U" -9 2>/dev/null\ndone\n' "$MAX" > /usr/local/bin/nexus-autokill.sh
         chmod +x /usr/local/bin/nexus-autokill.sh
         (crontab -l 2>/dev/null|grep -v nexus-autokill; echo "*/1 * * * * /usr/local/bin/nexus-autokill.sh")|crontab -
         ok "Auto-kill aktif (max $MAX)"; press_enter ;;
      8) local BK="$PANEL_DIR/backup/bk_$(date +%Y%m%d_%H%M%S).tar.gz"
         tar -czf "$BK" /etc/ssh/sshd_config /etc/default/dropbear \
           /etc/udp-custom/config.json /etc/zivpn/config.json "$XRAY_CFG" \
           "$USERS_DB" "$UDPC_DB" "$ZIVPN_DB" "$XRAY_DB" 2>/dev/null
         ok "Backup: $BK"; press_enter ;;
      9) ls "$PANEL_DIR/backup/"*.tar.gz 2>/dev/null||{err "Tidak ada.";press_enter;continue;}
         read -rp "  Path: " BK; [[ ! -f "$BK" ]] && err "Tidak ditemukan!" && press_enter && continue
         tar -xzf "$BK" -C / > /dev/null 2>&1
         for S in ssh dropbear stunnel4 udp-custom zivpn xray; do systemctl restart "$S" > /dev/null 2>&1; done
         ok "Restore selesai."; press_enter ;;
      0) return ;;
    esac
  done
}

menu_tema(){
  header; sub_hdr "$MB" "PILIH TEMA WARNA"; echo ""
  echo -e "  ${R}[1]${NC} ${R}■${O}■${Y}■${GB}■${CB}■${B}■${MB}■${NC} Rainbow   ${R}[6]${NC} ${MB}■${NC} Magenta"
  echo -e "  ${R}[2]${NC} ${R}■${NC} Merah     ${R}[7]${NC} ${CB}■${NC} Cyan"
  echo -e "  ${R}[3]${NC} ${GB}■${NC} Hijau     ${R}[8]${NC} ${D}■${NC} Gelap"
  echo -e "  ${R}[4]${NC} ${CB}■${NC} Biru      ${R}[9]${NC} ${GB}■${Y}■${CB}■${NC} Neon"
  echo -e "  ${R}[5]${NC} ${Y}■${NC} Kuning    ${R}[10]${NC} ${M}■${MB}■${B}■${NC} Ungu"
  echo -e "  ${R}[0]${NC} Kembali"; echo ""
  read -rp "$(echo -e "  ${MB}Tema : ${NC}")" TM
  local TS=("" "rainbow" "merah" "hijau" "biru" "kuning" "magenta" "cyan" "gelap" "neon" "ungu")
  [[ "$TM" -ge 1 && "$TM" -le 10 ]] && echo "${TS[$TM]}" > "$THEME_FILE" && ok "Tema ${TS[$TM]} aktif!"
  press_enter
}

_info_bin(){
  header; sub_hdr "$W" "SUMBER BINARY (BIN)"; echo ""
  echo -e "  ${CB}━━ XRAY-CORE ${XRAY_VER} — VMess/VLess/Trojan TLS & nTLS ━━${NC}"
  echo -e "  ${D}Repo   :${NC} ${Y}github.com/XTLS/Xray-core${NC}"
  echo -e "  ${D}AMD64  :${NC} ${W}$XRAY_ZIP_AMD64${NC}"
  echo -e "  ${D}ARM64  :${NC} ${W}$XRAY_ZIP_ARM64${NC}"
  echo -e "  ${D}Install:${NC} ${W}$XRAY_INSTALL_URL${NC}"
  echo ""
  echo -e "  ${CB}━━ UDP CUSTOM ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${D}Repo   :${NC} ${Y}github.com/feely666/udp-custom${NC}"
  echo -e "  ${D}AMD64  :${NC} ${W}$UDPC_BIN_AMD64${NC}"
  echo ""
  echo -e "  ${CB}━━ ZIVPN UDP v1.4.9 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${D}Repo   :${NC} ${Y}github.com/zahidbd2/udp-zivpn${NC}"
  echo -e "  ${D}AMD64  :${NC} ${W}$ZIVPN_AMD64${NC}"
  echo -e "  ${D}ARM64  :${NC} ${W}$ZIVPN_ARM64${NC}"
  echo ""
  echo -e "  ${CB}━━ BADVPN UDPGW ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${D}Repo   :${NC} ${Y}github.com/idtunnel/UDPGW-SSH${NC}"
  echo -e "  ${D}AMD64  :${NC} ${W}$BADVPN_AMD64${NC}"
  rb_line; press_enter
}

# =================================================================
#   MAIN MENU v3.1
# =================================================================
main_menu(){
  check_root
  mkdir -p "$PANEL_DIR/backup" "$XRAY_DIR"
  touch "$USERS_DB" "$UDPC_DB" "$ZIVPN_DB" "$XRAY_DB" "$LOG_FILE" "$THEME_FILE" 2>/dev/null
  [[ ! -s "$THEME_FILE" ]] && echo "rainbow" > "$THEME_FILE"

  while true; do
    header
    printf "  ${D}%-22s${NC}%b  ${D}%-22s${NC}%b\n" "SSH/Dropbear"  "$(svc_stat ssh)"       "UDP Custom"   "$(svc_stat udp-custom)"
    printf "  ${D}%-22s${NC}%b  ${D}%-22s${NC}%b\n" "Websocket(80)" "$(svc_stat ws-ssh-80)" "ZIVPN UDP"    "$(svc_stat zivpn)"
    printf "  ${D}%-22s${NC}%b  ${D}%-22s${NC}%b\n" "Stunnel4 SSL"  "$(svc_stat stunnel4)"  "Xray (V2Ray)" "$(svc_stat xray)"
    echo ""; rb_line

    echo -e "  ${R}[${W}1${R}]${NC} ${W}Manajemen SSH${NC}               ${D}│${NC}  ${M}[${W}7${M}]${NC} ${W}Monitor Server${NC}"
    echo -e "  ${O}[${W}2${O}]${NC} ${W}Manajemen UDP Custom${NC}        ${D}│${NC}  ${GB}[${W}8${GB}]${NC} ${W}Info Server & Port${NC}"
    echo -e "  ${M}[${W}3${M}]${NC} ${W}Manajemen ZIVPN UDP${NC}         ${D}│${NC}  ${B}[${W}9${B}]${NC} ${W}Log & Riwayat${NC}"
    echo -e "  ${Y}[${W}4${Y}]${NC} ${W}Manajemen Xray${NC}              ${D}│${NC}  ${Y}[${W}10${Y}]${NC} ${W}Pengaturan + Tema${NC}"
    echo -e "  ${D}    ${NC}${W}└─ VMess/VLess/Trojan TLS+nTLS${NC} ${D}│${NC}  ${R}[${W}11${R}]${NC} ${W}Install Semua Layanan${NC}"
    echo -e "  ${CB}[${W}5${CB}]${NC} ${W}Kelola Service${NC}              ${D}│${NC}  ${D}[${W}12${D}]${NC} ${W}Info Sumber Bin${NC}"
    echo -e "  ${GB}[${W}6${GB}]${NC} ${W}Speedtest VPS${NC}"
    rb_line
    echo -e "  ${D}[${W}0${D}]${NC} ${W}Keluar${NC}"
    rb_line; echo ""
    read -rp "$(echo -e "  $(rainbow 'Pilih Menu') ${R}[${W}0-12${R}]${NC} : ")" MENU

    case "$MENU" in
      1)  menu_ssh ;;
      2)  menu_udpc ;;
      3)  menu_zivpn ;;
      4)  menu_xray ;;
      5)  menu_service ;;
      6)  menu_speedtest ;;
      7)  menu_monitor ;;
      8)  header; _show_all_info; press_enter ;;
      9)  menu_log ;;
      10) menu_setting ;;
      11) echo -e "\n  ${Y}Jalankan install dari menu ini membutuhkan fungsi do_install.${NC}"
          echo -e "  ${Y}Pastikan menggunakan nexus-panel-v3.sh full atau copy fungsi do_install.${NC}"
          press_enter ;;
      12) _info_bin ;;
      0)  header; echo -e "  $(rainbow 'Terima kasih! Nexus Panel v3.1')"; echo ""; exit 0 ;;
      *)  err "Pilihan tidak valid!"; sleep 1 ;;
    esac
  done
}

main_menu
