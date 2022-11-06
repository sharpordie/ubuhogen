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
	yes | sdkmanager 'platforms;android-33'
	yes | sdkmanager 'sources;android-33'
	yes | sdkmanager 'system-images;android-33;google_apis;x86_64'
	avdmanager create avd -n 'Pixel_5_API_33' -d 'pixel_5' -k 'system-images;android-33;google_apis;x86_64'
	if [[ "$present" == "false" ]]; then
		sleep 1 && (sudo ydotoold &) &>/dev/null
		sleep 1 && (android-studio &) &>/dev/null
		# Handle the import dialog
		sleep 8 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0
		# Handle the improve dialog
		sleep 20 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		# Handle the wizard window
		sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0
		# Handle the finish button
		sleep 1 && sudo ydotool key 56:1 62:1 62:0 56:0
		sleep 1 && sudo ydotool key 28:1 28:0 && sleep 1 && sudo ydotool key 28:1 28:0
		# Finish the latest window
		sleep 8 && sudo ydotool key 56:1 62:1 62:0 56:0
	fi

	# TODO: Change project directory
	# TODO: Change line height

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

update_chromium() {

	# # Update dependencies
	sudo apt -y install flatpak
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	# Update chromium
	flatpak install -y flathub com.github.Eloston.UngoogledChromium

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
	if which "firefox" | grep -q "snap"; then
		sudo snap remove --purge firefox && sudo apt -y purge firefox
		rm -r "$HOME/snap/firefox" &>/dev/null
	fi

	# Update firefox
	configs="/etc/apt/preferences.d/firefox-no-snap"
	echo "Package: firefox*" | sudo tee "$configs"
	echo "Pin: release o=Ubuntu*" | sudo tee -a "$configs"
	echo "Pin-Priority: -1" | sudo tee -a "$configs"
	sudo add-apt-repository -y ppa:mozillateam/ppa
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

	# TODO: Update android-studio extensions
	# TODO: Update vscode extensions

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

	# Update dependencies
	sudo apt -y install curl fonts-cascadia-code jq

	# Change fonts
	gsettings set org.gnome.desktop.interface font-name "Ubuntu 10"
	gsettings set org.gnome.desktop.interface document-font-name "Sans 10"
	gsettings set org.gnome.desktop.interface monospace-font-name "Cascadia Code 10"
	gsettings set org.gnome.desktop.wm.preferences titlebar-font "Ubuntu Bold 10"
	gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false

	# Change icons
	sudo add-apt-repository -y ppa:papirus/papirus-dev
	sudo apt update && sudo apt -y install papirus-icon-theme
	gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"

	# Change theme
	gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
	gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"
	gsettings set org.gnome.gedit.preferences.editor scheme "Yaru-dark"

	# Change terminal
	profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
	deposit="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
	# gsettings set "$deposit" cell-height-scale 1.2500000000000002
	gsettings set "$deposit" cell-height-scale 1.1000000000000001
	gsettings set "$deposit" default-size-columns 96
	gsettings set "$deposit" default-size-rows 24
	gsettings set "$deposit" font "Cascadia Code 10"

	# Change backgrounds
	address="https://github.com/sharpordie/andpaper/raw/main/src/android-bottom-darken.png"
	picture="$HOME/Pictures/Backgrounds/android-bottom-darken.png"
	mkdir -p "$(dirname $picture)" && curl -Ls "$address" -o "$picture"
	# gsettings set org.gnome.desktop.background picture-uri "file://$picture"
	gsettings set org.gnome.desktop.background picture-uri-dark "file://$picture"
	gsettings set org.gnome.desktop.background picture-options "zoom"
	gsettings set org.gnome.desktop.screensaver picture-uri "file://$picture"
	gsettings set org.gnome.desktop.screensaver picture-options "zoom"

	# Change favorites
	gsettings get org.gnome.shell favorite-apps 
	gsettings set org.gnome.shell favorite-apps "[ \
		'org.gnome.Nautilus.desktop', \
		'com.github.Eloston.UngoogledChromium.desktop', \
		'firefox.desktop', \
		'org.jdownloader.JDownloader.desktop', \
		'code.desktop', \
		'org.gnome.Terminal.desktop', \
		'jetbrains-pycharm.desktop', \
		'android-studio.desktop', \
		'figma-linux.desktop', \
		'io.github.celluloid_player.Celluloid.desktop' \
	]"

	# Change dash-to-dock
	gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize
	gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
	gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
	gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false

	# Change night-light
	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 5000

	# Change nautilus
	gsettings set org.gnome.nautilus.preferences default-folder-viewer "list-view"
	gsettings set org.gtk.Settings.FileChooser show-hidden false
	gsettings set org.gtk.Settings.FileChooser sort-directories-first true

	# Remove home directory
	gsettings set org.gnome.shell.extensions.ding show-home false

	# Remove is ready notification
	update_gnome_extension "windowIsReady_Removernunofarrucagmail.com.v19.shell-extension.zip"

}

