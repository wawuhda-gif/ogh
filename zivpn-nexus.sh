#!/bin/bash
# Zivpn UDP Module installer
# Creator Zahid Islam
echo -e "Updating server"
sudo apt-get update && apt-get upgrade -y
systemctl stop zivpn.service 1> /dev/null 2> /dev/null
echo -e "Downloading UDP Service"
wget https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn 1> /dev/null 2> /dev/null
chmod +x /usr/local/bin/zivpn
mkdir /etc/zivpn 1> /dev/null 2> /dev/null
wget https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/config.json -O /etc/zivpn/config.json 1> /dev/null 2> /dev/null
echo "Generating cert files:"
sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"
sudo sysctl -w net.core.rmem_max=16777216 > /dev/null
sudo sysctl -w net.core.wmem_max=16777216 > /dev/null
sudo bash -c 'cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=zivpn VPN Server
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn-bin server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
EOF'
# Buat file database pengguna awal, file tema, dan file domain
sudo bash -c 'echo "[]" > /etc/zivpn/users.db.json'
sudo bash -c 'echo "rainbow" > /etc/zivpn/theme.conf'
sudo bash -c "echo \"$user_domain\" > /etc/zivpn/domain.conf"
# Bersihin iptables rules yang lama
INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
while sudo iptables -t nat -D PREROUTING -i $INTERFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null; do :; done
sudo iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667
sudo iptables -A FORWARD -p udp -d 127.0.0.1 --dport 5667 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 127.0.0.1/32 -o $INTERFACE -j MASQUERADE
sudo apt install iptables-persistent -y -qq
sudo netfilter-persistent save > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable zivpn.service
sudo systemctl start zivpn.service
sudo ufw allow 6000:19999/udp > /dev/null
sudo ufw allow 5667/udp > /dev/null

# ============================================================
#  SETUP MENU PANEL - Dipanggil dengan perintah 'menu'
# ============================================================

MENU_SCRIPT="/usr/local/bin/menu"
SELF="$(readlink -f "$0")"

# Tulis menu script ke /usr/local/bin/menu
sudo tee "$MENU_SCRIPT" > /dev/null << 'MENU_EOF'
#!/bin/bash
# ============================================================
#   NEXUS ZIVPN - Premium Panel
#   Ketik: menu  untuk membuka panel ini
# ============================================================

# ─── PATHS ───────────────────────────────────────────────────
CFG="/etc/zivpn"
USER_DB="$CFG/users.db"
THEME_FILE="$CFG/theme.conf"
DOMAIN_FILE="$CFG/domain.conf"
TG_FILE="$CFG/telegram.conf"
BRAND="NEXUS-ZIV"
VERSION="v2.0"

# ─── WARNA DASAR ─────────────────────────────────────────────
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_MAGENTA='\033[45m'
BG_CYAN='\033[46m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
LCYAN='\033[1;36m'
LMAGENTA='\033[1;35m'
LBLUE='\033[1;34m'

RB=('\033[0;31m' '\033[0;33m' '\033[1;33m' '\033[0;32m' '\033[0;36m' '\033[0;34m' '\033[0;35m')

# ─── LOAD TEMA ───────────────────────────────────────────────
load_theme() {
    CUR_THEME="rainbow"
    [[ -f "$THEME_FILE" ]] && CUR_THEME=$(cat "$THEME_FILE" 2>/dev/null | tr -d '[:space:]')
    case "$CUR_THEME" in
        green)   P1='\033[0;32m';  P2='\033[1;32m';  P3='\033[0;32m'  ;;
        blue)    P1='\033[0;34m';  P2='\033[1;34m';  P3='\033[0;34m'  ;;
        red)     P1='\033[0;31m';  P2='\033[1;31m';  P3='\033[0;31m'  ;;
        yellow)  P1='\033[1;33m';  P2='\033[0;33m';  P3='\033[1;33m'  ;;
        cyan)    P1='\033[0;36m';  P2='\033[1;36m';  P3='\033[0;36m'  ;;
        *)       P1='\033[0;36m';  P2='\033[0;35m';  P3='\033[1;33m'  ;;
    esac
}

