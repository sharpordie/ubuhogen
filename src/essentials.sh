#!/usr/bin/env bash

update_android_cmdline() {

	# Update dependencies
	sudo apt install -y default-jdk

	# Update package
	sdkroot="$HOME/.android/sdk"
	deposit="$sdkroot/cmdline-tools"
	if [[ ! -d $deposit ]]; then
		mkdir -p "$deposit"
		website="https://developer.android.com/studio#command-tools"
		version="$(curl -s "$website" | grep -oP "commandlinetools-linux-\K(\d+)" | head -1)"
		address="https://dl.google.com/android/repository/commandlinetools-linux-${version}_latest.zip"
		archive="$(mktemp -d)/$(basename "$address")"
		curl -LA "Mozilla/5.0" "$address" -o "$archive"
		unzip -d "$deposit" "$archive"
		yes | "$deposit/cmdline-tools/bin/sdkmanager" --sdk_root="$sdkroot" "cmdline-tools;latest"
		rm -rf "$deposit/cmdline-tools"
	fi

	# Change environment
	configs="$HOME/.bashrc"
	if ! grep -q "ANDROID_HOME" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export ANDROID_HOME="$HOME/.android/sdk"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >>"$configs"
		export ANDROID_HOME="$HOME/.android/sdk"
		export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
		export PATH="$PATH:$ANDROID_HOME/emulator"
		export PATH="$PATH:$ANDROID_HOME/platform-tools"
	fi

}

