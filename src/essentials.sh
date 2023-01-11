#!/usr/bin/env bash

update_appearance() {

    # Change fonts
    sudo apt -y install fonts-cascadia-code
	gsettings set org.gnome.desktop.interface font-name "Ubuntu 10"
	gsettings set org.gnome.desktop.interface document-font-name "Sans 10"
	gsettings set org.gnome.desktop.interface monospace-font-name "Cascadia Mono PL Semi-Bold 10"
	gsettings set org.gnome.desktop.wm.preferences titlebar-font "Ubuntu Bold 10"
	gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false

    # Change icons
	sudo add-apt-repository -y ppa:papirus/papirus-dev
	sudo apt update
    sudo apt -y install papirus-icon-theme
	gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"

    # Change theme
	gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
	gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"

    # Change terminal
	profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
	deposit="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
	# gsettings set "$deposit" cell-height-scale 1.2500000000000002
	gsettings set "$deposit" cell-height-scale 1.1000000000000001
	gsettings set "$deposit" default-size-columns 96
	gsettings set "$deposit" default-size-rows 24
	# gsettings set "$deposit" font "Cascadia Code 10"

    # Change desktop
    sudo apt install -y curl
	address="https://github.com/sharpordie/andpaper/raw/main/src/android-bottom-darken.png"
	picture="$HOME/Pictures/Backgrounds/android-bottom-darken.png"
	mkdir -p "$(dirname $picture)"
    curl -L "$address" -o "$picture"
	# gsettings set org.gnome.desktop.background picture-uri "file://$picture"
	gsettings set org.gnome.desktop.background picture-uri-dark "file://$picture"
	gsettings set org.gnome.desktop.background picture-options "zoom"

    # Change screensaver
	gsettings set org.gnome.desktop.screensaver picture-uri "file://$picture"
	gsettings set org.gnome.desktop.screensaver picture-options "zoom"

    # Change login
    sudo apt install -y libglib2.0-dev-bin
    address="https://github.com/PRATAP-KUMAR/ubuntu-gdm-set-background/archive/main.tar.gz"
    element="ubuntu-gdm-set-background-main/ubuntu-gdm-set-background"
    wget -qO - "$address" | tar zx --strip-components=1 "$element"
    sudo ./ubuntu-gdm-set-background --image "$picture"
    rm ./ubuntu-gdm-set-background

    # Vanish snap directory
    ! grep -q "snap" "$HOME/.hidden" 2>/dev/null && echo "snap" >>"$HOME/.hidden"

}

update_system() {

    # Handle adjunct
	country=${1:-Europe/Brussels}
	machine=${2:-ubuhogen}

    # Change hostname
	hostnamectl hostname "$machine"

	# Change timezone
	sudo unlink "/etc/localtime"
	sudo ln -s "/usr/share/zoneinfo/$country" "/etc/localtime"

    # Update system
	sudo apt -qq update
    sudo apt -y upgrade
    sudo apt -y dist-upgrade

    # Update firmware
	sudo fwupdmgr get-devices
    sudo fwupdmgr refresh --force
	sudo fwupdmgr get-updates
    sudo fwupdmgr update -y

}

main() {

	# Prompt password
	sudo -v && clear

	# Change headline
	printf "\033]0;%s\007" "ubuhogen"

	# Output greeting
	read -r -d "" welcome <<-EOD
		██╗░░░██╗██████╗░██╗░░░██╗██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
		██║░░░██║██╔══██╗██║░░░██║██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
		██║░░░██║██████╦╝██║░░░██║███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
		██║░░░██║██╔══██╗██║░░░██║██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
		╚██████╔╝██████╦╝╚██████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
		░╚═════╝░╚═════╝░░╚═════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD
	printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Remove timeouts
	echo "Defaults timestamp_timeout=-1" | sudo tee "/etc/sudoers.d/disable_timeout" &>/dev/null

	# Remove sleeping
	gsettings set org.gnome.desktop.notifications show-banners false
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	gsettings set org.gnome.desktop.session idle-delay 0

	# Handle elements
	factors=(
		"update_system"
		"update_appearance"
	)

	# Output progress
	maximum=$((${#welcome} / $(echo "$welcome" | wc -l)))
	heading="\r%-"$((maximum - 20))"s   %-6s   %-8s\n\n"
	loading="\r%-"$((maximum - 20))"s   \033[93mACTIVE\033[0m   %-8s\b"
	failure="\r%-"$((maximum - 20))"s   \033[91mFAILED\033[0m   %-8s\n"
	success="\r%-"$((maximum - 20))"s   \033[92mWORKED\033[0m   %-8s\n"
	printf "$heading" "FUNCTION" "STATUS" "DURATION"
	for element in "${factors[@]}"; do
		written=$(basename "$(echo "$element" | cut -d ' ' -f 1)" | tr "[:lower:]" "[:upper:]")
		started=$(date +"%s") && printf "$loading" "$written" "--:--:--"
		eval "$element" >/dev/null 2>&1 && current="$success" || current="$failure"
		extinct=$(date +"%s") && elapsed=$((extinct - started))
		elapsed=$(printf "%02d:%02d:%02d\n" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
		printf "$current" "$written" "$elapsed"
	done

	# Revert timeouts
	sudo rm "/etc/sudoers.d/disable_timeout"

	# Revert sleeping
	gsettings set org.gnome.desktop.notifications show-banners true
	gsettings set org.gnome.desktop.screensaver lock-enabled true
	gsettings set org.gnome.desktop.session idle-delay 300
	printf "\n"

}

main