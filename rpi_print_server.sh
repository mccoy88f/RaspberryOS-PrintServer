#!/bin/bash

# Script per configurare Raspberry Pi come Print Server con CUPS, Webmin e WiFi Hotspot
# Raspberry Pi OS Print Server Setup Script
# Autore: McCoy88f - https://github.com/mccoy88f/RaspberryOS-PrintServer

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurazioni
HOTSPOT_SSID="RPi-PrintServer"
HOTSPOT_PASSWORD="printserver123"
HOTSPOT_INTERFACE="wlan0"
DHCP_RANGE_START="192.168.4.2"
DHCP_RANGE_END="192.168.4.20"
DHCP_SUBNET="192.168.4.0/24"
HOTSPOT_IP="192.168.4.1"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Raspberry Pi Print Server Setup Script${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Funzione per logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Verifica se lo script viene eseguito come root
if [[ $EUID -ne 0 ]]; then
   error "Questo script deve essere eseguito come root (usa sudo)"
fi

# Aggiorna il sistema
log "Aggiornamento del sistema..."
apt update -y
apt upgrade -y

# Installa dipendenze base
log "Installazione dipendenze base..."
apt install -y wget curl git vim nano htop

# Installa CUPS e driver stampanti
log "Installazione CUPS e driver stampanti..."
apt install -y cups cups-bsd cups-client cups-filters
apt install -y printer-driver-all printer-driver-cups-pdf
apt install -y hplip printer-driver-hpijs
apt install -y printer-driver-gutenprint
apt install -y printer-driver-escpr
apt install -y avahi-daemon avahi-utils

# Configura CUPS
log "Configurazione CUPS..."
cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.backup

cat > /etc/cups/cupsd.conf << 'EOF'
# Configuration file for the CUPS scheduler
LogLevel warn
MaxLogSize 0
Listen localhost:631
Listen /var/run/cups/cups.sock
Listen 0.0.0.0:631

Browsing On
BrowseLocalProtocols dnssd
DefaultAuthType Basic
WebInterface Yes

<Location />
  Order allow,deny
  Allow all
</Location>

<Location /admin>
  Order allow,deny
  Allow all
</Location>

<Location /admin/conf>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow all
</Location>

<Location /admin/log>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow all
</Location>

<Policy default>
  JobPrivateAccess default
  JobPrivateValues default
  SubscriptionPrivateAccess default
  SubscriptionPrivateValues default
  <Limit Create-Job Print-Job Print-URI Validate-Job>
    Order deny,allow
  </Limit>
  <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Document-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job Cancel-My-Jobs Close-Job CUPS-Move-Job CUPS-Get-Document>
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>
  <Limit CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Add-Modify-Class CUPS-Delete-Class CUPS-Set-Default CUPS-Get-Devices>
    AuthType Default
    Require user @SYSTEM
    Order deny,allow
  </Limit>
  <Limit Pause-Printer Resume-Printer Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After Cancel-Jobs CUPS-Accept-Jobs CUPS-Reject-Jobs>
    AuthType Default
    Require user @SYSTEM
    Order deny,allow
  </Limit>
  <Limit Cancel-Job CUPS-Authenticate-Job>
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>
  <Limit All>
    Order deny,allow
  </Limit>
</Policy>
EOF

# Aggiungi utente pi al gruppo lpadmin
log "Aggiunta utente pi al gruppo lpadmin..."
usermod -a -G lpadmin pi

# Abilita e avvia CUPS
systemctl enable cups
systemctl start cups

# Installa Webmin
log "Installazione Webmin..."
cd /tmp
wget https://prdownloads.sourceforge.net/webadmin/webmin_2.105_all.deb
apt install -y ./webmin_2.105_all.deb || {
    # Se l'installazione fallisce, prova con le dipendenze
    apt install -f -y
    dpkg -i webmin_2.105_all.deb
}

# Configura Webmin
log "Configurazione Webmin..."
systemctl enable webmin
systemctl start webmin

# Installa software per hotspot
log "Installazione software per WiFi Hotspot..."
apt install -y hostapd dnsmasq iptables-persistent

# Ferma i servizi temporaneamente
systemctl stop hostapd
systemctl stop dnsmasq

# Configura hostapd
log "Configurazione hostapd..."
cat > /etc/hostapd/hostapd.conf << EOF
interface=$HOTSPOT_INTERFACE
driver=nl80211
ssid=$HOTSPOT_SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$HOTSPOT_PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# Imposta il percorso del file di configurazione hostapd
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd

# Configura dnsmasq
log "Configurazione dnsmasq..."
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup

cat > /etc/dnsmasq.conf << EOF
# Configuration file for dnsmasq
interface=$HOTSPOT_INTERFACE
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.0,24h
domain=local
address=/gw.local/$HOTSPOT_IP
address=/printserver.local/$HOTSPOT_IP
EOF

# Configura l'interfaccia di rete statica per l'hotspot
log "Configurazione interfaccia di rete..."
cat >> /etc/dhcpcd.conf << EOF

# Static IP configuration for hotspot
interface $HOTSPOT_INTERFACE
static ip_address=$HOTSPOT_IP/24
nohook wpa_supplicant
EOF

# Abilita l'IP forwarding
log "Abilitazione IP forwarding..."
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

# Configura iptables per NAT (se c'è una connessione ethernet)
log "Configurazione iptables..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o $HOTSPOT_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $HOTSPOT_INTERFACE -o eth0 -j ACCEPT

# Salva le regole iptables
netfilter-persistent save

# Crea script per avviare l'hotspot
log "Creazione script di avvio hotspot..."
cat > /usr/local/bin/start-hotspot.sh << 'EOF'
#!/bin/bash
# Script per avviare l'hotspot WiFi

# Ferma wpa_supplicant se attivo
sudo systemctl stop wpa_supplicant

# Avvia i servizi
sudo systemctl start hostapd
sudo systemctl start dnsmasq

echo "Hotspot WiFi avviato!"
echo "SSID: RPi-PrintServer"
echo "Password: printserver123"
echo "IP Address: 192.168.4.1"
echo ""
echo "CUPS Web Interface: http://192.168.4.1:631"
echo "Webmin Interface: https://192.168.4.1:10000"
EOF

chmod +x /usr/local/bin/start-hotspot.sh

# Crea script per fermare l'hotspot
cat > /usr/local/bin/stop-hotspot.sh << 'EOF'
#!/bin/bash
# Script per fermare l'hotspot WiFi

sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Riavvia wpa_supplicant per connettersi alle reti WiFi
sudo systemctl start wpa_supplicant

echo "Hotspot WiFi fermato!"
EOF

chmod +x /usr/local/bin/stop-hotspot.sh

# Abilita i servizi per l'avvio automatico
log "Abilitazione servizi per l'avvio automatico..."
systemctl enable hostapd
systemctl enable dnsmasq

# Configura avvio automatico dell'hotspot
cat > /etc/systemd/system/printserver-hotspot.service << 'EOF'
[Unit]
Description=Print Server WiFi Hotspot
After=multi-user.target
Conflicts=wpa_supplicant.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/start-hotspot.sh
RemainAfterExit=yes
ExecStop=/usr/local/bin/stop-hotspot.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl enable printserver-hotspot.service

# Installa driver aggiuntivi se necessario
log "Installazione driver aggiuntivi..."
apt install -y printer-driver-brlaser printer-driver-c2050 printer-driver-foo2zjs

# Configura Avahi per la scoperta delle stampanti
log "Configurazione Avahi..."
systemctl enable avahi-daemon
systemctl start avahi-daemon

# Crea script di utilità per gestire le stampanti
cat > /usr/local/bin/printer-utils.sh << 'EOF'
#!/bin/bash
# Utility per gestire le stampanti

case "$1" in
    "list")
        echo "Stampanti installate:"
        lpstat -p -d
        ;;
    "add")
        echo "Per aggiungere una stampante, usa il web interface:"
        echo "http://192.168.4.1:631/admin"
        ;;
    "status")
        echo "Stato servizi:"
        echo "CUPS: $(systemctl is-active cups)"
        echo "Hotspot: $(systemctl is-active hostapd)"
        echo "DHCP: $(systemctl is-active dnsmasq)"
        echo "Webmin: $(systemctl is-active webmin)"
        ;;
    *)
        echo "Uso: $0 {list|add|status}"
        ;;
