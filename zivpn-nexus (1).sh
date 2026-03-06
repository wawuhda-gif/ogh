#!/bin/bash
# ============================================================
#   Zivpn UDP Module installer
#   Creator Zahid Islam
#   Panel OGH-ZIV by NEXUS TEAM
# ============================================================

# ── Install bin UDP ZivPN ───────────────────────────────────
echo -e "Updating server"
apt-get update -y && apt-get upgrade -y

systemctl stop zivpn.service 1>/dev/null 2>/dev/null

echo -e "Downloading UDP Service"
wget -q https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn

mkdir -p /etc/zivpn
wget -q https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/config.json -O /etc/zivpn/config.json

echo "Generating cert files:"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" \
  -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"

sysctl -w net.core.rmem_max=16777216 >/dev/null
sysctl -w net.core.wmem_max=16777216 >/dev/null

cat > /etc/systemd/system/zivpn.service << 'SVCEOF'
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
SVCEOF

# File awal
echo "[]"      > /etc/zivpn/users.db.json
echo "rainbow" > /etc/zivpn/theme.conf
touch /etc/zivpn/users.db

# iptables
IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
while iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null; do :; done
iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
iptables -A FORWARD -p udp -d 127.0.0.1 --dport 5667 -j ACCEPT
iptables -t nat -A POSTROUTING -s 127.0.0.1/32 -o "$IFACE" -j MASQUERADE
apt-get install -y -qq iptables-persistent
netfilter-persistent save >/dev/null 2>&1

systemctl daemon-reload
systemctl enable zivpn.service
systemctl start zivpn.service

ufw allow 6000:19999/udp >/dev/null 2>&1
ufw allow 5667/udp       >/dev/null 2>&1

# ── Install Menu Panel ──────────────────────────────────────
cat > /usr/local/bin/menu << 'MENUEOF'
#!/bin/bash
# OGH-ZIV Premium Panel | ketik: menu

CFG="/etc/zivpn"
USER_DB="$CFG/users.db"
THEME_FILE="$CFG/theme.conf"
DOMAIN_FILE="$CFG/domain.conf"
TG_FILE="$CFG/telegram.conf"
VERSION="v2.0"
BRAND="OGH-ZIV"
BINARY_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
CONFIG_URL="https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/config.json"

NC='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'
RED='\033[0;31m';   LRED='\033[1;31m'
GREEN='\033[0;32m'; LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m';  LBLUE='\033[1;34m'
CYAN='\033[0;36m';  LCYAN='\033[1;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
RB=('\033[0;31m' '\033[0;33m' '\033[1;33m' '\033[0;32m' '\033[0;36m' '\033[0;34m' '\033[0;35m')

load_theme() {
    CUR_THEME="rainbow"
    [[ -f "$THEME_FILE" ]] && CUR_THEME=$(tr -d '[:space:]' < "$THEME_FILE" 2>/dev/null)
    case "$CUR_THEME" in
        green)  P1='\033[0;32m'; P2='\033[1;32m'; P3='\033[0;32m' ;;
        blue)   P1='\033[0;34m'; P2='\033[1;34m'; P3='\033[0;34m' ;;
        red)    P1='\033[0;31m'; P2='\033[1;31m'; P3='\033[0;31m' ;;
        yellow) P1='\033[1;33m'; P2='\033[0;33m'; P3='\033[1;33m' ;;
        cyan)   P1='\033[0;36m'; P2='\033[1;36m'; P3='\033[0;36m' ;;
        *)      P1='\033[0;36m'; P2='\033[0;35m'; P3='\033[1;33m' ;;
    esac
}

