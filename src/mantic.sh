#!/usr/bin/env bash

update_antares() {

	# Update dependencies
	sudo apt install -y apt-transport-https ca-certificates curl gnupg software-properties-common

	# Update package
	curl https://antares-sql.github.io/antares-ppa/key.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/antares.gpg
	sudo curl -s --compressed -o /etc/apt/sources.list.d/antares.list https://antares-sql.github.io/antares-ppa/list_file.list
	sudo apt update && sudo apt install -y antares

}

update_appearance() {

	# Change terminal
	local profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
	local deposit="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
	gsettings set "$deposit" cell-height-scale 1.1000000000000001
	gsettings set "$deposit" default-size-columns 96
	gsettings set "$deposit" default-size-rows 24
	gsettings set "$deposit" use-theme-colors false
	gsettings set "$deposit" foreground-color "rgb(208,207,204)"
	gsettings set "$deposit" background-color "rgb(23,20,33)"

	# Enable night light
	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000
	sudo -u gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	sudo -u gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
	sudo -u gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
	sudo -u gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000

	# Remove event sounds
	gsettings set org.gnome.desktop.sound event-sounds false

	# Remove home directory
	gsettings set org.gnome.shell.extensions.ding show-home false

	# Remove snap directory
	! grep -q "snap" "$HOME/.hidden" 2>/dev/null && echo "snap" >>"$HOME/.hidden"

	# Change dash-to-dock
	gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize
	gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
	gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
	gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false

	# Change favorites
	gsettings set org.gnome.shell favorite-apps "[ \
		'org.gnome.Nautilus.desktop', \
		'ungoogled-chromium.desktop', \
		'org.gnome.Terminal.desktop', \
		'jetbrains-pycharm.desktop', \
		'code.desktop'
	]"

	# Change fonts
	gsettings set org.gnome.desktop.interface font-name "Ubuntu 10"
	gsettings set org.gnome.desktop.interface document-font-name "Sans 10"
	gsettings set org.gnome.desktop.interface monospace-font-name "Ubuntu Mono 12"
	gsettings set org.gnome.desktop.wm.preferences titlebar-font "Ubuntu Bold 10"
	gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false

	# Change icons
	sudo add-apt-repository -y ppa:papirus/papirus-dev
	sudo apt update && sudo apt install -y papirus-folders papirus-icon-theme
	gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
	sudo papirus-folders --color yaru --theme Papirus-Dark

	# Change nautilus
	gsettings set org.gnome.nautilus.preferences default-folder-viewer "list-view"
	gsettings set org.gtk.Settings.FileChooser show-hidden false
	gsettings set org.gtk.Settings.FileChooser sort-directories-first true

	# Change theme
	gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
	gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"

	# Change wallpapers
	sudo apt install -y curl
	local address="https://raw.githubusercontent.com/sharpordie/andpaper/main/src/android-bottom-bright.png"
	local picture="$HOME/Pictures/Backgrounds/$(basename "$address")"
	mkdir -p "$(dirname $picture)" && curl -L "$address" -o "$picture"
	gsettings set org.gnome.desktop.background picture-uri-dark "file://$picture"
	gsettings set org.gnome.desktop.background picture-options "zoom"
	gsettings set org.gnome.desktop.screensaver picture-uri "file://$picture"
	gsettings set org.gnome.desktop.screensaver picture-options "zoom"

}

