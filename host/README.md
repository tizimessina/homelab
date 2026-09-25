# Host

Configuración del sistema operativo que vive fuera de Docker.

## `screen-off.service`

Apaga el panel integrado del All-in-One en cada arranque, escribiendo
directo al framebuffer del kernel (el porqué de este método, y los que
fallaron antes, está en el [README principal](../README.md#-apagado-del-panel-físico)).

Instalación:

```bash
sudo cp screen-off.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now screen-off.service
```

Para volver a prender la pantalla sin reiniciar:

```bash
echo 0 | sudo tee /sys/class/graphics/fb0/blank
```