rb_text() {
    local t="$1" i=0
    for (( c=0; c<${#t}; c++ )); do
        echo -ne "${RB[$((i%7))]}${t:$c:1}"; ((i++))
    done; echo -ne "${NC}"
}

draw_line() {
    local s="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" i=0
    if [[ "$CUR_THEME" == "rainbow" ]]; then
        for (( c=0; c<${#s}; c++ )); do echo -ne "${RB[$((i%7))]}${s:$c:1}"; ((i++)); done
        echo -e "${NC}"
    else echo -e "${P1}${s}${NC}"; fi
}

draw_thin() {
    local s="─────────────────────────────────────────────────────" i=0
    if [[ "$CUR_THEME" == "rainbow" ]]; then
        for (( c=0; c<${#s}; c++ )); do echo -ne "${RB[$((i%7))]}${s:$c:1}"; ((i++)); done
        echo -e "${NC}"
    else echo -e "${DIM}${P1}${s}${NC}"; fi
}

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
    _AKUN=$(grep -c '.' "$USER_DB" 2>/dev/null || echo "0")
    _EXP=0; TODAY=$(date +%Y%m%d)
    while IFS=':' read -r U E P; do
        [[ -z "$U" ]] && continue
        [[ "$TODAY" -gt "$E" ]] && ((_EXP++))
    done < "$USER_DB" 2>/dev/null
    _TG_STATUS="✗"
    [[ -f "$TG_FILE" ]] && grep -q '^TOKEN=.' "$TG_FILE" 2>/dev/null && _TG_STATUS="✓"
    _TEMA=$(tr '[:lower:]' '[:upper:]' < "$THEME_FILE" 2>/dev/null || echo "RAINBOW")
    _SVC=$(systemctl is-active zivpn 2>/dev/null)
}

svc_dot() {
    systemctl is-active --quiet zivpn 2>/dev/null \
        && echo -e "${LGREEN}${BOLD}● ZiVPN RUNNING${NC}" \
        || echo -e "${LRED}${BOLD}● ZiVPN STOPPED${NC}"
}

show_header() {
    clear; load_theme; get_info; echo
    if [[ "$CUR_THEME" == "rainbow" ]]; then
        rb_text '   ___    ____  _   _            ____  ___ _    __';  echo
        rb_text '  / _ \  / ___|| | | |     _    |_  / |_ _| |  / /'; echo
        rb_text ' | | | || |  _ | |_| |   _| |_   / /   | | | / /  '; echo
        rb_text ' | |_| || |_| ||  _  |  |_   _| / /_   | | |/ /   '; echo
        rb_text '  \___/  \____||_| |_|    |_|  /____|  |___|_/     '; echo
        echo
        rb_text '  //////////  O G H - Z I V  P R E M I U M  //////////'; echo
    else
        echo -e "${P2}${BOLD}   ___    ____  _   _            ____  ___ _    __${NC}"
        echo -e "${P2}${BOLD}  / _ \\  / ___|| | | |     _    |_  / |_ _| |  / /${NC}"
        echo -e "${P1}${BOLD} | | | || |  _ | |_| |   _| |_   / /   | | | / /  ${NC}"
        echo -e "${P1}${BOLD} | |_| || |_| ||  _  |  |_   _| / /_   | | |/ /   ${NC}"
        echo -e "${P2}${BOLD}  \\___/  \\____||_| |_|    |_|  /____|  |___|_/     ${NC}"
        echo
        echo -e "${P3}${BOLD}  //////////  O G H - Z I V  P R E M I U M  //////////${NC}"
    fi
    echo
    echo -e "  ${DIM}◆${NC} ${LRED}${BOLD}OGH-ZIV Premium${NC}  ${DIM}·${NC}  ${CYAN}fauzanihanipah/ziv-udp${NC}  ${DIM}·${NC}  ${YELLOW}${VERSION}${NC}"
    echo
    draw_line
    printf "  ${LRED}${BOLD}◆ INFO VPS${NC}%22s${YELLOW}%s${NC}\n" "" "$_DATE"
    draw_thin
    printf "  ${WHITE}Hostname : ${LCYAN}%-20s${NC}  ${WHITE}OS     : ${LCYAN}%s${NC}\n" "$_HOST" "$_OS"
    printf "  ${WHITE}IP Publik: ${LGREEN}%-20s${NC}  ${WHITE}Domain : ${LGREEN}%s${NC}\n" "$_IP" "$_DOM"
    printf "  ${WHITE}Port VPN : ${YELLOW}%-20s${NC}  ${WHITE}Brand  : ${YELLOW}%s${NC}\n" "$_PORT" "$BRAND"
    draw_thin
    printf "  ${WHITE}CPU: ${LGREEN}%-8s${NC}  ${WHITE}RAM: ${LGREEN}%s/%sMB${NC}  ${WHITE}Disk: ${LGREEN}%s/%s${NC}\n" \
        "${_CPU}%" "$_RAM_USED" "$_RAM_TOTAL" "$_DISK_USED" "$_DISK_TOTAL"
    draw_thin
    printf "  $(svc_dot)  ${WHITE}Akun: ${LCYAN}%s${NC}  ${WHITE}Exp: ${LRED}%s${NC}  ${WHITE}Bot: ${YELLOW}%s${NC}  ${WHITE}Tema: " \
        "$_AKUN" "$_EXP" "$_TG_STATUS"
    if [[ "$CUR_THEME" == "rainbow" ]]; then rb_text "RAINBOW"; echo -e "${NC}"
    else echo -e "${P2}${_TEMA}${NC}"; fi
    draw_line; echo
}

mi() {
    local N="$1" IC="$2" LBL="$3" IDX=$(( $1 % 7 ))
    if [[ "$CUR_THEME" == "rainbow" ]]; then
        printf "  ${RB[$IDX]}[%s]${NC}  %s  %-28s${DIM}┃${NC}\n" "$N" "$IC" "$LBL"
    else
        printf "  ${P2}[%s]${NC}  %s  %-28s${DIM}┃${NC}\n" "$N" "$IC" "$LBL"
    fi
}

tg_send() {
    [[ ! -f "$TG_FILE" ]] && return
    local TK=$(grep '^TOKEN=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
    local CID=$(grep '^CHATID=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
    [[ -z "$TK" || -z "$CID" ]] && return
    curl -s --max-time 5 "https://api.telegram.org/bot${TK}/sendMessage" \
        -d "chat_id=${CID}&text=$1&parse_mode=Markdown" >/dev/null 2>&1 &
}

akun_menu() {
    while true; do
        show_header
        echo -e "  ${LRED}${BOLD}◆ KELOLA AKUN USER${NC}"; draw_thin; echo
        mi 1 "👤" "Tambah Akun"
        mi 2 "📋" "List Akun"
        mi 3 "🗑 " "Hapus Akun"
        mi 4 "🔄" "Perpanjang Akun"
        mi 5 "🔍" "Cek Akun"
        mi 0 "↩ " "Kembali"
        echo; draw_thin; read -rp "  Pilih [0-5] : " O
        case $O in 1) akun_tambah ;; 2) akun_list ;; 3) akun_hapus ;;
                   4) akun_renew  ;; 5) akun_cek  ;; 0) break ;; esac
    done
}

akun_tambah() {
    show_header; echo -e "  ${LGREEN}${BOLD}➕ TAMBAH AKUN${NC}"; draw_thin; echo
    read -rp "  Username        : " U
    [[ -z "$U" ]] && { echo -e "  ${RED}✗ Kosong!${NC}"; sleep 1; return; }
    grep -q "^${U}:" "$USER_DB" 2>/dev/null && { echo -e "  ${YELLOW}⚠ Sudah ada!${NC}"; sleep 1; return; }
    read -rp "  Password        : " P
    [[ -z "$P" ]] && { echo -e "  ${RED}✗ Kosong!${NC}"; sleep 1; return; }
    read -rp "  Masa aktif hari [30] : " D; D=${D:-30}
    E=$(date -d "+${D} days" +%Y%m%d 2>/dev/null)
    EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
    echo "${U}:${E}:${P}" >> "$USER_DB"
    DOM=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$_IP")
    echo; draw_line; echo -e "  ${LGREEN}${BOLD}✓ AKUN BERHASIL DIBUAT${NC}"; draw_thin
    printf "  ${WHITE}%-12s${NC}: ${LCYAN}%s${NC}\n" "Username" "$U"
    printf "  ${WHITE}%-12s${NC}: ${LCYAN}%s${NC}\n" "Password" "$P"
    printf "  ${WHITE}%-12s${NC}: ${YELLOW}%s${NC}\n"  "Expired"  "$EF"
    printf "  ${WHITE}%-12s${NC}: ${LGREEN}%s${NC}\n" "Host"     "$DOM"
    printf "  ${WHITE}%-12s${NC}: ${LGREEN}%s${NC}\n" "Port"     "5667"
    draw_line; echo
    tg_send "➕ *AKUN BARU*%0AUser: \`$U\` | Pass: \`$P\`%0AExp: $EF | Host: $DOM:5667"
    read -rp "  ENTER..." _
}

akun_list() {
    show_header; echo -e "  ${LCYAN}${BOLD}📋 DAFTAR AKUN${NC}"; draw_thin
    printf "  ${YELLOW}%-4s %-18s %-12s %-12s${NC}\n" "NO" "USERNAME" "EXPIRED" "STATUS"
    draw_thin; TODAY=$(date +%Y%m%d); N=0
    while IFS=':' read -r U E P; do
        [[ -z "$U" ]] && continue; ((N++))
        EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
        DL=$(( ( $(date -d "$E" +%s 2>/dev/null || echo 0) - $(date +%s) ) / 86400 ))
        [[ "$TODAY" -le "$E" ]] && ST="${LGREEN}Aktif(${DL}h)${NC}" || ST="${LRED}Expired${NC}"
        printf "  %-4s %-18s %-12s " "$N" "$U" "$EF"; echo -e "$ST"
    done < "$USER_DB" 2>/dev/null
    draw_thin; echo -e "  Total: ${LCYAN}${N} akun${NC}"; draw_line; echo
    read -rp "  ENTER..." _
}

akun_hapus() {
    show_header; echo -e "  ${LRED}${BOLD}🗑  HAPUS AKUN${NC}"; draw_thin; echo
    while IFS=':' read -r U E P; do
        [[ -z "$U" ]] && continue
        echo -e "  ${DIM}•${NC} ${WHITE}$U${NC}  ${DIM}($(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E"))${NC}"
    done < "$USER_DB" 2>/dev/null
    echo; read -rp "  Username yang dihapus : " U; [[ -z "$U" ]] && return
    if grep -q "^${U}:" "$USER_DB" 2>/dev/null; then
        sed -i "/^${U}:/d" "$USER_DB"
        echo -e "  ${LGREEN}✓ Akun $U dihapus!${NC}"
        tg_send "🗑 *AKUN DIHAPUS*%0AUsername: \`$U\`"
    else echo -e "  ${RED}✗ Tidak ditemukan!${NC}"; fi
    sleep 1
}

akun_renew() {
    show_header; echo -e "  ${YELLOW}${BOLD}🔄 PERPANJANG AKUN${NC}"; draw_thin; echo
    while IFS=':' read -r U E P; do
        [[ -z "$U" ]] && continue
        echo -e "  ${DIM}•${NC} ${WHITE}$U${NC}  ${DIM}($(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E"))${NC}"
    done < "$USER_DB" 2>/dev/null
    echo; read -rp "  Username : " U; [[ -z "$U" ]] && return
    grep -q "^${U}:" "$USER_DB" 2>/dev/null || { echo -e "  ${RED}✗ Tidak ditemukan!${NC}"; sleep 1; return; }
    read -rp "  Tambah hari [30] : " D; D=${D:-30}
    OLD=$(grep "^${U}:" "$USER_DB" | cut -d':' -f2)
    PW=$(grep "^${U}:" "$USER_DB" | cut -d':' -f3)
    NEW=$(date -d "${OLD}+${D} days" +%Y%m%d 2>/dev/null || echo "$OLD")
    NF=$(date -d "$NEW" '+%d-%m-%Y' 2>/dev/null || echo "$NEW")
    sed -i "s/^${U}:.*/${U}:${NEW}:${PW}/" "$USER_DB"
    echo -e "  ${LGREEN}✓ Diperpanjang s/d ${NF}${NC}"
    tg_send "🔄 *DIPERPANJANG*%0AUser: \`$U\`%0AExpired: $NF"
    sleep 1
}

