#!/data/data/com.termux/files/usr/bin/bash
# System Pro Monitor — Termux optimized (big skull + MR.XHACKER)
# Usage:
# chmod +x system.sh
# bash system.sh

# --- COLORS ---
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; CYAN='\033[1;36m'; MAGENTA='\033[1;35m'; BOLD='\033[1m'; NC='\033[0m'

# ---------- Helpers ----------
progress_bar() {
    local percent=$1
    if [ -z "$percent" ] || ! [[ "$percent" =~ ^[0-9]+$ ]]; then percent=0; fi
    if [ "$percent" -gt 100 ]; then percent=100; fi
    local filled=$((percent / 5))
    local empty=$((20 - filled))
    for i in $(seq 1 $filled); do printf "${GREEN}█${NC}"; done
    for i in $(seq 1 $empty); do printf "${RED}█${NC}"; done
    printf "  ${BOLD}%s%%%s\n" "$percent" "$NC"
}

# ---------- SKULL BANNER ----------
skull_banner() {
    # Big but Termux-friendly skull (carefully escaped)
    echo -e "${MAGENTA}                 _________                 ${NC}"
    echo -e "${MAGENTA}              .-\"         \"-.              ${NC}"
    echo -e "${MAGENTA}            .'/  .-----.  \\'.            ${NC}"
    echo -e "${MAGENTA}           / /  /  .--.  \\  \\ \\           ${NC}"
    echo -e "${MAGENTA}          | |  |  /    \\  |  | |          ${NC}"
    echo -e "${MAGENTA}          | |  | |  ()  | |  | |          ${NC}"
    echo -e "${MAGENTA}          | |  |  \\\\    /  |  | |          ${NC}"
    echo -e "${MAGENTA}           \\ \\  '.__.'  / /           ${NC}"
    echo -e "${MAGENTA}            '._         _.'              ${NC}"
    echo -e "${MAGENTA}               /-----\\                 ${NC}"
    echo -e "${MAGENTA}              /  /   \\  \\                ${NC}"
    echo -e "${MAGENTA}             /__/     \\__\\               ${NC}"
    echo -e "${CYAN}${BOLD}             === MR.XHACKER ===${NC}\n"
}

# ---------- SYSTEM / METRICS FUNCTIONS ----------
system_info() {
    echo -e "${CYAN}💻 System Info${NC}"
    echo -e "  OS:      ${YELLOW}$(uname -o 2>/dev/null || uname)${NC}"
    echo -e "  Kernel:  ${YELLOW}$(uname -r)${NC}"
    echo -e "  Arch:    ${YELLOW}$(uname -m)${NC}"
    echo -e "  User:    ${YELLOW}$(whoami)${NC}"
    echo -e "  Uptime:  ${GREEN}$(uptime -p 2>/dev/null || uptime)${NC}"
    echo
}

memory_info() {
    # uses free (available on Termux)
    total=$(free -m | awk '/Mem:/ {print $2}' 2>/dev/null || echo 0)
    used=$(free -m | awk '/Mem:/ {print $3}' 2>/dev/null || echo 0)
    if [ "$total" -eq 0 ]; then
        echo -e "${RED}Memory info unavailable${NC}\n"
        return
    fi
    percent=$((100 * used / total))
    echo -e "${CYAN}📊 Memory Usage${NC}"
    echo -e "  Total: ${YELLOW}${total} MB${NC}"
    echo -e "  Used:  ${YELLOW}${used} MB${NC}"
    echo -n "  Usage: "
    progress_bar "$percent"
    echo
}

storage_info() {
    echo -e "${CYAN}💾 Storage Info${NC}"
    # try /data first (Android), fallback to /
    if df -h /data >/dev/null 2>&1; then
        df -h /data | awk 'NR==2 {print "  Used: " $3 " / " $2 " (" $5 ")"}'
        percent=$(df /data | awk 'NR==2 {gsub("%",""); print $5}')
    else
        df -h / | awk 'NR==2 {print "  Used: " $3 " / " $2 " (" $5 ")"}'
        percent=$(df / | awk 'NR==2 {gsub("%",""); print $5}')
    fi
    [ -z "$percent" ] && percent=0
    echo -n "  Storage: "
    progress_bar "$percent"
    echo
}

