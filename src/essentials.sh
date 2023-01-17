#!/usr/bin/env bash

update_android_cmdline() {

	# Update dependencies
	sudo apt install -y default-jdk

	# Update package
	sdkroot="$HOME/Android/Sdk"
	tempdir="$sdkroot/cmdline-tools"
	if [[ ! -d "$tempdir" ]]; then
		mkdir -p "$tempdir"
		address="https://developer.android.com/studio#command-tools"
		version="$(curl -s "$address" | grep -oP "commandlinetools-linux-\K(\d+)" | head -1)"
		address="https://dl.google.com/android/repository/commandlinetools-linux-${version}_latest.zip"
		archive="$(mktemp -d)/$(basename "$address")"
		curl -LA "mozilla/5.0" "$address" -o "$archive"
		unzip -d "$tempdir" "$archive"
		yes | "$tempdir/cmdline-tools/bin/sdkmanager" --sdk_root="$sdkroot" "cmdline-tools;latest"
		rm -rf "$tempdir/cmdline-tools"
	fi

	# Remove Android directory
	! grep -q "Android" "$HOME/.hidden" 2>/dev/null && echo "Android" >>"$HOME/.hidden"

	# Change environment
	configs="$HOME/.bashrc"
	if ! grep -q "ANDROID_HOME" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >>"$configs"
		export ANDROID_HOME="$HOME/Android/Sdk"
		export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
		export PATH="$PATH:$ANDROID_HOME/emulator"
		export PATH="$PATH:$ANDROID_HOME/platform-tools"
	fi

}

