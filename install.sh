#!/bin/bash

# Script Panel Management Server by wawuhda-gif
# Mendukung SSH, VMESS, VLESS, TROJAN, UDP Custom, UDP Zivpn
# Language: Indonesian
# Auto install all binaries on first run

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directory setup
INSTALL_DIR="/opt/ogh"
BIN_DIR="${INSTALL_DIR}/bin"
CONFIG_DIR="/etc/ogh"
LOG_DIR="/var/log/ogh"

# Create necessary directories
mkdir -p "${BIN_DIR}" "${CONFIG_DIR}" "${LOG_DIR}"

# ============== HELPER FUNCTIONS ==============

print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════╗"
    echo "║     OGH - SERVER MANAGEMENT PANEL      ║"
    echo "║         V1.0 - Indonesia             ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

get_system_info() {
    # OS Info
    OS=$(grep -i "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
    
    # RAM Info
    RAM=$(free -h | awk '/^Mem:/ {print $2}')
    SWAP=$(free -h | awk '/^Swap:/ {print $2}')
    
    # City/Location info (from IP geolocation)
    CITY=$(curl -s https://ipapi.co/json/ | grep -o '"city":"[^"]*' | cut -d'"' -f4 || echo "Unknown")
    ISP=$(curl -s https://ipapi.co/json/ | grep -o '"org":"[^"]*' | cut -d'"' -f4 || echo "Unknown")
    
    # IP Address
    IP=$(curl -s https://api.ipify.org)
    
    # Domain (read from config if exists)
    if [ -f "${CONFIG_DIR}/domain.conf" ]; then
        DOMAIN=$(cat "${CONFIG_DIR}/domain.conf")
    else
        DOMAIN="-"
    fi
    
    # Uptime
    UPTIME=$(uptime -p | sed 's/up //')
    
    # Traffic data
    MONTH_TRAFFIC=$(vnstat -m --json 2>/dev/null | jq '.data.traffic[0].total' 2>/dev/null || echo "0")
    if [ "$MONTH_TRAFFIC" != "0" ]; then
        MONTH_TRAFFIC=$(echo "scale=2; $MONTH_TRAFFIC / 1073741824" | bc)GB
    else
        MONTH_TRAFFIC="0 GB"
    fi
    
    # Get RX/TX for current month
    MONTH_RX=$(vnstat -m --json 2>/dev/null | jq '.data.traffic[0].rx' 2>/dev/null || echo "0")
    MONTH_TX=$(vnstat -m --json 2>/dev/null | jq '.data.traffic[0].tx' 2>/dev/null || echo "0")
    
    if [ "$MONTH_RX" != "0" ]; then
        MONTH_RX=$(echo "scale=2; $MONTH_RX / 1073741824" | bc)GB
    else
        MONTH_RX="0 GB"
    fi
    
    if [ "$MONTH_TX" != "0" ]; then
        MONTH_TX=$(echo "scale=2; $MONTH_TX / 1073741824" | bc)GB
    else
        MONTH_TX="0 GB"
    fi
    
    # Daily traffic
    DAY_TRAFFIC=$(vnstat -d --json 2>/dev/null | jq '.data.traffic[0].total' 2>/dev/null || echo "0")
    if [ "$DAY_TRAFFIC" != "0" ]; then
        DAY_TRAFFIC=$(echo "scale=2; $DAY_TRAFFIC / 1073741824" | bc)GB
    else
        DAY_TRAFFIC="0 GB"
    fi
    
    DAY_RX=$(vnstat -d --json 2>/dev/null | jq '.data.traffic[0].rx' 2>/dev/null || echo "0")
    DAY_TX=$(vnstat -d --json 2>/dev/null | jq '.data.traffic[0].tx' 2>/dev/null || echo "0")
    
    if [ "$DAY_RX" != "0" ]; then
        DAY_RX=$(echo "scale=2; $DAY_RX / 1073741824" | bc)GB
    else
        DAY_RX="0 GB"
    fi
    
    if [ "$DAY_TX" != "0" ]; then
        DAY_TX=$(echo "scale=2; $DAY_TX / 1073741824" | bc)GB
    else
        DAY_TX="0 GB"
    fi
}

check_services() {
    # Check if services are running
    XRAY_STATUS="OFF"
    SSH_WS_STATUS="OFF"
    LOADBLC_STATUS="OFF"
    
    if systemctl is-active --quiet xray 2>/dev/null; then
        XRAY_STATUS="ON"
    fi
    
    if systemctl is-active --quiet ssh-ws 2>/dev/null; then
        SSH_WS_STATUS="ON"
    fi
    
    if systemctl is-active --quiet loadblc 2>/dev/null; then
        LOADBLC_STATUS="ON"
    fi
}

show_status_panel() {
    get_system_info
    check_services
    
    print_header
    
    echo -e "${BLUE}┌─ INFORMASI SERVER ─────────────────────┐${NC}"
    printf "%--15s: %s\n" "OS" "$OS"
    printf "%--15s: %s\n" "RAM" "$RAM"
    printf "%--15s: %s\n" "SWAP" "$SWAP"
    printf "%--15s: %s\n" "CITY" "$CITY"
    printf "%--15s: %s\n" "ISP" "$ISP"
    printf "%--15s: %s\n" "IP" "$IP"
    printf "%--15s: %s\n" "DOMAIN" "$DOMAIN"
    printf "%--15s: %s\n" "UPTIME" "$UPTIME"
    echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${BLUE}┌─ TRAFFIC DATA ─────────────────────────┐${NC}"
    printf "%--15s: %s [Bulan]\n" "MONTH" "$MONTH_TRAFFIC"
    printf "%--15s: %s\n" "RX" "$MONTH_RX"
    printf "%--15s: %s\n" "TX" "$MONTH_TX"
    echo ""
    printf "%--15s: %s [Hari]\n" "DAY" "$DAY_TRAFFIC"
    printf "%--15s: %s\n" "RX" "$DAY_RX"
    printf "%--15s: %s\n" "TX" "$DAY_TX"
    echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${BLUE}┌─ STATUS SERVICES ──────────────────────┐${NC}"
    echo -e "XRAY : ${XRAY_STATUS} | SSH-WS : ${SSH_WS_STATUS} | LOADBLC : ${LOADBLC_STATUS} | GOOD"
    echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${YELLOW}┌─ VERSION & CLIENT ─────────────────────┐${NC}"
    echo "Version         : SPV07.01.26"
    echo -e "Order By        : ${YELLOW}wawuhda-gif${NC}"
    echo "Client Name     : ogh"
    echo "Expiry In       : 999 Days"
    echo -e "${YELLOW}└────────────────────────────────────────┘${NC}"
}

show_menu() {
    print_header
    
    echo ""
    echo -e "${CYAN}1.0 >> SSH${NC}              ${CYAN}6.0 >> FEATURES${NC}"
    echo -e "${CYAN}2.0 >> VMESS${NC}            ${CYAN}7.0 >> SET REDUCE/TIME${NC}"
    echo -e "${CYAN}3.0 >> VLESS${NC}            ${CYAN}8.0 >> SET BRAND NAME${NC}"
    echo -e "${CYAN}4.0 >> TROJAN${NC}           ${CYAN}9.0 >> CHECK SERVICES${NC}"
    echo -e "${CYAN}5.0 >> SETUP BOT${NC}        ${CYAN}0.0 >> EXIT${NC}"
    echo ""
    echo -e "${BLUE}┌─────────────────────────────────────────┐${NC}"
    echo -n -e "Pilih Menu [1-9 atau x] : ${NC}"
}

install_dependencies() {
    echo -e "${YELLOW}Menginstall dependencies...${NC}"
    apt-get update -qq
    apt-get install -y -qq \
        curl \
        wget \
        jq \
        bc \
        vnstat \
        net-tools \
        git \
        unzip \
        systemctl > /dev/null 2>&1
    
    echo -e "${GREEN}✓ Dependencies berhasil diinstall${NC}"
}

install_xray() {
    echo -e "${YELLOW}Menginstall Xray...${NC}"
    
    if [ -f "${BIN_DIR}/xray" ]; then
        echo -e "${GREEN}✓ Xray sudah terinstall${NC}"
        return
    fi
    
    # Download Xray
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v1.7.5/Xray-linux-64.zip"
            ;;
        aarch64)
            XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v1.7.5/Xray-linux-arm64-v8a.zip"
            ;;
        *)
            echo -e "${RED}Arsitektur tidak didukung: $ARCH${NC}"
            return 1
            ;;
    esac
    
    cd /tmp
    wget -q "${XRAY_URL}" -O xray.zip
    unzip -q xray.zip
    chmod +x xray
    mv xray "${BIN_DIR}/"
    
    # Create systemd service
    cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/ogh/bin/xray -c /etc/ogh/xray.json
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    echo -e "${GREEN}✓ Xray berhasil diinstall${NC}"
}

install_udp_zivpn() {
    echo -e "${YELLOW}Menginstall UDP Zivpn (by zahidbd2)...${NC}"
    
    if [ -f "${BIN_DIR}/udp-server" ]; then
        echo -e "${GREEN}✓ UDP Zivpn sudah terinstall${NC}"
        return
    fi
    
    # Download dari original developer zahidbd2
    git clone https://github.com/zahidbd2/udp-zivpn.git /tmp/udp-zivpn 2>/dev/null || true
    
    if [ -f /tmp/udp-zivpn/udp-server ]; then
        chmod +x /tmp/udp-zivpn/udp-server
        mv /tmp/udp-zivpn/udp-server "${BIN_DIR}/"
        echo -e "${GREEN}✓ UDP Zivpn berhasil diinstall${NC}"
    else
        echo -e "${RED}✗ Gagal menginstall UDP Zivpn${NC}"
    fi
}

install_udp_custom() {
    echo -e "${YELLOW}Menginstall UDP Custom...${NC}"
    
    if [ -f "${BIN_DIR}/udp-custom" ]; then
        echo -e "${GREEN}✓ UDP Custom sudah terinstall${NC}"
        return
    fi
    
    # Download UDP Custom binary
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            UDP_CUSTOM_URL="https://raw.githubusercontent.com/arismaramar/udp-custom/master/udp-custom-linux-x64"
            ;;
        aarch64)
            UDP_CUSTOM_URL="https://raw.githubusercontent.com/arismaramar/udp-custom/master/udp-custom-linux-arm64"
            ;;
        *)
            echo -e "${RED}Arsitektur tidak didukung: $ARCH${NC}"
            return 1
            ;;
    esac
    
    wget -q "${UDP_CUSTOM_URL}" -O "${BIN_DIR}/udp-custom"
    chmod +x "${BIN_DIR}/udp-custom"
    
    echo -e "${GREEN}✓ UDP Custom berhasil diinstall${NC}"
}

