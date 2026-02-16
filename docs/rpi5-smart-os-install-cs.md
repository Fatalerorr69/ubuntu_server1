# RPi5 SmartOS Blueprint (CZ)

## 1) Cíl platformy

Cílem je postavit na **Raspberry Pi 5** jednu inteligentní, modulární platformu se 3 režimy:

- **Home/NAS uzel** (souborový server, zálohy, media, VPN)
- **SmartHome řídicí uzel** (Home Assistant + automatizace)
- **Robot/Edge AI uzel** (MQTT, Node-RED/ROS2, inference)

Návrh je připraven pro:

- boot/data na **SSD přes USB 3.0**
- boot/data na **NVMe přes PCIe HAT**
- lokální ovládání na **3.5" LCD**
- co nejvyšší automatizaci (IaC, služby, health-checky, self-healing)

---

## 2) Doporučený hardware

## Varianta A: USB SSD

- RPi 5 (8 GB doporučeno)
- USB 3.0 SSD (500 GB+)
- kvalitní USB-SATA/NVMe bridge s UASP
- oficiální 27W PSU (stabilita)
- aktivní chlazení
- microSD pouze pro recovery (volitelné)

## Varianta B: NVMe HAT

- RPi 5 + PCIe/NVMe HAT kompatibilní s RPi5
- NVMe 2280 SSD (1 TB doporučeno)
- aktivní chlazení (HAT + SoC)
- oficiální 27W PSU

## LCD 3.5"

- preferuj model s aktivně udržovaným ovladačem
- pokud je to SPI model: počítej s nižším výkonem GUI
- pokud je to HDMI model: jednodušší integrace a lepší kompatibilita

---

## 3) Doporučený software stack

- **OS Base**: Raspberry Pi OS 64-bit (Bookworm) nebo Ubuntu Server 24.04 LTS (arm64)
- **Orchestrace služeb**: Docker + Docker Compose
- **Automatizace**: Ansible + systemd timers
- **Storage**: ext4/XFS (jednoduchost) nebo btrfs (snapshoty)
- **NAS**: Samba + NFS + optional MinIO
- **SmartHome**: Home Assistant + Mosquitto + Zigbee2MQTT
- **Robot/IoT**: Node-RED + MQTT + (volitelně ROS2)
- **AI**: Ollama (menší modely), OpenWebUI / vlastní API vrstva
- **Monitoring**: Prometheus + Node Exporter + Grafana + Loki/Promtail
- **Bezpečnost**: UFW/nftables, Fail2ban, MFA admin workflow, WireGuard
- **Zálohy**: restic + offsite (S3/Backblaze/NAS2)

### „AI mozek přímo v OS" (doporučené komponenty)

- **`brain-core`** (systemd služba): centrální plánovač akcí a pravidel
- **`brain-api`**: lokální REST/gRPC API (`127.0.0.1`) pro interní moduly
- **`brain-agents`**: specializovaní agenti (NAS, síť, SmartHome, robot, security)
- **`brain-memory`**: vektorová + relační paměť (historie incidentů, doporučení)
- **`brain-policy`**: policy engine (co může AI provést automaticky)
- **`brain-ui`**: stav, návrhy, schvalování akcí, audit trail

Praktický princip:

- AI neběží „mimo", ale jako nativní OS vrstva s jasnou strukturou `/opt/brain`, `/etc/brain`, `/var/lib/brain`.
- Každý AI zásah má **ID události, důvod, vstupy a výstup**, aby šel auditovat.
- Kritické akce (firewall, síť, storage) vyžadují explicitní policy + volitelně manuální schválení.

---

## 4) Disk layout (doporučení)

## USB SSD / NVMe společný layout

1. `EFI` 512 MB (FAT32)
2. `BOOT` 1 GB (ext4)
3. `ROOT` 60–120 GB
4. `DATA` zbytek disku (`/srv`)

Mountpointy:

- `/srv/nas`
- `/srv/smarthome`
- `/srv/robot`
- `/srv/ai`
- `/srv/backups`
- `/srv/containers`

Doporučení:

- `noatime` mount options
- pravidelný `fstrim.timer`
- smartctl monitoring + alerty

---

## 5) Boot scénáře

## A) Boot z USB SSD

1. aktualizuj EEPROM (`rpi-eeprom-update -a`)
2. nastav USB boot prioritu (raspi-config / boot-order)
3. zapiš OS image přímo na SSD
4. první boot bez microSD (ověření skutečného USB boot)

## B) Boot z NVMe HAT

1. aktualizuj EEPROM + firmware
2. ověř PCIe mode (`dtparam=pciex1` případně gen2/gen3 dle stability)
3. nainstaluj systém na NVMe
4. ověř trvalý boot bez microSD

Poznámka: u některých HAT/SSD kombinací je nutné snížit PCIe rychlost kvůli stabilitě.

---

## 6) LCD 3.5" integrace

## SPI LCD

- aktivuj SPI (`raspi-config`)
- doinstaluj vendor driver dle konkrétního panelu
- nastav rotaci/fbcon mapování
- lehké UI (Kiosk dashboard, ne plné desktop prostředí)

## HDMI LCD

- nastav fixní rozlišení v boot configu
- přepni na Kiosk režim (Chromium/Fullscreen dashboard)

Lokální ovládací panel doporučeno:

- „Status“ (teplota, load, disk)
- „NAS“ (využití, klienti)
- „SmartHome“ (stavy zařízení)
- „Robot“ (MQTT/mission queue)
- „AI“ (dostupnost modelu, token usage)

---

## 7) Architektura služeb (modulární)

## Core vrstva

- SSH hardening
- firewall
- čas/NTP
- log forwarding
- secrets management (sops/age)

## NAS vrstva

- Samba share profily: `public`, `family`, `admin`, `robot-data`
- NFS pro Linux klienty
- snapshot + retence
- backup policy (3-2-1)

## SmartHome vrstva

- Home Assistant (container)
- Mosquitto (MQTT)
- Zigbee2MQTT (USB coordinator)
- automatizační pravidla s fallback logikou

## Robot vrstva

- MQTT topics namespace (`robot/<id>/...`)
- Node-RED flows pro orchestrace
- volitelně ROS2 bridge
- watchdog pro kritické uzly

## AI vrstva (centrální mozek)

- orchestrátor jako systemd služba: `brain-orchestrator.service`
- vstupy: metriky, logy, MQTT eventy, API události
- výstupy: doporučení, akce, notifikace, plánovač úloh
- režimy:
  - **Observe** (jen doporučuje)
  - **Assist** (spouští schválené workflow)
  - **Auto** (plná automatizace dle policy)

### Interní AI workflow (doporučený cyklus)

1. **Sběr**: logy + metriky + MQTT + síťové události
2. **Detekce**: pravidla + anomálie (AIOps)
3. **Návrh**: AI vytvoří konkrétní remediation plán
4. **Policy check**: ACL/RBAC + rizikové skóre
5. **Akce**: automaticky nebo po schválení
6. **Verifikace**: health-check po zásahu + rollback při neúspěchu
7. **Učení**: uložení výsledku do knowledge base

### Agenti AI mozku (minimum)

- `agent-system`: CPU/RAM/teplota/napájení
- `agent-network`: latence, packet loss, DNS, VPN, firewall drift
- `agent-storage`: SMART, I/O latence, snapshot integrity
- `agent-smarthome`: automations health, MQTT backlog
- `agent-robot`: telemetry watchdog, mission queue
- `agent-security`: audit, IOC korelace, brute-force detekce

---

## 7.1) Penetrační a síťové nástroje (legální bezpečnostní režim)

Používej výhradně na vlastní infrastruktuře nebo s písemným oprávněním.

### Síťová diagnostika a troubleshooting