update_chromium() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}
	local startup=${2:-about:blank}

	# Update dependencies
	update_ydotool || return 1
	sudo apt install -y curl jq

	# Update package
	local present=$([[ -x "$(command -v ungoogled-chromium)" ]] && echo true || echo false)
	sudo add-apt-repository -y ppa:xtradeb/apps
	sudo apt update && sudo apt install -y ungoogled-chromium

	# Change desktop
	local desktop="/usr/share/applications/ungoogled-chromium.desktop"
	sudo sed -i "s/Name=.*/Name=Chromium/" "$desktop"

	# Change environment
	local configs="$HOME/.bashrc"
	if ! grep -q "CHROME_EXECUTABLE" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export CHROME_EXECUTABLE="/usr/bin/ungoogled-chromium"' >>"$configs"
		export CHROME_EXECUTABLE="/usr/bin/ungoogled-chromium"
	fi

	# Finish installation
	if [[ "$present" == "false" ]]; then
		# Launch chromium
		sleep 1 && (sudo ydotoold &) &>/dev/null
		sleep 1 && (ungoogled-chromium --lang=en --start-maximized &) &>/dev/null

		# Change deposit
		mkdir -p "$deposit"
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://settings/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "before downloading" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 56:1 15:1 15:0 56:0 && sleep 1 && sudo ydotool key 56:1 15:1 15:0 56:0
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0 && sleep 1 && sudo ydotool type "$deposit" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change search engine
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://settings/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "search engines" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "duckduckgo" && sleep 1 && sudo ydotool key 28:1 28:0

		# Change custom-ntp flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "custom-ntp" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done
		sleep 1 && sudo ydotool key 29:1 30:1 30:0 29:0 && sleep 1 && sudo ydotool type "$startup"
		sleep 1 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change disable-sharing-hub flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "disable-sharing-hub" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 7); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change extension-mime-request-handling flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "extension-mime-request-handling" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 7); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 108:1 108:0; done && sleep 1 && sudo ydotool key 28:1 28:0

		# Change hide-sidepanel-button flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "hide-sidepanel-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 7); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change remove-tabsearch-button flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "remove-tabsearch-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 7); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change show-avatar-button flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "show-avatar-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 7); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 108:1 108:0; done && sleep 1 && sudo ydotool key 28:1 28:0

		# Toggle bookmark bar
		sleep 4 && sudo ydotool key 29:1 42:1 48:1 48:0 42:0 29:0

		# Finish chromium
		sleep 4 && sudo ydotool key 56:1 62:1 62:0 56:0

		# Update chromium-web-store extension
		local adjunct="NeverDecaf/chromium-web-store"
		local address="https://api.github.com/repos/$adjunct/releases/latest"
		local version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".tag_name" | tr -d "v")
		update_chromium_extension "https://github.com/$adjunct/releases/download/v$version/Chromium.Web.Store.crx"

		# Update some extensions
		update_chromium_extension "bcjindcccaagfpapjjmafapmmgkkhgoa" # json-formatter
		update_chromium_extension "ibplnjkanclpjokhdolnendpplpjiace" # simple-translate
		update_chromium_extension "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock-for-youtube
		update_chromium_extension "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock-origin
	fi

	# Update bypass-paywalls-chrome-clean extension
	local address="https://gitlab.com/magnolia1234/bypass-paywalls-chrome-clean"
	local address="$address/-/archive/master/bypass-paywalls-chrome-clean-master.zip"
	update_chromium_extension "$address"

}

update_chromium_extension() {

	# Handle parameters
	local payload=${1}

	# Update dependencies
	update_ydotool || return 1
	sudo apt install -y curl libarchive-tools

	# Update extension
	if [[ -x "$(command -v ungoogled-chromium)" ]]; then
		if [[ "$payload" == http* ]]; then
			local address="$payload"
			local package="$(mktemp -d)/$(basename "$address")"
		else
			local version=$(ungoogled-chromium --product-version)
			local address="https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3"
			local address="${address}&prodversion=${version}&x=id%3D${payload}%26installsource%3Dondemand%26uc"
			local package="$(mktemp -d)/$payload.crx"
		fi
		curl -LA "mozilla/5.0" "$address" -o "$package" || return 1
		if [[ "$package" == *.zip ]]; then
			local deposit="$HOME/.config/chromium/Unpacked/$(echo "$payload" | cut -d / -f5)"
			local present=$([[ -d "$deposit" ]] && echo "true" || echo "false")
			mkdir -p "$deposit"
			bsdtar -zxf "$package" -C "$deposit" --strip-components=1 || return 1
			[[ "$present" == "true" ]] && return 0
			sleep 2 && (sudo ydotoold &) &>/dev/null
			sleep 2 && (ungoogled-chromium --lang=en --start-maximized &) &>/dev/null
			sleep 4 && sudo ydotool key 29:1 38:1 38:0 29:0
			sleep 2 && sudo ydotool type "chrome://extensions/" && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 15:1 15:0 && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 15:1 15:0 && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool type "$deposit" && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 15:1 15:0 && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 4 && sudo ydotool key 56:1 62:1 62:0 56:0
			sleep 2 && (ungoogled-chromium --lang=en --start-maximized &) &>/dev/null
			sleep 4 && sudo ydotool key 29:1 38:1 38:0 29:0
			sleep 2 && sudo ydotool type "chrome://extensions/" && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 15:1 15:0 && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 56:1 62:1 62:0 56:0
		else
			sleep 1 && (sudo ydotoold &) &>/dev/null
			sleep 1 && (ungoogled-chromium --lang=en --start-maximized "$package" &) &>/dev/null
			sleep 4 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 56:1 62:1 62:0 56:0
		fi
	fi

}