battery_info() {
    echo -e "${CYAN}🔋 Battery Info${NC}"
    if command -v termux-battery-status >/dev/null 2>&1; then
        data=$(termux-battery-status)
        percent=$(echo "$data" | grep -o '"percentage":[0-9]*' | cut -d: -f2)
        status=$(echo "$data" | grep -o '"status":"[^"]*"' | cut -d: -f2 | tr -d '"')
        echo -e "  Level:  ${YELLOW}${percent}%${NC}"
        echo -e "  Status: ${GREEN}${status}${NC}"
    else
        echo -e "  ${RED}Install termux-api for battery info (pkg install termux-api)${NC}"
    fi
    echo
}

cpu_info() {
    echo -e "${CYAN}⚙️ CPU Info${NC}"
    model=$(grep -m1 -E 'Hardware|model name' /proc/cpuinfo 2>/dev/null | cut -d ':' -f2 | sed 's/^ //' )
    model=${model:-N/A}
    cores=$(nproc 2>/dev/null || echo N/A)
    echo -e "  Model: ${YELLOW}${model}${NC}"
    echo -e "  Cores: ${GREEN}${cores}${NC}"
    echo
}

network_info() {
    echo -e "${CYAN}🌐 Network Info${NC}"
    if command -v termux-wifi-connectioninfo >/dev/null 2>&1; then
        ssid=$(termux-wifi-connectioninfo | grep -o '"ssid":"[^"]*"' | cut -d: -f2 | tr -d '"')
        ip=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        echo -e "  Wi-Fi: ${YELLOW}${ssid:-N/A}${NC}"
        echo -e "  IP:    ${GREEN}${ip:-N/A}${NC}"
    else
        echo -e "  ${RED}Install termux-api for Wi-Fi info (pkg install termux-api)${NC}"
    fi
    echo
}

big_files() {
    echo -e "${CYAN}🔍 Top 10 Largest Files (home)${NC}"
    # list top 10 by size in MB
    find "$HOME" -type f -printf "%s %p\n" 2>/dev/null | sort -rn | head -n 10 |
        awk '{printf " %7.2f MB  %s\n", $1/1048576, $2}'
    echo
}

clean_system() {
    echo -e "${CYAN}🧹 Cleaning Cache...${NC}"
    rm -rf /data/data/com.termux/files/usr/tmp/* >/dev/null 2>&1
    rm -rf /data/data/com.termux/files/usr/var/cache/* >/dev/null 2>&1
    echo -e "${GREEN}✔️ Cleaned temporary files (where possible).${NC}\n"
}

# ---------- MAIN MENU ----------
while true; do
    clear
    skull_banner
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${BOLD}       🧠 SYSTEM PRO MONITOR v3${NC}"
    echo -e "${GREEN}=============================================${NC}\n"
    echo -e "${YELLOW}1)${NC} System Info"
    echo -e "${YELLOW}2)${NC} Memory Usage"
    echo -e "${YELLOW}3)${NC} Storage Info"
    echo -e "${YELLOW}4)${NC} Battery Info"
    echo -e "${YELLOW}5)${NC} CPU Info"
    echo -e "${YELLOW}6)${NC} Network Info"
    echo -e "${YELLOW}7)${NC} Big Files"
    echo -e "${YELLOW}8)${NC} Clean System"
    echo -e "${YELLOW}9)${NC} Exit"
    echo
    read -p "Choose option: " opt
    clear

    case "$opt" in
        1) system_info ;;
        2) memory_info ;;
        3) storage_info ;;
        4) battery_info ;;
        5) cpu_info ;;
        6) network_info ;;
        7) big_files ;;
        8) clean_system ;;
        9) echo -e "${RED}👋 Bye veer, stay techy!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}" ;;
    esac

    echo
    read -n1 -r -p "Press any key to continue..."
done
