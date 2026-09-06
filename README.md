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
| **Red** | WiFi interno (Realtek RTL8188EE) como principal, Ethernet Gigabit (Realtek RTL8111) como failover automático — ver detalle en [Topología de red](#-topología-de-red-y-su-historia) |
| **SO** | Ubuntu Server 24.04 LTS |

Hardware modesto a propósito — parte del ejercicio es aprender a tomar buenas decisiones de arquitectura *a pesar de* las limitaciones de recursos, no ignorándolas. Cada elección de stack (Docker en vez de Proxmox, VictoriaMetrics en vez de Prometheus donde aplique, etc.) está pensada primero para este hardware real.

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
| `monitoring/` | Uptime Kuma / métricas | 🔜 Próximo |
| `gitea/` | Git self-hosted + runner CI/CD | 🔜 Planeado |
| `wireguard/` | VPN para acceso remoto a la red doméstica | 🔜 Planeado |

Cada carpeta con servicio activo tiene su propio README con arquitectura, setup, y — cuando lo hubo — el troubleshooting real documentado paso a paso.

## 🌐 Topología de red (y su historia)

El servidor pasó por tres configuraciones de conectividad distintas, cada una diagnosticada con datos reales en vez de intuición:

1. **Dongle WiFi USB** (setup original) — compartía bus USB con el disco Seagate, sujeto a autosuspend y drivers menos maduros. Terminó fallando por hardware (`device descriptor read/64, error -32` en `dmesg`).
2. **Ethernet directo** (fix de emergencia) — al fallar el dongle, se conectó por cable hasta un extensor de rango WiFi 4 que hace de puente hacia el Deco principal. Resolvió el problema de hardware, pero expuso dos cuellos de botella nuevos: el puerto Ethernet del extensor es Fast Ethernet (100Mbps, confirmado con `ethtool`), y el backhaul extensor↔Deco por WiFi 4 sufre "double dip" (un solo radio repartiendo turnos entre hablar con el servidor y con el Deco) — confirmado con `speedtest-cli`: subida errática entre 2.9 y 39 Mbps.
3. **WiFi interno directo al Deco** (configuración actual) — usando la placa integrada de la Lenovo (Realtek RTL8188EE, gama baja, pero con señal al 100% por estar físicamente cerca del Deco). Elimina el salto intermedio del extensor. Resultado medido: subida estable en 74-81 Mbps, latencia igual de buena que por cable (12-16ms), ~1.3% de pérdida de paquetes ocasional (esperable en WiFi con muchas redes vecinas visibles).

**Configuración final:** ambas interfaces (`wlp3s0` WiFi interno y `enp2s0` Ethernet) conviven activas, con métricas de ruta fijadas en Netplan (`route-metric: 100` para WiFi, `700` para Ethernet) para que el WiFi gane como ruta principal pero el cable siga sirviendo de failover automático si el WiFi cae — sin intervención manual.

La reserva DHCP de `192.168.10.150` en el Deco está atada a la MAC del WiFi interno; Pi-hole escucha en `0.0.0.0` así que responde sin importar por qué interfaz llegue la consulta.

**Pendiente evaluado, no resuelto:** el cuello de botella real de fondo sigue siendo el tramo extensor↔Deco por WiFi 4. La solución de raíz sería backhaul cableado hasta el Deco principal, o reemplazar el extensor por un nodo Deco real con banda de backhaul dedicada.

## 🗺️ Roadmap general

```
Docker + Git ──► Pi-hole + Unbound ──► Portainer ──► Samba ──► Reverse Proxy
                                                                     │
        ┌────────────────────────────────────────────────────────────┘
        ▼
  Monitoreo (Uptime Kuma) ──► Backups ──► Gitea + CI/CD ──► WireGuard
        │
        └──► AIOps: n8n/Node-RED + API de Claude sobre logs y alertas
```

Este homelab alimenta directo mi camino hacia certificaciones AWS (arrancando por Cloud Practitioner) y sirve de entorno de práctica para Terraform antes de tocar infraestructura real de clientes.

## 🎯 Por qué existe este repo

Además de ser mi entorno de aprendizaje, este repo funciona como evidencia de trabajo real para mi perfil profesional — no tutoriales seguidos al pie de la letra, sino diagnóstico y resolución de problemas reales de infraestructura, documentados a medida que aparecen.

---

📍 Cada servicio vive en su propia carpeta con su `docker-compose.yml` y documentación puntual. Este README se va a ir actualizando a medida que se sumen proyectos nuevos.