# ─── RAINBOW LINE ────────────────────────────────────────────
rb_line() {
    local chars="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local i=0
    for (( c=0; c<${#chars}; c++ )); do
        echo -ne "${RB[$((i%7))]}${chars:$c:1}"
        ((i++))
    done
    echo -e "${NC}"
}

rb_text() {
    local t="$1" i=0
    for (( c=0; c<${#t}; c++ )); do
        echo -ne "${RB[$((i%7))]}${t:$c:1}"
        ((i++))
    done
    echo -ne "${NC}"
}

draw_line() {
    if [[ "$CUR_THEME" == "rainbow" ]]; then rb_line
    else echo -e "${P1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; fi
}

draw_thin() {
    if [[ "$CUR_THEME" == "rainbow" ]]; then
        local chars="─────────────────────────────────────────────────────"
        local i=0
        for (( c=0; c<${#chars}; c++ )); do
            echo -ne "${RB[$((i%7))]}${chars:$c:1}"; ((i++))
        done; echo -e "${NC}"
    else
        echo -e "${DIM}${P1}─────────────────────────────────────────────────────${NC}"
    fi
}

# ─── INFO VPS ────────────────────────────────────────────────
get_info() {
    _HOST=$(hostname 2>/dev/null)
    _OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 | sed 's/ GNU\/Linux//')
    _IP=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    _DOM=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$_IP")
    _PORT="5667"
    _CPU=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{printf "%.1f", $2}')
    _RAM_USED=$(free -m 2>/dev/null | awk '/Mem:/{print $3}')
    _RAM_TOTAL=$(free -m 2>/dev/null | awk '/Mem:/{print $2}')
    _DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
    _DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
    _DATE=$(date '+%H:%M  %d/%m/%Y')
    _AKUN=$(wc -l < "$USER_DB" 2>/dev/null || echo "0")
    _EXP=0
    TODAY=$(date +%Y%m%d)
    while IFS=':' read -r U E P; do
        [[ -z "$U" ]] && continue
        [[ "$TODAY" -gt "$E" ]] && ((_EXP++))
    done < "$USER_DB" 2>/dev/null
    _TG_STATUS="0"
    [[ -f "$TG_FILE" ]] && [[ -n "$(grep '^TOKEN=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)" ]] && _TG_STATUS="1"
    _TEMA=$(cat "$THEME_FILE" 2>/dev/null | tr '[:lower:]' '[:upper:]' || echo "RAINBOW")
    _SVC_RAW=$(systemctl is-active zivpn 2>/dev/null)
}

svc_dot() {
    systemctl is-active --quiet zivpn 2>/dev/null \
        && echo -e "${LGREEN}● ZiVPN RUNNING${NC}" \
        || echo -e "${LRED}● ZiVPN STOPPED${NC}"
}

# ─── HEADER / LOGO ───────────────────────────────────────────
show_header() {
    clear
    load_theme
    get_info
    echo
    # Logo ASCII OGH-ZIV
    if [[ "$CUR_THEME" == "rainbow" ]]; then
        rb_text '   ___    ____  _   _            ____  ___ _    __'; echo
        rb_text '  / _ \  / ___|| | | |     _    |_  / |_ _| |  / /'; echo
        rb_text ' | | | || |  _ | |_| |   _| |_   / /   | | | / / '; echo
        rb_text ' | |_| || |_| ||  _  |  |_   _| / /_   | | |/ /  '; echo
        rb_text '  \___/  \____||_| |_|    |_|  /____|  |___|_/    '; echo
        echo
        rb_text '  //////////  O G H - Z I V  P R E M I U M  //////////'; echo
    else
        echo -e "${P2}${BOLD}   ___    ____  _   _            ____  ___ _    __${NC}"
        echo -e "${P2}${BOLD}  / _ \\  / ___|| | | |     _    |_  / |_ _| |  / /${NC}"
        echo -e "${P1}${BOLD} | | | || |  _ | |_| |   _| |_   / /   | | | / / ${NC}"
        echo -e "${P1}${BOLD} | |_| || |_| ||  _  |  |_   _| / /_   | | |/ /  ${NC}"
        echo -e "${P2}${BOLD}  \\___/  \\____||_| |_|    |_|  /____|  |___|_/    ${NC}"
        echo
        echo -e "${P3}${BOLD}  //////////  O G H - Z I V  P R E M I U M  //////////${NC}"
    fi
    echo
    # Tag info
    echo -e "  ${DIM}◆${NC} ${LRED}${BOLD}OGH-ZIV Premium${NC}  ${DIM}·${NC}  ${CYAN}fauzanihanipah/ziv-udp${NC}  ${DIM}·${NC}  ${YELLOW}${VERSION}${NC}"
    echo
    draw_line
    # ── INFO VPS BOX ──
    printf "  ${LRED}${BOLD}◆ INFO VPS${NC}%-20s${YELLOW}%s${NC}\n" "" "$_DATE"
    draw_thin
    printf "  ${WHITE}Hostname : ${LCYAN}%-20s${NC}  ${WHITE}OS     : ${LCYAN}%s${NC}\n" "$_HOST" "$_OS"
    printf "  ${WHITE}IP Publik: ${LGREEN}%-20s${NC}  ${WHITE}Domain : ${LGREEN}%s${NC}\n" "$_IP" "$_DOM"
    printf "  ${WHITE}Port VPN : ${YELLOW}%-20s${NC}  ${WHITE}Brand  : ${YELLOW}%s${NC}\n" "$_PORT" "$BRAND"
    draw_thin
    printf "  ${WHITE}CPU: ${LGREEN}%-6s${NC}  ${WHITE}RAM: ${LGREEN}%s/%sMB${NC}  ${WHITE}Disk: ${LGREEN}%s/%s${NC}\n" \
        "${_CPU}%" "$_RAM_USED" "$_RAM_TOTAL" "$_DISK_USED" "$_DISK_TOTAL"
    draw_thin
    # Status bar
    printf "  $(svc_dot)  ${WHITE}Akun: ${LCYAN}%s${NC}  ${WHITE}Exp: ${LRED}%s${NC}  ${WHITE}Bot: ${YELLOW}%s${NC}  ${WHITE}Tema: " \
        "$_AKUN" "$_EXP" "$_TG_STATUS"
    if [[ "$CUR_THEME" == "rainbow" ]]; then rb_text "RAINBOW"; echo -e "${NC}"
    else echo -e "${P2}$(echo "$_TEMA")${NC}"; fi
    draw_line
    echo
}

# ─── TELEGRAM ────────────────────────────────────────────────
tg_send() {
    local MSG="$1"
    [[ ! -f "$TG_FILE" ]] && return
    local TK=$(grep '^TOKEN=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
    local CID=$(grep '^CHATID=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
    [[ -z "$TK" || -z "$CID" ]] && return
    curl -s --max-time 5 \
        "https://api.telegram.org/bot${TK}/sendMessage" \
        -d "chat_id=${CID}&text=${MSG}&parse_mode=Markdown" >/dev/null 2>&1 &
}

# ─── BOX MENU ITEM ───────────────────────────────────────────
menu_item() {
    local NUM="$1" ICON="$2" LABEL="$3"
    if [[ "$CUR_THEME" == "rainbow" ]]; then
        printf "  ${RB[$((NUM%7))]}[%s]${NC}  %s  %-30s${DIM}┃${NC}\n" "$NUM" "$ICON" "$LABEL"
    else
        printf "  ${P2}[%s]${NC}  %s  %-30s${DIM}┃${NC}\n" "$NUM" "$ICON" "$LABEL"
    fi
}

# ═══════════════════════════════════════════════════════════
# MENU: KELOLA AKUN USER
# ═══════════════════════════════════════════════════════════
akun_menu() {
    while true; do
        show_header
        echo -e "  ${LRED}${BOLD}◆ KELOLA AKUN USER${NC}"
        draw_thin; echo
        menu_item 1 "👤" "Tambah Akun"
        menu_item 2 "📋" "List Akun"
        menu_item 3 "🗑 " "Hapus Akun"
        menu_item 4 "🔄" "Perpanjang Akun"
        menu_item 5 "🔍" "Cek Akun"
        menu_item 0 "↩ " "Kembali"
        echo
        draw_thin
        read -rp "  Pilih [0-5] : " OPT
        case $OPT in
            1) akun_tambah ;;
            2) akun_list ;;
            3) akun_hapus ;;
            4) akun_renew ;;
            5) akun_cek ;;
            0) break ;;
        esac
    done
}

akun_tambah() {
    show_header
    echo -e "  ${LGREEN}${BOLD}➕ TAMBAH AKUN UDP ZIVPN${NC}"
    draw_thin; echo
    read -rp "  Username        : " USR
    [[ -z "$USR" ]] && echo -e "  ${RED}✗ Username kosong!${NC}" && sleep 1 && return
    grep -q "^${USR}:" "$USER_DB" 2>/dev/null && echo -e "  ${YELLOW}⚠ Username sudah ada!${NC}" && sleep 1 && return
    read -rp "  Password        : " PW
    [[ -z "$PW" ]] && echo -e "  ${RED}✗ Password kosong!${NC}" && sleep 1 && return
    read -rp "  Masa aktif (hari) [30] : " DAYS; DAYS=${DAYS:-30}
    EXP=$(date -d "+${DAYS} days" +%Y%m%d 2>/dev/null)
    EXP_FMT=$(date -d "$EXP" '+%d-%m-%Y' 2>/dev/null || echo "$EXP")
    echo "${USR}:${EXP}:${PW}" >> "$USER_DB"
    DOM=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$(curl -s --max-time 3 ifconfig.me)")
    echo
    draw_line
    echo -e "  ${LGREEN}${BOLD}✓ AKUN BERHASIL DIBUAT${NC}"
    draw_thin
    printf "  ${WHITE}%-12s${NC}: ${LCYAN}%s${NC}\n" "Username" "$USR"
    printf "  ${WHITE}%-12s${NC}: ${LCYAN}%s${NC}\n" "Password" "$PW"
    printf "  ${WHITE}%-12s${NC}: ${YELLOW}%s${NC}\n"  "Expired"  "$EXP_FMT"
    printf "  ${WHITE}%-12s${NC}: ${LGREEN}%s${NC}\n" "Host"     "$DOM"
    printf "  ${WHITE}%-12s${NC}: ${LGREEN}%s${NC}\n" "Port"     "5667"
    draw_line; echo
    tg_send "➕ *AKUN BARU*%0AUser: \`$USR\` | Pass: \`$PW\`%0AExp: $EXP_FMT | Host: $DOM:5667"
    read -rp "  Tekan ENTER..." _
}

akun_list() {
    show_header
    echo -e "  ${LCYAN}${BOLD}📋 DAFTAR AKUN${NC}"
    draw_thin
    printf "  ${YELLOW}%-4s %-18s %-12s %-10s${NC}\n" "NO" "USERNAME" "EXPIRED" "STATUS"
    draw_thin
    TODAY=$(date +%Y%m%d); N=0
    while IFS=':' read -r U E P; do
        [[ -z "$U" ]] && continue; ((N++))
        EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
        DL=$(( ( $(date -d "$E" +%s 2>/dev/null || echo 0) - $(date +%s) ) / 86400 ))
        [[ "$TODAY" -le "$E" ]] && ST="${LGREEN}Aktif(${DL}h)${NC}" || ST="${LRED}Expired${NC}"
        printf "  %-4s %-18s %-12s " "$N" "$U" "$EF"
        echo -e "$ST"
    done < "$USER_DB" 2>/dev/null
    draw_thin
    echo -e "  Total: ${LCYAN}${N} akun${NC}"; draw_line; echo
    read -rp "  Tekan ENTER..." _
}

akun_hapus() {
    show_header
    echo -e "  ${LRED}${BOLD}🗑  HAPUS AKUN${NC}"; draw_thin; echo
    while IFS=':' read -r U E P; do
        [[ -z "$U" ]] && continue
        EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
        echo -e "  ${DIM}•${NC} ${WHITE}$U${NC}  ${DIM}(exp: $EF)${NC}"
    done < "$USER_DB" 2>/dev/null
    echo
    read -rp "  Username yang dihapus : " USR; [[ -z "$USR" ]] && return
    if grep -q "^${USR}:" "$USER_DB" 2>/dev/null; then
        sed -i "/^${USR}:/d" "$USER_DB"
        echo -e "  ${LGREEN}✓ Akun $USR dihapus!${NC}"
        tg_send "🗑 *AKUN DIHAPUS*%0AUsername: \`$USR\`"
    else
        echo -e "  ${RED}✗ Akun tidak ditemukan!${NC}"
    fi
    sleep 1
}

akun_renew() {
    show_header
    echo -e "  ${YELLOW}${BOLD}🔄 PERPANJANG AKUN${NC}"; draw_thin; echo
    while IFS=':' read -r U E P; do
        [[ -z "$U" ]] && continue
        EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
        echo -e "  ${DIM}•${NC} ${WHITE}$U${NC}  ${DIM}(exp: $EF)${NC}"
    done < "$USER_DB" 2>/dev/null
    echo
    read -rp "  Username : " USR; [[ -z "$USR" ]] && return
    grep -q "^${USR}:" "$USER_DB" 2>/dev/null || { echo -e "  ${RED}✗ Tidak ditemukan!${NC}"; sleep 1; return; }
    read -rp "  Tambah hari [30] : " DAYS; DAYS=${DAYS:-30}
    OLD=$(grep "^${USR}:" "$USER_DB" | cut -d':' -f2)
    PW=$(grep "^${USR}:" "$USER_DB" | cut -d':' -f3)
    NEW=$(date -d "${OLD}+${DAYS} days" +%Y%m%d 2>/dev/null || echo "$OLD")
    NF=$(date -d "$NEW" '+%d-%m-%Y' 2>/dev/null || echo "$NEW")
    sed -i "s/^${USR}:.*/${USR}:${NEW}:${PW}/" "$USER_DB"
    echo -e "  ${LGREEN}✓ Diperpanjang s/d ${NF}${NC}"
    tg_send "🔄 *AKUN DIPERPANJANG*%0AUser: \`$USR\`%0AExpired: $NF"
    sleep 1
}

akun_cek() {
    show_header
    echo -e "  ${CYAN}${BOLD}🔍 CEK AKUN${NC}"; draw_thin; echo
    read -rp "  Username : " USR; [[ -z "$USR" ]] && return
    if grep -q "^${USR}:" "$USER_DB" 2>/dev/null; then
        E=$(grep "^${USR}:" "$USER_DB" | cut -d':' -f2)
        P=$(grep "^${USR}:" "$USER_DB" | cut -d':' -f3)
        EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
        TODAY=$(date +%Y%m%d)
        DL=$(( ( $(date -d "$E" +%s 2>/dev/null || echo 0) - $(date +%s) ) / 86400 ))
        [[ "$TODAY" -le "$E" ]] && ST="${LGREEN}AKTIF (sisa ${DL} hari)${NC}" || ST="${LRED}EXPIRED${NC}"
        echo
        draw_thin
        printf "  ${WHITE}%-12s${NC}: ${LCYAN}%s${NC}\n" "Username" "$USR"
        printf "  ${WHITE}%-12s${NC}: ${LCYAN}%s${NC}\n" "Password" "$P"
        printf "  ${WHITE}%-12s${NC}: ${YELLOW}%s${NC}\n"  "Expired"  "$EF"
        printf "  ${WHITE}%-12s${NC}: " "Status"; echo -e "$ST"
        draw_thin
    else
        echo -e "  ${RED}✗ Akun tidak ditemukan!${NC}"
    fi
    echo; read -rp "  Tekan ENTER..." _
}

# ═══════════════════════════════════════════════════════════
# MENU: MANAJEMEN SERVICE
# ═══════════════════════════════════════════════════════════
service_menu() {
    while true; do
        show_header
        echo -e "  ${LRED}${BOLD}◆ MANAJEMEN SERVICE${NC}"
        draw_thin
        echo -e "  Status : $(svc_dot)"
        echo
        menu_item 1 "▶ " "Start Service"
        menu_item 2 "⏹ " "Stop Service"
        menu_item 3 "🔄" "Restart Service"
        menu_item 4 "📜" "Lihat Log (30 baris)"
        menu_item 5 "📋" "Status Detail"
        menu_item 0 "↩ " "Kembali"
        echo; draw_thin
        read -rp "  Pilih [0-5] : " OPT
        case $OPT in
            1) sudo systemctl start zivpn   && echo -e "  ${LGREEN}✓ Service distart${NC}"   ;;
            2) sudo systemctl stop zivpn    && echo -e "  ${YELLOW}✓ Service distop${NC}"    ;;
            3) sudo systemctl restart zivpn && echo -e "  ${LGREEN}✓ Service direstart${NC}" ;;
            4) echo; sudo journalctl -u zivpn -n 30 --no-pager 2>/dev/null; echo; read -rp "  ENTER..." _ ;;
            5) echo; sudo systemctl status zivpn; echo; read -rp "  ENTER..." _ ;;
            0) break ;;
        esac
        [[ "$OPT" =~ ^[1-3]$ ]] && sleep 1
    done
}

