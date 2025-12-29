#!/bin/bash

# --- VARIABLES ---
AUR_HELPER="paru" # CachyOS suele traer paru o yay
REPO_DIR="$HOME/Documents/dotfiles"
PROGS_FILE="$REPO_DIR/progs.csv"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# --- FUNCIONES ---

error() {
    echo -e "${RED}ERROR: $1${NC}"
    exit 1
}

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    error "Por favor, ejecuta este script como root (sudo ./install.sh)"
fi

# Detectar el usuario real (no root)
if [ $SUDO_USER ]; then
    REAL_USER=$SUDO_USER
else
    REAL_USER=$(whoami)
fi

echo -e "${GREEN}Iniciando instalación para el usuario: $REAL_USER${NC}"
echo -e "Directorio del repositorio: $REPO_DIR"

# --- 1. PREPARATIVOS CACHYOS ---

echo "--> Actualizando base de datos de pacman..."
pacman -Sy --noconfirm

# Instalar dependencias básicas para el script
# stow: para los dotfiles
# git: necesario
# python: para el instalador
echo "--> Instalando dependencias del script (python, stow, git)..."
pacman -S --needed --noconfirm python python-pip git stow base-devel

# Verificar si existe el AUR Helper
if ! command -v $AUR_HELPER &> /dev/null; then
    echo "--> $AUR_HELPER no encontrado. Instalando binario (chaotic-aur o compilación)..."
    # En CachyOS normalmente ya está, pero por si acaso usamos yay si paru falla, o lo instalamos.
    pacman -S --needed --noconfirm paru || pacman -S --needed --noconfirm yay
    if command -v yay &> /dev/null; then AUR_HELPER="yay"; fi
fi

# Permisos para el usuario en sudoers (temporal, para que makepkg funcione sin pedir password mil veces)
echo "--> Configurando permisos temporales de sudo..."
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/temp-install-rights

# --- 2. INSTALACIÓN DE PROGRAMAS (PYTHON) ---

if [ -f "$REPO_DIR/.local/bin/package_installer.py" ]; then
    echo "--> Ejecutando instalador de paquetes Python..."
    python "$REPO_DIR/.local/bin/package_installer.py" \
        --username "$REAL_USER" \
        --aurhelper "$AUR_HELPER" \
        --progsfile "$PROGS_FILE"
else
    error "No se encontró el script de Python en $REPO_DIR/.local/bin/package_installer.py"
fi

# --- 3. GESTIÓN DE DOTFILES (STOW) ---

echo "--> Aplicando Dotfiles con STOW..."
# Nos aseguramos de estar en el directorio correcto
cd "$REPO_DIR" || error "No se pudo acceder a $REPO_DIR"

# Cuidado: --adopt sobreescribirá lo que hay en el repo con lo que tienes en el sistema
# si hay conflictos. Si el repo es nuevo y el sistema tiene configs, esto las "adopta".
stow --adopt . 

# Restaurar el estado de git si adopt modificó archivos (opcional, para no dejar el repo sucio)
# sudo -u "$REAL_USER" git restore .

# --- 4. CONFIGURACIÓN DEL SISTEMA ---

# Cambiar Shell a FISH
if grep -q "fish" /etc/shells; then
    echo "--> Cambiando shell por defecto a FISH para $REAL_USER..."
    chsh -s /usr/bin/fish "$REAL_USER"
else
    echo -e "${RED}Fish no está instalado. Saltando cambio de shell.${NC}"
fi

# Configurar SDDM (KDE Login Manager)
echo "--> Habilitando servicio SDDM..."
systemctl enable sddm.service --force

# Limpieza
echo "--> Limpiando..."
rm -f /etc/sudoers.d/temp-install-rights

echo -e "${GREEN}¡INSTALACIÓN COMPLETADA!${NC}"
echo "Por favor, reinicia tu computadora para asegurar que todos los cambios (especialmente SDDM y Shell) surtan efecto."