akun_cek() {
    show_header; echo -e "  ${CYAN}${BOLD}🔍 CEK AKUN${NC}"; draw_thin; echo
    read -rp "  Username : " U; [[ -z "$U" ]] && return
    if grep -q "^${U}:" "$USER_DB" 2>/dev/null; then
        E=$(grep "^${U}:" "$USER_DB" | cut -d':' -f2)
        P=$(grep "^${U}:" "$USER_DB" | cut -d':' -f3)
        EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
        DL=$(( ( $(date -d "$E" +%s 2>/dev/null || echo 0) - $(date +%s) ) / 86400 ))
        TODAY=$(date +%Y%m%d)
        [[ "$TODAY" -le "$E" ]] && ST="${LGREEN}AKTIF (sisa ${DL} hari)${NC}" || ST="${LRED}EXPIRED${NC}"
        echo; draw_thin
        printf "  ${WHITE}%-12s${NC}: ${LCYAN}%s${NC}\n" "Username" "$U"
        printf "  ${WHITE}%-12s${NC}: ${LCYAN}%s${NC}\n" "Password" "$P"
        printf "  ${WHITE}%-12s${NC}: ${YELLOW}%s${NC}\n"  "Expired"  "$EF"
        printf "  ${WHITE}%-12s${NC}: " "Status"; echo -e "$ST"; draw_thin
    else echo -e "  ${RED}✗ Akun tidak ditemukan!${NC}"; fi
    echo; read -rp "  ENTER..." _
}