# ═══════════════════════════════════════════════════════════
# MENU: TELEGRAM BOT
# ═══════════════════════════════════════════════════════════
telegram_menu() {
    while true; do
        show_header
        echo -e "  ${LRED}${BOLD}◆ TELEGRAM BOT${NC}"; draw_thin; echo
        TK=$(grep '^TOKEN=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
        CID=$(grep '^CHATID=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
        printf "  ${WHITE}%-12s${NC}: ${CYAN}%s${NC}\n" "Bot Token" "${TK:-Belum diatur}"
        printf "  ${WHITE}%-12s${NC}: ${CYAN}%s${NC}\n" "Chat ID"   "${CID:-Belum diatur}"
        echo
        menu_item 1 "🔑" "Set Bot Token"
        menu_item 2 "💬" "Set Chat ID"
        menu_item 3 "📡" "Test Koneksi Bot"
        menu_item 4 "📊" "Kirim Laporan VPS"
        menu_item 5 "📋" "Kirim Daftar Akun"
        menu_item 6 "🗑 " "Hapus Konfigurasi"
        menu_item 0 "↩ " "Kembali"
        echo; draw_thin
        read -rp "  Pilih [0-6] : " OPT
        case $OPT in
            1)
                echo; read -rp "  Bot Token : " TKN; [[ -z "$TKN" ]] && continue
                sudo mkdir -p "$CFG"
                grep -q '^TOKEN=' "$TG_FILE" 2>/dev/null \
                    && sudo sed -i "s|^TOKEN=.*|TOKEN=$TKN|" "$TG_FILE" \
                    || echo "TOKEN=$TKN" | sudo tee -a "$TG_FILE" > /dev/null
                echo -e "  ${LGREEN}✓ Token disimpan${NC}"; sleep 1 ;;
            2)
                echo; read -rp "  Chat ID : " CIDD; [[ -z "$CIDD" ]] && continue
                grep -q '^CHATID=' "$TG_FILE" 2>/dev/null \
                    && sudo sed -i "s|^CHATID=.*|CHATID=$CIDD|" "$TG_FILE" \
                    || echo "CHATID=$CIDD" | sudo tee -a "$TG_FILE" > /dev/null
                echo -e "  ${LGREEN}✓ Chat ID disimpan${NC}"; sleep 1 ;;
            3)
                tg_send "✅ *Test Berhasil!*%0ANEXUS ZIVPN terhubung ke Telegram!%0AHost: $(hostname) | IP: $(curl -s --max-time 3 ifconfig.me)"
                echo -e "  ${LGREEN}✓ Pesan test dikirim, cek Telegram!${NC}"; sleep 2 ;;
            4)
                get_info
                MSG="📊 *LAPORAN VPS - NEXUS ZIVPN*%0AHost: $_HOST%0AIP: $_IP%0AOS: $_OS%0ARAM: ${_RAM_USED}/${_RAM_TOTAL}MB%0ADisk: $_DISK_USED/$_DISK_TOTAL%0AUptime: $(uptime -p)%0AService: $_SVC_RAW%0AAkun: $_AKUN | Exp: $_EXP"
                tg_send "$MSG"
                echo -e "  ${LGREEN}✓ Laporan dikirim${NC}"; sleep 2 ;;
            5)
                N=0; MSG="📋 *DAFTAR AKUN ZIVPN*%0A"
                while IFS=':' read -r U E P; do
                    [[ -z "$U" ]] && continue
                    EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
                    MSG+="• \`$U\` — $EF%0A"; ((N++))
                done < "$USER_DB" 2>/dev/null
                MSG+="Total: $N akun"
                tg_send "$MSG"
                echo -e "  ${LGREEN}✓ Daftar akun dikirim${NC}"; sleep 2 ;;
            6)
                sudo rm -f "$TG_FILE"
                echo -e "  ${YELLOW}✓ Konfigurasi Telegram dihapus${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════
