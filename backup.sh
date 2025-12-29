#!/bin/bash

# --- CONFIGURACIÓN ---
# Carpeta donde se guardarán tus dotfiles (se creará si no existe)
BACKUP_DIR="$HOME/Documents/dotfiles"
CONFIG_DIR="$HOME/.config"

# Colores para los mensajes
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Iniciando respaldo de configuraciones en $BACKUP_DIR...${NC}"

# Crear la estructura de carpetas necesaria
mkdir -p "$BACKUP_DIR/.config"
mkdir -p "$BACKUP_DIR/sddm"

# --- 1. ARCHIVOS SUELTOS DE KDE (Los esenciales) ---
# Estos definen atajos, paneles, reglas de ventanas y colores.
FILES_TO_COPY=(
    "kdeglobals"
    "kglobalshortcutsrc"
    "kwinrc"
    "plasmarc"
    "plasma-org.kde.plasma.desktop-appletsrc"
    "kscreenlockerrc"
    "ksplashrc"
    "konsolerc"
    "starship.toml" # Si usas starship prompt
)

for file in "${FILES_TO_COPY[@]}"; do
    if [ -f "$CONFIG_DIR/$file" ]; then
        cp "$CONFIG_DIR/$file" "$BACKUP_DIR/.config/"
        echo "Copiado: $file"
    else
        echo "No encontrado (saltando): $file"
    fi
done

# --- 2. CARPETAS COMPLETAS ---
# Aquí van las configs de apps que viste en tu 'ls'
DIRS_TO_COPY=(
    "fish"
    "kitty"
    "fastfetch"
    "btop"
    "cava"
    "micro"
    "spicetify"
    "gtk-3.0"
)

for dir in "${DIRS_TO_COPY[@]}"; do
    if [ -d "$CONFIG_DIR/$dir" ]; then
        # Copia recursiva (-r), borrando destino previo para evitar basura
        rm -rf "$BACKUP_DIR/.config/$dir"
        cp -r "$CONFIG_DIR/$dir" "$BACKUP_DIR/.config/"
        echo "Carpeta copiada: $dir"
    fi
done

# --- 3. CONFIGURACIÓN DE SDDM (Login) ---
# Intenta copiar la config de SDDM si existe en /etc
if [ -f /etc/sddm.conf ]; then
    cp /etc/sddm.conf "$BACKUP_DIR/sddm/"
    echo "Copiado sddm.conf"
elif [ -d /etc/sddm.conf.d ]; then
    cp -r /etc/sddm.conf.d "$BACKUP_DIR/sddm/"
    echo "Copiada carpeta sddm.conf.d"
else
    echo "Aviso: No se encontró configuración personalizada de SDDM en /etc"
fi

# --- 4. LISTA DE PAQUETES (CachyOS/Arch) ---
# Guarda una lista de todo lo que tienes instalado para reinstalar rápido
pacman -Qqe > "$BACKUP_DIR/pkglist.txt"
echo "Generada lista de paquetes en pkglist.txt"

echo -e "${GREEN}¡Respaldo completado exitosamente!${NC}"
echo "Ahora puedes entrar a $BACKUP_DIR e iniciar git."
