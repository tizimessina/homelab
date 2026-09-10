# 🏠 Homelab

Infraestructura casera para aprender Sysadmin, Cloud Engineering y AIOps con las manos en la masa — cada servicio documentado, versionado como código, y con la bitácora real de los problemas que aparecieron (y cómo se resolvieron) en el camino.

![Status](https://img.shields.io/badge/status-en%20construcción-yellow)
![Docker](https://img.shields.io/badge/runtime-Docker%20%2B%20Compose-2496ED?logo=docker&logoColor=white)
![IaC](https://img.shields.io/badge/infra-versionada%20en%20git-success)

---

## 📖 Sobre este proyecto

Este repo es la base de mi laboratorio casero, pensado como terreno de práctica real para mi camino hacia **Infraestructura / Sysadmin / Cloud Engineering**, con **AIOps** como capa adicional de interés — no como reemplazo del foco en infra, sino como una herramienta más arriba de ella.

La idea no es solo "instalar cosas" — cada carpeta de este repo tiene su propio `docker-compose.yml` versionado y, cuando aplica, un `README.md` con el troubleshooting real que hizo falta para dejarlo andando. Si algo se rompió, quedó anotado el porqué y el fix, en vez de barrerlo bajo la alfombra.

## 🖥️ El hardware

| | |
|---|---|
| **Equipo** | Lenovo All-in-One C260 (2014/2015) |
| **CPU** | Intel Celeron J1800 @ 2.41GHz, dual-core |
| **RAM** | 4GB (3.89GB usables) |
| **Disco sistema** | SSD WD Blue 120GB (SATA) |
| **Disco datos** | HDD Seagate 2TB (único dispositivo en el bus USB) |
| **Red** | Ethernet Gigabit (Realtek RTL8111) conectado directo al Deco X80 — sin nodos ni extensores intermedios. Ver historia completa en [Topología de red](#-topología-de-red-y-su-historia) |
| **SO** | Ubuntu Server 26.04 LTS |

Hardware modesto a propósito — parte del ejercicio es aprender a tomar buenas decisiones de arquitectura *a pesar de* las limitaciones de recursos, no ignorándolas. Cada elección de stack (Docker en vez de Proxmox, SQLite en vez de MariaDB donde aplica, etc.) está pensada primero para este hardware real.

## 🧱 Stack y filosofía

- **Docker + Docker Compose** como runtime base — contenedores en vez de VMs completas, la skill que más se transfiere directo a Cloud (ECS, EKS, Cloud Run).
- **Un `docker-compose.yml` + `.env` por servicio**, cada uno en su propia carpeta, como ejercicio de Infrastructure as Code liviano.
- **Todo versionado en Git** desde el día uno — decisiones, configs y fixes quedan documentados, no solo en mi cabeza.
- **`.env` y datos persistentes nunca se suben** — solo la infraestructura como código.

## 📦 Proyectos

| Servicio | Qué hace | Estado |
|---|---|---|
| [`pihole/`](./pihole) | DNS propio con bloqueo de ads (Pi-hole) + resolución recursiva sin terceros (Unbound) | ✅ Funcionando |
| [`portainer/`](./portainer) | Panel visual de gestión de containers | ✅ Funcionando |
| [`samba/`](./samba) | Servidor de archivos sobre el disco Seagate | ✅ Funcionando |
| [`uptime-kuma/`](./uptime-kuma) | Monitoreo de disponibilidad de los 5 servicios clave, con alertas por Telegram | ✅ Funcionando |
| `reverse-proxy/` | Caddy — acceso a cada servicio por nombre (`servicio.home.arpa`) en vez de IP:puerto | 🔜 Próximo |
| `gitea/` | Git self-hosted + runner CI/CD | 🔜 Planeado |
| `wireguard/` | VPN para acceso remoto a la red doméstica | 🔜 Planeado |

Cada carpeta con servicio activo tiene su propio README con arquitectura, setup, y — cuando lo hubo — el troubleshooting real documentado paso a paso.

## 🌐 Topología de red (y su historia)

El servidor pasó por cuatro configuraciones de conectividad distintas, cada una diagnosticada con datos reales en vez de intuición.

**1. Dongle WiFi USB** (setup original) — compartía bus USB con el disco Seagate, sujeto a autosuspend y drivers menos maduros. Terminó fallando por hardware (`device descriptor read/64, error -32` en `dmesg`).

**2. Ethernet vía extensor de rango** (fix de emergencia) — al fallar el dongle, se conectó por cable hasta un extensor de rango WiFi 4 que hacía de puente hacia el Deco. Resolvió el problema de hardware, pero expuso dos cuellos de botella nuevos: el puerto Ethernet del extensor era Fast Ethernet (100Mbps, confirmado con `ethtool`), y el backhaul extensor↔Deco por WiFi 4 sufría "double dip" (un solo radio repartiendo turnos entre hablar con el servidor y con el Deco) — confirmado con `speedtest-cli`: subida errática entre 2.9 y 39 Mbps.

**3. WiFi interno directo al Deco** — usando la placa integrada de la Lenovo (Realtek RTL8188EE, gama baja, pero con señal al 100% por estar físicamente cerca del Deco). Eliminaba el salto intermedio del extensor. Mejoró la subida (74-81 Mbps estable) pero seguía siendo un enlace inalámbrico, con ~1.3% de pérdida ocasional.

**4. Ethernet directo al Deco (configuración actual y definitiva)** — se reubicó físicamente el servidor debajo del router y se conectó por cable Cat5e directo al Deco X80 (único router de la red, sin nodos ni extensores). `ethtool` confirma `1000baseT/Full` negociado en ambos extremos — Gigabit real de punta a punta. Ping con jitter de apenas 0.352ms, el más estable medido en las cuatro configuraciones.

### Gotcha: NetworkManager vs Netplan peleando por la misma interfaz

Durante la migración de la config 3 a la 4, la interfaz WiFi (`wlp3s0`) seguía reconectándose sola después de declararla `down` y sacarla del Netplan. Causa: en la config 3 se había usado `nmcli connection add/connect` para conectar rápido al WiFi, lo cual crea un perfil **persistente en NetworkManager** — un gestor de red completamente separado de Netplan/systemd-networkd. Ambos pueden coexistir en el mismo Ubuntu Server, y cuando lo hacen sin coordinación, cada uno cree tener autoridad sobre la interfaz.

Fix: `nmcli connection delete <nombre-del-perfil>` para borrar el perfil persistente, no solo `ip link set down`.

**Lección para el futuro:** usar `nmcli` para una conexión rápida de emergencia está bien, pero si después se declara la configuración definitiva en Netplan, hay que acordarse de borrar el perfil de NetworkManager — sino quedan dos gestores de red compitiendo por la misma interfaz sin que sea evidente por qué.

### Configuración final

Una sola interfaz activa (`enp2s0`, Ethernet), sin WiFi de respaldo por ahora. Reserva DHCP de `192.168.10.150` en el Deco atada a la MAC del cable (`f0:76:1c:26:9f:86`). Pi-hole escucha en `0.0.0.0`, así que responde sin importar la interfaz por la que llegue la consulta.

## 🗺️ Roadmap general

```
Docker + Git ──► Pi-hole + Unbound ──► Portainer ──► Samba ──► Uptime Kuma ──► Reverse Proxy
                                                                                     │
        ┌──────────────────────────────────────────────────────────────────────────┘
        ▼
  Backups ──► Gitea + CI/CD ──► WireGuard
        │
        └──► AIOps: n8n/Node-RED + API de Claude sobre logs y alertas
```

Este homelab alimenta directo mi camino hacia certificaciones AWS (arrancando por Cloud Practitioner) y sirve de entorno de práctica para Terraform antes de tocar infraestructura real de clientes.

## Apagado del panel físico

El servidor no tiene monitor conectado en uso normal (headless, acceso
por SSH), pero el panel integrado del AIO quedaba encendido indefinidamente
a pesar de `consoleblank` configurado en GRUB.

Se probaron 3 métodos antes de encontrar uno que funcionara en este hardware:
- `consoleblank=60` (kernel param) — solo pone texto negro, no dispara DPMS real
- `vbetool dpms off` — falla con "Real mode call failed" (necesita BIOS legacy,
  el equipo arranca en UEFI)
- `setterm --blank force` — falla por detección de terminal (`TERM` no
  soportado), incluso corriendo sin sesión SSH de por medio

**Lo que funciona:** escribir directo al framebuffer del kernel:
```bash
echo 4 | sudo tee /sys/class/graphics/fb0/blank   # apagar (powerdown real)
echo 0 | sudo tee /sys/class/graphics/fb0/blank   # reactivar si hace falta
```
Automatizado como servicio systemd (`screen-off.service`), corre una vez
en cada arranque.

## 🎯 Por qué existe este repo

Además de ser mi entorno de aprendizaje, este repo funciona como evidencia de trabajo real para mi perfil profesional — no tutoriales seguidos al pie de la letra, sino diagnóstico y resolución de problemas reales de infraestructura, documentados a medida que aparecen.

---

📍 Cada servicio vive en su propia carpeta con su `docker-compose.yml` y documentación puntual. Este README se va a ir actualizando a medida que se sumen proyectos nuevos.