# MENU: MENU JUALAN
# ═══════════════════════════════════════════════════════════
jualan_menu() {
    while true; do
        show_header
        echo -e "  ${LRED}${BOLD}◆ MENU JUALAN${NC}"; draw_thin; echo
        DOM=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$(curl -s --max-time 3 ifconfig.me)")
        echo -e "  ${WHITE}Host/Domain : ${LGREEN}$DOM${NC}"
        echo -e "  ${WHITE}Port UDP    : ${YELLOW}5667${NC}  ${DIM}(range: 6000-19999)${NC}"
        echo -e "  ${WHITE}Protocol    : ${CYAN}UDP ZivPN${NC}"
        echo
        menu_item 1 "📄" "Buat Info Akun (untuk share)"
        menu_item 2 "📲" "Format Kirim ke Telegram"
        menu_item 3 "📝" "Ganti Catatan Jualan"
        menu_item 0 "↩ " "Kembali"
        echo; draw_thin
        read -rp "  Pilih [0-3] : " OPT
        case $OPT in
            1)
                show_header
                echo -e "  ${LGREEN}${BOLD}📄 INFO AKUN - FORMAT SHARE${NC}"; draw_thin; echo
                while IFS=':' read -r U E P; do
                    [[ -z "$U" ]] && continue
                    EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
                    TODAY=$(date +%Y%m%d)
                    [[ "$TODAY" -gt "$E" ]] && continue  # skip expired
                    echo -e "  ${DIM}────────────────────────────────${NC}"
                    echo -e "  ${YELLOW}⚡ UDP ZivPN Premium${NC}"
                    echo -e "  Host     : ${LGREEN}$DOM${NC}"
                    echo -e "  Port     : ${CYAN}5667${NC}"
                    echo -e "  Username : ${WHITE}$U${NC}"
                    echo -e "  Password : ${WHITE}$P${NC}"
                    echo -e "  Expired  : ${YELLOW}$EF${NC}"
                done < "$USER_DB" 2>/dev/null
                echo
                read -rp "  Tekan ENTER..." _ ;;
            2)
                show_header
                echo -e "  ${CYAN}${BOLD}📲 KIRIM SEMUA AKUN AKTIF KE TELEGRAM${NC}"
                draw_thin; echo
                N=0; TODAY=$(date +%Y%m%d)
                while IFS=':' read -r U E P; do
                    [[ -z "$U" ]] && continue
                    [[ "$TODAY" -gt "$E" ]] && continue
                    EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
                    MSG="⚡ *UDP ZivPN*%0AHost: $DOM%0APort: 5667%0AUser: \`$U\`%0APass: \`$P\`%0AExp: $EF"
                    tg_send "$MSG"; ((N++))
                    sleep 0.5
                done < "$USER_DB" 2>/dev/null
                echo -e "  ${LGREEN}✓ $N akun aktif dikirim ke Telegram${NC}"
                sleep 2 ;;
            3)
                echo; read -rp "  Catatan jualan : " NOTE
                echo "$NOTE" | sudo tee "$CFG/jualan_note.txt" > /dev/null
                echo -e "  ${LGREEN}✓ Catatan disimpan${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════
