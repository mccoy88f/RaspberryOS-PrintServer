# 🖨️ RaspberryOS Print Server

Un script completo per trasformare un Raspberry Pi in un potente print server con interfaccia web, gestione remota e supporto hotspot WiFi.

![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-A22846?style=for-the-badge&logo=Raspberry%20Pi&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![WiFi](https://img.shields.io/badge/WiFi-Hotspot-blue?style=for-the-badge)
![CUPS](https://img.shields.io/badge/CUPS-Print%20System-green?style=for-the-badge)

## ✨ Caratteristiche

- 🖨️ **Server di stampa CUPS** con interfaccia web completa
- 🌐 **Webmin** per gestione sistema remota
- 📡 **Hotspot WiFi** opzionale con DHCP integrato
- 🔓 **Stampa senza autenticazione** per accesso pubblico
- 🔌 **Auto-rilevamento** stampanti USB
- 📱 **Condivisione automatica** delle stampanti
- 🛠️ **Script di utilità** per gestione avanzata
- 📋 **Supporto driver** per le principali marche di stampanti

## 🚀 Installazione Rapida

### Prerequisiti
- Raspberry Pi con Raspberry Pi OS (Bookworm o superiore)
- Accesso SSH o terminale diretto
- Connessione Internet per il download dei pacchetti

### Installazione

1. **Scarica lo script:**
```bash
wget https://raw.githubusercontent.com/mccoy88f/RaspberryOS-PrintServer/main/setup-printserver.sh
chmod +x setup-printserver.sh
```

2. **Esegui la prima volta (Fase 1 - Aggiornamento sistema):**
```bash
sudo ./setup-printserver.sh
```
*Il sistema si riavvierà automaticamente*

3. **Esegui la seconda volta (Fase 2 - Installazione servizi):**
```bash
sudo ./setup-printserver.sh
```
*Completa l'installazione con le configurazioni*

### Configurazione Interattiva

Durante la Fase 2, lo script ti chiederà:

**Attivazione Hotspot WiFi:**
```
Vuoi attivare l'hotspot WiFi per il print server? [s/N]:
```

**Se scegli l'hotspot, potrai configurare:**
- 📶 **SSID** (nome rete): personalizzabile
- 🔐 **Password**: personalizzabile (min. 8 caratteri)
- 🌐 **IP Range**: 192.168.4.2-192.168.4.20 (automatico)

## 🔧 Modalità Operative

### 🌐 Modalità Hotspot WiFi
- Il Raspberry Pi crea una rete WiFi dedicata
- DHCP integrato per assegnazione automatica IP
- Accesso diretto ai servizi tramite IP fisso

**Accesso ai servizi:**
- 🖨️ **CUPS**: `http://192.168.4.1:631`
- ⚙️ **Webmin**: `https://192.168.4.1:10000`
- 🔧 **SSH**: `ssh pi@192.168.4.1`

### 🏠 Modalità Rete Locale
- Il Raspberry Pi si connette alla rete esistente
- Servizi accessibili tramite IP locale
- Configurazione WiFi manuale se necessaria

**Scopri l'IP corrente:**
```bash
/usr/local/bin/network-info.sh
```

## 📱 Utilizzo

### Aggiunta Stampanti
1. **Collega stampante USB** al Raspberry Pi
2. **Auto-rilevamento**: La stampante viene automaticamente condivisa
3. **Configurazione manuale**: Vai su CUPS web interface se necessario

### Comandi Utili

```bash
# Gestione stampanti
/usr/local/bin/printer-utils.sh status          # Stato servizi
/usr/local/bin/printer-utils.sh list            # Lista stampanti
/usr/local/bin/printer-utils.sh share-all       # Condividi tutte le stampanti
/usr/local/bin/printer-utils.sh test            # Test di stampa

# Gestione hotspot (solo se configurato)
sudo /usr/local/bin/start-hotspot.sh            # Avvia hotspot
sudo /usr/local/bin/stop-hotspot.sh             # Ferma hotspot

# Info rete (modalità rete locale)
/usr/local/bin/network-info.sh                  # Mostra IP e servizi
```

## 🛠️ Configurazione Avanzata

### Credenziali Webmin
- **Username**: `pi`
- **Password**: *stessa password dell'utente pi*

### Stampanti Supportate
Lo script installa driver per:
- **HP**: driver HPLIP completi
- **Brother**: driver laser e inkjet
- **Canon**: driver ESCPR
- **Epson**: driver Gutenprint
- **Generic**: driver universali PostScript/PCL

### Porte e Servizi
- **CUPS**: porta 631 (HTTP)
- **Webmin**: porta 10000 (HTTPS)
- **SSH**: porta 22
- **DHCP**: range 192.168.4.2-192.168.4.20 (modalità hotspot)

## 🔍 Risoluzione Problemi

### Riavvio Servizi
```bash
sudo systemctl restart cups
sudo systemctl restart hostapd dnsmasq  # solo modalità hotspot
```

### Log di Sistema
```bash
# Log CUPS
sudo tail -f /var/log/cups/error_log

# Log generale
sudo journalctl -f

# Stato servizi
systemctl status cups hostapd dnsmasq webmin
```

### Problemi Comuni

**Stampante non rilevata:**
```bash
lsusb                                           # Verifica rilevamento USB
sudo /usr/local/bin/setup-printer-sharing.sh   # Riconfigura condivisione
```

**Hotspot non funziona:**
```bash
sudo systemctl status hostapd                  # Verifica stato hostapd
sudo systemctl restart hostapd dnsmasq         # Riavvia servizi
```

**Problemi di rete:**
```bash
ip addr show                                    # Verifica configurazione IP
sudo systemctl restart networking              # Riavvia rete
```

## 📋 File Generati dal Setup

Lo script `setup-printserver.sh` crea automaticamente questi file di utilità durante l'installazione:

```
/usr/local/bin/
├── start-hotspot.sh          # Script per avviare hotspot
├── stop-hotspot.sh           # Script per fermare hotspot  
├── setup-printer-sharing.sh  # Configurazione condivisione stampanti
├── printer-utils.sh          # Utility gestione stampanti
└── network-info.sh           # Info rete (modalità locale)

/home/pi/
└── PRINT_SERVER_INFO.txt     # Documentazione completa del sistema

/etc/
├── cups/cupsd.conf           # Configurazione CUPS
├── hostapd/hostapd.conf      # Configurazione hotspot (se abilitato)
└── dnsmasq.conf              # Configurazione DHCP (se abilitato)
```

> **🎯 Importante**: Non devi scaricare questi file manualmente! Vengono creati automaticamente durante l'installazione.

## 🤝 Contribuire

I contributi sono benvenuti! Per contribuire:

1. Fai un fork del repository
2. Crea un branch per la tua feature (`git checkout -b feature/nuova-feature`)
3. Commit delle modifiche (`git commit -am 'Aggiunge nuova feature'`)
4. Push del branch (`git push origin feature/nuova-feature`)
5. Apri una Pull Request

## 📄 Licenza

Questo progetto è rilasciato sotto licenza MIT. Vedi il file `LICENSE` per i dettagli.

## 👨‍💻 Autore

**McCoy88f**
- GitHub: [@mccoy88f](https://github.com/mccoy88f)
- Repository: [RaspberryOS-PrintServer](https://github.com/mccoy88f/RaspberryOS-PrintServer)

## ⭐ Supporta il Progetto

Se questo progetto ti è stato utile, lascia una ⭐ star su GitHub!

## 📊 Compatibilità

| Raspberry Pi | Raspberry Pi OS | Stato |
|--------------|-----------------|-------|
| Pi 4 Model B | Bookworm | ✅ Testato |
| Pi 3 Model B+ | Bookworm | ✅ Testato |
| Pi Zero 2 W | Bookworm | ⚠️ Limitato* |
| Pi 5 | Bookworm | ✅ Compatibile |

*\*Pi Zero 2 W: funzionalità limitate per prestazioni hardware*

---

## 🔗 Link Utili

- [Documentazione CUPS](https://www.cups.org/doc/)
- [Webmin Official Site](https://www.webmin.com/)
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)

**Trasforma il tuo Raspberry Pi in un print server professionale in pochi minuti! 🚀**