update_android_studio() {

	# Handle parameters
	release=${1:-beta}
	deposit=${2:-$HOME/Projects}

	# Update dependencies
	sudo apt install -y bridge-utils curl libvirt-clients libvirt-daemon-system qemu-kvm

	# Update package
	[[ $release = sta* || $release = bet* || $release = can* ]] || return 1
	[[ $release = sta* ]] && payload="android-studio"
	[[ $release = bet* ]] && payload="android-studio-beta"
	[[ $release = can* ]] && payload="android-studio-canary"
	address="https://aur.archlinux.org/packages/$payload"
	version=$(curl -s "$address" | grep -oP "android-studio.* \K(\d.+)(?=-)" | head -1)
	current=$(cat "/opt/$payload/product-info.json" | jq -r ".dataDirectoryName" | grep -oP "(\d.+)" || echo "0.0.0.0")
	present=$([[ -f "/opt/$payload/bin/studio.sh" ]] && echo true || echo false)
	updated=$(dpkg --compare-versions "$current" "ge" "${version:0:6}" && echo true || echo false)
	if [[ $updated == false ]]; then
		address="https://dl.google.com/dl/android/studio/ide-zips/$version/android-studio-$version-linux.tar.gz"
		package="$(mktemp -d)/$(basename "$address")"
		curl -LA "Mozilla/5.0" "$address" -o "$package"
		sudo rm -r "/opt/$payload"
		tempdir="$(mktemp -d)" && sudo tar -xvf "$package" -C "$tempdir"
		sudo mv -f "$tempdir/android-studio" "/opt/$payload"
		sudo ln -fs "/opt/$payload/bin/studio.sh" "/bin/$payload"
		source "$HOME/.bashrc"
	fi

	# Create desktop
	sudo rm "/usr/share/applications/jetbrains-studio.desktop"
	desktop="/usr/share/applications/$payload.desktop"
	cat /dev/null | sudo tee "$desktop"
	echo "[Desktop Entry]" | sudo tee -a "$desktop"
	echo "Version=1.0" | sudo tee -a "$desktop"
	echo "Type=Application" | sudo tee -a "$desktop"
	echo "Name=Android Studio" | sudo tee -a "$desktop"
	echo "Icon=androidstudio" | sudo tee -a "$desktop"
	echo "Exec=\"/opt/$payload/bin/studio.sh\" %f" | sudo tee -a "$desktop"
	echo "Comment=The Drive to Develop" | sudo tee -a "$desktop"
	echo "Categories=Development;IDE;" | sudo tee -a "$desktop"
	echo "Terminal=false" | sudo tee -a "$desktop"
	echo "StartupWMClass=jetbrains-studio" | sudo tee -a "$desktop"
	echo "StartupNotify=true" | sudo tee -a "$desktop"
	[[ $release = bet* ]] && sudo sed -i "s/Name=.*/Name=Android Studio Beta/" "$desktop"
	[[ $release = can* ]] && sudo sed -i "s/Icon=.*/Icon=androidstudio-canary/" "$desktop"
	[[ $release = can* ]] && sudo sed -i "s/Name=.*/Name=Android Studio Canary/" "$desktop"

	# TODO: Change settings
	# update_jetbrains_config "Android" "directory" "$deposit"
	# update_jetbrains_config "Android" "font_size" "14"
	# update_jetbrains_config "Android" "line_size" "1.5"
	# [[ $release = can* ]] && update_jetbrains_config "AndroidPreview" "newest_ui" "true"

	# Finish installation
	if [[ $present == false ]]; then
		update_android_cmdline || return 1
		[[ $release = sta* ]] && channel=0
		[[ $release = bet* ]] && channel=1
		[[ $release = can* ]] && channel=2
		yes | sdkmanager --channel=$channel "build-tools;33.0.1"
		yes | sdkmanager --channel=$channel "emulator"
		yes | sdkmanager --channel=$channel "emulator"
		yes | sdkmanager --channel=$channel "patcher;v4"
		yes | sdkmanager --channel=$channel "platform-tools"
		yes | sdkmanager --channel=$channel "platforms;android-33"
		yes | sdkmanager --channel=$channel "platforms;android-33-ext4"
		yes | sdkmanager --channel=$channel "sources;android-33"
		yes | sdkmanager --channel=$channel "system-images;android-33;google_apis;x86_64"
		yes | sdkmanager --channel=$channel --licenses
		avdmanager create avd -n "Pixel_3_API_33" -d "pixel_3" -k "system-images;android-33;google_apis;x86_64" -f
		# update_ydotool || return 1
		# gsettings set org.gnome.desktop.notifications show-banners false
		# sleep 1 && (sudo ydotoold &) &>/dev/null
		# sleep 1 && ($payload &) &>/dev/null
		# sleep 8 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0
		# sleep 20 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		# sleep 1 && sudo ydotool key 28:1 28:0
		# sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		# sleep 1 && sudo ydotool key 28:1 28:0
		# sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		# sleep 1 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0
		# sleep 1 && sudo ydotool key 56:1 62:1 62:0 56:0
		# sleep 1 && sudo ydotool key 28:1 28:0 && sleep 1 && sudo ydotool key 28:1 28:0
		# sleep 8 && sudo ydotool key 56:1 62:1 62:0 56:0
	fi

}

