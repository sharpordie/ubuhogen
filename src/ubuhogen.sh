#!/usr/bin/env bash

update_android_studio() {

	# Update dependencies
	sudo apt -y install curl

	# Update android-studio
	website="https://developer.android.com/studio#downloads"
	pattern="android-studio-\K(\d.+)(?=-linux)"
	version="$(curl -s "$website" | grep -oP "$pattern" | head -1)"
	present="$([[ -x $(command -v android-studio) ]] && echo "true" || echo "false")"
	if [[ "$present" == "false" ]]; then
		address="https://dl.google.com/dl/android/studio/ide-zips/$version/android-studio-$version-linux.tar.gz"
		package="$(mktemp -d)/$(basename "$address")"
		curl -LA "Mozilla/5.0" "$address" -o "$package"
		sudo rm -r "/opt/android-studio"
		sudo tar -zxvf "$package" -C "/opt"
		sudo ln -fs "/opt/android-studio/bin/studio.sh" "/bin/android-studio"
		source "$HOME/.bashrc"
	fi

	# Create desktop
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

	# Update cmdline-tools
	cmdline="$HOME/Android/Sdk/cmdline-tools"
	if [[ ! -d $cmdline ]]; then
		mkdir -p "$cmdline"
		website="https://developer.android.com/studio#command-tools"
		pattern="commandlinetools-win-\K(\d+)"
		version="$(curl -s "$website" | grep -oP "$pattern" | head -1)"
		address="https://dl.google.com/android/repository"
		address="$address/commandlinetools-linux-${version}_latest.zip"
		archive="$(mktemp -d)/$(basename "$address")"
		curl -LA "Mozilla/5.0" "$address" -o "$archive"
		unzip -d "$cmdline" "$archive"
		jdkhome="/opt/android-studio/jre"
		manager="$cmdline/cmdline-tools/bin/sdkmanager"
		export JAVA_HOME="$jdkhome" && yes | $manager "cmdline-tools;latest"
		rm -rf "$cmdline/cmdline-tools"
	fi

	# Adjust environment
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
		export ANDROID_HOME="$HOME/Android/Sdk"
		export JAVA_HOME="/opt/android-studio/jre"
		export PATH="$PATH:$JAVA_HOME/bin"
		export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
		export PATH="$PATH:$ANDROID_HOME/emulator"
		export PATH="$PATH:$ANDROID_HOME/platform-tools"
	fi

	# Finish installation
	yes | sdkmanager 'build-tools;33.0.0'
	yes | sdkmanager 'emulator'
	yes | sdkmanager 'platform-tools'
	yes | sdkmanager 'platforms;android-32'
	yes | sdkmanager 'platforms;android-33'
	yes | sdkmanager 'sources;android-33'
	yes | sdkmanager 'system-images;android-33;google_apis;x86_64'
	avdmanager create avd -n 'Pixel_5' -d 'pixel_5' -k 'system-images;android-33;google_apis;x86_64'
	if [[ "$present" == "false" ]]; then
		sleep 1 && (sudo ydotoold &) &>/dev/null
		sleep 1 && (android-studio &) &>/dev/null
		# Handle the import dialog
		sleep 8 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0 # {TAB} + {ENTER}
		# Handle the improve dialog
		sleep 20 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0 # {TAB} + {TAB} + {ENTER}
		# Handle the wizard window
		sleep 1 && sudo ydotool key 28:1 28:0 # {ENTER}
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0 # {TAB} + {TAB} + {ENTER}
		sleep 1 && sudo ydotool key 28:1 28:0 # {ENTER}
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0 # {TAB} + {TAB} + {ENTER}
		sleep 1 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0 # {TAB} + {ENTER}
		# Handle the finish button
		sleep 1 && sudo ydotool key 56:1 62:1 62:0 56:0 # {ALT}{F4}
		sleep 1 && sudo ydotool key 28:1 28:0 && sleep 1 && sudo ydotool key 28:1 28:0 # {ENTER} + {ENTER}
		# Finish the latest window
		sleep 8 && sudo ydotool key 56:1 62:1 62:0 56:0 # {ALT}{F4}
	fi

}

