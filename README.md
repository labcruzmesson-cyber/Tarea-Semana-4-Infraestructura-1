# Implementación y Hardening de Seguridad Perimetral y DMZ

[![Demostración en Video](https://img.shields.io/badge/Video-Demostración%20en%20YouTube-red?style=for-the-badge&logo=youtube)](https://TU-ENLACE-DE-VIDEO-AQUI.com)

> **Autor:** Manuel Alejandro Cruz Messón  
> **Matrícula:** 2025-0689  
> **Enlace del Video:** [Ver Demostración Técnica en YouTube](https://TU-ENLACE-DE-VIDEO-AQUI.com)

---

## 1. Propósito del Proyecto
Diseñar, implementar y auditar una infraestructura de red segura con microsegmentación perimetral utilizando un Next-Generation Firewall (FortiGate) y switches multicapa Cisco. El entorno aísla los servicios críticos en una Zona Desmilitarizada (DMZ), implementa control de fuga de datos hacia las redes locales (*Anti-Leak*), restringe el acceso a Internet de los servidores a únicamente repositorios de actualización, centraliza la administración SSH para un segmento privilegiado y aplica inspección de capa de aplicación con mensajes visuales de violación de políticas para los usuarios finales.

---

## 2. Diagrama de la Topología

![Topología de Red](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/topologia.png)

### Plan de Direccionamiento IP (Matrícula: 2025-0689)
| Segmento / Función | Interfaz FortiGate | Subred / CIDR | Máscara | Gateway | Rango Asignado / DHCP |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **VLAN 10 (Usuarios)** | `port3.10` | `10.25.68.0/25` | `255.255.255.128` | `10.25.68.1` | `.10` – `.120` (DHCP) |
| **VLAN 20 (Gestión)** | `port3.20` | `10.25.68.128/25` | `255.255.255.128` | `10.25.68.129` | `.140` – `.250` (DHCP) |
| **DMZ (Servidores)** | `port2` | `10.25.89.0/28` | `255.255.255.240` | `10.25.89.1` | `.2` a `.4` (Estático) |
| **WAN / Uplink ISP** | `port1` | *IP Pública / DHCP* | - | Gateway ISP | - |

---

## 3. Descripción de lo Implementado

### 3.1. Infraestructura de Conmutación (Switches Cisco L2)
* **Switch LAN (`SW-LAN-ACCESS`):**
  * **Uplink:** Puerto `GigabitEthernet0/0` en modo troncal 802.1Q hacia el `port3` del FortiGate.
  * **Acceso VLAN 10:** Puerto `GigabitEthernet0/1` con `switchport port-security` (máximo 2 MACs, violación restrictiva), STP PortFast y BPDU Guard.
  * **Acceso VLAN 20:** Puerto `GigabitEthernet1/1` con las mismas medidas de hardening perimetral.
  * **DHCP Snooping:** Habilitado para VLANs 10 y 20, marcando `Gi0/0` como puerto de confianza (`trust`) y deshabilitando la Opción 82 para compatibilidad directa con el servicio DHCP de FortiOS.
* **Switch DMZ (`SW-DMZ-SERVERS`):**
  * **Uplink:** Puerto `GigabitEthernet0/0` conectado al `port2` del FortiGate en modo acceso.
  * **Servidores:** Puertos `GigabitEthernet0/1` (Caja), `GigabitEthernet0/2` (Inventario) y `GigabitEthernet0/3` (DB) asegurados con Port-Security fijo a 1 MAC sticky y violación `shutdown`. Puertos restantes deshabilitados administrativamente.

### 3.2. Seguridad Perimetral y UTM (FortiGate NGFW)
* **Microsegmentación y Políticas de Firewall:**
  * **Aislamiento SSH:** Política restrictiva que permite el tráfico TCP 22 hacia la DMZ exclusivamente si el origen es la subred de la `VLAN20_Admin`. Cualquier intento desde la `VLAN10_Users` es rechazado de inmediato.
  * **Control Web con Advertencia de Infracción:** La VLAN 10 tiene permitido el acceso HTTP hacia el Sistema de Caja (`10.25.89.2`). El acceso al Sistema de Inventario (`10.25.89.3`) está interceptado mediante un perfil de **Web Filter** en modo proxy que despliega un mensaje personalizado HTML de violación de políticas de seguridad.
  * **Anti-Leak DMZ -> LAN:** Política con acción `DENY` y log activado para todo tráfico originado en la DMZ con destino hacia las VLANs de usuarios y gestión.
  * **Salida Restringida de DMZ a Internet:** Políticas que permiten exclusivamente consultas DNS salientes hacia `8.8.8.8` y tráfico HTTP/HTTPS hacia los repositorios oficiales de Ubuntu (`archive.ubuntu.com`, `security.ubuntu.com`). El resto de Internet y tráfico ICMP se encuentra bloqueado con registro en log.

---

## 4. Evidencias de Cumplimiento

### Requisito 1: Segmentación, DHCP y Seguridad L2
Concesión de direcciones por DHCP para usuarios y validación de enlace troncal y seguridad en switch.

![Concesiones DHCP en FortiGate](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/dhcp_leases.png)
![Seguridad en Switch LAN](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/switch_security_lan.png)
![Seguridad en Switch SERVER](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/switch_security_server.png)

---

### Requisito 2: Acceso a Servicios Web y Bloqueo Notificado (VLAN 10)
* **Permitido:** Acceso al servidor Web de Caja (`10.25.89.2`).
![Acceso Permitido a Web Caja](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/vlan10_caja_ok.png)
![Acceso Permitido a Web Caja](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/vlan10_caja_ok_log.png)
* **Bloqueado:** Intento de acceso al servidor de Inventario (`10.25.89.3`) desplegando el reemplazo institucional de advertencia.
![Bloqueo de Inventario con Página de Violación](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/vlan10_inventario_block.png)
![Bloqueo de Inventario con Página de Violación](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/vlan10_inventario_block_log.png)


---

### Requisito 3: Exclusividad de Acceso SSH (VLAN 20)
* **VLAN 10:** Conexión SSH rechazada/descartada con registro en los logs.
![Intento SSH Denegado desde VLAN 10](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/ssh_vlan10_denied.png)
![Intento SSH Denegado desde VLAN 10](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/ssh_vlan10_denied_log.png)
* **VLAN 20:** Conexión SSH establecida satisfactoriamente contra la DMZ.
![Acceso SSH Autorizado desde VLAN 20](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/ssh_vlan20_allowed..png)
![Acceso SSH Autorizado desde VLAN 20](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/ssh_vlan20_allowed_log.png)
---

### Requisito 4: Prevención de Fuga de Tráfico (Anti-Leak DMZ -> LAN)
Demostración de descarte de paquetes originados desde el servidor hacia las IPs de las VLANs de usuarios.

![Log Anti-Leak en FortiGate](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/dmz_anti_leak_log.png)

---

### Requisito 5: Internet en DMZ Solo para Actualizaciones
* **Actualización:** Descarga operativa desde repositorios de paquetes oficiales.
![Actualización Exitosa de Repositorios](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/dmz_update_allowed.png)
![Actualización Exitosa de Repositorios](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/dmz_update_allowed_log.png)
* **Bloqueo General:** Timeout en intentos de navegación a sitios externos (ej. Google) y tráfico ICMP bloqueado.
![Bloqueo de Navegación Abierta e Internet](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/dmz_internet_blocked.png)
![Bloqueo de Navegación Abierta e Internet](https://github.com/labcruzmesson-cyber/Tarea-Semana-4-Infraestructura-1/blob/main/IMAGES/dmz_internet_blocked_log.png)
