# Mis Dotfiles (CachyOS / KDE Plasma)

Este repositorio contiene mi configuración personal, scripts de automatización y una lista de paquetes esenciales para recrear mi entorno de trabajo en cualquier sistema basado en Arch Linux, optimizado específicamente para **CachyOS**.



## Instalación Rápida

> **Advertencia:** No ejecutes el script sin antes revisar el archivo `progs.csv`.

```bash
# 1. Clonar el repositorio
git clone [https://github.com/ManuSavenia/dotfiles.git](https://github.com/ManuSavenia/dotfiles.git) ~/Documents/dotfiles

# 2. Entrar al directorio
cd ~/Documents/dotfiles

# 3. Dar permisos de ejecución
chmod +x install.sh
chmod +x .local/bin/package_installer.py

# 4. Ejecutar el instalador (como sudo)
sudo ./install.si

## Actualización de dotfiles
Cuando realices cambios en la configuración de tu sistema (colores de KDE, alias de Fish, etc.) y quieras guardarlos en tu repo, simplemente ejecuta backup.sh y luego sube los cambios.
