#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please run as a normal user (without sudo)${NC}"
    exit 1
fi

monitor=$(xrandr | grep "connected primary" | cut -d " " -f1)
echo -e "${GREEN}Usando monitor: $monitor${NC}"

create_resolution() {

    config_dir="$HOME/.config/custom-resolution"
    mkdir -p "$config_dir"
    current_resolution=$(xrandr | grep "$monitor" -A1 | grep "*" | awk '{print $1}')
    echo "$current_resolution" >"$HOME/.config/custom-resolution/previous_resolution"

    startup_option="$2"

    local apply=true
    if [ "$1" = "--no-apply" ]; then
        apply=false
        shift
    fi

    read -p "Enter the desired width: " width
    read -p "Enter the desired height: " altura
    read -p "Enter the update rate (ex: 60): " refresh

    cvt_output=$(cvt "$width" "$altura" "$refresh")
    echo -e "\n${BLUE}Output CVT:${NC}"
    echo "$cvt_output"

    modeline=$(echo "$cvt_output" | grep "Modeline" | cut -d'"' -f2-)
    mode_name=$(echo "$modeline" | awk '{print $1}')
    mode_params=$(echo "$modeline" | cut -d' ' -f2-)

    echo -e "\n${BLUE}Creating New Mode...${NC}"
    xrandr --newmode "$mode_name" $mode_params

    echo -e "${BLUE}Adding Mode to the Monitor...${NC}"
    xrandr --addmode "$monitor" "$mode_name"

    if [ "$apply" = true ]; then
        echo -e "${BLUE}Applying New Resolution...${NC}"
        xrandr --output "$monitor" --mode "$mode_name"
        xrandr --output "$monitor" --set "scaling mode" "Full"
        xrandr --output "$monitor" --transform 1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0
    fi

    save_config "$mode_name" "$mode_params" "$startup_option"
}

remove_resolution() {
    echo -e "\n${BLUE}Custom resolutions:${NC}"
    custom_modes=$(xrandr | grep -A 20 "^$monitor connected" | grep -v "connected" | grep "_" | nl -w2 -s") ")
    echo "$custom_modes"

    if [ -z "$custom_modes" ]; then
        echo -e "${RED}No custom resolution found${NC}"
        return 1
    fi

    read -p "Enter the resolution number to remove: " del_num
    del_mode=$(echo "$custom_modes" | sed -n "${del_num}p" | awk '{print $2}')

    if [ -n "$del_mode" ]; then

        saved_resolution=$(cat "$HOME/.config/custom-resolution/previous_resolution")

        echo -e "${BLUE}Changing to saved resolution...${NC}"
        xrandr --output "$monitor" --mode "$saved_resolution"
        sleep 1
        echo -e "${BLUE}Removing Customized Mode...${NC}"
        xrandr --delmode "$monitor" "$del_mode"
        xrandr --rmmode "$del_mode"

        config_file="$HOME/.config/custom-resolution/setup.sh"
        if [ -f "$config_file" ]; then
            sed -i "/$del_mode/d" "$config_file"
            sed -i "/scaling mode/d" "$config_file"
            sed -i "/transform/d" "$config_file"
            echo -e "${GREEN}Mode $del_mode Removed from the configuration file${NC}"
        fi

        echo -e "${GREEN}Mode $del_mode removed${NC}"
        echo -e "${GREEN}Restored resolution for: $saved_resolution${NC}"
    else
        echo -e "${RED}Mode not found${NC}"
    fi
}
adjust_position() {
    echo -e "\n${BLUE}Available resolutions:${NC}"
    xrandr | grep -A 20 "^$monitor connected" | grep -v "connected" | grep "+" | nl -w2 -s") "

    read -p "Select the resolution number: " res_num
    resolution=$(xrandr | grep -A 20 "^$monitor connected" | grep -v "connected" | grep "+" | sed -n "${res_num}p" | awk '{print $1}')

    if [ -z "$resolution" ]; then
        echo -e "${RED}Invalid Resolution Selected${NC}"
        return 1
    fi

    read -p "Enter the position X: " pos_x
    read -p "Enter the position Y: " pos_y

    xrandr --output "$monitor" --mode "$resolution" --pos "${pos_x}x${pos_y}"

    # Update config file with new position
    config_file="$HOME/.config/custom-resolution/setup.sh"
    if [ -f "$config_file" ]; then
        sed -i "/--output $monitor --mode \"$resolution\"/c\xrandr --output $monitor --mode \"$resolution\" --pos ${pos_x}x${pos_y}" "$config_file"
        echo -e "${GREEN}Position updated in the configuration file${NC}"
    fi
}