update_celluloid() {

	# Update celluloid
	sudo add-apt-repository -y ppa:xuzhen666/gnome-mpv
	sudo apt update && sudo apt -y install celluloid

	# Update yt-dlp
	address"https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"
	package"/usr/local/bin/yt-dlp"
	sudo url -LA "Mozilla/5.0" "$address" -o "$package"
	sudo chmod a+rx "$package"

	# Create mpv.conf
	config1="$HOME/.config/celluloid/mpv.conf"
	mkdir -p "$(dirname "$config1")" && cat /dev/null >"$config1"
	echo "profile=gpu-hq" >>"$config1"
	echo "vo=gpu-next" >>"$config1"
	echo "hwdec=auto-copy" >>"$config1"
	echo "keep-open=yes" >>"$config1"
	echo "save-position-on-quit=yes" >>"$config1"
	echo 'ytdl-format="bestvideo[height<=?2160]+bestaudio/best"' >>"$config1"
	echo "[protocol.http]" >>"$config1"
	echo "force-window=immediate" >>"$config1"
	echo "[protocol.https]" >>"$config1"
	echo "profile=protocol.http" >>"$config1"
	echo "[protocol.ytdl]" >>"$config1"
	echo "profile=protocol.http" >>"$config1"

	# Create input.conf
	config2="$HOME/.config/celluloid/input.conf"
	mkdir -p "$(dirname "$config2")" && cat /dev/null >"$config2"

	# Change settings
	dconf write /io/github/celluloid-player/celluloid/mpv-config-enable true
	dconf write /io/github/celluloid-player/celluloid/mpv-config-file "'file://$config1'"
	dconf write /io/github/celluloid-player/celluloid/mpv-input-config-enable true
	dconf write /io/github/celluloid-player/celluloid/mpv-input-config-file "'file://$config2'"
	dconf write /io/github/celluloid-player/celluloid/mpv-options "''"

}

update_docker() {

	# Update dependencies
	sudo apt -y install apt-transport-https ca-certificates curl software-properties-common

	# Update docker
	curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | sudo gpg --dearmor --yes -o "/usr/share/keyrings/docker-archive-keyring.gpg"
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
	sudo apt update && sudo apt -y install docker-ce docker-compose-plugin
	sudo usermod -aG docker $USER

}

update_figma() {

	# Update dependencies
	sudo apt -y install apt-show-versions curl jq

	# Update figma-linux
	website="https://api.github.com/repos/Figma-Linux/figma-linux/releases"
	version="$(curl -s "$website" | jq -r ".[0].tag_name" | tr -d "v")"
	current="$(apt-show-versions figma-linux | grep -oP "[\d.]+" | tail -1)"
	updated="$([[ ${current:0:4} == "${version:0:4}" ]] && echo "true" || echo "false")"
	if [[ "$updated" == "false" ]]; then
		address="https://github.com/Figma-Linux/figma-linux/releases/download/v$version/figma-linux_${version}_linux_amd64.deb"
		package="$(mktemp -d)/$(basename "$address")"
		curl -LA "Mozilla/5.0" "$address" -o "$package"
		sudo apt install -y "$package"
	fi

	# Adjust desktop
	desktop="/usr/share/applications/figma-linux.desktop"
	sudo sed -i "s/Name=.*/Name=Figma/" "$desktop"

}

update_firefox() {

	# Remove package
	sudo snap remove --purge firefox

	# Update firefox
	sudo add-apt-repository -y ppa:mozillateam/ppa
	configs="/etc/apt/preferences.d/mozillateamppa"
	echo "Package: firefox*" | sudo tee "$configs"
	echo "Pin: release o=LP-PPA-mozillateam" | sudo tee -a "$configs"
	echo "Pin-Priority: 501" | sudo tee -a "$configs"
	sudo apt update && sudo apt -y install firefox

}

update_flutter() {

	# Update dependencies
	sudo apt -y install build-essential clang cmake curl git
	sudo apt -y install libgtk-3-dev ninja-build pkg-config

	# Update flutter
	deposit="$HOME/Android/Flutter" && mkdir -p "$deposit"
	git clone "https://github.com/flutter/flutter.git" -b stable "$deposit"

	# Adjust environment
	configs="$HOME/.bashrc"
	if ! grep -q "Flutter" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export PATH="$PATH:$HOME/Android/Flutter/bin"' >>"$configs"
		export PATH="$PATH:$HOME/Android/Flutter/bin"
	fi

	# Change settings
	flutter config --no-analytics

	# Finish installation
	flutter precache
	flutter upgrade

	# Accept licenses
	yes | flutter doctor --android-licenses

}

update_git() {

	default=${1:-master}
	gitmail=${2:-sharpordie@outlook.com}
	gituser=${3:-sharpordie}

	# Update git
	sudo add-apt-repository -y ppa:git-core/ppa
	sudo apt update && sudo apt -y install git

	# Change settings
	git config --global credential.helper "store"
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"
	git config --global user.email "$gitmail"
	git config --global user.name "$gituser"

}

update_gnome() {

	return 0

}