# MENU: BANDWIDTH & KONEKSI
# ═══════════════════════════════════════════════════════════
bw_menu() {
    while true; do
        show_header
        echo -e "  ${LRED}${BOLD}◆ BANDWIDTH & KONEKSI${NC}"; draw_thin; echo
        menu_item 1 "📶" "Cek Koneksi Aktif UDP"
        menu_item 2 "📊" "Statistik Network Interface"
        menu_item 3 "🌐" "Speedtest (jika tersedia)"
        menu_item 4 "🔌" "Cek Port Terbuka"
        menu_item 0 "↩ " "Kembali"
        echo; draw_thin
        read -rp "  Pilih [0-4] : " OPT
        case $OPT in
            1)
                echo
                echo -e "  ${CYAN}Koneksi UDP aktif ke port 5667:${NC}"
                draw_thin
                ss -nup 2>/dev/null | grep ':5667' || echo "  Tidak ada koneksi aktif"
                echo
                echo -e "  ${CYAN}Total koneksi:${NC} $(ss -nup 2>/dev/null | grep ':5667' | wc -l)"
                echo; read -rp "  ENTER..." _ ;;
            2)
                echo
                IFACE=$(ip -4 route ls 2>/dev/null | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
                echo -e "  ${CYAN}Interface: $IFACE${NC}"; draw_thin
                cat /proc/net/dev 2>/dev/null | grep "$IFACE" | awk '{
                    printf "  RX: %.2f MB\n", $2/1024/1024
                    printf "  TX: %.2f MB\n", $10/1024/1024
                }'
                echo; read -rp "  ENTER..." _ ;;
            3)
                echo
                command -v speedtest-cli &>/dev/null \
                    && speedtest-cli --simple \
                    || echo -e "  ${YELLOW}speedtest-cli tidak terinstall. Install: apt install speedtest-cli${NC}"
                echo; read -rp "  ENTER..." _ ;;
            4)
                echo
                echo -e "  ${CYAN}Port yang terbuka (UFW):${NC}"; draw_thin
                sudo ufw status 2>/dev/null | grep -v "^$\|Status\|To\|--"
                echo; read -rp "  ENTER..." _ ;;
            0) break ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════
