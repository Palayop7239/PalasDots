#!/usr/bin/env bash
#     ____        __     _          ____        __      
#    / __ \____ _/ /___ ( )_____   / __ \____  / /______
#   / /_/ / __ `/ / __ `/// ___/  / / / / __ \/ __/ ___/
#  / ____/ /_/ / / /_/ / (__  )  / /_/ / /_/ / /_(__  ) 
# /_/    \__,_/_/\__,_/ /____/  /_____/\____/\__/____/  
#
#                   Installation Script

set -euo pipefail

BACKUP_DIR="$HOME/.dots_backup_$(date +%Y%m%d_%H%M%S)"

CONFIGS=("hypr" "quickshell" "foot" "fish" "RicingAssets" "swaync" "fastfetch" "rofi")
DOTFILES_DIR="$HOME/.Pala-Dots"
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
		echo "Do not run this as sudo, it might break stuff !"
		echo "Just run: ./install.sh"
		exit 1
	fi
}

is_arch() {
    if [ -f /etc/arch-release ]; then
        return 0
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "arch" ]] || [[ "$ID_LIKE" == *arch* ]]; then
            return 0
        fi
    fi

    return 1
}
get_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        echo ""
    fi
}
SCRIPT_VERSION="1.0.0"

get_git_commit() {
    if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
        git rev-parse --short HEAD
    fi
}

GIT_COMMIT=$(get_git_commit)

if [ -n "$GIT_COMMIT" ]; then
    DISPLAY_VERSION="$SCRIPT_VERSION ($GIT_COMMIT)"
else
    DISPLAY_VERSION="$SCRIPT_VERSION"
fi

AUR_HELPER=$(get_aur_helper)

print_banner() {
    cat ascii.txt
    echo -e "\n\033[1;33mWelcome to Pala's Dots installation script!\033[0m"
	echo -e "\033[1;36mVersion: $DISPLAY_VERSION\033[0m\n"
}

SOURCE_DIR="$(dirname "$(realpath "$0")")"
CONFIG_PATH="$HOME/.config"
install() {
    echo "Starting installation..."
	if is_arch; then
		echo -e "\n\033[1;33mArch/Arch based distribution detected !\033[0m\n"

		echo "Attempting to install AUR depedencies."
		if [ -z "$AUR_HELPER" ]; then
			echo "❌ You need an AUR helper (yay or paru) to run this installer."
			echo "Please install one first and re-run the script."
			exit 1
		fi
		echo -e "\n\033[1;33mDetected AUR helper : $AUR_HELPER\033[0m\n"

		DEPS_LIST="$SOURCE_DIR/deps.txt"
		while IFS=: read -r pkg source; do
			[[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

			if [[ "$source" == "official" ]]; then
				echo "Installing $pkg from official repos..."
				sudo pacman -S --needed --noconfirm "$pkg"
			elif [[ "$source" == "aur" ]]; then
				echo "Installing $pkg from AUR..."
				$AUR_HELPER -S --needed --noconfirm "$pkg"
			else
				echo "Unknown source for $pkg, skipping..."
			fi
		done < "$DEPS_LIST"

		echo
		echo
		echo
		mkdir -p "$BACKUP_DIR"
		printf "\n\033[1;33mIMPORTANT:\033[0m Existing configs are backed up in %s\n\n" "$BACKUP_DIR"

		mkdir -p "$DOTFILES_DIR"

		for folder in "${CONFIGS[@]}"; do
			SRC="$SOURCE_DIR/$folder"
			DEST="$DOTFILES_DIR/$folder"

			if [ -e "$CONFIG_PATH" ] || [ -L "$CONFIG_PATH" ]; then
				echo "Backing up existing ~/.config/$folder..."
				mv "$CONFIG_PATH" "$BACKUP_DIR/"
			fi

			echo "Installing $folder configs..."
			cp -r "$SRC" "$DEST"
			ln -s "$DEST" "$HOME/.config/$folder"
		done

	else
		echo ""
		echo "Sorry, this helper script currently supports Arch-based distributions only !"
		echo "Installing the depedencies and the configs manually should be possible for you though !"
		exit 1
	fi

	cp $SOURCE_DIR/install.sh $DOTFILES_DIR/setup.sh
    echo "Installation complete."
	printf "\n\033[1;32mAll configs are installed successfully in %s!\033[0m\n" "$DOTFILES_DIR"
	echo "You can now log off and choose the Hyprland session when logging in ! Enjoy !"
}

uninstall() {
    echo "Starting removal..."
	for folder in "${CONFIGS[@]}"; do
		REPO_PATH="$DOTFILES_DIR/$folder"

		if [ -L "$CONFIG_PATH" ]; then
			echo "Removing symlink $CONFIG_PATH"
			rm "$CONFIG_PATH"	
		fi

		if [ -d "$REPO_PATH" ]; then
			echo "Removing $REPO_PATH from dotfiles directory"
			rm -rf "$REPO_PATH"
		fi
	done
	echo
	echo -e "\n\033[1;33mThe dotfiles have been removed from your computer ! I hope you enjoyed your stay !\033[0m\n"

	rm -rf "$DOTFILES_DIR"
}

main() {
	check_sudo
	clear
    print_banner

    while true; do
		echo -e "[1] Installation - The script will do everything while you watch !"
		echo -e "[2] Uninstall - The dots will be uninstalled, goodbye !"
		echo

		read -rp "Enter your choice (1-2): " choice

		case "$choice" in
			1)
				install
				break
				;;
			2)
				uninstall
				break
				;;
			*)
				echo "Invalid choice. Try again."
				echo
				;;
		esac
	done
}

main
