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

1. Copiar `.env.example` a `.env`.
2. Generar el hash de usuario:
   `docker run -it --rm ghcr.io/servercontainers/samba:latest create-hash.sh`
3. Completar en `.env` `SAMBA_USER` (el usuario real del host) y
   `SAMBA_PASSWORD_HASH` (el hash completo del paso anterior).
4. Confirmar que el punto de montaje del disco pertenece al usuario
   correcto (no a root) antes de levantar el container:
   `sudo chown -R <usuario>:<usuario> /mnt/disco-seagate`
5. `docker compose up -d`

## Gotchas

- **Permisos del punto de montaje**: si `/mnt/disco-seagate` pertenece a
  `root`, el usuario de Samba (aunque tenga el UID correcto) puede leer
  pero no escribir. Hay que hacer `chown` al usuario real antes de conectar.
- **El nombre de usuario tiene que coincidir en todos lados**: la variable
  `ACCOUNT_<usuario>`, el `valid users` del volume config y el usuario real
  del sistema (mismo UID). Un desajuste rompe la autenticación sin dar un
  error claro. Por eso el compose arma los dos primeros a partir de una
  sola variable (`SAMBA_USER`).
- **`WSDD2_DISABLE: 0` desactiva WSDD2 en vez de activarlo**: el entrypoint
  de la imagen chequea si la variable *existe* (`${WSDD2_DISABLE+x}`), no su
  valor. Para dejar WSDD2 (descubrimiento en "Red" de Windows) andando, la
  variable directamente no se define. Se confirma en el arranque:
  `docker logs samba | grep WSDD2` no debería mostrar `WSDD2 - DISABLED`.

## Acceso

- Desde Windows: `\\192.168.10.150\Seagate` (o desde "Red" en el Explorador,
  gracias a WSDD2)
- Usuario: el definido en `SAMBA_USER`
