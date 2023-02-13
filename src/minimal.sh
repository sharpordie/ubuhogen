update_ungoogled_chromium() {

    # Handle parameters
    local deposit=${1:-$HOME/Downloads/DDL}
    local newpage=${2:-about:blank}
    local service=${3:-duckduckgo}

    # Update dependencies
    sudo apt -y install apt-show-versions curl jq
    sudo apt -y install libdouble-conversion3 libevent-2.1-7 libminizip1 libxnvctrl0

    # Update package
	local address="https://api.github.com/repos/berkley4/ungoogled-chromium-debian/releases/latest"
	local version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".tag_name")
    local current=$(apt-show-versions "ungoogled-chromium" | grep -oP "[\d.]+" | tail -1)
	local updated=$(dpkg --compare-versions "$current" "ge" "$version" && echo "true" || echo "false")
    if [[ "$updated" == "false" ]]; then
        local baseurl="https://github.com/berkley4/ungoogled-chromium-debian/releases/download"
        # local factors=("" "-sandbox" "-l10n" "-libraries" "-driver")
        local factors=("" "-sandbox" "-libraries")
        local members=()
        for element in "${factors[@]}"; do
            local address="$baseurl/$version/ungoogled-chromium${element}_${version}_amd64.deb"
            local package="$(mktemp -d)/$(basename "$address")"
		    curl -LA "mozilla/5.0" "$address" -o "$package"
            members=($package "${members[@]}")
        done
        # sudo dpkg -i "${members[@]}"
        sudo apt -y -f install
        sudo apt -y -f install "${members[@]}" --reinstall
	fi

}

update_ungoogled_chromium