service_menu() {
    while true; do
        show_header; echo -e "  ${LRED}${BOLD}◆ MANAJEMEN SERVICE${NC}"; draw_thin
        echo -e "  Status : $(svc_dot)"; echo
        mi 1 "▶ " "Start Service"
        mi 2 "⏹ " "Stop Service"
        mi 3 "🔄" "Restart Service"
        mi 4 "📜" "Lihat Log"
        mi 5 "📋" "Status Detail"
        mi 0 "↩ " "Kembali"
        echo; draw_thin; read -rp "  Pilih [0-5] : " O
        case $O in
            1) systemctl start   zivpn && echo -e "  ${LGREEN}✓ Started${NC}"   ;;
            2) systemctl stop    zivpn && echo -e "  ${YELLOW}✓ Stopped${NC}"   ;;
            3) systemctl restart zivpn && echo -e "  ${LGREEN}✓ Restarted${NC}" ;;
            4) echo; journalctl -u zivpn -n 30 --no-pager 2>/dev/null; echo; read -rp "  ENTER..." _ ;;
            5) echo; systemctl status zivpn; echo; read -rp "  ENTER..." _ ;;
            0) break ;;
        esac
        [[ "$O" =~ ^[1-3]$ ]] && sleep 1
    done
}

telegram_menu() {
    while true; do
        show_header; echo -e "  ${LRED}${BOLD}◆ TELEGRAM BOT${NC}"; draw_thin; echo
        TK=$(grep '^TOKEN=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
        CID=$(grep '^CHATID=' "$TG_FILE" 2>/dev/null | cut -d'=' -f2)
        printf "  ${WHITE}%-10s${NC}: ${CYAN}%s${NC}\n" "Bot Token" "${TK:-Belum diatur}"
        printf "  ${WHITE}%-10s${NC}: ${CYAN}%s${NC}\n" "Chat ID"   "${CID:-Belum diatur}"
        echo
        mi 1 "🔑" "Set Bot Token"
        mi 2 "💬" "Set Chat ID"
        mi 3 "📡" "Test Koneksi Bot"
        mi 4 "📊" "Kirim Laporan VPS"
        mi 5 "📋" "Kirim Daftar Akun"
        mi 6 "🗑 " "Hapus Konfigurasi"
        mi 0 "↩ " "Kembali"
        echo; draw_thin; read -rp "  Pilih [0-6] : " O
        case $O in
            1) echo; read -rp "  Bot Token : " TKN; [[ -z "$TKN" ]] && continue
               grep -q '^TOKEN=' "$TG_FILE" 2>/dev/null \
                   && sed -i "s|^TOKEN=.*|TOKEN=$TKN|" "$TG_FILE" \
                   || echo "TOKEN=$TKN" >> "$TG_FILE"
               echo -e "  ${LGREEN}✓ Token disimpan${NC}"; sleep 1 ;;
            2) echo; read -rp "  Chat ID : " CID2; [[ -z "$CID2" ]] && continue
               grep -q '^CHATID=' "$TG_FILE" 2>/dev/null \
                   && sed -i "s|^CHATID=.*|CHATID=$CID2|" "$TG_FILE" \
                   || echo "CHATID=$CID2" >> "$TG_FILE"
               echo -e "  ${LGREEN}✓ Chat ID disimpan${NC}"; sleep 1 ;;
            3) tg_send "✅ *Test Berhasil!*%0AOGH-ZIV Panel terhubung!%0AHost: $(hostname)"
               echo -e "  ${LGREEN}✓ Pesan test dikirim!${NC}"; sleep 2 ;;
            4) get_info
               tg_send "📊 *LAPORAN VPS*%0AHost: $_HOST%0AIP: $_IP%0AOS: $_OS%0ARAM: ${_RAM_USED}/${_RAM_TOTAL}MB%0ADisk: $_DISK_USED/$_DISK_TOTAL%0AService: $_SVC"
               echo -e "  ${LGREEN}✓ Laporan dikirim${NC}"; sleep 2 ;;
            5) N=0; MSG="📋 *DAFTAR AKUN*%0A"
               while IFS=':' read -r U E P; do
                   [[ -z "$U" ]] && continue
                   EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
                   MSG+="• \`$U\` — $EF%0A"; ((N++))
               done < "$USER_DB" 2>/dev/null
               MSG+="Total: $N akun"; tg_send "$MSG"
               echo -e "  ${LGREEN}✓ Daftar dikirim${NC}"; sleep 2 ;;
            6) rm -f "$TG_FILE"; echo -e "  ${YELLOW}✓ Dihapus${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