# MENU: RESTART SERVICE (shortcut)
# ═══════════════════════════════════════════════════════════
restart_service() {
    show_header
    echo -e "  ${YELLOW}${BOLD}🔄 RESTART SERVICE ZIVPN${NC}"; draw_thin; echo
    echo -ne "  Merestart service..."
    sudo systemctl restart zivpn 2>/dev/null
    sleep 1
    if systemctl is-active --quiet zivpn 2>/dev/null; then
        echo -e "  ${LGREEN}${BOLD}✓ Service berhasil direstart & AKTIF${NC}"
        tg_send "🔄 *Service ZivPN direstart*%0AStatus: AKTIF%0AHost: $(hostname)"
    else
        echo -e "  ${RED}✗ Service tidak aktif setelah restart!${NC}"
    fi
    echo; read -rp "  Tekan ENTER..." _
}

# ═══════════════════════════════════════════════════════════
# MENU: INSTALL ZIVPN (reinstall binary)
# ═══════════════════════════════════════════════════════════
install_menu() {
    show_header
    echo -e "  ${LRED}${BOLD}◆ INSTALL / REINSTALL ZIVPN${NC}"; draw_thin; echo
    echo -e "  ${YELLOW}Binary ZivPN akan diunduh ulang dari GitHub.${NC}"
    echo -e "  ${DIM}Akun & konfigurasi TIDAK terhapus.${NC}"
    echo
    echo -e "  ${P2}[1]${NC}  Reinstall Binary Saja"
    echo -e "  ${P2}[2]${NC}  Reinstall Binary + Reset Config"
    echo -e "  ${DIM}[0]  Batal${NC}"
    echo; draw_thin
    read -rp "  Pilih [0-2] : " OPT
    [[ "$OPT" == "0" ]] && return
    BINARY_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    CONFIG_URL="https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/config.json"
    echo
    echo -e "  ${CYAN}[1/3]${NC} Stop service..."
    sudo systemctl stop zivpn 2>/dev/null; sleep 1
    echo -e "  ${CYAN}[2/3]${NC} Download binary..."
    if sudo wget -q --show-progress -O /tmp/zivpn-new "$BINARY_URL"; then
        [[ -f /usr/local/bin/zivpn ]] && sudo cp /usr/local/bin/zivpn /usr/local/bin/zivpn.bak
        sudo mv /tmp/zivpn-new /usr/local/bin/zivpn
        sudo chmod +x /usr/local/bin/zivpn
        echo -e "  ${LGREEN}  ✓ Binary berhasil diunduh ulang${NC}"
    else
        echo -e "  ${RED}  ✗ Gagal! Memulihkan backup...${NC}"
        [[ -f /usr/local/bin/zivpn.bak ]] && sudo mv /usr/local/bin/zivpn.bak /usr/local/bin/zivpn
        sudo systemctl start zivpn 2>/dev/null; sleep 2; return
    fi
    if [[ "$OPT" == "2" ]]; then
        echo -e "       Download config.json..."
        [[ -f "$CFG/config.json" ]] && sudo cp "$CFG/config.json" "$CFG/config.json.bak"
        sudo wget -q -O "$CFG/config.json" "$CONFIG_URL" 2>/dev/null \
            && echo -e "  ${LGREEN}  ✓ Config diunduh ulang${NC}" \
            || echo -e "  ${YELLOW}  ⚠ Gagal, config lama tetap digunakan${NC}"
    fi
    echo -e "  ${CYAN}[3/3]${NC} Start service..."
    sudo systemctl start zivpn 2>/dev/null; sleep 1
    echo; draw_line
    systemctl is-active --quiet zivpn 2>/dev/null \
        && echo -e "  ${LGREEN}${BOLD}✓ Reinstall selesai! Service aktif.${NC}" \
        || echo -e "  ${YELLOW}⚠ Selesai, tapi service tidak aktif. Cek: systemctl status zivpn${NC}"
    draw_line; echo
    read -rp "  Tekan ENTER..." _
}