- `nmap`, `masscan` (opatrně), `arp-scan`
- `tcpdump`, `wireshark` (remote capture), `mtr`, `iperf3`
- `ethtool`, `iftop`, `nethogs`, `vnstat`
- `dig`, `kdig`, `drill`, `whois`

### Bezpečnostní testy a audity

- `nikto`, `testssl.sh`, `sslyze`
- `lynis`, `rkhunter`, `chkrootkit`
- `nuclei` (šablonové kontroly)
- `sqlmap` / `wpscan` pouze při autorizovaném scope

### Provozní model nástrojů

- Režim **LAB**: plná sada nástrojů v izolované VLAN
- Režim **PROD**: read-only diagnostika + schvalované testy
- Veškeré skeny logovat: kdo, kdy, proti čemu, proč, výsledek
- Doporučeno spouštět přes „security-runner" službu s RBAC

---

## 7.2) Kontrola stavu a chodu celé OS (NOC panel)

### Kritické health-checky

- Napájení/undervoltage (`vcgencmd get_throttled`)
- Teploty SoC/NVMe + thermal throttling
- Stav filesystemu + volné místo + inody
- Stav kontejnerů + restart smyčky
- Dostupnost NAS share, MQTT, HA, robot control topics
- Latence LAN/WAN + DNS resolver health

### „Semafor" pro rychlou orientaci

- **Zelená**: vše OK
- **Oranžová**: degradace výkonu/služby
- **Červená**: kritický stav, aktivní fallback/rollback

### Automatické reakce OS

- při přehřátí: snížení zátěže AI + fan profile + alert
- při chybách SSD: read-only mode vybraných služeb + snapshot
- při pádu VPN: zablokování admin endpointů z internetu
- při výpadku MQTT: bufferování robot/smarthome událostí

---

## 8) Automatizace „co nejvíce chytrý OS“

Implementuj 4 úrovně automatizace:

1. **Provisioning** – cloud-init/Ansible one-shot
2. **Lifecycle** – unattended updates + maintenance windows
3. **Self-healing** – systemd restart policies + health checks
4. **AIOps** – korelace metrik/logů a návrhy zásahů

Praktické mechanismy:

- `systemd` unit s `Restart=always`
- `systemd` timers: trim, backup, integrity check
- health endpointy každé služby
- centrální notifikace (Telegram/Matrix/Email)
- „safe mode“ profil při přehřátí/low-voltage

---

## 9) Security baseline

- pouze SSH klíče, zákaz password login
- oddělené role: `admin`, `ops`, `viewer`, `robot`
- MFA pro kritické UI (reverse proxy + IdP)
- VPN-only management (WireGuard)
- audit trail všech automatických akcí AI
- pravidelné vulnerability skeny interních služeb

---

## 10) Postup instalace (produkční runbook)

1. Sestav HW + chlazení + napájení
2. Flash OS na SSD/NVMe
3. První boot, update firmware/EEPROM
4. Základní hardening (SSH, firewall, uživatelé)
5. Připojení disku a mountpointů `/srv/*`
6. Instalace Docker/Compose
7. Nasazení stacku:
   - NAS
   - SmartHome
   - Robot
   - AI + monitoring
8. Integrace LCD dashboardu
9. Nastavení záloh a disaster recovery test
10. Burn-in test 24–72 h (teplota, I/O, stabilita)

### 10.1) Doporučené automatizované instalační profily

- `profile-nas.yaml`
- `profile-smarthome.yaml`
- `profile-robot.yaml`
- `profile-ai-core.yaml`
- `profile-security-lab.yaml`

V praxi: vybereš profil a installer složí výsledný stack bez ručního zásahu.

---

## 11) Doporučená struktura repozitáře

```text
infra/
  ansible/
  compose/
  scripts/
services/
  nas/
  smarthome/
  robot/
  ai-brain/
ops/
  backup/
  monitoring/
  recovery/
docs/
  runbooks/
  wiring/
  lcd/
```

---

## 12) KPI (jak poznat, že je systém „hotový“)