jualan_menu() {
    while true; do
        show_header; echo -e "  ${LRED}${BOLD}◆ MENU JUALAN${NC}"; draw_thin; echo
        DOM=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$_IP")
        echo -e "  ${WHITE}Host : ${LGREEN}$DOM${NC}  ${WHITE}Port : ${YELLOW}5667${NC}"; echo
        mi 1 "📄" "Lihat Info Akun Aktif"
        mi 2 "📲" "Kirim Akun Aktif ke Telegram"
        mi 0 "↩ " "Kembali"
        echo; draw_thin; read -rp "  Pilih [0-2] : " O
        case $O in
            1) show_header; TODAY=$(date +%Y%m%d)
               echo -e "  ${LGREEN}${BOLD}📄 AKUN AKTIF${NC}"; draw_thin; echo
               while IFS=':' read -r U E P; do
                   [[ -z "$U" || "$TODAY" -gt "$E" ]] && continue
                   EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
                   echo -e "  ${DIM}────────────────────────────────${NC}"
                   printf "  ${WHITE}%-10s${NC}: ${LGREEN}%s${NC}\n" "Host" "$DOM"
                   printf "  ${WHITE}%-10s${NC}: ${YELLOW}%s${NC}\n"  "Port" "5667"
                   printf "  ${WHITE}%-10s${NC}: ${WHITE}%s${NC}\n"  "User" "$U"
                   printf "  ${WHITE}%-10s${NC}: ${WHITE}%s${NC}\n"  "Pass" "$P"
                   printf "  ${WHITE}%-10s${NC}: ${YELLOW}%s${NC}\n"  "Exp"  "$EF"
               done < "$USER_DB" 2>/dev/null
               echo; read -rp "  ENTER..." _ ;;
            2) TODAY=$(date +%Y%m%d); N=0
               while IFS=':' read -r U E P; do
                   [[ -z "$U" || "$TODAY" -gt "$E" ]] && continue
                   EF=$(date -d "$E" '+%d-%m-%Y' 2>/dev/null || echo "$E")
                   tg_send "⚡ *UDP ZivPN*%0AHost: $DOM%0APort: 5667%0AUser: \`$U\`%0APass: \`$P\`%0AExp: $EF"
                   ((N++)); sleep 0.5
               done < "$USER_DB" 2>/dev/null
               echo -e "  ${LGREEN}✓ $N akun dikirim${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

