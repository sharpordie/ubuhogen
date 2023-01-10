#!/usr/bin/env bash

update_android_studio() {

	# Update dependencies
	sudo apt -y install bridge-utils curl libvirt-clients libvirt-daemon-system qemu-kvm

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
		tempdir="$(mktemp -d)" && sudo tar -xvf "$package" -C "$tempdir"
		sudo mv -f "$tempdir/android-studio" "/opt/android-studio"
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

	# Update sdk
	yes | sdkmanager 'build-tools;33.0.1'
	yes | sdkmanager 'emulator'
	yes | sdkmanager 'platform-tools'
	yes | sdkmanager 'platforms;android-32'
	yes | sdkmanager 'platforms;android-33'
	yes | sdkmanager 'sources;android-33'
	yes | sdkmanager 'system-images;android-33;google_apis;x86_64'
	avdmanager create avd -n 'Pixel_3_API_33' -d 'pixel_3' -k 'system-images;android-33;google_apis;x86_64'

	# Finish installation
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

}

update_android_studio_preview() {

	# Update dependencies
	sudo apt -y install bridge-utils curl libvirt-clients libvirt-daemon-system qemu-kvm

	# Update android-studio-preview
	website="https://aur.archlinux.org/packages/android-studio-canary"
	pattern="android-studio-canary \K(\d.+)(?=-)"
	version=$(curl -s "$website" | grep -oP "$pattern" | head -1)
	present=$([[ -x $(command -v android-studio-preview) ]] && echo "true" || echo "false")
	if [[ $present == false ]]; then
		address="https://dl.google.com/dl/android/studio/ide-zips/$version/android-studio-$version-linux.tar.gz"
		package="$(mktemp -d)/$(basename "$address")"
		curl -LA "Mozilla/5.0" "$address" -o "$package"
		sudo rm -r "/opt/android-studio-preview"
		tempdir="$(mktemp -d)" && sudo tar -xvf "$package" -C "$tempdir"
		sudo mv -f "$tempdir/android-studio" "/opt/android-studio-preview"
		sudo ln -fs "/opt/android-studio-preview/bin/studio.sh" "/bin/android-studio-preview"
		source "$HOME/.bashrc"
	fi

	# Create desktop
	sudo rm "/usr/share/applications/jetbrains-studio.desktop"
	desktop="/usr/share/applications/android-studio-preview.desktop"
	cat /dev/null | sudo tee "$desktop"
	echo "[Desktop Entry]" | sudo tee -a "$desktop"
	echo "Version=1.0" | sudo tee -a "$desktop"
	echo "Type=Application" | sudo tee -a "$desktop"
	echo "Name=Android Studio Preview" | sudo tee -a "$desktop"
	echo "Icon=androidstudio-preview" | sudo tee -a "$desktop"
	echo 'Exec="/opt/android-studio-preview/bin/studio.sh" %f' | sudo tee -a "$desktop"
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
		jdkhome="/opt/android-studio-preview/jbr"
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
		echo 'export JAVA_HOME="/opt/android-studio-preview/jbr"' >>"$configs"
		echo 'export PATH="$PATH:$JAVA_HOME/bin"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >>"$configs"
		export ANDROID_HOME="$HOME/Android/Sdk"
		export JAVA_HOME="/opt/android-studio-preview/jbr"
		export PATH="$PATH:$JAVA_HOME/bin"
		export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
		export PATH="$PATH:$ANDROID_HOME/emulator"
		export PATH="$PATH:$ANDROID_HOME/platform-tools"
	fi

	# Update sdk
	yes | sdkmanager 'build-tools;33.0.1'
	yes | sdkmanager 'emulator'
	yes | sdkmanager 'platform-tools'
	yes | sdkmanager 'platforms;android-32'
	yes | sdkmanager 'platforms;android-33'
	yes | sdkmanager 'sources;android-33'
	yes | sdkmanager 'system-images;android-33;google_apis;x86_64'
	avdmanager create avd -n 'Pixel_3_API_33' -d 'pixel_3' -k 'system-images;android-33;google_apis;x86_64'

	# Finish installation
	if [[ "$present" == "false" ]]; then
		sleep 1 && (sudo ydotoold &) &>/dev/null
		sleep 1 && (android-studio-preview &) &>/dev/null
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

}