update_gnome_extension() {

	payload=${1}

	address="https://extensions.gnome.org/extension-data/$payload"
	archive="$(mktemp -d)/$(basename "$address")"
	curl -LA "Mozilla/5.0" "$address" -o "$archive"
	element="$(unzip -c "$archive" metadata.json | grep uuid | cut -d \" -f4)"
	deposit="$HOME/.local/share/gnome-shell/extensions/$element"
	if [[ ! -d "$deposit" ]]; then
		mkdir -p "$deposit"
		unzip -d "$deposit" "$archive"
		gnome-shell-extension-tool -e "$element"
		# gnome-shell --replace &
	fi

}

update_jdownloader() {

	# # Update dependencies
	sudo apt -y install flatpak
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	# Update chromium
	flatpak install -y flathub org.jdownloader.JDownloader

}

update_nodejs() {

	version=${1:-16}

	#  Update nodejs
	curl -fsSL "https://deb.nodesource.com/setup_$version.x" | sudo -E bash -
	sudo apt-get install -y nodejs npm

	# Adjust environment
	configs="$HOME/.bashrc" && deposit="$HOME/.npm-global"
	mkdir -p "$deposit" && npm config set prefix "$deposit"
	if ! grep -q ".npm-global" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export PATH="$PATH:$HOME/.npm-global/bin"' >>"$configs"
		export PATH="$PATH:$HOME/.npm-global/bin"
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

	# TODO: Change project directory
	# TODO: Change line height

}

update_python() {

	# Update python
	sudo apt -y install python3 python3-dev python3-venv

	# Adjust environment
	configs="$HOME/.bashrc"
	if ! grep -q "PYTHONDONTWRITEBYTECODE" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export PYTHONDONTWRITEBYTECODE=1' >>"$configs"
		echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$configs"
		export PYTHONDONTWRITEBYTECODE=1
		export PATH="$PATH:$HOME/.local/bin"
	fi

	# Update poetry
	curl -sSL https://install.python-poetry.org | python3 -
	poetry config virtualenvs.in-project true

}

update_quickemu() {

	return 0

}

update_system() {

	# Update system
	sudo apt -qq update && sudo apt -y upgrade && sudo apt -y dist-upgrade
	! grep -q "snap" "$HOME/.hidden" 2>/dev/null && echo "snap" >>"$HOME/.hidden"

	# Change timezone
	sudo unlink "/etc/localtime"
	sudo ln -s "/usr/share/zoneinfo/Europe/Brussels" "/etc/localtime"

}

update_vscode() {

	# Update dependencies
	sudo apt -qy install curl fonts-cascadia-code jq moreutils

	# Update code
	present="$([[ -x $(command -v code) ]] && echo "true" || echo "false")"
	if [[ $present == "false" ]]; then
		package="$(mktemp -d)/code_latest_amd64.deb"
		address="https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
		curl -LA -A "mozilla/5.0" "$address" -o "$package"
		sudo apt -y install "$package"
	fi

	# Update extensions
	code --install-extension bierner.markdown-preview-github-styles
	code --install-extension foxundermoon.shell-format
	code --install-extension github.github-vscode-theme

	# Change settings
	configs="$HOME/.config/Code/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."editor.fontFamily" = "Cascadia Code, monospace"' "$configs" | sponge "$configs"
	jq '."editor.fontSize" = 13' "$configs" | sponge "$configs"
	jq '."editor.lineHeight" = 32' "$configs" | sponge "$configs"
	jq '."security.workspace.trust.enabled" = false' "$configs" | sponge "$configs"
	jq '."telemetry.telemetryLevel" = "crash"' "$configs" | sponge "$configs"
	jq '."update.mode" = "none"' "$configs" | sponge "$configs"
	jq '."window.menuBarVisibility" = "toggle"' "$configs" | sponge "$configs"
	jq '."workbench.colorTheme" = "GitHub Dark"' "$configs" | sponge "$configs"

	# Update max_user_watches
	if ! grep -q "fs.inotify.max_user_watches" "/etc/sysctl.conf" 2>/dev/null; then
		[[ -z $(tail -1 "/etc/sysctl.conf") ]] || echo "" | sudo tee -a "/etc/sysctl.conf"
		echo "# Augment the amount of inotify watchers." | sudo tee -a "/etc/sysctl.conf"
		echo "fs.inotify.max_user_watches=524288" | sudo tee -a "/etc/sysctl.conf"
		sudo sysctl -p
	fi

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
		# "update_system"
		"update_gnome"
		# "update_git"
		# "update_ydotool"
		# "update_android_studio"
		"update_chromium"
		# "update_vscode"
		# "update_celluloid"
		# "update_docker"
		# "update_figma"
		# "update_firefox"
		# "update_flutter"
		"update_jdownloader"
		# "update_nodejs"
		# "update_pycharm"
		# "update_python"
		# "update_quickemu"
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

	# Revert timeout
	printf "\n" && sudo rm "/etc/sudoers.d/disable_timeout"

	# Revert screensaver
	gsettings set org.gnome.desktop.screensaver lock-enabled true

}

main "$@"