- uptime > 99.5 %
- obnova ze zálohy < 30 minut
- reboot-to-ready < 180 s
- AI orchestrátor reaguje < 2 s na event
- teplota SoC stabilně pod safe limitem
- 100 % kritických služeb má health-check + alert
- MTTR (mean time to recovery) < 10 minut u běžných incidentů
- počet neautorizovaných změn konfigurace = 0

---

## 13) Co zapnout jako první (MVP pořadí)

1. Core + hardening
2. NAS + backup
3. Home Assistant + MQTT
4. Monitoring + alerting
5. AI orchestrátor v režimu Observe
6. Robot integrace
7. Auto režim po 2–4 týdnech stabilního provozu

---

## 14) Poznámky k výkonu na RPi5

- AI modely drž menší (3B–8B quantized)
- preferuj event-driven automatizaci místo heavy polling
- limity CPU/RAM na kontejnery (`cpus`, `mem_limit`)
- log retention rozumně (Pi není SIEM server)
- pro náročnější AI přidej externí inference node

---

## 15) Minimální checklist před ostrým provozem

- [ ] ověřený boot bez microSD
- [ ] recovery image + recovery postup
- [ ] funkční snapshots/backup restore test
- [ ] VPN-only management
- [ ] alerting při výpadku, teplotě, low-voltage, plném disku
- [ ] dokumentovaný upgrade postup
- [ ] LCD panel zobrazuje klíčové provozní stavy

---

## 16) Další návrhy vylepšení (roadmapa)

1. **GitOps konfigurace**
   - veškeré `/etc` šablony držet v Gitu
   - rollout přes CI, ne ruční editace

2. **Digitální dvojče konfigurace**
   - testovací VM s identickou konfigurací před ostrým nasazením

3. **Federace více RPi uzlů**
   - 1× řídicí node + N worker node pro robotiku/AI inferenci

