#!/usr/bin/env bash

update_android() {

	# Ensure the dependencies are installed.
	sudo apt -qy install curl

	# Handle the installation.
	website="https://developer.android.com/studio#downloads"
	pattern="android-studio-\K(\d.+)(?=-linux)"
	version=$(curl -s "$website" | grep -oP "$pattern" | head -1)
	present="$([[ -x $(command -v android-studio) ]] && echo 'true' || echo 'false')"
	if [[ "$present" == "false" ]]; then
		address="https://dl.google.com/dl/android/studio/ide-zips/$version/android-studio-$version-linux.tar.gz"
		package="$(mktemp -d)/$(basename "$address")"
		curl -sLA "Mozilla/5.0" "$address" -o "$package"
		sudo tar -zxvf "$package" -C "/opt"
		sudo ln -sf "/opt/android-studio/bin/studio.sh" "/bin/android-studio"
		source "$HOME/.bashrc"
	fi

	# Change the desktop file.
	desktop="/usr/share/applications/android-studio.desktop"
	cat /dev/null | sudo tee "$desktop"
	echo "[Desktop Entry]" | sudo tee -a "$desktop"
	echo "Version=1.0" | sudo tee -a "$desktop"
	echo "Type=Application" | sudo tee -a "$desktop"
	echo "Name=Android Studio" | sudo tee -a "$desktop"
	echo "Icon=androidstudio" | sudo tee -a "$desktop"
	echo 'Exec="/opt/android-studio/bin/studio.sh" %f' | sudo tee -a "$desktop"
	echo "Comment=The Drive to Develop" | sudo tee -a "$desktop"
	echo "Categories=Development;IDE;" | sudo tee -a "$desktop"
	echo "Terminal=false" | sudo tee -a "$desktop"
	echo "StartupWMClass=jetbrains-studio" | sudo tee -a "$desktop"
	echo "StartupNotify=true" | sudo tee -a "$desktop"

	# Handle the cmdline-tools installation.
	cmdline="$HOME/Android/Sdk/cmdline-tools"
	if [[ ! -d $cmdline ]]; then
		mkdir -p "$cmdline"
		website="https://developer.android.com/studio#command-tools"
		pattern="commandlinetools-win-\K(\d+)"
		version=$(curl -s "$website" | grep -oP "$pattern" | head -1)
		address="https://dl.google.com/android/repository"
		address="$address/commandlinetools-linux-${version}_latest.zip"
		archive=$(mktemp -d)/$(basename "$address")
		curl -sLA "Mozilla/5.0" "$address" -o "$archive"
		unzip -d "$cmdline" "$archive"
		# chmod -R +x "$cmdline/cmdline-tools/bin" # TODO: Check if required.
		jdkhome="/opt/android-studio/jre"
		manager="$cmdline/cmdline-tools/bin/sdkmanager"
		export JAVA_HOME="$jdkhome" && yes | $manager "cmdline-tools;latest"
		rm -rf "$cmdline/cmdline-tools"
	fi

	# Adjust the required environment variables.
	configs="$HOME/.bashrc"
	if ! grep -q "ANDROID_HOME" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >>"$configs"
		echo 'export JAVA_HOME="/opt/android-studio/jre"' >>"$configs"
		echo 'export PATH="$PATH:$JAVA_HOME/bin"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >>"$configs"
		source "$configs"
	fi

}

update_celluloid() {

	return 0

}

update_docker() {

	return 0

}

update_figma() {

	return 0

}

update_firefox() {

	return 0

}

update_flutter() {

	return 0

}

update_git() {

	return 0

}

update_gnome() {

	return 0

}

update_nodejs() {

	return 0

}

update_pycharm() {

	return 0

}

update_python() {

	# Handle the installation.
	sudo apt -y install python3 python3-dev python3-venv

}

update_quickemu() {

	return 0

}

update_system() {

	return 0

}

update_vscode() {

	return 0

}

update_ydotool() {

	return 0

}

main() {

	# Prompt for sudo password.
	sudo -v && clear

	# Remove the sudo timeout.
	echo "Defaults timestamp_timeout=-1" | sudo tee "/etc/sudoers.d/disable_timeout" &>/dev/null

	# Remove the gnome automatic screensaver.
	gsettings set org.gnome.desktop.screensaver lock-enabled false

	# Change the terminal title.
	printf "\033]0;%s\007" "ubuhogen"

	# Output the script welcome message.
	read -r -d "" welcome <<-EOD
		██╗░░░██╗██████╗░██╗░░░██╗██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
		██║░░░██║██╔══██╗██║░░░██║██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
		██║░░░██║██████╦╝██║░░░██║███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
		██║░░░██║██╔══██╗██║░░░██║██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
		╚██████╔╝██████╦╝╚██████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
		░╚═════╝░╚═════╝░░╚═════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD
	printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Handle the functions to be executed.
	factors=(
		"update_system"

		"update_git"
		"update_ydotool"

		"update_android"
		"update_firefox"
		"update_pycharm"
		"update_vscode"

		"update_docker"
		"update_flutter"
		"update_nodejs"
		"update_python"

		"update_celluloid"
		"update_figma"
		"update_quickemu"

		"update_gnome"
	)

	# Output the function execution progress.
	maximum=$((${#welcome} / $(echo "$welcome" | wc -l)))
	heading="\r%-"$((maximum - 20))"s   %-6s   %-8s\n\n"
	loading="\r%-"$((maximum - 20))"s   \033[93mACTIVE\033[0m   %-8s\b"
	failure="\r%-"$((maximum - 20))"s   \033[91mFAILED\033[0m   %-8s\n"
	success="\r%-"$((maximum - 20))"s   \033[92mWORKED\033[0m   %-8s\n"
	printf "$heading" "FUNCTION" "STATUS" "DURATION"
	for element in "${factors[@]}"; do
		written=$(basename "$(echo "$element" | cut -d '"' -f 1)" | tr "[:lower:]" "[:upper:]")
		started=$(date +"%s") && printf "$loading" "$written" "--:--:--"
		eval "$element" >/dev/null 2>&1 && current="$success" || current="$failure"
		extinct=$(date +"%s") && elapsed=$((extinct - started))
		elapsed=$(printf "%02d:%02d:%02d\n" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
		printf "$current" "$written" "$elapsed"
	done

	# Revert the gnome automatic screensaver.
	gsettings set org.gnome.desktop.screensaver lock-enabled true

	# Revert the sudo timeout.
	printf "\n" && sudo rm "/etc/sudoers.d/disable_timeout"

}

[ "${BASH_SOURCE[0]}" == "$0" ] && main
