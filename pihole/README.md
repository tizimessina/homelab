# Pi-hole + Unbound

DNS propio con bloqueo de ads (Pi-hole) y resolución recursiva sin
depender de terceros (Unbound), corriendo en containers separados.

## Arquitectura

Cliente (LAN) -> Pi-hole (172.20.0.3, puerto 53/80 publicados)
              -> Unbound (172.20.0.2, solo red interna)
              -> Root servers (resolución recursiva)

## Setup

1. Copiar `.env.example` a `.env` y setear `PIHOLE_WEBPASSWORD`.
2. `mkdir -p unbound-data && touch unbound-data/{a-records,srv-records,forward-records}.conf`
3. `docker compose up -d`
4. Configuración manual post-arranque (ver "Gotchas" abajo).
5. En el Deco (o router): DHCP Server > Primary DNS = IP del servidor.

## Gotchas / troubleshooting (setup inicial, 2026-09-04)

- **Puerto 53 ocupado por systemd-resolved**: hubo que desactivar el
  stub listener (`DNSStubListener=no` en `/etc/systemd/resolved.conf`)
  sin matar systemd-resolved completo.

- **Unbound no arrancaba**: la imagen `mvance/unbound` espera los
  archivos `a-records.conf`, `srv-records.conf`, `forward-records.conf`
  en el volumen montado. Hay que crearlos vacíos antes del primer
  `up` (ver paso 2 de Setup).

- **WEBPASSWORD no seteaba la contraseña**: en Pi-hole v6 esa variable
  quedó deprecada. Usar `FTLCONF_webserver_api_password` en su lugar.
  Si falla, setear en runtime: `docker exec pihole pihole setpassword <pass>`

- **PIHOLE_DNS_ no configura el upstream en v6**: esa variable es de
  Pi-hole v5 y v6 la ignora sin avisar. El log de arranque mostraba
  "1 FTLCONF environment variable found" (solo la password), lo cual
  era la pista de que el upstream nunca se aplicó. Resultado: Pi-hole
  arrancaba resolviendo contra Google en vez de Unbound.
  Fix: Settings > DNS > destildar el proveedor default > Custom DNS
  servers > agregar `172.20.0.2#53`. O por comando:
  `docker exec pihole pihole-FTL --config dns.upstreams '["172.20.0.2#53"]'`

- **Timeout total desde cualquier dispositivo de la LAN (el bug más
  largo de resolver)**: Pi-hole/FTL arranca por default con
  `dns.listeningMode LOCAL`, que descarta silenciosamente cualquier
  consulta que no reconozca como proveniente de una red "local" desde
  el punto de vista del container — lo cual excluye el tráfico NAT-eado
  normal desde la LAN a través de Docker. Se confirmó en el log de FTL:
  `WARNING: dnsmasq: ignoring query from non-local network 192.168.10.150`
  Fix: `docker exec pihole pihole-FTL --config dns.listeningMode ALL`
  seguido de `docker restart pihole`.

  Antes de encontrar esta causa real se descartaron (en orden):
  DNS manual de Quad9 configurado en el adaptador de Windows (real,
  pero no la causa de este bug puntual), AP/Client isolation del Deco
  (descartado con tcpdump: los paquetes sí llegaban a la interfaz),
  reglas de iptables/NAT de Docker (correctas, no era esto).

## Verificado funcionando (2026-09-04)

- `docker exec pihole pihole-FTL --config dns.upstreams` -> `[ 172.20.0.2#53 ]`
- `dig @192.168.10.150 cloudflare.com` resuelve correctamente vía Unbound.
- Windows toma `192.168.10.150` como DNS automáticamente vía DHCP del Deco.

## Referencia rápida

- Web UI: http://192.168.10.150/admin
- Ver upstream actual: `docker exec pihole pihole-FTL --config dns.upstreams`
- Ver logs: `docker compose logs pihole` / `docker compose logs unbound`