update_appearance() {

	# Change terminal
	profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
	deposit="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
	gsettings set "$deposit" font "Ubuntu Mono 12"
	gsettings set "$deposit" cell-height-scale 1.1000000000000001
	gsettings set "$deposit" default-size-columns 96
	gsettings set "$deposit" default-size-rows 24
	gsettings set "$deposit" use-theme-colors false
	gsettings set "$deposit" foreground-color "rgb(208,207,204)"
	gsettings set "$deposit" background-color "rgb(23,20,33)"

	# Change fonts
	# sudo apt install -y fonts-cascadia-code
	# gsettings set org.gnome.desktop.interface font-name "Ubuntu 10"
	# gsettings set org.gnome.desktop.interface document-font-name "Sans 10"
	# gsettings set org.gnome.desktop.interface monospace-font-name "Ubuntu Mono 12"
	# gsettings set org.gnome.desktop.wm.preferences titlebar-font "Ubuntu Bold 10"
	# gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false

	# Change icons
	sudo add-apt-repository -y ppa:papirus/papirus-dev
	sudo apt update && sudo apt install -y papirus-folders papirus-icon-theme
	gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
	sudo papirus-folders --color yaru --theme Papirus-Dark

	# Change theme
	gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
	gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"
	
	# Change desktop
	sudo apt install -y curl
	address="https://raw.githubusercontent.com/sharpordie/odoowall/master/src/odoo-higher-darken.png"
	picture="$HOME/Pictures/Backgrounds/$(basename "$address")"
	mkdir -p "$(dirname $picture)" && curl -L "$address" -o "$picture"
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
	sudo ./ubuntu-gdm-set-background --image "$picture" || rm ./ubuntu-gdm-set-background

	# Change favorites
	update-desktop-database .
	gsettings set org.gnome.shell favorite-apps "[ \
		'org.gnome.Nautilus.desktop', \
		'com.github.Eloston.UngoogledChromium.desktop', \
		'org.gnome.Terminal.desktop' \
	]"

	# Change dash-to-dock
	gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize
	gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
	gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
	gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false

	# Change nautilus
	gsettings set org.gnome.nautilus.preferences default-folder-viewer "list-view"
	gsettings set org.gtk.Settings.FileChooser show-hidden false
	gsettings set org.gtk.Settings.FileChooser sort-directories-first true
	nautilus -q

	# Change night-light
	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 5000

	# Remove snap directory
	! grep -q "snap" "$HOME/.hidden" 2>/dev/null && echo "snap" >>"$HOME/.hidden"

	# Remove home directory
	gsettings set org.gnome.shell.extensions.ding show-home false

}

update_chromium() {

	# Handle parameters
	deposit=${1:-$HOME/Downloads/DDL}
	startup=${2:-about:blank}

	# Update dependencies
	update_ydotool || return 1
	sudo apt install -y curl flatpak jq

	# Update package
	starter="/var/lib/flatpak/exports/bin/com.github.Eloston.UngoogledChromium"
	present=$([[ -f "$starter" ]] && echo true || echo false)
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	sudo flatpak remote-modify --enable flathub
	flatpak install -y flathub com.github.Eloston.UngoogledChromium

	# Change default browser
	xdg-settings set default-web-browser "com.github.Eloston.UngoogledChromium.desktop"
	xdg-settings check default-web-browser "com.github.Eloston.UngoogledChromium.desktop"
	# xdg-mime default "com.github.Eloston.UngoogledChromium.desktop" x-scheme-handler/https x-scheme-handler/http

	# Change environment
	configs="$HOME/.bashrc"
	if ! grep -q "CHROME_EXECUTABLE" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export CHROME_EXECUTABLE="/var/lib/flatpak/exports/bin/com.github.Eloston.UngoogledChromium"' >>"$configs"
		export CHROME_EXECUTABLE="/var/lib/flatpak/exports/bin/com.github.Eloston.UngoogledChromium"
	fi

	# Finish installation
	# INFO: Use `sudo showkey -k` to display keycodes
	if [[ $present = false ]]; then

		# Launch chromium
		sleep 1 && (sudo ydotoold &) &>/dev/null
		sleep 1 && (flatpak run com.github.Eloston.UngoogledChromium &) &>/dev/null
		sleep 4 && sudo ydotool key 125:1 103:1 103:0 125:0

		# Change deposit
		mkdir -p "$deposit"
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://settings/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "before downloading" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 56:1 15:1 15:0 56:0 && sleep 1 && sudo ydotool key 56:1 15:1 15:0 56:0
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0 && sleep 1 && sudo ydotool type "$deposit" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change engine
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://settings/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "search engines" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "duckduckgo" && sleep 1 && sudo ydotool key 28:1 28:0

		# Change custom-ntp
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "custom-ntp" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 5); do sleep 0.5 && sudo ydotool key 15:1 15:0; done
		sleep 1 && sudo ydotool key 29:1 30:1 30:0 29:0 && sleep 1 && sudo ydotool type "$startup"
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change extension-mime-request-handling
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "extension-mime-request-handling" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 108:1 108:0; done && sleep 1 && sudo ydotool key 28:1 28:0

		# Change hide-sidepanel-button
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "hide-sidepanel-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change remove-tabsearch-button
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "remove-tabsearch-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change show-avatar-button
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "show-avatar-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 108:1 108:0; done && sleep 1 && sudo ydotool key 28:1 28:0

		# Remove bookmark bar (ctr+shift+b)
		sleep 4 && sudo ydotool key 29:1 42:1 48:1 48:0 42:0 29:0

		# Finish chromium
		sleep 4 && sudo ydotool key 56:1 62:1 62:0 56:0

		# Update chromium-web-store
		website="https://api.github.com/repos/NeverDecaf/chromium-web-store/releases"
		version=$(curl -Ls "$website" | jq -r ".[0].tag_name" | tr -d "v")
		address="https://github.com/NeverDecaf/chromium-web-store/releases/download/v$version/Chromium.Web.Store.crx"
		update_chromium_extension "$address"

		# Update extensions
		update_chromium_extension "bcjindcccaagfpapjjmafapmmgkkhgoa" # json-formatter
		update_chromium_extension "ibplnjkanclpjokhdolnendpplpjiace" # simple-translate
		update_chromium_extension "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock-for-youtube
		update_chromium_extension "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock-origin

	fi

}

