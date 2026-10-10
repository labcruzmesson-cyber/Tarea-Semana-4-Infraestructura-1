#!/bin/bash
# ========================================================
# SCRIPT DE CONFIGURACION: SERVIDOR DATABASE
# IP: 10.25.89.4/28 | Gateway: 10.25.89.1 | Interfaz: e0
# ========================================================

set -e

echo "[+] Configurando direccionamiento IP estatico en e0..."
cat << 'EOF' > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    e0:
      dhcp4: no
      addresses:
        - 10.25.89.4/28
      gateway4: 10.25.89.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
EOF

netplan apply

echo "[+] Instalando OpenSSH y MariaDB..."
apt update -y
apt install -y openssh-server mariadb-server ufw

echo "[+] Configurando MariaDB para escuchar en la interfaz de red..."
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf 2>/dev/null || true

echo "[+] Habilitando servicios..."
systemctl enable --now ssh
systemctl enable --now mariadb

echo "[+] Aplicando politicas complementarias de firewall local (UFW)..."
ufw default deny incoming
ufw default allow outgoing
# Permitir SSH unicamente desde el segmento de gestion VLAN 20
ufw allow from 10.25.68.128/25 to any port 22 proto tcp
# Permitir MySQL exclusivamente desde los dos servidores web de la DMZ
ufw allow from 10.25.89.2 to any port 3306 proto tcp
ufw allow from 10.25.89.3 to any port 3306 proto tcp
ufw --force enable

echo "[✔] Servidor DB configurado y protegido correctamente."