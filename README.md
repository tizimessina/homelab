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
| **Disco datos** | HDD Seagate 2TB (USB portátil) |
| **SO** | Ubuntu Server 26.04 LTS |

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
| `monitoring/` | Uptime Kuma / métricas | 🔜 Próximo |
| `samba/` | Servidor de archivos sobre el disco Seagate | 🔜 Planeado |
| `gitea/` | Git self-hosted + runner CI/CD | 🔜 Planeado |
| `wireguard/` | VPN para acceso remoto a la red doméstica | 🔜 Planeado |

Cada carpeta con servicio activo tiene su propio README con arquitectura, setup, y — cuando lo hubo — el troubleshooting real documentado paso a paso.

## 🗺️ Roadmap general

```
Docker + Git ──► Pi-hole + Unbound ──► Portainer ──► Reverse Proxy
                                                          │
        ┌─────────────────────────────────────────────────┘
        ▼
  Monitoreo ──► Samba + Backups ──► Gitea + CI/CD ──► WireGuard
        │
        └──► AIOps: n8n/Node-RED + API de Claude sobre logs y alertas
```

Este homelab alimenta directo mi camino hacia certificaciones AWS (arrancando por Cloud Practitioner) y sirve de entorno de práctica para Terraform antes de tocar infraestructura real de clientes.

## 🎯 Por qué existe este repo

Además de ser mi entorno de aprendizaje, este repo funciona como evidencia de trabajo real para mi perfil profesional — no tutoriales seguidos al pie de la letra, sino diagnóstico y resolución de problemas reales de infraestructura, documentados a medida que aparecen.

---

📍 Cada servicio vive en su propia carpeta con su `docker-compose.yml` y documentación puntual. Este README se va a ir actualizando a medida que se sumen proyectos nuevos.