update_chromium_extension() {

	# Handle parameters
	payload=${1}

	# Update dependencies
	update_ydotool || return 1
	sudo apt install -y curl

	# Update extension
	starter="/var/lib/flatpak/exports/bin/com.github.Eloston.UngoogledChromium"
	present=$([[ -f "$starter" ]] && echo true || echo false)
	if [[ $present = true ]]; then
		flatpak kill com.github.Eloston.UngoogledChromium
		sudo flatpak override com.github.Eloston.UngoogledChromium --filesystem=/tmp
		if [ "${payload:0:4}" == "http" ]; then
			address="$payload"
			package="$(mktemp -d)/$(basename "$address")"
		else
			version="$(flatpak run com.github.Eloston.UngoogledChromium --product-version)"
			address="https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3"
			address="${address}&prodversion=${version}&x=id%3D${payload}%26installsource%3Dondemand%26uc"
			package="$(mktemp -d)/$payload.crx"
		fi
		curl -L "$address" -o "$package" || return 1
		sleep 1 && (sudo ydotoold &) &>/dev/null
		sleep 1 && (flatpak run com.github.Eloston.UngoogledChromium "$package" &) &>/dev/null
		sleep 4 && sudo ydotool key 125:1 103:1 103:0 125:0
		sleep 2 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 2 && sudo ydotool key 56:1 62:1 62:0 56:0
	fi

}

update_flutter() {

	# Update dependencies
	sudo apt -y install build-essential clang cmake curl git libgtk-3-dev ninja-build pkg-config

	# Update package
	deposit="$HOME/.android/flutter" && mkdir -p "$deposit"
	git clone "https://github.com/flutter/flutter.git" -b stable "$deposit"

	# Adjust environment
	configs="$HOME/.bashrc"
	if ! grep -q "flutter" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export PATH="$PATH:$HOME/.android/flutter/bin"' >>"$configs"
		export PATH="$PATH:$HOME/.android/flutter/bin"
	fi

	# Finish installation
	flutter channel stable
	flutter precache && flutter upgrade
	dart --disable-analytics
	flutter config --no-analytics
	yes | flutter doctor --android-licenses

	# Update vscode
	present=$([[ -x "$(which code)" ]] && echo true || echo false)
	if [[ $present == false ]]; then
		code --install-extension "dart-code.flutter" &>/dev/null
		code --install-extension "RichardCoutts.mvvm-plus" &>/dev/null
	fi

	# Update android-studio
	product=$(find /opt/android-* -maxdepth 0 2>/dev/null | sort -r | head -1)
	update_jetbrains_plugin "$product" "6351"  # dart
	update_jetbrains_plugin "$product" "9212"  # flutter
	update_jetbrains_plugin "$product" "13666" # flutter-intl
	update_jetbrains_plugin "$product" "14641" # flutter-riverpod-snippets

}

