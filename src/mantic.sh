#!/usr/bin/env bash

update_chromium() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}
	local startup=${2:-about:blank}

	# Update dependencies
	update_ydotool || return 1
	sudo apt install -y curl jq

    # Update package
    local present=$([[ -x "$(which ungoogled-chromium)" ]] && echo true || echo false)
	sudo add-apt-repository -y ppa:xtradeb/apps
	sudo apt update && sudo apt install -y ungoogled-chromium

}

update_ydotool() {

	# Update dependencies
	sudo apt install -y build-essential cmake git libboost-program-options-dev scdoc

	# Remove package
	sudo apt autoremove -y --purge ydotool

	# Update package
	local current=$(date -r "$(which ydotool)" +"%s")
	local maximum=$(date -d "10 days ago" +"%s")
	local updated=$([[ $current -lt $maximum ]] && echo false || echo true)
	[[ $updated == true ]] && return 0
	local current=$(dirname "$(readlink -f "$0")") && tempdir=$(mktemp -d)
	git clone "https://github.com/ReimuNotMoe/ydotool.git" "$tempdir"
	cd "$tempdir" && mkdir build && cd build && cmake .. && make && sudo make install
	cd "$current" && source "$HOME/.bashrc"

}

main() {

	# Prompt password
	clear && sudo -v && clear

	# Change headline
	printf "\033]0;%s\007" "$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"

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

	# Handle members
	local members=(
		"update_appearance"
		# "update_system"
		"update_chromium"
		# "update_git 'main' 'sharpordie' '72373746+sharpordie@users.noreply.github.com'"
		# "update_vscode"

		"update_docker"
		# "update_github_cli"
		# "update_keepassxc"
		# "update_mambaforge"
		# "update_mpv"
		"update_nodejs"
		"update_obs"
		"update_pgadmin"
		"update_postgresql"
		"update_pycharm"
		# "update_yt_dlp"

		"update_odoo"
	)

	# Output progress
	local bigness=$((${#welcome} / $(echo "$welcome" | wc -l)))
	local heading="\r%-"$((bigness - 19))"s   %-5s   %-8s\n\n"
	local loading="\033[93m\r%-"$((bigness - 19))"s   %02d/%02d   %-8s\b\033[0m"
	local failure="\033[91m\r%-"$((bigness - 19))"s   %02d/%02d   %-8s\n\033[0m"
	local success="\033[92m\r%-"$((bigness - 19))"s   %02d/%02d   %-8s\n\033[0m"
	printf "$heading" "FUNCTION" "ITEMS" "DURATION"
	local minimum=1 && local maximum=${#members[@]}
	for element in "${members[@]}"; do
		local written=$(basename "$(echo "$element" | cut -d "'" -f 1)" | tr "[:lower:]" "[:upper:]")
		local started=$(date +"%s") && printf "$loading" "$written" "$minimum" "$maximum" "--:--:--"
		eval "$element" >/dev/null 2>&1 && local current="$success" || local current="$failure"
		local extinct=$(date +"%s") && elapsed=$((extinct - started))
		local elapsed=$(printf "%02d:%02d:%02d\n" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
		printf "$current" "$written" "$minimum" "$maximum" "$elapsed" && ((minimum++))
	done

	# Revert sleeping
	gsettings set org.gnome.desktop.notifications show-banners true
	gsettings set org.gnome.desktop.screensaver lock-enabled true
	gsettings set org.gnome.desktop.session idle-delay 300

	# Revert timeouts
	sudo rm "/etc/sudoers.d/disable_timeout"

	# Output new line
	printf "\n"

}

main