update_nodejs() {

	version=${1:-16}

	#  Update nodejs
	curl -fsSL "https://deb.nodesource.com/setup_$version.x" | sudo -E bash -
	sudo apt-get install -y nodejs

	# Adjust environment
	configs="$HOME/.bashrc" && deposit="$HOME/.npm-global"
	mkdir -p "$deposit" && npm config set prefix "$deposit"
	if ! grep -q ".npm-global" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export PATH="$PATH:$HOME/.npm-global/bin"' >>"$configs"
		source "$configs"
	fi

	# Change settings
	npm set audit false

	# Update modules
	npm install -g pnpm

}

update_pycharm() {

	# Update dependencies
	sudo apt -y install curl jq

	# Update pycharm-professional
	website="https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&type=release"
	version="$(curl -Ls "$website" | jq -r ".PCP[0].version")"
	present="$([[ -x $(command -v pycharm) ]] && echo "true" || echo "false")"
	if [[ "$present" == "false" ]]; then
		address="https://download.jetbrains.com/python/pycharm-professional-$version.tar.gz"
		package="$(mktemp -d)/$(basename "$address")"
		curl -LA "Mozilla/5.0" "$address" -o "$package"
		sudo rm -r "/opt/pycharm"
		sudo tar -zxvf "$package" -C "/opt"
		sudo mv /opt/pycharm-* "/opt/pycharm"
		sudo ln -sf "/opt/pycharm/bin/pycharm.sh" "/bin/pycharm"
		source "$HOME/.bashrc"
	fi

	# Change desktop
	desktop="/usr/share/applications/jetbrains-pycharm.desktop"
	cat /dev/null | sudo tee "$desktop"
	echo "[Desktop Entry]" | sudo tee -a "$desktop"
	echo "Version=1.0" | sudo tee -a "$desktop"
	echo "Type=Application" | sudo tee -a "$desktop"
	echo "Name=PyCharm" | sudo tee -a "$desktop"
	echo "Icon=pycharm" | sudo tee -a "$desktop"
	echo 'Exec="/opt/pycharm/bin/pycharm.sh" %f' | sudo tee -a "$desktop"
	echo "Comment=Python IDE for Professional Developers" | sudo tee -a "$desktop"
	echo "Categories=Development;IDE;" | sudo tee -a "$desktop"
	echo "Terminal=false" | sudo tee -a "$desktop"
	echo "StartupWMClass=jetbrains-pycharm" | sudo tee -a "$desktop"
	echo "StartupNotify=true" | sudo tee -a "$desktop"

	# Finish installation
	# if [[ "$present" == "false" ]]; then
	# fi

}

update_python() {

	# Update python
	sudo apt -y install python3 python3-dev python3-venv

	# Update poetry

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

	# Update dependencies
	sudo apt -y install build-essential cmake git libboost-program-options-dev scdoc

	# Remove package
	sudo apt -y autoremove --purge ydotool

	# Update ydotool
	current=$(dirname "$(readlink -f "$0")") && git clone "https://github.com/ReimuNotMoe/ydotool.git"
	cd ydotool && mkdir build && cd build && cmake .. && make && sudo make install
	cd "$current" && source "$HOME/.bashrc" && rm -rf ydotool

}

main() {

	# Prompt password
	sudo -v && clear

	# Remove timeout
	echo "Defaults timestamp_timeout=-1" | sudo tee "/etc/sudoers.d/disable_timeout" &>/dev/null

	# Remove screensaver
	gsettings set org.gnome.desktop.screensaver lock-enabled false

	# Change title
	printf "\033]0;%s\007" "ubuhogen"

	# Output welcome
	read -r -d "" welcome <<-EOD
		██╗░░░██╗██████╗░██╗░░░██╗██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
		██║░░░██║██╔══██╗██║░░░██║██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
		██║░░░██║██████╦╝██║░░░██║███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
		██║░░░██║██╔══██╗██║░░░██║██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
		╚██████╔╝██████╦╝╚██████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
		░╚═════╝░╚═════╝░░╚═════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD
	printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Handle functions
	factors=(
		"update_system"
		"update_git"
		"update_ydotool"
		"update_android_studio"
		# "update_firefox"
		# "update_pycharm"
		# "update_vscode"
		# "update_docker"
		# "update_flutter"
		# "update_nodejs"
		# "update_python"
		# "update_celluloid"
		# "update_figma"
		# "update_quickemu"
		# "update_gnome"
	)

	# Output progress
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

	# Revert screensaver
	gsettings set org.gnome.desktop.screensaver lock-enabled true

	# Revert timeout
	printf "\n" && sudo rm "/etc/sudoers.d/disable_timeout"

}

main "$@"