save_config() {
    mode_name=$(echo "$1" | tr -d '"')
    mode_params=$2

    config_dir="$HOME/.config/custom-resolution"
    mkdir -p "$config_dir"
    {
        echo "#!/bin/bash"
        echo "xrandr --newmode \"$mode_name\" $mode_params"
        echo "xrandr --addmode $monitor \"$mode_name\""
        if [ "$3" = "--apply-on-startup" ]; then
            echo "xrandr --output $monitor --mode \"$mode_name\""
            echo "xrandr --output $monitor --set \"scaling mode\" \"Full\""
            echo "xrandr --output $monitor --transform 1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0"
        fi
    } >"$config_dir/setup.sh"
    chmod +x "$config_dir/setup.sh"

    autostart_file="$HOME/.config/autostart/custom-resolution.desktop"
    if [ ! -f "$autostart_file" ]; then
        toggle_autostart
    fi

    echo -e "\n${GREEN}Saved Configuration $config_dir/setup.sh${NC}"
}

toggle_autostart() {
    autostart_file="$HOME/.config/autostart/custom-resolution.desktop"

    if [ -f "$autostart_file" ]; then
        echo -e "${BLUE}Deactivating autostart...${NC}"
        rm "$autostart_file"
        echo -e "${GREEN}Autostart successfully deactivated${NC}"
    else
        echo -e "${BLUE}Ativando autostart...${NC}"
        autostart_dir="$HOME/.config/autostart"
        mkdir -p "$autostart_dir"
        config_dir="$HOME/.config/custom-resolution"
        {
            echo "[Desktop Entry]"
            echo "Type=Application"
            echo "Name=Custom Resolution"
            echo "Exec=$config_dir/setup.sh"
            echo "Terminal=false"
            echo "Hidden=false"
            echo "Icon="
            echo "Comment="
            echo "Path="
            echo "StartupNotify=false"
        } >"$autostart_file"
        chmod +x "$autostart_file"
        echo -e "${GREEN}Successful AutoStart activated${NC}"
    fi
}

remove_borders() {
    echo -e "${BLUE}Choose an option:${NC}"
    echo "1. Remove black edges"
    echo "2. Restore Standard Borders"
    read -p "Option (1-2): " border_option

    config_file="$HOME/.config/custom-resolution/setup.sh"

    case $border_option in
    1)
        echo -e "${BLUE}Removing Black Borders...${NC}"
        xrandr --output "$monitor" --set "scaling mode" "Full"
        xrandr --output "$monitor" --transform 1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0

        if [ -f "$config_file" ]; then
            sed -i "/scaling mode/d" "$config_file"
            sed -i "/transform/d" "$config_file"
            echo "xrandr --output $monitor --set \"scaling mode\" \"Full\"" >>"$config_file"
            echo "xrandr --output $monitor --transform 1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0" >>"$config_file"
        fi
        echo -e "${GREEN}Borders successfully removed${NC}"
        ;;
    2)
        echo -e "${BLUE}Restoring Standard Borders...${NC}"
        xrandr --output "$monitor" --transform none
        xrandr --output "$monitor" --set "scaling mode" "Center"

        if [ -f "$config_file" ]; then
            sed -i "/scaling mode/d" "$config_file"
            sed -i "/transform/d" "$config_file"
            echo "xrandr --output $monitor --transform none" >>"$config_file"
            echo "xrandr --output $monitor --set \"scaling mode\" \"Center\"" >>"$config_file"
        fi
        echo -e "${GREEN}Successful restored borders${NC}"
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
    esac
}

while true; do
    echo -e "\n${BLUE}=== Current configuration ===${NC}"
    xrandr
    echo -e "${BLUE}=======================${NC}"

    echo -e "\n${GREEN}Choose an option:${NC}"
    echo "1. Create new resolution"
    echo "2. Adjust position"
    echo "3. Remove custom resolution"
    echo "4. Remove or apply black borders"
    echo "5. Activate/disable autostart"
    echo "6. Exit"
    read -p "Option (1-6): " option

    case $option in
    1) create_resolution "$@" ;;
    2) adjust_position ;;
    3) remove_resolution ;;
    4) remove_borders ;;
    5) toggle_autostart ;;
    6) exit 0 ;;
    *) echo -e "${RED}Invalid option${NC}" ;;
    esac
done