update_android_studio() {

	# Handle parameters
	release=${1:-stable}
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
		curl -LA "mozilla/5.0" "$address" -o "$package"
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
	gsettings set org.gnome.desktop.interface font-name "Ubuntu 10"
	gsettings set org.gnome.desktop.interface document-font-name "Sans 10"
	gsettings set org.gnome.desktop.interface monospace-font-name "Ubuntu Mono 12"
	gsettings set org.gnome.desktop.wm.preferences titlebar-font "Ubuntu Bold 10"
	gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false

	# Enable night-light
	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 5000

	# Change dash-to-dock
	gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize
	gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
	gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
	gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false

	# Change favorites
	gsettings set org.gnome.shell favorite-apps "[ \
		'org.gnome.Nautilus.desktop', \
		'com.github.Eloston.UngoogledChromium.desktop', \
		'org.jdownloader.JDownloader.desktop', \
		'org.gnome.Terminal.desktop', \
		'code.desktop', \
		'android-studio.desktop', \
		'jetbrains-pycharm.desktop', \
		'pgadmin4.desktop', \
		'lunacy.desktop', \
		'mpv.desktop', \
		'org.keepassxc.KeePassXC.desktop' \
	]"

	# Remove home directory
	gsettings set org.gnome.shell.extensions.ding show-home false

	# Change theme
	gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
	gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"

	# Change icons
	sudo add-apt-repository -y ppa:papirus/papirus-dev
	sudo apt update && sudo apt install -y papirus-folders papirus-icon-theme
	gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
	sudo papirus-folders --color yaru --theme Papirus-Dark

	# Change desktop
	sudo apt install -y curl
	address="https://raw.githubusercontent.com/sharpordie/andpaper/main/src/android-bottom-bright.png"
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

	# Remove snap directory
	! grep -q "snap" "$HOME/.hidden" 2>/dev/null && echo "snap" >>"$HOME/.hidden"

	# Remove event-sounds
	gsettings set org.gnome.desktop.sound event-sounds false

	# Change nautilus
	gsettings set org.gnome.nautilus.preferences default-folder-viewer "list-view"
	gsettings set org.gtk.Settings.FileChooser show-hidden false
	gsettings set org.gtk.Settings.FileChooser sort-directories-first true

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
	if [[ $present == false ]]; then

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
	if [[ $present == true ]]; then
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

update_docker() {

	# Update dependencies
	sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

	# Update package
	curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | sudo gpg --dearmor --yes -o "/usr/share/keyrings/docker-archive-keyring.gpg"
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
	sudo apt update && sudo apt install -y docker-ce docker-compose-plugin
	sudo usermod -aG docker $USER

}

update_flutter() {

	# Update dependencies
	sudo apt install -y build-essential clang cmake curl git libgtk-3-dev ninja-build pkg-config

	# Update package
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

	# Finish installation
	flutter channel stable
	# flutter precache && flutter upgrade
	dart --disable-analytics
	flutter config --no-analytics
	yes | flutter doctor --android-licenses

	# Update vscode
	code --install-extension "dart-code.flutter" --force &>/dev/null
	code --install-extension "RichardCoutts.mvvm-plus" --force &>/dev/null

	# Update android-studio
	product=$(find /opt/android-* -maxdepth 0 2>/dev/null | sort -r | head -1)
	update_jetbrains_plugin "$product" "6351"  # dart
	update_jetbrains_plugin "$product" "9212"  # flutter
	update_jetbrains_plugin "$product" "13666" # flutter-intl
	update_jetbrains_plugin "$product" "14641" # flutter-riverpod-snippets

}

update_gh() {

	# Update dependencies
	sudo apt -y install curl

	# Update package
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
	sudo apt update && sudo apt install -y gh

}

update_git() {

	# Handle parameters
	default=${1:-main}
	gituser=${2:-anonymous}
	gitmail=${3:-anonymous@example.org}

	# Update package
	sudo add-apt-repository -y ppa:git-core/ppa
	sudo apt update && sudo apt install -y git

	# Change settings
	git config --global credential.helper "store"
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"
	git config --global user.email "$gitmail"
	git config --global user.name "$gituser"

}

update_inkscape() {

	# Update package
	sudo add-apt-repository -y ppa:inkscape.dev/stable
	sudo apt update && sudo apt install -y inkscape

}

update_jdownloader() {

	# Handle parameters
	deposit=${1:-$HOME/Downloads/JD2}

	# Update dependencies
	sudo apt install -y flatpak jq moreutils

	# Update package
	starter="/var/lib/flatpak/exports/bin/org.jdownloader.JDownloader"
	present=$([[ -f "$starter" ]] && echo true || echo false)
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	sudo flatpak remote-modify --enable flathub
	flatpak install -y flathub org.jdownloader.JDownloader

	# Create deposit
	mkdir -p "$deposit"

	# Change desktop
	desktop="/var/lib/flatpak/exports/share/applications/org.jdownloader.JDownloader.desktop"
	sudo sed -i "s/Icon=.*/Icon=jdownloader/" "$desktop"

	# Change settings
	if [[ $present = false ]]; then
		appdata="$HOME/.var/app/org.jdownloader.JDownloader/data/jdownloader/cfg"
		config1="$appdata/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
		config2="$appdata/org.jdownloader.settings.GeneralSettings.json"
		config3="$appdata/org.jdownloader.gui.jdtrayicon.TrayExtension.json"
		config4="$appdata/org.jdownloader.extensions.extraction.ExtractionExtension.json"
		(flatpak run org.jdownloader.JDownloader >/dev/null 2>&1 &) && sleep 8
		while [[ ! -f "$config1" ]]; do sleep 2; done
		flatpak kill org.jdownloader.JDownloader && sleep 8
		jq ".bannerenabled = false" "$config1" | sponge "$config1"
		jq ".clipboardmonitored = false" "$config1" | sponge "$config1"
		jq ".donatebuttonlatestautochange = 4102444800000" "$config1" | sponge "$config1"
		jq ".donatebuttonstate = \"AUTO_HIDDEN\"" "$config1" | sponge "$config1"
		jq ".myjdownloaderviewvisible = false" "$config1" | sponge "$config1"
		jq ".premiumalertetacolumnenabled = false" "$config1" | sponge "$config1"
		jq ".premiumalertspeedcolumnenabled = false" "$config1" | sponge "$config1"
		jq ".premiumalerttaskcolumnenabled = false" "$config1" | sponge "$config1"
		jq ".specialdealoboomdialogvisibleonstartup = false" "$config1" | sponge "$config1"
		jq ".specialdealsenabled = false" "$config1" | sponge "$config1"
		jq ".speedmetervisible = false" "$config1" | sponge "$config1"
		jq ".defaultdownloadfolder = \"$deposit\"" "$config2" | sponge "$config2"
		jq ".enabled = false" "$config3" | sponge "$config3"
		jq ".enabled = false" "$config4" | sponge "$config4"
		update_chromium_extension "fbcohnmimjicjdomonkcbcpbpnhggkip"
	fi

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
	adjunct=$([[ $datadir == "AndroidStudio"* ]] && echo "Google/$datadir" || echo "JetBrains/$datadir")
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
				curl -LA "mozilla/5.0" "$address" -o "$archive"
				unzip -o "$archive" -d "$plugins"
				break 2
			fi
			sleep 1
		done
	done

}

update_keepassxc() {

	# Update package
	sudo add-apt-repository -y ppa:phoerious/keepassxc
	sudo apt update && sudo apt install -y keepassxc

}

update_lunacy() {

	# Update dependencies
	sudo apt install curl jq

	# Update package
	current=$(apt-show-versions lunacy | grep -oP "[\d.]+" | tail -1)
	address="https://raw.githubusercontent.com/scoopinstaller/extras/master/bucket/lunacy.json"
	version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".version")
	updated=$(dpkg --compare-versions "$current" "ge" "$version" && echo true || echo false)
	if [[ $updated == false ]]; then
		address="https://lcdn.icons8.com/setup/Lunacy.deb"
		package="$(mktemp -d)/$(basename "$address")"
		curl -LA "mozilla/5.0" "$address" -o "$package"
		sudo apt install -y "$package"
	fi

	# Change desktop
	desktop="/usr/share/applications/lunacy.desktop"
	sudo sed -i "s/Icon=.*/Icon=lunacy/" "$desktop"

}