# ═══════════════════════════════════════════════════════════
# MENU: MANAJEMEN DOMAIN
# ═══════════════════════════════════════════════════════════
domain_menu() {
    while true; do
        show_header
        echo -e "  ${LRED}${BOLD}◆ MANAJEMEN DOMAIN${NC}"; draw_thin; echo
        DOM_NOW=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Belum diatur (pakai IP)")
        echo -e "  ${WHITE}Domain aktif : ${LGREEN}${DOM_NOW}${NC}"
        echo
        menu_item 1 "✏ " "Set / Ganti Domain"
        menu_item 2 "🗑 " "Hapus Domain (pakai IP)"
        menu_item 3 "🔍" "Cek DNS Domain"
        menu_item 4 "📋" "Info Koneksi Lengkap"
        menu_item 0 "↩ " "Kembali"
        echo; draw_thin
        read -rp "  Pilih [0-4] : " OPT
        case $OPT in
            1)
                echo; read -rp "  Domain baru : " ND; [[ -z "$ND" ]] && continue
                echo "$ND" | sudo tee "$DOMAIN_FILE" > /dev/null
                echo -e "  ${LGREEN}✓ Domain diset: $ND${NC}"; sleep 1 ;;
            2)
                IP_NOW=$(curl -s --max-time 3 ifconfig.me)
                echo "$IP_NOW" | sudo tee "$DOMAIN_FILE" > /dev/null
                echo -e "  ${YELLOW}✓ Menggunakan IP: $IP_NOW${NC}"; sleep 1 ;;
            3)
                echo; read -rp "  Domain yang dicek : " CD
                echo -e "\n  ${CYAN}DNS Result:${NC}"; draw_thin
                nslookup "$CD" 2>/dev/null || host "$CD" 2>/dev/null || echo "  Tool tidak tersedia"
                echo; read -rp "  ENTER..." _ ;;
            4)
                show_header
                DOM=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$(curl -s --max-time 3 ifconfig.me)")
                echo -e "  ${LCYAN}${BOLD}📋 INFO KONEKSI UDP ZIVPN${NC}"; draw_thin; echo
                printf "  ${WHITE}%-12s${NC}: ${LGREEN}%s${NC}\n" "Host/Domain" "$DOM"
                printf "  ${WHITE}%-12s${NC}: ${YELLOW}%s${NC}\n"  "Port"        "5667"
                printf "  ${WHITE}%-12s${NC}: ${CYAN}%s${NC}\n"   "Range Port"  "6000-19999/UDP"
                printf "  ${WHITE}%-12s${NC}: ${CYAN}%s${NC}\n"   "Protocol"    "UDP ZivPN"
                echo; draw_line; echo
                read -rp "  Tekan ENTER..." _ ;;
            0) break ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════
# MENU: GANTI TEMA WARNA
# ═══════════════════════════════════════════════════════════
tema_menu() {
    while true; do
        show_header
        echo -e "  ${LRED}${BOLD}◆ GANTI TEMA WARNA${NC}"; draw_thin; echo
        echo -e "  Tema aktif : ${P2}${BOLD}$(echo "$CUR_THEME" | tr '[:lower:]' '[:upper:]')${NC}"
        echo
        echo -e "  ${CYAN}[1]${NC}  🔵  Cyan"
        echo -e "  ${LGREEN}[2]${NC}  🟢  Green"
        echo -e "  ${LBLUE}[3]${NC}  🔷  Blue"
        echo -e "  ${LRED}[4]${NC}  🔴  Red"
        echo -e "  ${YELLOW}[5]${NC}  🟡  Yellow"
        echo -ne "  "; rb_text "[6]  🌈  Rainbow Pelangi ✨  [DEFAULT]"; echo
        echo -e "  ${DIM}[0]  ↩   Kembali${NC}"
        echo; draw_thin
        read -rp "  Pilih tema [0-6] : " OPT
        case $OPT in
            1) echo "cyan"    | sudo tee "$THEME_FILE" > /dev/null ;;
            2) echo "green"   | sudo tee "$THEME_FILE" > /dev/null ;;
            3) echo "blue"    | sudo tee "$THEME_FILE" > /dev/null ;;
            4) echo "red"     | sudo tee "$THEME_FILE" > /dev/null ;;
            5) echo "yellow"  | sudo tee "$THEME_FILE" > /dev/null ;;
            6) echo "rainbow" | sudo tee "$THEME_FILE" > /dev/null ;;
            0) break ;;
        esac
        load_theme
        [[ "$OPT" =~ ^[1-6]$ ]] && echo -e "  ${LGREEN}✓ Tema berhasil diganti!${NC}" && sleep 1
    done
}

