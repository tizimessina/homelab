# Uptime Kuma

Monitor de disponibilidad para los servicios del homelab, con notificaciones
por Telegram.

## Arquitectura

Container único, base de datos SQLite embebida (suficiente para el volumen
de datos de un homelab personal — MariaDB embebida o externa quedan
reservadas para escalas mucho mayores, con múltiples usuarios/instancias).

No se monta el socket de Docker (`/var/run/docker.sock`) a propósito: esa
integración solo hace falta para el tipo de monitor "Docker Container", y
dar ese nivel de acceso al host no se justifica cuando Portainer ya cubre
la gestión de containers.

## Monitores activos

| Monitor | Tipo | Qué valida |
|---|---|---|
| Pi-hole | DNS | Que resuelva de verdad contra `192.168.10.150`, no solo que el puerto esté abierto |
| Portainer | HTTP(s) | `https://192.168.10.150:9443` (con excepción TLS por certificado autofirmado) |
| Samba | TCP Port | `192.168.10.150:445` |
| Deco (Gateway) | Ping | `192.168.10.1` — distingue caída de red interna vs. caída de internet |
| Internet | Ping | `1.1.1.1` |
| AgroApp | HTTP(s) | `https://api.agroapp.home.arpa/health` — prueba la cadena completa en un solo chequeo: DNS (Pi-hole) → Caddy → API → base de datos. Con "Ignore TLS/SSL errors", porque el container no confía en la CA interna de Caddy |

## Notificaciones

Telegram vía bot propio (creado con @BotFather), Chat ID obtenido con el
botón "Auto Get" de Uptime Kuma tras iniciar conversación con el bot.
Aplicado por default a todos los monitores.

## Setup

1. `docker compose up -d`
2. Elegir SQLite como base de datos en el wizard inicial
3. Crear usuario admin
4. Configurar notificación de Telegram: Settings → Notifications → Setup Notification
5. Agregar monitores según la tabla de arriba

## Referencia

- Web UI: https://uptime.home.arpa (vía [Caddy](../caddy)) o http://192.168.10.150:3001