update_mambaforge() {

	# Handle parameters
	deposit=${1:-$HOME/.mambaforge}

	# Update dependencies
	sudo apt install -y curl

	# Update package
	present=$([[ -x "$(which mamba)" ]] && echo true || echo false)
	if [[ $present = false ]]; then
		address="https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
		fetched="$(mktemp -d)/$(basename "$address")"
		curl -L "$address" -o "$fetched" && sh "$fetched" -b -p "$deposit"
	fi

	# Change environment
	"$deposit/condabin/conda" init

	# Change settings
	"$deposit/condabin/conda" config --set auto_activate_base false

}

update_mpv() {

	# Update package
	sudo add-apt-repository -y ppa:savoury1/ffmpeg4
	sudo add-apt-repository -y ppa:savoury1/ffmpeg5
	sudo add-apt-repository -y ppa:savoury1/mpv
	sudo apt update && sudo apt -y install libmpv2 mpv

	# Change desktop
	desktop="/usr/share/applications/mpv.desktop"
	sudo sed -i "s/Name=.*/Name=Mpv/" "$desktop"

	# Create mpv.conf
	config1="$HOME/.config/mpv/mpv.conf"
	mkdir -p "$(dirname "$config1")" && cat /dev/null >"$config1"
	echo "profile=gpu-hq" >>"$config1"
	echo "vo=gpu-next" >>"$config1"
	echo "keep-open=yes" >>"$config1"
	# echo "save-position-on-quit=yes" >>"$config1"
	echo 'ytdl-format="bestvideo[height<=?2160]+bestaudio/best"' >>"$config1"
	echo "[protocol.http]" >>"$config1"
	echo "force-window=immediate" >>"$config1"
	echo "[protocol.https]" >>"$config1"
	echo "profile=protocol.http" >>"$config1"
	echo "[protocol.ytdl]" >>"$config1"
	echo "profile=protocol.http" >>"$config1"

	# Create input.conf
	config2="$HOME/.config/mpv/input.conf"
	mkdir -p "$(dirname "$config2")" && cat /dev/null >"$config2"

}

update_nodejs() {

	# Handle parameters
	version=${1:-16}

	# Update dependencies
	sudo apt install -y curl gcc g++ make

	# Update package
	curl -fsSL "https://deb.nodesource.com/setup_$version.x" | sudo -E bash -
	sudo apt update && sudo apt install -y nodejs

	# Change environment
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

}

update_nvidia() {

	# Update dependencies
	[[ $(lspci | grep -e VGA) == *"NVIDIA"* ]] || return 1
	sudo apt install -y linux-headers-$(uname -r)

	# Update package
	address="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb"
	package="$(mktemp -d)/$(basename "$address")"
	curl -LA "mozilla/5.0" "$address" -o "$package" && sudo dpkg -i "$package"
	sudo apt update && sudo apt install -y cuda

}

update_odoo() {

	# Update dependencies
	(update_nodejs && update_postgresql && update_python && update_pycharm) || return 1

	# Update nodejs
	npm install -g rtlcss

	# Update wkhtmltopdf

	# Update pycharm
	product=$(find /opt/pycharm -maxdepth 0 2>/dev/null | sort -r | head -1)
	update_jetbrains_plugin "$product" "10037" # csv-editor
	update_jetbrains_plugin "$product" "12478" # xpathview-xslt
	update_jetbrains_plugin "$product" "13499" # odoo

	# Update vscode
	code --install-extension "jigar-patel.odoosnippets" --force &>/dev/null

}

update_pgadmin() {

	# Update dependencies
	sudo apt install -y curl

	# Update package
	curl -fsSL https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --yes --dearmor -o /etc/apt/trusted.gpg.d/pgadmin.gpg
	sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
	sudo apt update && sudo apt install -y pgadmin4

}

update_postgresql() {

	# Update package
	sudo apt install -y postgresql postgresql-client

	# Change settings
	sudo su - postgres -c "createuser $USER"
	createdb "$USER" || return 0

}