esac
EOF

chmod +x /usr/local/bin/printer-utils.sh

# Crea documentazione
log "Creazione documentazione..."
cat > /home/pi/PRINT_SERVER_INFO.txt << 'EOF'
=== RASPBERRY PI PRINT SERVER ===

CONFIGURAZIONE COMPLETATA!

ACCESSO AI SERVIZI:
- CUPS Web Interface: http://192.168.4.1:631
- Webmin: https://192.168.4.1:10000
- SSH: ssh pi@192.168.4.1

HOTSPOT WIFI:
- SSID: RPi-PrintServer
- Password: printserver123
- IP Range: 192.168.4.2 - 192.168.4.20

COMANDI UTILI:
- Avvia hotspot: sudo /usr/local/bin/start-hotspot.sh
- Ferma hotspot: sudo /usr/local/bin/stop-hotspot.sh
- Stato stampanti: /usr/local/bin/printer-utils.sh status
- Lista stampanti: /usr/local/bin/printer-utils.sh list

AGGIUNTA STAMPANTI:
1. Collega la stampante USB al Raspberry Pi
2. La stampante verrà automaticamente condivisa senza autenticazione
3. Per configurazione manuale: http://192.168.4.1:631/admin
4. Le stampanti sono accessibili da qualsiasi dispositivo connesso al WiFi