bw_menu() {
    while true; do
        show_header; echo -e "  ${LRED}${BOLD}◆ BANDWIDTH & KONEKSI${NC}"; draw_thin; echo
        mi 1 "📶" "Koneksi UDP Aktif"
        mi 2 "📊" "Statistik Network"
        mi 3 "🔌" "Cek Port Terbuka"
        mi 0 "↩ " "Kembali"
        echo; draw_thin; read -rp "  Pilih [0-3] : " O
        case $O in
            1) echo; draw_thin; ss -nup 2>/dev/null | grep ':5667' || echo "  Tidak ada koneksi aktif"
               echo -e "  Total: ${CYAN}$(ss -nup 2>/dev/null | grep -c ':5667')${NC}"; echo; read -rp "  ENTER..." _ ;;
            2) echo; IFACE=$(ip -4 route ls 2>/dev/null | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
               echo -e "  ${CYAN}Interface: $IFACE${NC}"; draw_thin
               awk -v i="$IFACE" '$0~i{printf "  RX: %.2f MB\n  TX: %.2f MB\n",$2/1024/1024,$10/1024/1024}' /proc/net/dev 2>/dev/null
               echo; read -rp "  ENTER..." _ ;;
            3) echo; ufw status 2>/dev/null | grep -v "^$\|Status\|To\|--" || echo "  ufw tidak aktif"
               echo; read -rp "  ENTER..." _ ;;
            0) break ;;
        esac
    done
}

restart_service() {
    show_header; echo -e "  ${YELLOW}${BOLD}🔄 RESTART SERVICE${NC}"; draw_thin; echo
    systemctl restart zivpn 2>/dev/null; sleep 1
    systemctl is-active --quiet zivpn 2>/dev/null \
        && echo -e "  ${LGREEN}${BOLD}✓ Service AKTIF${NC}" \
        || echo -e "  ${RED}✗ Service TIDAK AKTIF!${NC}"
    tg_send "🔄 *Service direstart*%0AStatus: $(systemctl is-active zivpn 2>/dev/null)"
    echo; read -rp "  ENTER..." _
}

