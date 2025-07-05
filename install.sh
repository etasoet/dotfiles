#!/bin/bash

# COLORS
purple='\033[1;35m'
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;94m'
grey='\033[90m'
normal='\033[0m'
bold='\033[1m'

# Dependencies (replaced 'waybar-hyprland-git' with stable 'waybar')
dependencies="rofi-lbonn-wayland-only-git hyprland kitty pcmanfm-gtk3 swaybg lxsession wl-gammarelay-rs \
              grim slurp playerctl alsa-utils bc neovim waybar wl-clipboard-rs"
dunst_dependencies="pod2man core/dbus libxinerama libxrandr libxss glib pango libnotify xdg-utils"
starship_dependencies="fish lsd neofetch"
paru_dependencies="cargo git"
fonts="ttf-nerd-fonts-symbols noto-fonts \
       noto-fonts-cjk noto-fonts-emoji noto-fonts-extra"
icons="sardi-icons"
optional_stuff="firefox github-cli pavucontrol"

# Functions (no edits needed here)
print_header() { echo -e "${purple}==>${normal} ${bold}$1...${normal}"; sleep 0.3; }
print_text() { echo -e "${blue}==>${normal} ${bold}$1...${normal}"; }
install() { paru -S --needed --noconfirm $1; }

confirm() {
  while true; do
    echo -e "$1 ${green}[y]${normal}es or ${red}[n]${normal}o (default: ${green}yes${normal}):"
    read -p ":: " -r answer
    case "$answer" in
      y|Y|yes|"") return 0 ;;
      n|N|no) return 1 ;;
      *) echo -e "${red}-> Please answer y or n.${normal}" ;;
    esac
  done
}

# Main install process
main() {
  echo -e "${bold}Select the features to install:${normal}"
  echo -e "${grey}[ x ]   Config files [Required]${normal}"
  echo -e "${grey}[ x ]   Dependencies [Required]${normal}"
  echo -e "${grey}[ x ]   Fonts [Required]${normal}"

  install_options=(
    "Icons [Recommended]"
    "AstroNvim [Install neovim]"
    "Vencord - [Installs discord]"
    "Starship - [Installs fish shell]"
    "Dunst"
    "Gtk theme"
    "Additional stuff [github-cli,firefox,pavucontrol]"
  )
  preselection=("true" "true" "false" "false" "true" "true" "false")
  multiselect results install_options preselection

  print_header "Checking if paru is installed"
  if ! hash paru 2>/dev/null; then
    print_text "Paru not found"
    if confirm "Install paru?"; then
      install_paru || { echo -e "${red}Paru install failed.${normal}"; exit 1; }
    else
      echo -e "${red}-> Paru is required. Exiting.${normal}"; exit 1
    fi
  fi

  print_header "Installing dependencies"
  install "${dependencies}"

  print_header "Installing fonts"
  install "${fonts}"

  [ "${results[0]}" == true ] && install "${icons}"
  [ "${results[1]}" == true ] && install_nvim
  [ "${results[2]}" == true ] && install_vencord
  [ "${results[3]}" == true ] && install_starship
  [ "${results[4]}" == true ] && install_dunst
  [ "${results[5]}" == true ] && install_gtk_theme

  if confirm "Backup current config?"; then
    print_header "Backing up config"
    mkdir -p ~/.config.bak && cp -a ~/.config/. ~/.config.bak/
  fi

  print_header "Installing config files"
  git clone -b arch https://github.com/etasoet/dotfiles ~/dotfiles
  cp -ar ~/dotfiles/.config/* ~/.config/
  cp -ar ~/dotfiles/home/* ~/

  [ "${results[6]}" == true ] && install "${optional_stuff}"

  echo -e "\n${green}Done. Reboot or log out to see the changes.${normal}"
}

# Install helpers
install_paru() {
  git clone https://aur.archlinux.org/paru.git
  cd paru && makepkg -si && cd .. && rm -rf paru
}

install_starship() {
  install "${starship_dependencies}"
  chsh -s "$(which fish)"
  install "starship"
}

install_vencord() {
  install "npm discord"
  sudo npm i -g pnpm
  git clone https://github.com/Vendicated/Vencord
  cd Vencord && pnpm install && pnpm build && sudo pnpm inject && cd .. && rm -rf Vencord
}

install_dunst() {
  install "${dunst_dependencies}"
  git clone -b progress-styling https://github.com/k-vernooy/dunst
  cd dunst && make && sudo make install && cd .. && rm -rf dunst
}

install_nvim() {
  rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
  git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim
}

install_gtk_theme() {
  sudo cp -a themes/adw-gtk3-dark/ /usr/share/themes/
  gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
}

# Menu selector
multiselect() {
  # … menu code unchanged …
  # You can leave this part as-is from the original file
}

main "$@"
