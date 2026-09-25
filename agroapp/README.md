# AgroApp (despliegue en el homelab)

AgroApp es una app full-stack (React + Express + Prisma + MySQL) que
desarrollamos en equipo como TP de Desarrollo de Software, y vive en
**[otro repo](https://github.com/JereC4/TP-DSW-2025-3k03-Messina-Costantini-Enrico)**
(clonado en `~/agroapp`, con su `docker-compose.yml` de db + migrate + api + web).
Esta carpeta no copia la app: solo define **cómo se despliega en este
server**, con un override de Compose que se aplica encima del original.
Así el repo de la app queda intacto para el resto del equipo.

## Arquitectura

```
LAN ──► Pi-hole (DNS) ──► caddy :443 ──┬─► agroapp-web:80   (nginx, SPA)
                                        └─► agroapp-api:3000
                                  red `proxy`       │ red agroapp_default
                                                    └─► agroapp-db:3306
```

- **Un solo Caddy** para todo el homelab (el de `../caddy`). Un segundo
  Caddy dentro de AgroApp no puede usar 80/443 (ya ocupados) y detrás del
  primero sería doble proxy sin ganancia.
- **Sin puertos publicados**: web y api se unen a la red externa `proxy`
  y Caddy les llega por nombre de contenedor. La db queda solo en la red
  interna del stack.
- **Dos subdominios**, igual que producción (`agroapp.dev` /
  `api.agroapp.dev`): no requiere cambios de código, solo `VITE_API_URL`
  (build) y `CORS_ORIGIN`.

| URL | Destino |
|---|---|
| https://agroapp.home.arpa | Frontend |
| https://api.agroapp.home.arpa | API (docs en `/docs`, salud en `/health`) |

## Archivos

| Archivo | Qué es |
|---|---|
| `docker-compose.homelab.yml` | Override: saca puertos, suma red `proxy`, inyecta secreto y URLs |
| `.env` | Valores reales (no se versiona) — partir de `.env.example` |
| `deploy.sh` | `git pull` del repo de la app + `docker compose up -d --build` con el override |

## Setup

1. `docker network create proxy` (una sola vez, la comparte con Caddy).
2. `cp .env.example .env` y completar `JWT_SECRET` (`openssl rand -hex 32`).
3. `./deploy.sh` (o `./deploy.sh --no-pull` para no actualizar el repo).
4. En Pi-hole → Local DNS → DNS Records: `agroapp.home.arpa` y
   `api.agroapp.home.arpa` → `192.168.10.150`.
5. Monitor en Uptime Kuma: `https://api.agroapp.home.arpa/health`.

Para actualizar la app alcanza con volver a correr `./deploy.sh`. El
servicio `migrate` aplica migraciones y el seed, que es idempotente
(upsert), así que no borra datos cargados.

## Gotchas

- **El frontend no levantaba con el compose original**: publica `8080:80`
  y ese puerto ya es de Pi-hole (`Bind for 0.0.0.0:8080 failed: port is
  already allocated`). El override hace `ports: !reset []` en los tres
  servicios, así que ya no compite por puertos del host.
- **Nunca `docker compose up` directo en `~/agroapp`**: sin el override,
  el stack arranca como en desarrollo — publica la base (`3307`, con las
  credenciales de desarrollo del repo) y la API (`3000`) a toda la LAN,
  usa el `JWT_SECRET` de desarrollo, y el frontend se compila apuntando a
  `localhost:3000`. El síntoma visible es el mismo choque con el `8080`
  de Pi-hole. Fix: `docker compose down` en `~/agroapp` (sin `-v`, para
  conservar la base) y `./deploy.sh --no-pull` desde esta carpeta.
- **`VITE_API_URL` se compila dentro del frontend** — cambiarla en `.env`
  requiere rebuild, que `deploy.sh` hace siempre (`--build`).
- **La CA interna tiene que estar confiada en el dispositivo.** Con el
  front se puede "aceptar el riesgo" en el navegador, pero las llamadas
  de la SPA a `api.agroapp.home.arpa` fallan en silencio (error de red,
  no warning) si el certificado no es confiable. Ver `../caddy/README.md`.
- **Build lento en el Celeron**: la primera compilación de las imágenes
  tarda varios minutos; las siguientes reutilizan la capa de
  dependencias mientras no cambie el lockfile.

## Futuro: exponer a internet

Plan: **Cloudflare Tunnel** (`cloudflared` como servicio más del homelab,
unido a la red `proxy`). No requiere abrir puertos en el router ni IP
pública (funciona con CGNAT) y no expone la IP de la casa. Cambios en la
app: solo `.env` (`AGROAPP_API_URL=https://api.agroapp.dev`,
`AGROAPP_WEB_ORIGIN=https://agroapp.dev,...`) y re-deploy. Requiere mover
los nameservers de `agroapp.dev` a Cloudflare, lo que reemplaza el deploy
actual en Vercel + Render + Aiven. Antes de exponer: backups del volumen
`agroapp_db-data` y nada de credenciales demo con usuarios reales.