update_docker() {

	# Update dependencies
	sudo apt install -y apt-transport-https ca-certificates curl gnupg software-properties-common

	# Update package
	curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | sudo gpg --dearmor --yes -o "/usr/share/keyrings/docker-archive-keyring.gpg"
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
	sudo apt update && sudo apt install -y docker-ce docker-compose-plugin
	sudo usermod -aG docker "$USER"

}

update_git() {

	# Handle parameters
	local default=${1:-main}
	local gituser=${2}
	local gitmail=${3}

	# Update package
	sudo add-apt-repository -y ppa:git-core/ppa
	sudo apt update && sudo apt install -y git

	# Change settings
	[[ -n "$gitmail" ]] && git config --global user.email "$gitmail"
	[[ -n "$gituser" ]] && git config --global user.name "$gituser"
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"

}

update_github_cli() {

	# Update dependencies
	sudo apt -y install curl

	# Update package
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
	sudo apt update && sudo apt install -y gh

}

update_keepassxc() {

	# Update package
	sudo add-apt-repository -y ppa:phoerious/keepassxc
	sudo apt update && sudo apt install -y keepassxc

}

update_mambaforge() {

	# Handle parameters
	local deposit=${1:-$HOME/.mambaforge}

	# Update dependencies
	sudo apt -y install curl

	# Update package
	local present=$([[ -x "$(which mamba)" ]] && echo "true" || echo "false")
	if [[ "$present" == "false" ]]; then
		local address="https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
		local fetched="$(mktemp -d)/$(basename "$address")"
		curl -L "$address" -o "$fetched" && sh "$fetched" -b -p "$deposit"
	fi

	# Change environment
	"$deposit/condabin/conda" init

	# Change settings
	"$deposit/condabin/conda" config --set auto_activate_base false

}

