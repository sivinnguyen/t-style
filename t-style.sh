#!/data/data/com.termux/files/usr/bin/bash

## Author : Sivin
readonly AUTHOR="Sivin Nguyen"

## Official Termux:Styling repo URLs
readonly COLOR_URL="https://api.github.com/repos/termux/termux-styling/contents/app/src/main/assets/colors"
readonly FONT_URL="https://api.github.com/repos/termux/termux-styling/contents/app/src/main/assets/fonts"


## Banner
banner() {
	clear
	banner="
  _____                        ___ _        _
 |_   _|__ _ _ _ __ _  ___ __ / __| |_ _  _| |___
   | |/ -_) '_| '  \ || \ \ / \__ \  _| || | / -_)
   |_|\___|_| |_|_|_\_,_/_\_\ |___/\__|\_, |_\___|
                                       |__/"

	echo -e "${banner}"
	echo -e "By: ${AUTHOR}\n"
}

## Get data from Github repo
getData() {
	json=$(curl -sL -H "X-GitHub-Api-Version:2022-11-28" -H "Accept: application/vnd.github.v3+json" $1)

	mapfile -t dataset < <(echo "$json" | grep -oP '(?<="name": ")[^"]*|(?<="download_url": ")[^"]*'| grep -E '\.(properties|ttf)$'| awk 'ORS=NR%2?",":" "')
	echo "${dataset[@]}"
}


## Initialization
initialize() {
	echo -n "Initializing..."
	declare -rg COLOR_MENU=($(getData "$COLOR_URL"))
	declare -rg FONT_MENU=($(getData "$FONT_URL"))
	echo "done."
}


## Display Menu
mainMenu() {
	banner

	echo "[C] Change Color"
	echo "[F] Change Font"
	#echo "[B] Backup"
	#echo "[R] Restore"
	echo "[E] Exit"
	echo ""

	while true; do
		read -rp "Enter your choice: " choice
		case $choice in
			c|C)
				subMenu "${COLOR_MENU[@]}"
				break
				;;
			f|F)
				subMenu "${FONT_MENU[@]}"
				break
				;;
			e|E)
				exit 0
				;;
			*)
				echo "Invalid choice. Please try again."
				;;
		esac
	done

	read -n1 -r -p "Press any key to continue..."
}

subMenu() {
	banner

	menu=("$@")
	len=${#menu[@]}
	len=$((len + 1))

	for i in "${!menu[@]}"; do
		item=$(echo "${menu[$i]}" | cut -d ',' -f 1 | sed -E 's/\.(properties|ttf)*$//' | sed 's/-/ /g' | sed 's/\b\w/\u&/g')
		printf "[%${#len}d] %s\n" $((i + 1)) "$item"
	done
}


## Main
main() {
	initialize
	mainMenu

	# https://stackoverflow.com/a/69885656
	#loadMenu "${FONT_MENU[@]}"
}


main