# ═══════════════════════════════════════════════════════════
# MENU: UNINSTALL
# ═══════════════════════════════════════════════════════════
uninstall_menu() {
    show_header
    echo -e "  ${LRED}${BOLD}⚠  UNINSTALL ZIVPN${NC}"; draw_thin; echo
    echo -e "  ${YELLOW}Semua binary, service & konfigurasi akan DIHAPUS!${NC}"
    echo -e "  ${DIM}(File users.db tetap disimpan sebagai backup)${NC}"
    echo
    read -rp "  Ketik 'HAPUS' untuk konfirmasi: " CONF
    if [[ "$CONF" == "HAPUS" ]]; then
        sudo systemctl stop zivpn 2>/dev/null
        sudo systemctl disable zivpn 2>/dev/null
        sudo rm -f /etc/systemd/system/zivpn.service
        sudo rm -f /usr/local/bin/zivpn /usr/local/bin/zivpn-bin
        sudo rm -f /etc/zivpn/config.json /etc/zivpn/zivpn.key /etc/zivpn/zivpn.crt
        sudo rm -f /etc/zivpn/theme.conf /etc/zivpn/domain.conf /etc/zivpn/telegram.conf
        sudo systemctl daemon-reload
        echo -e "  ${LGREEN}✓ ZivPN berhasil diuninstall${NC}"
        echo -e "  ${DIM}  (users.db tetap ada di /etc/zivpn/users.db)${NC}"
        echo -e "  ${DIM}  Hapus manual: rm -rf /etc/zivpn${NC}"
    else
        echo -e "  ${YELLOW}Uninstall dibatalkan${NC}"
    fi
    sleep 2
}

# ═══════════════════════════════════════════════════════════
# MAIN MENU
# ═══════════════════════════════════════════════════════════
main_menu() {
    while true; do
        show_header
        # Panel title
        if [[ "$CUR_THEME" == "rainbow" ]]; then
            printf "  "; rb_text "◆ NEXUS-ZIV PREMIUM PANEL ◆"; printf " "; echo -e "${DIM}┃${NC}"
        else
            echo -e "  ${P2}${BOLD}◆ NEXUS-ZIV PREMIUM PANEL ◆${NC}"
        fi
        draw_thin; echo
        menu_item 1  "👤" "Kelola Akun User"
        menu_item 2  "⚙ " "Manajemen Service"
        menu_item 3  "🤖" "Telegram Bot"
        menu_item 4  "🛒" "Menu Jualan"
        menu_item 5  "📶" "Bandwidth & Koneksi"
        menu_item 6  "🔄" "Restart Service"
        menu_item 7  "📦" "Install ZiVPN"
        menu_item 8  "🌐" "Manajemen Domain"
        menu_item 9  "🎨" "Ganti Tema Warna  [$(echo "$CUR_THEME" | tr '[:lower:]' '[:upper:]')]"
        echo -e "  ${LRED}[E]${NC}  🗑   Uninstall ZiVPN               ${DIM}┃${NC}"
        echo -e "  ${DIM}[0]  ✖   Keluar                        ┃${NC}"
        echo
        draw_line
        read -rp "  Pilih menu : " CH
        case $CH in
            1) akun_menu ;;
            2) service_menu ;;
            3) telegram_menu ;;
            4) jualan_menu ;;
            5) bw_menu ;;
            6) restart_service ;;
            7) install_menu ;;
            8) domain_menu ;;
            9) tema_menu ;;
            [Ee]) uninstall_menu ;;
            0) echo -e "\n  ${P2}Sampai jumpa! 👋${NC}\n"; exit 0 ;;
            *) echo -e "  ${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

# ─── INIT ────────────────────────────────────────────────────
sudo mkdir -p "$CFG"
[[ ! -f "$USER_DB" ]] && sudo touch "$USER_DB"
load_theme
main_menu
MENU_EOF

sudo chmod +x "$MENU_SCRIPT"

# Tambahkan alias ke .bashrc root
grep -q 'alias menu=' /root/.bashrc 2>/dev/null || echo 'alias menu="/usr/local/bin/menu"' >> /root/.bashrc

# Juga daftarkan sebagai perintah langsung tanpa alias (source bashrc tidak selalu aktif)
if ! grep -q 'menu' /etc/profile.d/ 2>/dev/null; then
    sudo bash -c 'echo "#!/bin/bash
exec /usr/local/bin/menu" > /etc/profile.d/zivpn-menu.sh'
    sudo chmod +x /etc/profile.d/zivpn-menu.sh
fi

echo -e "\n\033[1;32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;32m  ✓ NEXUS ZIVPN berhasil diinstall!\033[0m"
echo -e "\033[1;33m  ➜ Ketik: menu  untuk membuka panel\033[0m"
echo -e "\033[1;32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"