4. **Voice + lokální HMI vrstva**
   - lokální hlasové příkazy pro scénáře („zálohuj", „safe mode", „restart robot")

5. **Offline-first mód**
   - při výpadku internetu zachovat klíčové služby (NAS, HA, robot orchestrace)

6. **Automatické kapacitní plánování**
   - AI předpovídá růst dat, zátěž a doporučí upgrade disků/služeb

7. **Hardening úrovně enterprise**
   - TPM/HSM pro klíče (pokud HW dovolí), signed updates, immutable části OS

8. **Self-service portál**
   - uživatel s rolí může požádat o službu/modul, AI vyhodnotí dopad a připraví rollout

Tento blueprint je navržen tak, aby šel postupně automatizovat do plně deklarativního provozu (GitOps + Ansible + Compose), ale zároveň byl praktický pro domácí i poloprofesionální nasazení na jednom RPi5.

---

## 17) Další funkce a nástroje (rozšířená výbava)

### Provozní a systémové funkce

- **UPS integrace** (NUT): bezpečné vypnutí při výpadku napájení
- **Netboot/Rescue mód**: PXE/iPXE recovery profil pro rychlou obnovu
- **QoS/SQM**: řízení provozu (CAKE/FQ_Codel) pro stabilní latenci
- **Lokální PKI**: interní certifikáty pro služby a mTLS
- **App katalog**: jednotný dashboard pro instalaci modulů jedním klikem
- **Energy mode**: automatické profily spotřeby (day/night)

### Nástroje pro správu a diagnostiku

- systém: `htop`, `btop`, `iotop`, `dstat`, `glances`
- storage: `smartmontools`, `nvme-cli`, `fio`, `hdparm`
- síť: `nftables`, `iproute2`, `mtr`, `iperf3`, `tcpdump`, `vnstat`
- kontejnery: `lazydocker`, `ctop`, `dive`
- backup/recovery: `restic`, `borgbackup`, `rclone`
- security: `lynis`, `aide`, `fail2ban`, `clamav` (podle use-case)

### Doporučené nové služby

- **Authentik/Keycloak** pro jednotné přihlášení
- **Traefik/Caddy** jako reverzní proxy s auto TLS
- **Uptime Kuma** pro dohled dostupnosti
- **Gitea + Runner** pro lokální GitOps
- **MinIO** pro objektové úložiště a zálohovací target

---

## 18) Přesný postup od nuly (krok za krokem)

Níže je minimální produkční postup pro RPi5 + SSD/NVMe. Cílem je mít funkční základ do 1 dne a stabilní chytrý OS do 2–3 dnů.

### 18.1 Co si připravit předem

1. Raspberry Pi 5, chlazení, 27W adaptér
2. SSD (USB) nebo NVMe + HAT
3. LCD 3.5" (SPI nebo HDMI)
4. PC pro flash image + LAN kabel
5. Účet do Git repa (pro konfigurace)

### 18.2 Flash systému

1. Stáhni Raspberry Pi Imager.
2. Vyber OS: **Raspberry Pi OS Lite 64-bit** (doporučeno pro server).
3. Zvol cílový disk (USB SSD nebo NVMe v USB boxu).
4. V Advanced Options nastav:
   - hostname (např. `rpi5-core`)
   - SSH enabled
   - přihlašovacího uživatele
   - Wi-Fi jen pokud opravdu potřebuješ (jinak LAN)
5. Zapiš image.

### 18.3 První boot a základní update

Po prvním startu se přihlas přes SSH a spusť:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo rpi-eeprom-update -a
sudo reboot
```

Po rebootu ověř:

```bash
uname -a
vcgencmd get_throttled
```

### 18.4 Boot z SSD/NVMe bez microSD

1. Vypni Pi.
2. Vyjmi microSD (pokud byla použita).
3. Zapni a ověř, že systém skutečně bootuje z SSD/NVMe.
4. Pokud nebootuje, oprav boot order v EEPROM config.

### 18.5 Základní hardening (hned)

```bash
sudo adduser ops
sudo usermod -aG sudo ops
sudo mkdir -p /home/ops/.ssh
sudo nano /home/ops/.ssh/authorized_keys
sudo chown -R ops:ops /home/ops/.ssh
sudo chmod 700 /home/ops/.ssh && sudo chmod 600 /home/ops/.ssh/authorized_keys

sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

sudo apt install -y ufw fail2ban
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable
```

### 18.6 Disky, mountpointy, trim

```bash
sudo mkdir -p /srv/{nas,smarthome,robot,ai,backups,containers}
sudo systemctl enable --now fstrim.timer
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
```

(Pokud máš nový disk bez FS, vytvoř ext4 a zapiš do `/etc/fstab`.)

### 18.7 Instalace Docker stacku

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
sudo apt install -y docker-compose-plugin
```

Ověření:

```bash
docker --version
docker compose version
```

### 18.8 Nasazení minimálního smart stacku

Pořadí:
1. Monitoring (Prometheus + Grafana + Node Exporter)
2. NAS (Samba/NFS)
3. SmartHome (Home Assistant + MQTT)
4. Robot (Node-RED + MQTT namespace)
5. AI mozek (`brain-core`, `brain-agents`, `brain-ui`)

Každou službu po nasazení ověř přes health endpoint a logy.

### 18.9 AI mozek – první spuštění

1. Vytvoř policy režim na **Observe** (ne Auto).
2. Zapni sběr metrik a logů.
3. Sleduj 48 hodin pouze doporučení AI.
4. Teprve poté přepni vybrané workflow do **Assist**.

### 18.10 LCD dashboard

- SPI: aktivovat SPI + vendor ovladač.
- HDMI: nastavit fixní rozlišení.
- Spustit kiosk panel se sekcemi Stav/NAS/SmartHome/Robot/AI.

### 18.11 Backup + test obnovy (povinné)

```bash
sudo apt install -y restic
restic init --repo /srv/backups/restic-repo
# nastav proměnné RESTIC_PASSWORD a proveď první backup
```

Povinně proveď test restore aspoň jednoho adresáře.

### 18.12 Burn-in a acceptance test

Po dobu 24–72 hodin sleduj:

- teplotu SoC/NVMe
- chyby v `dmesg`
- restarty kontejnerů
- latenci sítě
- stabilitu MQTT a Home Assistant automací

Pokud vše stabilní, přepni část AI workflow z Observe do Assist.

---

## 19) Co máš dělat přesně teď (rychlý start checklist)

1. **Dnes**: flash OS na SSD/NVMe, update firmware, SSH hardening.
2. **Dnes**: Docker + monitoring + NAS.
3. **Zítra**: Home Assistant + MQTT + Node-RED.
4. **Zítra**: AI mozek v Observe režimu.
5. **Den 3**: backup/restore test + alerting + LCD dashboard.
6. **Po týdnu**: přepnutí vybraných akcí AI do Assist režimu.

Tím získáš funkční, rozšiřitelnou a bezpečnou platformu „od nuly“ s jasným pořadím kroků.


---

## 20) Server-first režim (OS jako centrální server)

Cílové chování: celý systém běží primárně jako **headless server**, ke kterému se připojuješ vzdáleně z notebooku/mobilu.

### Přístupové cesty

- SSH (administrace, automatizace, údržba)
- Web konzole (Grafana, Home Assistant, AI UI, NAS panel)
- API přístup (interní služby + automatizace)
- VPN přístup (WireGuard) pro bezpečné řízení odkudkoliv

### Co získáš navíc oproti „běžnému desktop“ režimu

- vyšší stabilita a menší spotřeba RAM/CPU
- snadnější zálohování a obnova (vše běží jako služby)
- centrální dohled (jedno místo pro logy/metriky/alerty)
- bezpečnější provoz (RBAC, audit, VPN-only admin)
- lepší škálování (snadné přidání dalších RPi node)

### Doporučené nastavení server chování

1. vypnout zbytečné GUI služby
2. zapnout auto-start všech core služeb po bootu
3. nastavit watchdog + auto-restart kritických unit
4. aktivovat health-check endpointy pro všechny moduly
5. používat deklarativní konfiguraci (GitOps)

### Minimum server services, které mají běžet vždy

- `sshd`, `ufw/nftables`, `fail2ban`
- `docker`, `containerd`, stack služby
- `node-exporter`, `promtail` (nebo jiný log agent)
- `wireguard` (pro vzdálenou správu)
- `brain-core` + `brain-agents`

---

## 21) Start instalace OS právě teď (praktický kickoff)

Toto je přesné pořadí, kterým **teď hned začni**:

### Krok A – připrav médium

1. Připoj SSD/NVMe k PC.
2. Ve Raspberry Pi Imager nastav:
   - Raspberry Pi OS Lite 64-bit
   - hostname: `rpi5-server`
   - SSH: enabled
   - user + SSH key
3. Flash image.

### Krok B – první boot jako server

1. Zapoj LAN + napájení.
2. Přihlas se přes SSH.
3. Proveď update:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo rpi-eeprom-update -a
sudo reboot
```

### Krok C – zpevni server

```bash
sudo apt install -y ufw fail2ban
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable
sudo systemctl enable --now fail2ban
```

### Krok D – připrav datovou strukturu

```bash
sudo mkdir -p /srv/{nas,smarthome,robot,ai,backups,containers}
sudo systemctl enable --now fstrim.timer
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
```

### Krok E – nainstaluj runtime služeb

```bash
curl -fsSL https://get.docker.com | sh
sudo apt install -y docker-compose-plugin
docker --version
docker compose version
```

### Krok F – ověř server ready stav

- SSH funguje
- firewall běží
- disk je připojen
- Docker běží
- systém je bez throttlingu (`vcgencmd get_throttled`)

Pokud vše prošlo, pokračuj kapitolou **18.8 Nasazení minimálního smart stacku**.