update_nodejs() {

	# Handle parameters
	local version=${1:-20}

	# Update dependencies
	sudo apt install -y ca-certificates curl gcc g++ gnupg make

	# Update package
	sudo mkdir -p /etc/apt/keyrings
	curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
	echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$version.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
	sudo apt update && sudo apt install -y nodejs

	# Change environment
	local configs="$HOME/.bashrc" && deposit="$HOME/.npm-global"
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

update_pgadmin() {

	# INFO: Doesn't work with mantic yet

	# Update dependencies
	sudo apt install -y curl gnupg

	# Update package
	curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
	sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'
	sudo apt update && sudo apt install -y pgadmin4-desktop

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
	local current=$(cat "/opt/pycharm/product-info.json" | jq -r ".dataDirectoryName" | grep -oP "(\d.+)" || echo "0.0.0.0")
	local address="https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&type=release"
	local version=$(curl -Ls "$address" | jq -r ".PCP[0].version")
	local present=$([[ -f "/opt/pycharm/bin/pycharm.sh" ]] && echo true || echo false)
	local updated=$(dpkg --compare-versions "$current" "ge" "${version:0:6}" && echo true || echo false)
	if [[ $updated == false ]]; then
		local address="https://download.jetbrains.com/python/pycharm-professional-$version.tar.gz"
		local package="$(mktemp -d)/$(basename "$address")"
		curl -LA "mozilla/5.0" "$address" -o "$package"
		sudo rm -r "/opt/pycharm"
		local tempdir="$(mktemp -d)" && sudo tar -xvf "$package" -C "$tempdir"
		sudo mv -f $tempdir/pycharm-* "/opt/pycharm"
		sudo ln -sf "/opt/pycharm/bin/pycharm.sh" "/bin/pycharm"
		source "$HOME/.bashrc"
	fi

	# Change desktop
	local desktop="/usr/share/applications/jetbrains-pycharm.desktop"
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

}

update_system() {

	# Handle parameters
	local country=${1:-Europe/Brussels}
	local machine=${2:-ubuhogen}

	# Change hostname
	hostnamectl hostname "$machine"

	# Change timezone
	sudo unlink "/etc/localtime"
	sudo ln -s "/usr/share/zoneinfo/$country" "/etc/localtime"

	# Change network
	local configs="/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf"
	sudo sed -i "s/wifi.powersave =.*/wifi.powersave = 2/" "$configs"
	sudo systemctl disable NetworkManager-wait-online.service

	# Update firmware
	sudo fwupdmgr get-devices -y
	sudo fwupdmgr refresh --force
	sudo fwupdmgr get-updates -y
	sudo fwupdmgr refresh --force
	sudo fwupdmgr update -y

	# Update system
	sudo apt update -y && sudo apt upgrade -y
	sudo apt full-upgrade -y && sudo apt autoremove -y

}

update_vscode() {

	# Update dependencies
	sudo apt install -y curl fonts-cascadia-code git jq moreutils

	# Update package
	local present=$([[ -x $(command -v code) ]] && echo "true" || echo "false")
	if [[ "$present" == "false" ]]; then
		local package="$(mktemp -d)/code_latest_amd64.deb"
		local address="https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
		curl -LA "mozilla/5.0" "$address" -o "$package" && sudo apt install -y "$package"
	fi

	# Update extensions
	code --install-extension bierner.markdown-preview-github-styles --force
	code --install-extension foxundermoon.shell-format --force
	code --install-extension github.github-vscode-theme --force

	# Change default editor
	git config --global core.editor "code --wait"
	xdg-mime default "code.desktop" text/plain

	# Change settings
	local configs="$HOME/.config/Code/User/settings.json"
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
	local current=$(date -r "$(which ydotool)" +"%s")
	local maximum=$(date -d "10 days ago" +"%s")
	local updated=$([[ $current -lt $maximum ]] && echo false || echo true)
	[[ $updated == true ]] && return 0
	local current=$(dirname "$(readlink -f "$0")") && tempdir=$(mktemp -d)
	git clone "https://github.com/ReimuNotMoe/ydotool.git" "$tempdir"
	cd "$tempdir" && mkdir build && cd build && cmake .. && make && sudo make install
	cd "$current" && source "$HOME/.bashrc"

}

update_yt_dlp() {

	# Update dependencies
	sudo apt install -y curl

	# Remove package
	sudo apt autoremove -y --purge yt-dlp

	# Update package
	local current=$(date -r "$(which yt-dlp)" +"%s")
	local maximum=$(date -d "10 days ago" +"%s")
	local updated=$([[ $current -lt $maximum ]] && echo false || echo true)
	[[ $updated == true ]] && return 0
	local address="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"
	local package="/usr/local/bin/yt-dlp" && sudo curl -LA "mozilla/5.0" "$address" -o "$package"
	sudo chmod a+rx "$package"

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
	clear && printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Remove sleeping
	gsettings set org.gnome.desktop.notifications show-banners false
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	gsettings set org.gnome.desktop.session idle-delay 0

	# Remove software updater
	sudo apt remove -y update-notifier &>/dev/null

	# Remove timeouts
	echo "Defaults timestamp_timeout=-1" | sudo tee "/etc/sudoers.d/disable_timeout" &>/dev/null

	# Handle members
	local members=(
		"update_appearance"
		"update_system"
		"update_chromium"
		"update_git 'main' 'sharpordie' '72373746+sharpordie@users.noreply.github.com'"
		"update_vscode"

		"update_antares"
		"update_docker"
		"update_github_cli"
		"update_keepassxc"
		"update_mambaforge"
		# "update_mpv"
		"update_nodejs"
		"update_obs"
		# "update_pgadmin"
		"update_postgresql"
		"update_pycharm"
		"update_yt_dlp"

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

	# Revert software updater
	sudo apt install -y update-notifier &>/dev/null

	# Revert timeouts
	sudo rm "/etc/sudoers.d/disable_timeout"

	# Output new line
	printf "\n"

}

main