update_jetbrains_plugin() {

	# Handle parameters
	deposit=${1:-/opt/android-studio}
	element=${2}

	# Update dependencies
	[[ -d "$deposit" && -n "$element" ]] || return 0
	sudo apt install -y curl jq

	# Update plugin
	release=$(cat "$deposit/product-info.json" | jq -r ".buildNumber" | grep -oP "(\d.+)")
	datadir=$(cat "$deposit/product-info.json" | jq -r ".dataDirectoryName")
	adjunct=$([[ $datadir == "AndroidStudio"* ]] && echo "Google/$datadir" || "JetBrains/$datadir")
	plugins="$HOME/.local/share/$adjunct" && mkdir -p "$plugins"
	for i in {1..3}; do
		for j in {0..19}; do
			address="https://plugins.jetbrains.com/api/plugins/$element/updates?page=$i"
			maximum=$(curl -s "$address" | jq ".[$j].until" | tr -d '"' | sed "s/\.\*/\.9999/")
			minimum=$(curl -s "$address" | jq ".[$j].since" | tr -d '"' | sed "s/\.\*/\.9999/")
			if dpkg --compare-versions "${minimum:-0000}" "le" "$release" && dpkg --compare-versions "$release" "le" "${maximum:-9999}"; then
				address=$(curl -s "$address" | jq ".[$j].file" | tr -d '"')
				address="https://plugins.jetbrains.com/files/$address"
				archive="$(mktemp -d)/$(basename "$address")"
				curl -LA "Mozilla/5.0" "$address" -o "$archive"
				unzip -o "$archive" -d "$plugins"
				break 2
			fi
			sleep 1
		done
	done

}

update_nvidia() {

	# Update package
	[[ $(lspci | grep -e VGA) == *"NVIDIA"* ]] || return 1
	sudo apt update && sudo apt upgrade -y
	sudo apt update && sudo apt install -y nvidia-driver

}

update_nvidia_cuda() {

	# Update dependencies
	[[ $(lspci | grep -e VGA) == *"NVIDIA"* ]] || return 1
	sudo apt install -y apt-transport-https ca-certificates curl dirmngr dkms software-properties-common

	# Update package
	address="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub"
	curl -fSsL "$address" | sudo gpg --dearmor | sudo tee /usr/share/keyrings/nvidia-drivers.gpg >/dev/null 2>&1
	content="deb [signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /"
	echo "$content" | sudo tee /etc/apt/sources.list.d/nvidia-drivers.list
	sudo apt update && sudo apt install -y cuda

}

update_system() {

	# Handle parameters
	country=${1:-Europe/Brussels}
	machine=${2:-ubuhogen}

	# Change hostname
	hostnamectl hostname "$machine"

	# Change timezone
	sudo unlink "/etc/localtime"
	sudo ln -s "/usr/share/zoneinfo/$country" "/etc/localtime"

	# Update system
	sudo apt update
	sudo apt upgrade -y
	sudo apt dist-upgrade -y
	sudo apt autoremove -y

	# Update firmware
	sudo fwupdmgr get-devices
	sudo fwupdmgr refresh --force
	sudo fwupdmgr get-updates
	sudo fwupdmgr update -y

}

update_ydotool() {

	# Update dependencies
	sudo apt install -y build-essential cmake git libboost-program-options-dev scdoc

	# Remove package
	sudo apt autoremove -y --purge ydotool

	# Update package
	current=$(date -r "$(which ydotool)" +"%s")
	maximum=$(date -d "10 days ago" +"%s")
	updated=$([[ $current -lt $maximum ]] && echo false || echo true)
	[[ $updated == true ]] && return 0
	deposit=$(dirname "$(readlink -f "$0")") && git clone "https://github.com/ReimuNotMoe/ydotool.git"
	cd ydotool && mkdir build && cd build && cmake .. && make && sudo make install
	cd "$deposit" && source "$HOME/.bashrc" && rm -rf ydotool

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
		"update_appearance"
		"update_system"
		"update_nvidia"
		"update_android_studio"
		"update_chromium"
		"update_flutter"
		"update_nvidia_cuda"
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