STAMPA SENZA AUTENTICAZIONE:
- Tutte le stampanti sono configurate per accesso pubblico
- Non è richiesta alcuna password per stampare
- Le stampanti USB vengono automaticamente condivise quando collegate

COMANDI AGGIUNTIVI:
- Condividi tutte stampanti: /usr/local/bin/printer-utils.sh share-all
- Test stampa: /usr/local/bin/printer-utils.sh test
- Condividi stampante specifica: /usr/local/bin/printer-utils.sh share NOME_STAMPANTE

CREDENZIALI WEBMIN:
- Username: pi
- Password: [la stessa password dell'utente pi]

RISOLUZIONE PROBLEMI:
- Riavvia servizi: sudo systemctl restart cups hostapd dnsmasq
- Log CUPS: sudo tail -f /var/log/cups/error_log
- Log sistema: sudo journalctl -f

Per supporto: controlla i log con journalctl o i file in /var/log/
EOF

chown pi:pi /home/pi/PRINT_SERVER_INFO.txt

log "Pulizia file temporanei..."
rm -f /tmp/webmin_*.deb

log "Configurazione completata!"
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  INSTALLAZIONE COMPLETATA CON SUCCESSO!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${BLUE}Il sistema si riavvierà automaticamente in 10 secondi...${NC}"
echo ""
if [ "$ENABLE_HOTSPOT" = true ]; then
    echo -e "${YELLOW}Dopo questo riavvio finale:${NC}"
    echo -e "- Hotspot WiFi: ${GREEN}$HOTSPOT_SSID${NC}"
    echo -e "- Password: ${GREEN}$HOTSPOT_PASSWORD${NC}"
    echo -e "- CUPS: ${GREEN}http://192.168.4.1:631${NC}"
    echo -e "- Webmin: ${GREEN}https://192.168.4.1:10000${NC}"
else
    echo -e "${YELLOW}Dopo questo riavvio finale:${NC}"
    echo -e "- CUPS disponibile sulla rete locale${NC}"
    echo -e "- Usa ${GREEN}/usr/local/bin/network-info.sh${NC} per vedere l'IP"
    echo -e "- Configura WiFi con ${GREEN}sudo raspi-config${NC} se necessario"
fi
echo ""
echo -e "${YELLOW}Leggi /home/pi/PRINT_SERVER_INFO.txt per i dettagli completi${NC}"

sleep 10
reboot