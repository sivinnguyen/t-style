#!/data/data/com.termux/files/usr/bin/bash

## Author : Sivin
readonly AUTHOR="Sivin Nguyen"
##readonly VERSION="v0.3.0"

## Official Termux:Styling repo URLs
readonly COLOR_URL="https://api.github.com/repos/termux/termux-styling/contents/app/src/main/assets/colors"
readonly FONT_URL="https://api.github.com/repos/termux/termux-styling/contents/app/src/main/assets/fonts"

declare -g COLOR_MENU=()
declare -g FONT_MENU=()

## Termux configuration directory
readonly CONF_DIR="$HOME/.termux"
readonly CONF_FILES=("colors.properties" "font.ttf" "termux.properties")


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
	##echo -e "Version: ${VERSION}"
	echo -e "By: ${AUTHOR}\n"
}


## Title
title() {
	title=$1
	echo "===================="
	echo "${title}"
	echo -e "====================\n"
	
}


## Get data from Github repo
getData() {
	json=$(curl -sL -H "X-GitHub-Api-Version:2022-11-28" -H "Accept: application/vnd.github.v3+json" $1)

	mapfile -t dataset < <(echo "$json" | grep -oP '(?<="name": ")[^"]*|(?<="download_url": ")[^"]*'| grep -E '\.(properties|ttf)$'| awk 'ORS=NR%2?",":" "')
	echo "${dataset[@]}"
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
	
	echo -n "Setting..."
	curl -sf $url -o $output
	echo " done."

	# Set cursor color
	if [[ $ext == "properties" ]]; then
		standardizeFile $output
	fi
}

## Standardize configuration file
standardizeFile() {
	sed -i 's/\s*\(:\|=\)\s*/=/g' $1
}


## Get Foreground color
getForegroundColor() {
	path="$CONF_DIR/${CONF_FILES[0]}"
	standardizeFile $path
	echo $(grep '^foreground=' $path | cut -d "=" -f 2)
}


## Set cursor to default color
setDefaultCursorColor() {
	path="$CONF_DIR/${CONF_FILES[0]}"
	
	if [[ -f $path ]]; then
		foreground=($(getForegroundColor))
		if [[ -n $foreground ]]; then
			setPropValue ${CONF_FILES[0]} "cursor" $foreground
		fi
	fi
}


## Change properties' value
setPropValue() {
	path="$CONF_DIR/$1"
	prop="$2"
	value="$3"
	
	if [[ ! -f  $path ]]; then
		echo "$prop=$value" >> $path
		return
	fi

	str=$(grep "^${prop}" $path)
	if [[ -z $str ]]; then
		echo "$prop=$value" >> $path
		
	else
		sed -i "s/^${prop}.*/$prop=$value/" $path
	fi
}


## Display Menu
mainMenu() {
	while true; do
		banner

		echo "[C] Change Color"
		echo "[F] Change Font"
		echo "[U] Customize Cursor"
		#echo "[B] Backup"
		#echo "[R] Restore"
		echo "[Q] Quit"
		echo ""

		read -rp "Select option: " option
		case $option in
			c|C)
				if [[ -z $COLOR_MENU ]]; then
					echo -n "Getting resource..."
					COLOR_MENU=($(getData "$COLOR_URL"))
					echo " done."
				fi
				# https://stackoverflow.com/a/69885656
				subMenu "${COLOR_MENU[@]}" "CHANGE COLOR"
				;;
			f|F)
				if [[ -z $FONT_MENU ]]; then
					echo -n "Getting resource..."
					FONT_MENU=($(getData "$FONT_URL"))
					echo " done."
				fi
				subMenu "${FONT_MENU[@]}" "CHANGE FONT"
				;;
			u|U)
				cursorMenu
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
	menu=("$@")
	len=$(( ${#menu[@]} - 1 ))
	page_size=10
	num_page=$((($len + $page_size - 1) / $page_size))
	dec=$((len + 1))
	current_page=1

	message="Press any key to try again..."

	while true; do
		banner
		title "${menu[$len]}"

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


cursorMenu() {
	while true; do
		banner

		title "CUSTOMIZE CURSOR"

		shape=("block" "bar" "underline")

		echo "CHANGE CURSOR COLOR"

		echo "[#] Reset to default color."
		echo "[#hex] Hexadecimal value (eg. #FFFFFF)."
		echo ""

		echo "CHANGE CURSOR SHAPE (NEED RESTART)"

		echo "[1] Block █"
		echo "[2] Bar |"
		echo "[3] Underline _"
		echo ""

		echo "CHANGE CURSOR BLINK RATE"

		echo "[0] Disable."
		echo "[100 - 2000] Blink rate."

		echo ""
		echo "(m) Main menu  (q) Quit"
		echo ""

		read -rp "Enter value: " value
		case $value in
			\#)
				setDefaultCursorColor
				termux-reload-settings
				echo -n "Cursor color reset to default color. "
				read -n1 -r -p "Press any key to continue..."
				;;
			# Hoặc dùng if để so sánh '\(#[A-Fa-f0-9]\{6\}\|#[A-Fa-f0-9]\{3\}\)'`
			\#[a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9])
				setPropValue ${CONF_FILES[0]} "cursor" $value
				termux-reload-settings
				echo -n "Cursor color changed to $value. "
				read -n1 -r -p "Press any key to continue..."
				;;
			0|[1-9][0-9][0-9]|1[0-9][0-9][0-9]|2000)
				setPropValue ${CONF_FILES[2]} "terminal-cursor-blink-rate" $value
				termux-reload-settings
				if [[ $value -eq 0 ]]; then
					echo -n "Blink rate disabled. "
				else
					echo -n "Blink rate changed to $value. "
				fi
				read -n1 -r -p "Press any key to continue..."
				;;
			1|2|3)
				i=$((value - 1))
				setPropValue ${CONF_FILES[2]} "terminal-cursor-style" ${shape[$i]}
				echo -n "Cursor shape changed to ${shape[$i]^}. "
				read -n1 -r -p "Press any key to continue..."
				;;
			m|M)
				break
				;;
			q|Q)
				exit 0
				;;
			*)
				echo -n "Invalid input. "
				read -n1 -r -p "Press any key to try again..."
				;;
		esac

	done

	return
}


## Main
main() {
	mainMenu
}


main
