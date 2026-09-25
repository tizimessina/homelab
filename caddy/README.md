# Caddy (Reverse Proxy)

Acceso a los servicios del homelab por nombre (`servicio.home.arpa`) en vez
de IP:puerto, con HTTPS automático vía autoridad certificadora interna.

## Arquitectura

Caddy no comparte red de Docker con Pi-hole/Portainer/Uptime Kuma (cada uno
es un proyecto de Compose separado) — les habla a través de la IP del host
(`192.168.10.150:puerto`), ya que todos publican su puerto ahí.

`tls internal` genera una CA propia para firmar certificados de estos
nombres internos, en vez de pedir certificados públicos (imposible para
`.home.arpa`, que no es un dominio real de internet).

## Servicios proxeados

| Nombre | Destino real | Nota |
|---|---|---|
| pihole.home.arpa | 192.168.10.150:8080 | Redirect automático a /admin |
| portainer.home.arpa | 192.168.10.150:9443 | TLS insecure_skip_verify (cert autofirmado propio de Portainer) |
| uptime.home.arpa | 192.168.10.150:3001 | — |

## Gotchas

- **Pi-hole tuvo que cambiar su puerto publicado** de 80 a 8080, porque
  Caddy necesita el 80/443 del host para sí mismo.
- **El 403 "Did you mean to go to your Pi-hole's dashboard"** al entrar a
  `pihole.home.arpa` a secas es normal — Pi-hole v6 sirve en `/admin`, no
  en `/`. Resuelto con un `redir / /admin/` en el Caddyfile.
- **Confiar en la CA es por dispositivo, no automático.** El certificado
  raíz (`root.crt`) está copiado en `/mnt/disco-seagate/certificados/`
  para que cualquier dispositivo de la casa pueda instalarlo sin tener
  que entrar al servidor por SSH. Sin este paso, cada dispositivo sigue
  viendo advertencia de certificado no confiable (funciona igual, solo
  con el warning).
- **El volumen `caddy-data` es crítico** — ahí vive la clave privada de
  la CA interna. Si se pierde, los certificados ya confiados dejan de
  servir y hay que re-confiar en todos los dispositivos con la CA nueva.

## Setup

1. `docker compose up -d`
2. Copiar el root CA a un lugar accesible:
   `docker exec caddy cat /data/caddy/pki/authorities/local/root.crt`
3. Instalar ese certificado como Autoridad Raíz de Confianza en cada
   dispositivo que se quiera usar sin advertencias (ver abajo).

## Confiar en la CA interna, por sistema operativo

El `root.crt` se puede tomar directo del share de Samba
(`\\192.168.10.150\Seagate\certificados\`).

- **Windows:** doble click en `root.crt` → Instalar certificado → Equipo
  local → "Colocar todos los certificados en el siguiente almacén" →
  *Entidades de certificación raíz de confianza*. Reiniciar el navegador.
- **macOS:** abrir `root.crt` con Acceso a Llaveros, agregarlo al llavero
  *Sistema*, y en sus detalles marcar *Confiar siempre*.
- **iOS / iPadOS:** instalar el perfil (Ajustes → Perfil descargado) y
  después habilitarlo en Ajustes → General → Información → Ajustes de
  confianza de certificados.
- **Android:** Ajustes → Seguridad → Encriptación y credenciales → Instalar
  un certificado → Certificado de CA (la ruta exacta varía por fabricante).
- **Linux:** copiar a `/usr/local/share/ca-certificates/homelab.crt` y
  correr `sudo update-ca-certificates`. Firefox usa su propio almacén:
  Ajustes → Privacidad y seguridad → Ver certificados → Importar.
