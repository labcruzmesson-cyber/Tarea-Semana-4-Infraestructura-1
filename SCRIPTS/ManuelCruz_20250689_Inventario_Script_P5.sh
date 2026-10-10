#!/bin/bash
# ========================================================
# SCRIPT DE CONFIGURACION: SERVIDOR WEB INVENTARIO
# IP: 10.25.89.3/28 | Gateway: 10.25.89.1 | Interfaz: e0
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
        - 10.25.89.3/28
      gateway4: 10.25.89.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
EOF

netplan apply

echo "[+] Instalando OpenSSH y Nginx..."
apt update -y
apt install -y openssh-server nginx

echo "[+] Habilitando servicios..."
systemctl enable --now ssh
systemctl enable --now nginx

echo "[+] Desplegando aplicacion web Sistema de Inventario..."
cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Sistema de Inventario</title>
</head>
<body style="font-family: Arial, sans-serif; text-align: center; margin-top: 60px; background-color: #f4f6f9;">
  <div style="background-color: white; width: 60%; margin: auto; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
    <h1 style="color: #2980b9;">SISTEMA DE CONTROL DE INVENTARIO</h1>
    <hr style="border: 0; height: 1px; background: #ddd;">
    <p style="font-size: 16px;">Servidor DMZ: <b>10.25.89.3</b></p>
    <p style="font-size: 16px; color: #c0392b; font-weight: bold;">ACCESO RESTRINGIDO A PERSONAL AUTORIZADO (VLAN 20)</p>
  </div>
</body>
</html>
EOF

systemctl restart nginx
echo "[✔] Servidor Inventario configurado correctamente."