import os
import subprocess
import argparse
import sys

# Colores para la terminal
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

def run_command(command, as_user=False):
    try:
        # Ejecuta el comando. Si as_user es True, el comando ya debe venir con sudo -u
        subprocess.run(command, check=True, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        return False
    return True

def check_packages_exist(package_list, package_manager):
    valid_packages = []
    print(f"{Colors.OKBLUE}Verificando existencia de paquetes para {package_manager}...{Colors.ENDC}")
    for package in package_list:
        # Verificamos si existe en los repositorios
        result = subprocess.run(f"pacman -Sp {package} --noconfirm", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode == 0:
            valid_packages.append(package)
        else:
            print(f"{Colors.WARNING}Paquete {package} no encontrado en repositorios oficiales (se omitirá de pacman).{Colors.ENDC}")
    return valid_packages

def read_programs(file_path):
    programs = {'pacman': [], 'aur': [], 'pip': [], 'git':[]}
    if not os.path.isfile(file_path):
        print(f"{Colors.FAIL}El archivo {file_path} no existe.{Colors.ENDC}")
        sys.exit(1)

    with open(file_path, 'r') as file:
        for line in file:
            if line.startswith('#') or not line.strip():
                continue
            try:
                tag, program = line.strip().split(',')
                # Limpiamos espacios en blanco
                tag = tag.strip()
                program = program.strip()
                
                match tag:
                    case 'p':
                        programs['pacman'].append(program)
                    case 'a':
                        programs['aur'].append(program)
                    case 'i':
                        # En Arch moderno, 'pip' directo es peligroso. Lo trataremos como pacman
                        # asumiendo que el usuario pone 'python-paquete'
                        programs['pip'].append(program) 
                    case 'g':
                        programs['git'].append(program)
            except ValueError:
                continue
    return programs

def install_group(package_list, package_manager, username, aurhelper):
    if not package_list:
        return

    # Mapeo de comandos
    # Nota: Para 'pip' usamos pacman para mantener la estabilidad del sistema (python-xyz)
    command_map = {
        'pacman': f'pacman --noconfirm --needed -S',
        'pip': f'pacman --noconfirm --needed -S',
        'aur': f'sudo -u {username} {aurhelper} -S --noconfirm',
    }
    
    prefix = "sudo" if package_manager != 'aur' else ""
    cmd_base = command_map.get(package_manager)

    print(f"{Colors.HEADER}Instalando grupo ({package_manager})...{Colors.ENDC}")
    
    # Intentamos instalar todo el grupo junto primero
    packages_str = ' '.join(package_list)
    full_command = f"{prefix} {cmd_base} {packages_str}"
    
    if not run_command(full_command):
        print(f"{Colors.WARNING}Error instalando grupo. Intentando uno por uno...{Colors.ENDC}")
        for package in package_list:
            single_command = f"{prefix} {cmd_base} {package}"
            if run_command(single_command):
                print(f"Instalado: {package}")
            else:
                print(f"{Colors.FAIL}Fallo al instalar: {package}{Colors.ENDC}")
    else:
        print(f"{Colors.OKGREEN}Grupo ({package_manager}) instalado correctamente.{Colors.ENDC}")

def install_git_repos(repo_list, username):
    if not repo_list:
        return
    
    src_dir = f"/home/{username}/.local/src"
    if not os.path.exists(src_dir):
        os.makedirs(src_dir, exist_ok=True)
        # Ajustar permisos porque os.makedirs lo hará como root si el script corre como root
        subprocess.run(f"chown -R {username}:{username} /home/{username}/.local", shell=True)

    print(f"{Colors.HEADER}Clonando repositorios Git en {src_dir}...{Colors.ENDC}")
    
    for repo_url in repo_list:
        repo_name = repo_url.split('/')[-1].replace('.git', '')
        target_dir = os.path.join(src_dir, repo_name)
        
        if os.path.exists(target_dir):
            print(f"Actualizando {repo_name}...")
            # Git pull como el usuario normal
            subprocess.run(f"sudo -u {username} git -C {target_dir} pull", shell=True)
        else:
            print(f"Clonando {repo_name}...")
            if not run_command(f"sudo -u {username} git clone --depth 1 {repo_url} {target_dir}"):
                 print(f"{Colors.FAIL}Error clonando {repo_name}{Colors.ENDC}")

def main():
    parser = argparse.ArgumentParser(description="Automate CachyOS configuration setup")
    parser.add_argument("--username", required=True, help="Username for the installation")
    parser.add_argument("--aurhelper", default="paru", help="AUR helper to use (default: paru)")
    parser.add_argument("--progsfile", default="progs.csv", help="Path to the programs file")
    args = parser.parse_args()

    username = args.username
    aurhelper = args.aurhelper
    progsfile = os.path.expanduser(args.progsfile)
    
    print(f"Leyendo paquetes de: {progsfile}")
    packages = read_programs(progsfile)

    # Filtrar paquetes de pacman
    packages['pacman'] = check_packages_exist(packages['pacman'], 'pacman')
    
    # Instalación
    install_group(packages['pacman'], 'pacman', username, aurhelper)
    install_group(packages['pip'], 'pip', username, aurhelper) # Se instalan con pacman
    install_group(packages['aur'], 'aur', username, aurhelper)
    
    # Git Repos
    install_git_repos(packages['git'], username)

if __name__ == "__main__":
    main()