install_menu() {
    show_header; echo -e "  ${LRED}${BOLD}◆ INSTALL / REINSTALL${NC}"; draw_thin; echo
    echo -e "  ${YELLOW}Binary diunduh ulang. Akun tidak terhapus.${NC}"; echo
    mi 1 "📦" "Reinstall Binary Saja"
    mi 2 "🔄" "Reinstall Binary + Reset Config"
    mi 0 "↩ " "Batal"
    echo; draw_thin; read -rp "  Pilih [0-2] : " O
    [[ "$O" == "0" ]] && return
    echo
    echo -e "  ${CYAN}[1/3]${NC} Stop service..."; systemctl stop zivpn 2>/dev/null; sleep 1
    echo -e "  ${CYAN}[2/3]${NC} Download binary..."
    if wget -q --show-progress -O /tmp/zivpn-new "$BINARY_URL"; then
        [[ -f /usr/local/bin/zivpn ]] && cp /usr/local/bin/zivpn /usr/local/bin/zivpn.bak
        mv /tmp/zivpn-new /usr/local/bin/zivpn && chmod +x /usr/local/bin/zivpn
        echo -e "  ${LGREEN}  ✓ Binary diunduh ulang${NC}"
    else
        echo -e "  ${RED}  ✗ Gagal!${NC}"
        [[ -f /usr/local/bin/zivpn.bak ]] && mv /usr/local/bin/zivpn.bak /usr/local/bin/zivpn
        systemctl start zivpn 2>/dev/null; sleep 2; return
    fi
    [[ "$O" == "2" ]] && {
        [[ -f "$CFG/config.json" ]] && cp "$CFG/config.json" "$CFG/config.json.bak"
        wget -q -O "$CFG/config.json" "$CONFIG_URL" 2>/dev/null \
            && echo -e "  ${LGREEN}  ✓ Config diunduh ulang${NC}" \
            || echo -e "  ${YELLOW}  ⚠ Config lama digunakan${NC}"
    }
    echo -e "  ${CYAN}[3/3]${NC} Start service..."; systemctl start zivpn 2>/dev/null; sleep 1
    echo; draw_line
    systemctl is-active --quiet zivpn 2>/dev/null \
        && echo -e "  ${LGREEN}${BOLD}✓ Reinstall selesai! Service aktif.${NC}" \
        || echo -e "  ${YELLOW}⚠ Selesai, service tidak aktif.${NC}"
    draw_line; echo; read -rp "  ENTER..." _
}

domain_menu() {
    while true; do
        show_header; echo -e "  ${LRED}${BOLD}◆ MANAJEMEN DOMAIN${NC}"; draw_thin; echo
        echo -e "  Domain aktif : ${LGREEN}$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Pakai IP")${NC}"; echo
        mi 1 "✏ " "Set / Ganti Domain"
        mi 2 "🔄" "Reset ke IP"
        mi 3 "🔍" "Cek DNS Domain"
        mi 4 "📋" "Info Koneksi"
        mi 0 "↩ " "Kembali"
        echo; draw_thin; read -rp "  Pilih [0-4] : " O
        case $O in
            1) echo; read -rp "  Domain baru : " ND; [[ -z "$ND" ]] && continue
               echo "$ND" > "$DOMAIN_FILE"; echo -e "  ${LGREEN}✓ Domain: $ND${NC}"; sleep 1 ;;
            2) IP_NOW=$(curl -s --max-time 3 ifconfig.me)
               echo "$IP_NOW" > "$DOMAIN_FILE"
               echo -e "  ${YELLOW}✓ Pakai IP: $IP_NOW${NC}"; sleep 1 ;;
            3) echo; read -rp "  Domain : " CD
               nslookup "$CD" 2>/dev/null || host "$CD" 2>/dev/null || echo "  Tidak tersedia"
               echo; read -rp "  ENTER..." _ ;;
            4) DOM=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$_IP"); echo; draw_thin
               printf "  ${WHITE}%-12s${NC}: ${LGREEN}%s${NC}\n" "Host/Domain" "$DOM"
               printf "  ${WHITE}%-12s${NC}: ${YELLOW}%s${NC}\n"  "Port"        "5667"
               printf "  ${WHITE}%-12s${NC}: ${CYAN}%s${NC}\n"   "Range"       "6000-19999/UDP"
               draw_thin; echo; read -rp "  ENTER..." _ ;;
            0) break ;;
        esac
    done
}