update_appearance() {

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

	# Change terminal
	profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
	deposit="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
	# gsettings set "$deposit" cell-height-scale 1.2500000000000002
	gsettings set "$deposit" cell-height-scale 1.1000000000000001
	gsettings set "$deposit" default-size-columns 96
	gsettings set "$deposit" default-size-rows 24
	gsettings set "$deposit" font "Cascadia Code 10"

	# Change desktop background
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

	# Change mouse speed
	gsettings set org.gnome.desktop.peripherals.mouse speed -1.0

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

update_gh() {

	# Update dependencies
	sudo apt -y install curl

	# Update gh
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
	sudo apt update && sudo apt install gh -y

}

update_git() {

	default=${1:-main}
	gitmail=${2:-anonymous@example.org}
	gituser=${3:-anonymous}

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

update_jdownloader() {

	deposit=${1:-$HOME/Downloads/JD2}

	# Update dependencies
	sudo apt -y install flatpak jq moreutils
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	# Update jdownloader
	flatpak install --assumeyes flathub org.jdownloader.JDownloader

	# Create deposit
	mkdir -p "$deposit"

	# Change desktop
	desktop="/var/lib/flatpak/exports/share/applications/org.jdownloader.JDownloader.desktop"
	sudo sed -i 's/Icon=.*/Icon=jdownloader/' "$desktop"

	# Change settings
	appdata="$HOME/.var/app/org.jdownloader.JDownloader/data/jdownloader"
	config1="$appdata/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
	config2="$appdata/cfg/org.jdownloader.settings.GeneralSettings.json"
	config3="$appdata/cfg/org.jdownloader.gui.jdtrayicon.TrayExtension.json"
	(flatpak run org.jdownloader.JDownloader >/dev/null 2>&1 &) && sleep 8
	while [[ ! -f "$config1" ]]; do sleep 2; done
	flatpak kill org.jdownloader.JDownloader && sleep 8
	jq '.bannerenabled = false' "$config1" | sponge "$config1"
	jq '.donatebuttonlatestautochange = 4102444800000' "$config1" | sponge "$config1"
	jq '.donatebuttonstate = "AUTO_HIDDEN"' "$config1" | sponge "$config1"
	jq '.myjdownloaderviewvisible = false' "$config1" | sponge "$config1"
	jq '.premiumalertetacolumnenabled = false' "$config1" | sponge "$config1"
	jq '.premiumalertspeedcolumnenabled = false' "$config1" | sponge "$config1"
	jq '.premiumalerttaskcolumnenabled = false' "$config1" | sponge "$config1"
	jq '.specialdealoboomdialogvisibleonstartup = false' "$config1" | sponge "$config1"
	jq '.specialdealsenabled = false' "$config1" | sponge "$config1"
	jq '.speedmetervisible = false' "$config1" | sponge "$config1"
	jq ".defaultdownloadfolder = \"$deposit\"" "$config2" | sponge "$config2"
	jq '.maxdownloadsperhostenabled = true' "$config2" | sponge "$config2"
	jq '.maxsimultanedownloadsperhost = 1' "$config2" | sponge "$config2"
	jq '.enabled = false' "$config3" | sponge "$config3"

}

update_joal_desktop() {

	# Update dependencies
	sudo apt -y install curl jq libfuse2

	# Update package
	address="https://api.github.com/repos/anthonyraymond/joal-desktop/releases"
	version=$(curl -Ls "$address" | jq -r ".[0].tag_name" | tr -d "v")
	current=""
	updated="false"
	if [[ $updated = false ]]; then
		address="https://github.com/anthonyraymond/joal-desktop/releases"
		address="$address/download/v$version/JoalDesktop-$version-linux-x86_64.AppImage"
		package="$HOME/Applications/JoalDesktop-$version.AppImage"
		mkdir -p "$HOME/Applications"
		curl -Ls "$address" -o "$package" && chmod +x "$package"
	fi

	# Change desktop
	desktop="/usr/share/applications/joal-desktop.desktop"
	cat /dev/null | sudo tee "$desktop"
	echo "[Desktop Entry]" | sudo tee -a "$desktop"
	echo "Name=JoalDesktop" | sudo tee -a "$desktop"
	echo "Exec=$HOME/Applications/JoalDesktop-$version.AppImage --no-sandbox %U" | sudo tee -a "$desktop"
	echo "Terminal=false" | sudo tee -a "$desktop"
	echo "Type=Application" | sudo tee -a "$desktop"
	# echo "Icon=appimagekit_e04f1b5d20cd264756ff6ab87e146149_joal-desktop" | sudo tee -a "$desktop"
	echo "Icon=downloader-arrow" | sudo tee -a "$desktop"
	echo "StartupWMClass=JoalDesktop" | sudo tee -a "$desktop"
	echo "X-AppImage-Version=$version" | sudo tee -a "$desktop"
	echo "Comment=A tool to fake your torrent tracker upload" | sudo tee -a "$desktop"
	echo "Categories=Utility;" | sudo tee -a "$desktop"
	echo "TryExec=$HOME/Applications/JoalDesktop-$version.AppImage" | sudo tee -a "$desktop"
	# echo "X-AppImage-Old-Icon=joal-desktop" | sudo tee -a "$desktop"
	# echo "X-AppImage-Identifier=e04f1b5d20cd264756ff6ab87e146149" | sudo tee -a "$desktop"


}

update_keepassxc() {

	# Update keepassxc
	sudo add-apt-repository -y ppa:phoerious/keepassxc
	sudo apt update && sudo apt -y install keepassxc

}

update_mambaforge() {

	# Handle adjunct
	deposit=${1:-$HOME/.mambaforge}

	# Update package
	present=$([[ -x "$(which mamba)" ]] && echo true || echo false)
	if [[ $present = false ]]; then
		address="https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
		fetched="$(mktemp -d)/$(basename "$address")"
		curl -L "$address" -o "$fetched" && sh "$fetched" -b -p "$deposit"
	fi

	# Change environ
	"$deposit/condabin/conda" init
	"$deposit/condabin/mamba" init

	# Change configs
	"$deposit/condabin/conda" config --set auto_activate_base false

}

update_nodejs() {

	version=${1:-16}

	# Update nodejs
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
		usagent="Mozilla/5.0"
		curl -LA "$usagent" "$address" -o "$package"
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

	# Update quickemu
	sudo add-apt-repository -y ppa:flexiondotorg/quickemu
	sudo apt update && sudo apt -y install quickemu

	# # Create macos vm
	# current=$(dirname "$(readlink -f "$0")") && deposit="$HOME/Machines"
	# mkdir -p "$deposit" && cd "$deposit" && quickget macos monterey
	# quickemu --vm macos-monterey.conf --shortcut && cd "$current"
	# desktop="$HOME/.local/share/applications/macos-monterey.desktop"
	# sed -i "s/Icon=.*/Icon=distributor-logo-mac/" "$desktop"
	# sed -i "s/Name=.*/Name=Monterey/" "$desktop"

	# # Create windows vm
	# current=$(dirname "$(readlink -f "$0")") && deposit="$HOME/Machines"
	# mkdir -p "$deposit" && cd "$deposit" && quickget windows 11
	# quickemu --vm windows-11.conf --shortcut && cd "$current"
	# desktop="$HOME/.local/share/applications/windows-11.desktop"
	# sed -i "s/Icon=.*/Icon=windows95/" "$desktop"
	# sed -i "s/Name=.*/Name=Windows/" "$desktop"

}

update_ubuntu() {

	# Change the hostname.
	hostnamectl hostname ubuhogen

	# Change timezone
	sudo unlink "/etc/localtime"
	sudo ln -s "/usr/share/zoneinfo/Europe/Brussels" "/etc/localtime"

	# Update system
	sudo apt -qq update && sudo apt -y upgrade && sudo apt -y dist-upgrade
	! grep -q "snap" "$HOME/.hidden" 2>/dev/null && echo "snap" >>"$HOME/.hidden"

	# Update firmware
	sudo fwupdmgr get-devices && sudo fwupdmgr refresh --force
	sudo fwupdmgr get-updates && sudo fwupdmgr update -y

	# Remove firefox
	if which "firefox" | grep -q "snap"; then
		sudo snap remove --purge firefox && sudo apt -y purge firefox
		rm -r "$HOME/snap/firefox" &>/dev/null
	fi

}

update_vscode() {

	# Update dependencies
	sudo apt -y install curl fonts-cascadia-code jq moreutils

	# Update code
	present="$([[ -x $(command -v code) ]] && echo "true" || echo "false")"
	if [[ $present == "false" ]]; then
		package="$(mktemp -d)/code_latest_amd64.deb"
		address="https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
		curl -LA "mozilla/5.0" "$address" -o "$package"
		sudo apt -y install "$package"
	fi

	# Update extensions
	code --install-extension bierner.markdown-preview-github-styles --force
	code --install-extension foxundermoon.shell-format --force
	code --install-extension github.github-vscode-theme --force

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
	jq '."workbench.colorTheme" = "GitHub Dark Default"' "$configs" | sponge "$configs"

	# Update max_user_watches
	if ! grep -q "fs.inotify.max_user_watches" "/etc/sysctl.conf" 2>/dev/null; then
		[[ -z $(tail -1 "/etc/sysctl.conf") ]] || echo "" | sudo tee -a "/etc/sysctl.conf"
		echo "# Augment the amount of inotify watchers" | sudo tee -a "/etc/sysctl.conf"
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
	gsettings set org.gnome.desktop.session idle-delay 0

	# Remove notifications
	gsettings set org.gnome.desktop.notifications show-banners false

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
		"update_ubuntu"
		"update_appimagelauncher"
		"update_ydotool"

		# "update_android_studio"
		"update_android_studio_preview"
		"update_chromium"
		"update_git main sharpordie@outlook.com sharpordie"
		"update_vscode"
		
		"update_celluloid"
		"update_docker"
		"update_figma"
		"update_flutter"
		"update_gh"
		"update_jdownloader"
		"update_keepassxc"
		"update_nodejs"
		"update_pycharm"
		"update_python"
		"update_quickemu"

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

	# Revert timeout
	sudo rm "/etc/sudoers.d/disable_timeout"

	# Revert screensaver
	gsettings set org.gnome.desktop.screensaver lock-enabled true
	gsettings set org.gnome.desktop.session idle-delay 300

	# Revert notifications
	gsettings set org.gnome.desktop.notifications show-banners true

	# Output newline
	printf "\n"

}

main
