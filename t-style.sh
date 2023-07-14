#!/data/data/com.termux/files/usr/bin/bash

## Author : Sivin
readonly AUTHOR="Sivin Nguyen"

## Official Termux:Styling repo URLs
readonly COLOR_URL="https://api.github.com/repos/termux/termux-styling/contents/app/src/main/assets/colors"
readonly FONT_URL="https://api.github.com/repos/termux/termux-styling/contents/app/src/main/assets/fonts"

## Termux configuration directory
readonly CONF_DIR="$HOME/.termux"


## Banner
banner() {
	clear
	banner="
  _____ _ ___ _        _      
 |_   _(_) __| |_ _  _| |___  
   | |  _\__ \  _| || | / -_) 
   |_| (_)___/\__|\_, |_\___| 
                  |__/        "

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


## Download properties
download() {
	url=$1
	output=""

	# https://stackoverflow.com/a/965069/1813901
	ext=$(echo "${url##*.}")
	case $ext in
		ttf)
			output="$CONF_DIR/font.ttf"
			;;
		properties)
			output="$CONF_DIR/colors.properties"
			;;
		*)
			echo "Invalid property url"
			exit 0
			;;
	esac
	
	curl $url -o $output
}


## Display Menu
mainMenu() {
	while true; do
		banner

		echo "[C] Change Color"
		echo "[F] Change Font"
		#echo "[B] Backup"
		#echo "[R] Restore"
		echo "[Q] Quit"
		echo ""

		read -rp "Select option: " option
		case $option in
			c|C)
				# https://stackoverflow.com/a/69885656
				subMenu "${COLOR_MENU[@]}"
				;;
			f|F)
				subMenu "${FONT_MENU[@]}"
				;;
			q|Q)
				exit 0
				;;
			*)
				read -n1 -r -p "Invalid option. Press any key to try again..."
				;;
		esac
	done
}

subMenu() {
	banner

	menu=("$@")
	len=${#menu[@]}
	page_size=10
	num_page=$((($len + $page_size - 1) / $page_size))
	dec=$((len + 1))
	current_page=1

	message="Press any key to try again..."

	while true; do
		banner
		start_i=$(((current_page-1)*page_size))
		end_i=$((current_page*page_size-1))

		for i in $(seq $start_i $end_i); do
			if [ $i -lt $len ]; then
				item=$(echo "${menu[$i]}" | cut -d ',' -f 1 | sed -E 's/\.(properties|ttf)*$//' | sed 's/-/ /g' | sed 's/\b\w/\u&/g')
				printf "[%${#dec}d] %s\n" $((i + 1)) "$item"
			fi
		done
		echo "<<$current_page/$num_page>>"

		echo ""
		echo "(p) Previous page  (n) Next page"
		echo "(m) Main menu  (q) Quit"
		echo ""

		read -rp "Select option: " option
		case $option in
			[1-9]|[1-9][0-9]*)
				index=$((option-1))
				if [ $index -ge $start_i ] && [ $index -le $end_i ] && [ $index -lt $len ]; then
					url=$(echo ${menu[$index]} | cut -d ',' -f 2 )
					download "$url"
					termux-reload-settings
					message="Press any key to continue..."
            	else
                	echo -n "Invalid number. "
            	fi
            	read -n1 -r -p "$message"
            	;;
			p|P)
				if [ $current_page -gt 1 ]; then
					current_page=$((current_page-1))
				fi
				;;
			n|N)
				if [ $((current_page*page_size)) -lt $len ]; then
					current_page=$((current_page+1))
				fi
				;;
			m|M)
				break
				;;
			q|Q)
				exit 0
				;;
			*)
				echo -n "Invalid option. "
				read -n1 -r -p "$message"
				;;
		esac
	done

	return
}


## Main
main() {
	initialize
	mainMenu
}


main