tema_menu() {
    while true; do
        show_header; echo -e "  ${LRED}${BOLD}◆ GANTI TEMA WARNA${NC}"; draw_thin; echo
        echo -e "  Aktif : ${P2}${BOLD}$(tr '[:lower:]' '[:upper:]' < "$THEME_FILE" 2>/dev/null)${NC}"; echo
        echo -e "  ${CYAN}[1]${NC}  🔵  Cyan"
        echo -e "  ${LGREEN}[2]${NC}  🟢  Green"
        echo -e "  ${LBLUE}[3]${NC}  🔷  Blue"
        echo -e "  ${LRED}[4]${NC}  🔴  Red"
        echo -e "  ${YELLOW}[5]${NC}  🟡  Yellow"
        echo -ne "  "; rb_text "[6]  🌈  Rainbow Pelangi ✨  [DEFAULT]"; echo
        echo -e "  ${DIM}[0]  ↩   Kembali${NC}"
        echo; draw_thin; read -rp "  Pilih [0-6] : " O
        case $O in
            1) echo "cyan"    > "$THEME_FILE" ;; 2) echo "green"   > "$THEME_FILE" ;;
            3) echo "blue"    > "$THEME_FILE" ;; 4) echo "red"     > "$THEME_FILE" ;;
            5) echo "yellow"  > "$THEME_FILE" ;; 6) echo "rainbow" > "$THEME_FILE" ;;
            0) break ;;
        esac
        load_theme
        [[ "$O" =~ ^[1-6]$ ]] && echo -e "  ${LGREEN}✓ Tema diganti!${NC}" && sleep 1
    done
}

uninstall_menu() {
    show_header; echo -e "  ${LRED}${BOLD}⚠  UNINSTALL ZIVPN${NC}"; draw_thin; echo
    echo -e "  ${YELLOW}Binary, service & konfigurasi akan DIHAPUS!${NC}"
    echo -e "  ${DIM}(users.db tetap disimpan)${NC}"; echo
    read -rp "  Ketik 'HAPUS' untuk konfirmasi: " CONF
    if [[ "$CONF" == "HAPUS" ]]; then
        systemctl stop zivpn 2>/dev/null; systemctl disable zivpn 2>/dev/null
        rm -f /etc/systemd/system/zivpn.service /usr/local/bin/zivpn
        rm -f "$CFG/config.json" "$CFG/zivpn.key" "$CFG/zivpn.crt"
        rm -f "$CFG/theme.conf"  "$CFG/domain.conf" "$CFG/telegram.conf"
        systemctl daemon-reload
        echo -e "  ${LGREEN}✓ ZivPN berhasil diuninstall${NC}"
    else echo -e "  ${YELLOW}Dibatalkan${NC}"; fi
    sleep 2
}

main_menu() {
    while true; do
        show_header
        if [[ "$CUR_THEME" == "rainbow" ]]; then
            printf "  "; rb_text "◆ OGH-ZIV PREMIUM PANEL ◆"; echo -e "  ${DIM}┃${NC}"
        else
            echo -e "  ${P2}${BOLD}◆ OGH-ZIV PREMIUM PANEL ◆${NC}"
        fi
        draw_thin; echo
        mi 1 "👤" "Kelola Akun User"
        mi 2 "⚙ " "Manajemen Service"
        mi 3 "🤖" "Telegram Bot"
        mi 4 "🛒" "Menu Jualan"
        mi 5 "📶" "Bandwidth & Koneksi"
        mi 6 "🔄" "Restart Service"
        mi 7 "📦" "Install ZiVPN"
        mi 8 "🌐" "Manajemen Domain"
        mi 9 "🎨" "Ganti Tema  [$(tr '[:lower:]' '[:upper:]' < "$THEME_FILE" 2>/dev/null || echo 'RAINBOW')]"
        echo -e "  ${LRED}[E]${NC}  🗑   Uninstall ZiVPN              ${DIM}┃${NC}"
        echo -e "  ${DIM}[0]  ✖   Keluar                       ┃${NC}"
        echo; draw_line
        read -rp "  Pilih menu : " CH
        case $CH in
            1) akun_menu    ;; 2) service_menu   ;; 3) telegram_menu ;;
            4) jualan_menu  ;; 5) bw_menu         ;; 6) restart_service ;;
            7) install_menu ;; 8) domain_menu     ;; 9) tema_menu ;;
            [Ee]) uninstall_menu ;;
            0) echo -e "\n  ${P2}Sampai jumpa! 👋${NC}\n"; exit 0 ;;
            *) echo -e "  ${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

mkdir -p "$CFG"
[[ ! -f "$USER_DB" ]] && touch "$USER_DB"
load_theme
main_menu
MENUEOF

chmod +x /usr/local/bin/menu

# Daftarkan alias 'menu' supaya bisa dipanggil kapan saja
grep -q 'alias menu=' /root/.bashrc 2>/dev/null \
    || echo 'alias menu="/usr/local/bin/menu"' >> /root/.bashrc

echo 'alias menu="/usr/local/bin/menu"' > /etc/profile.d/zivpn-menu.sh
chmod +x /etc/profile.d/zivpn-menu.sh

# ── Langsung masuk menu, tanpa ketik apapun ────────────────
exec /usr/local/bin/menu
