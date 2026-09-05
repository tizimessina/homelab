# Samba

Servidor de archivos sobre el disco Seagate 2TB, accesible desde Windows/Mac
como carpeta de red.

## Arquitectura

Usa `network_mode: host` en vez de una red Docker propia — Samba depende de
protocolos de descubrimiento (NetBIOS, WSDD2, Avahi/mDNS) que se basan en
broadcast/multicast, tráfico que no atraviesa bien el NAT de las redes
bridge normales de Docker. Es la única excepción al patrón de red aislada
que usamos en el resto de los servicios.

Imagen: `ghcr.io/servercontainers/samba` — activamente mantenida (a
diferencia de `dperson/samba`, la más popular en tutoriales viejos pero
sin actualizaciones hace más de 5 años).

## Setup

1. Generar el hash de usuario:
   `docker run -it --rm ghcr.io/servercontainers/samba:latest create-hash.sh`
2. Pegar el hash completo en `.env` como `ACCOUNT_<usuario>=<hash>`
3. Confirmar que el punto de montaje del disco pertenece al usuario
   correcto (no a root) antes de levantar el container:
   `sudo chown -R <usuario>:<usuario> /mnt/disco-seagate`
4. `docker compose up -d`

## Gotchas

- **Permisos del punto de montaje**: si `/mnt/disco-seagate` pertenece a
  `root`, el usuario de Samba (aunque tenga el UID correcto) puede leer
  pero no escribir. Hay que hacer `chown` al usuario real antes de conectar.
- El usuario en `ACCOUNT_<nombre>`, en `valid users` del volume config, y
  el usuario real del sistema (mismo UID) tienen que coincidir exactamente
  en nombre — un desajuste ahí rompe la autenticación silenciosamente.

## Acceso

- Desde Windows: `\\192.168.10.150\Seagate`
- Usuario: tizimessina