install_ssh_ws() {
    echo -e "${YELLOW}Menginstall SSH WebSocket...${NC}"
    
    if [ -f "${BIN_DIR}/ssh-ws" ]; then
        echo -e "${GREEN}✓ SSH WebSocket sudah terinstall${NC}"
        return
    fi
    
    # Download SSH WebSocket
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            SSH_WS_URL="https://github.com/arismaramar/ssh-ws/releases/download/v1.3.0/ssh-ws-linux-x64"
            ;;
        aarch64)
            SSH_WS_URL="https://github.com/arismaramar/ssh-ws/releases/download/v1.3.0/ssh-ws-linux-arm64"
            ;;
        *)
            echo -e "${RED}Arsitektur tidak didukung: $ARCH${NC}"
            return 1
            ;;
    esac
    
    wget -q "${SSH_WS_URL}" -O "${BIN_DIR}/ssh-ws"
    chmod +x "${BIN_DIR}/ssh-ws"
    
    echo -e "${GREEN}✓ SSH WebSocket berhasil diinstall${NC}"
}

install_loadblc() {
    echo -e "${YELLOW}Menginstall Load Balancer...${NC}"
    
    if [ -f "${BIN_DIR}/loadblc" ]; then
        echo -e "${GREEN}✓ Load Balancer sudah terinstall${NC}"
        return
    fi
    
    # Download LoadBlc
    git clone https://github.com/arismaramar/loadblc.git /tmp/loadblc 2>/dev/null || true
    
    if [ -f /tmp/loadblc/loadblc ]; then
        chmod +x /tmp/loadblc/loadblc
        mv /tmp/loadblc/loadblc "${BIN_DIR}/"
        echo -e "${GREEN}✓ Load Balancer berhasil diinstall${NC}"
    else
        echo -e "${RED}✗ Gagal menginstall Load Balancer${NC}"
    fi
}

