# Portainer

Panel de control visual para gestionar containers Docker.

## Setup

1. `docker compose up -d`
2. Entrar a https://192.168.10.150:9443 y crear el usuario admin
   **dentro de los primeros minutos** (si tardás demasiado, Portainer
   deshabilita el setup y hay que reiniciar el container para reintentar).
3. Elegir "Get Started" con el entorno Docker local.

## Nota de seguridad

Portainer tiene acceso al socket de Docker del host (/var/run/docker.sock),
lo cual equivale a control total sobre el servidor. Nunca exponer el
puerto 9443 a internet sin VPN/túnel de por medio.

Por la misma razón solo se publica el 9443: el puerto 8000 (túnel para
Edge Agents remotos) viene en casi todos los ejemplos, pero acá no se usa,
así que no se abre.

## Referencia

- Web UI: https://portainer.home.arpa (vía [Caddy](../caddy)) o https://192.168.10.150:9443
- Imagen pineada: portainer/portainer-ce:2.39.6