update_pycharm() {

	# Update dependencies
	sudo apt install -y curl jq

	# Update package
	current=$(cat "/opt/pycharm/product-info.json" | jq -r ".dataDirectoryName" | grep -oP "(\d.+)" || echo "0.0.0.0")
	address="https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&type=release"
	version=$(curl -Ls "$address" | jq -r ".PCP[0].version")
	present=$([[ -f "/opt/pycharm/bin/pycharm.sh" ]] && echo true || echo false)
	updated=$(dpkg --compare-versions "$current" "ge" "${version:0:6}" && echo true || echo false)
	if [[ $updated == false ]]; then
		address="https://download.jetbrains.com/python/pycharm-professional-$version.tar.gz"
		package="$(mktemp -d)/$(basename "$address")"
		curl -LA "mozilla/5.0" "$address" -o "$package"
		sudo rm -r "/opt/pycharm"
		tempdir="$(mktemp -d)" && sudo tar -xvf "$package" -C "$tempdir"
		sudo mv -f $tempdir/pycharm-* "/opt/pycharm"
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

	# Update package
	sudo apt install -y python3 python3-dev python3-venv

	# Change environment
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
	"$HOME/.local/bin/poetry" config virtualenvs.in-project true

}

update_quickemu() {

	# Update package
	sudo add-apt-repository -y ppa:flexiondotorg/quickemu
	sudo apt update && sudo apt install -y quickemu

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

	# Change network
	configs="/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf"
	sudo sed -i "s/wifi.powersave =.*/wifi.powersave = 2/" "$configs"
	sudo systemctl disable NetworkManager-wait-online.service

	# Update firmware
	sudo fwupdmgr get-devices
	sudo fwupdmgr refresh --force
	sudo fwupdmgr get-updates
	sudo fwupdmgr update -y

	# Update system
	sudo apt update
	sudo apt upgrade -y
	sudo apt dist-upgrade -y
	sudo apt autoremove -y

}

update_vscode() {

	# Update dependencies
	sudo apt install -y curl fonts-cascadia-code jq moreutils

	# Update package
	present="$([[ -x $(command -v code) ]] && echo true || echo false)"
	if [[ $present == false ]]; then
		package="$(mktemp -d)/code_latest_amd64.deb"
		address="https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
		curl -LA "mozilla/5.0" "$address" -o "$package"
		sudo apt install -y "$package"
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
	jq '."editor.lineHeight" = 35' "$configs" | sponge "$configs"
	jq '."security.workspace.trust.enabled" = false' "$configs" | sponge "$configs"
	jq '."telemetry.telemetryLevel" = "crash"' "$configs" | sponge "$configs"
	jq '."update.mode" = "none"' "$configs" | sponge "$configs"
	jq '."window.menuBarVisibility" = "toggle"' "$configs" | sponge "$configs"
	jq '."workbench.colorTheme" = "GitHub Dark Default"' "$configs" | sponge "$configs"

	# Change max_user_watches
	if ! grep -q "fs.inotify.max_user_watches" "/etc/sysctl.conf" 2>/dev/null; then
		[[ -z $(tail -1 "/etc/sysctl.conf") ]] || echo "" | sudo tee -a "/etc/sysctl.conf"
		echo "# Augment the amount of inotify watchers" | sudo tee -a "/etc/sysctl.conf"
		echo "fs.inotify.max_user_watches=524288" | sudo tee -a "/etc/sysctl.conf"
		sudo sysctl -p
	fi

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
	tempdir=$(dirname "$(readlink -f "$0")") && git clone "https://github.com/ReimuNotMoe/ydotool.git"
	cd ydotool && mkdir build && cd build && cmake .. && make && sudo make install
	rm -rf ydotool && cd "$tempdir" && source "$HOME/.bashrc"

}

update_yt_dlp() {

	# Update dependencies
	sudo apt install -y curl

	# Remove package
	sudo apt autoremove -y --purge yt-dlp

	# Update package
	current=$(date -r "$(which yt-dlp)" +"%s")
	maximum=$(date -d "10 days ago" +"%s")
	updated=$([[ $current -lt $maximum ]] && echo false || echo true)
	[[ $updated == true ]] && return 0
	address="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"
	package="/usr/local/bin/yt-dlp" && sudo curl -LA "mozilla/5.0" "$address" -o "$package"
	sudo chmod a+rx "$package"

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
		"update_git main sharpordie 72373746+sharpordie@users.noreply.github.com"
		"update_pycharm"
		"update_vscode"

		"update_docker"
		"update_flutter"
		"update_gh"
		"update_mambaforge"
		"update_nodejs"
		"update_pgadmin"
		"update_postgresql"
		"update_python"
		"update_odoo"

		"update_inkscape"
		"update_jdownloader"
		"update_keepassxc"
		"update_lunacy"
		"update_mpv"
		"update_quickemu"
		"update_yt_dlp"
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