first_time_setup() {
    if [ ! -f "${CONFIG_DIR}/.installed" ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}     SETUP PERTAMA KALI - INSTALL BINARIES${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        install_dependencies
        echo ""
        install_xray
        echo ""
        install_udp_zivpn
        echo ""
        install_udp_custom
        echo ""
        install_ssh_ws
        echo ""
        install_loadblc
        
        touch "${CONFIG_DIR}/.installed"
        
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ SETUP BERHASIL - Semua binaries terinstall${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "Tekan Enter untuk melanjutkan..."
    fi
}

ssh_menu() {
    print_header
    echo -e "${CYAN}═══════════════ MENU SSH ═══════════════${NC}"
    echo ""
    echo "1. Tambah User SSH"
    echo "2. Delete User SSH"
    echo "3. Lihat Daftar User SSH"
    echo "4. Kembali ke Menu Utama"
    echo ""
    echo -n "Pilih opsi [1-4]: "
}

vmess_menu() {
    print_header
    echo -e "${CYAN}═══════════════ MENU VMESS ═══════════════${NC}"
    echo ""
    echo "1. Tambah VMESS Account"
    echo "2. Delete VMESS Account"
    echo "3. Lihat Daftar VMESS"
    echo "4. Kembali ke Menu Utama"
    echo ""
    echo -n "Pilih opsi [1-4]: "
}

vless_menu() {
    print_header
    echo -e "${CYAN}═══════════════ MENU VLESS ═══════════════${NC}"
    echo ""
    echo "1. Tambah VLESS Account"
    echo "2. Delete VLESS Account"
    echo "3. Lihat Daftar VLESS"
    echo "4. Kembali ke Menu Utama"
    echo ""
    echo -n "Pilih opsi [1-4]: "
}

trojan_menu() {
    print_header
    echo -e "${CYAN}═══════════════ MENU TROJAN ═══════════════${NC}"
    echo ""
    echo "1. Tambah Trojan Account"
    echo "2. Delete Trojan Account"
    echo "3. Lihat Daftar Trojan"
    echo "4. Kembali ke Menu Utama"
    echo ""
    echo -n "Pilih opsi [1-4]: "
}

setup_bot_menu() {
    print_header
    echo -e "${CYAN}═══════════════ SETUP BOT ═══════════════${NC}"
    echo ""
    echo "1. Setup Bot Telegram"
    echo "2. Setup Bot WhatsApp"
    echo "3. Kembali ke Menu Utama"
    echo ""
    echo -n "Pilih opsi [1-3]: "
}

features_menu() {
    print_header
    echo -e "${CYAN}═══════════════ FITUR-FITUR ═══════════════${NC}"
    echo ""
    echo "1. UDP Custom"
    echo "2. UDP Zivpn"
    echo "3. Auto Reboot"
    echo "4. Backup Config"
    echo "5. Restore Config"
    echo "6. Kembali ke Menu Utama"
    echo ""
    echo -n "Pilih opsi [1-6]: "
}

set_reduce_time_menu() {
    print_header
    echo -e "${CYAN}════════════════ SET REDUCE/TIME ════════════════${NC}"
    echo ""
    echo "1. Set Waktu Reduce Data"
    echo "2. Set Batas Data Reduce"
    echo "3. Auto Reduce Schedule"
    echo "4. Kembali ke Menu Utama"
    echo ""
    echo -n "Pilih opsi [1-4]: "
}

set_brand_name_menu() {
    print_header
    echo -e "${CYAN}════════════════ SET BRAND NAME ════════════════${NC}"
    echo ""
    echo "Masukkan nama brand/nama panel:"
    read -p "> " brand_name
    echo "$brand_name" > "${CONFIG_DIR}/brand.conf"
    echo -e "${GREEN}✓ Brand name berhasil disimpan${NC}"
    sleep 2
}

check_services_detail() {
    print_header
    echo -e "${CYAN}════════════════ CHECK SERVICES ════════════════${NC}"
    echo ""
    
    # Check Xray
    if systemctl is-active --quiet xray 2>/dev/null; then
        echo -e "${GREEN}✓ Xray${NC} : RUNNING"
        systemctl status xray --no-pager | grep "Active:" | tail -1
    else
        echo -e "${RED}✗ Xray${NC} : STOPPED"
    fi
    
    # Check SSH-WS
    if systemctl is-active --quiet ssh-ws 2>/dev/null; then
        echo -e "${GREEN}✓ SSH-WS${NC} : RUNNING"
    else
        echo -e "${RED}✗ SSH-WS${NC} : STOPPED"
    fi
    
    # Check LoadBlc
    if systemctl is-active --quiet loadblc 2>/dev/null; then
        echo -e "${GREEN}✓ LoadBlc${NC} : RUNNING"
    else
        echo -e "${RED}✗ LoadBlc${NC} : STOPPED"
    fi
    
    # Check UDP Zivpn
    if [ -f "${BIN_DIR}/udp-server" ]; then
        echo -e "${GREEN}✓ UDP Zivpn${NC} : INSTALLED"
    else
        echo -e "${RED}✗ UDP Zivpn${NC} : NOT INSTALLED"
    fi
    
    # Check UDP Custom
    if [ -f "${BIN_DIR}/udp-custom" ]; then
        echo -e "${GREEN}✓ UDP Custom${NC} : INSTALLED"
    else
        echo -e "${RED}✗ UDP Custom${NC} : NOT INSTALLED"
    fi
    
    echo ""
    read -p "Tekan Enter untuk kembali..."
}

# ============== MAIN PROGRAM ==============

main_loop() {
    while true; do
        show_status_panel
        echo ""
        show_menu
        read choice
        
        case $choice in
            1|1.0)
                while true; do
                    ssh_menu
                    read ssh_choice
                    case $ssh_choice in
                        1) echo -e "${YELLOW}Fitur Tambah User SSH akan ditambahkan${NC}"; sleep 1 ;; 
                        2) echo -e "${YELLOW}Fitur Delete User SSH akan ditambahkan${NC}"; sleep 1 ;;
                        3) echo -e "${YELLOW}Fitur Lihat User SSH akan ditambahkan${NC}"; sleep 1 ;;
                        4) break ;;
                        *) echo -e "${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            2|2.0)
                while true; do
                    vmess_menu
                    read vmess_choice
                    case $vmess_choice in
                        1) echo -e "${YELLOW}Fitur Tambah VMESS akan ditambahkan${NC}"; sleep 1 ;;
                        2) echo -e "${YELLOW}Fitur Delete VMESS akan ditambahkan${NC}"; sleep 1 ;;
                        3) echo -e "${YELLOW}Fitur Lihat VMESS akan ditambahkan${NC}"; sleep 1 ;;
                        4) break ;;
                        *) echo -e "${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            3|3.0)
                while true; do
                    vless_menu
                    read vless_choice
                    case $vless_choice in
                        1) echo -e "${YELLOW}Fitur Tambah VLESS akan ditambahkan${NC}"; sleep 1 ;;
                        2) echo -e "${YELLOW}Fitur Delete VLESS akan ditambahkan${NC}"; sleep 1 ;;
                        3) echo -e "${YELLOW}Fitur Lihat VLESS akan ditambahkan${NC}"; sleep 1 ;;
                        4) break ;;
                        *) echo -e "${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            4|4.0)
                while true; do
                    trojan_menu
                    read trojan_choice
                    case $trojan_choice in
                        1) echo -e "${YELLOW}Fitur Tambah Trojan akan ditambahkan${NC}"; sleep 1 ;;
                        2) echo -e "${YELLOW}Fitur Delete Trojan akan ditambahkan${NC}"; sleep 1 ;;
                        3) echo -e "${YELLOW}Fitur Lihat Trojan akan ditambahkan${NC}"; sleep 1 ;;
                        4) break ;;
                        *) echo -e "${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            5|5.0)
                while true; do
                    setup_bot_menu
                    read bot_choice
                    case $bot_choice in
                        1) echo -e "${YELLOW}Fitur Setup Bot Telegram akan ditambahkan${NC}"; sleep 1 ;;
                        2) echo -e "${YELLOW}Fitur Setup Bot WhatsApp akan ditambahkan${NC}"; sleep 1 ;;
                        3) break ;;
                        *) echo -e "${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            6|6.0)
                while true; do
                    features_menu
                    read features_choice
                    case $features_choice in
                        1) echo -e "${YELLOW}Fitur UDP Custom akan ditambahkan${NC}"; sleep 1 ;;
                        2) echo -e "${YELLOW}Fitur UDP Zivpn akan ditambahkan${NC}"; sleep 1 ;;
                        3) echo -e "${YELLOW}Fitur Auto Reboot akan ditambahkan${NC}"; sleep 1 ;;
                        4) echo -e "${YELLOW}Fitur Backup Config akan ditambahkan${NC}"; sleep 1 ;;
                        5) echo -e "${YELLOW}Fitur Restore Config akan ditambahkan${NC}"; sleep 1 ;;
                        6) break ;;
                        *) echo -e "${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            7|7.0)
                while true; do
                    set_reduce_time_menu
                    read reduce_choice
                    case $reduce_choice in
                        1) echo -e "${YELLOW}Fitur Set Waktu Reduce akan ditambahkan${NC}"; sleep 1 ;;
                        2) echo -e "${YELLOW}Fitur Set Batas Data akan ditambahkan${NC}"; sleep 1 ;;
                        3) echo -e "${YELLOW}Fitur Auto Reduce akan ditambahkan${NC}"; sleep 1 ;;
                        4) break ;;
                        *) echo -e "${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            8|8.0)
                set_brand_name_menu
                ;;
            9|9.0)
                check_services_detail
                ;;
            0|0.0|x|X)
                echo -e "${CYAN}Terima kasih telah menggunakan OGH Panel${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid, silakan coba lagi${NC}"
                sleep 2
                ;;
        esac
    done
}

# Start program
first_time_setup
main_loop
