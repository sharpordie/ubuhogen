#!/usr/bin/env bash

update_android() {; }

update_celluloid() {; }

update_docker() {; }

update_figma() {; }

update_firefox() {; }

update_flutter() {; }

update_git() {; }

update_gnome() {; }

update_nodejs() {; }

update_pycharm() {; }

update_python() {; }

uodate_quickemu() {; }

update_system() {; }

update_vscode() {; }

update_ydotool() {; }

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
