#!/bin/bash

# Colors
purple='\033[1;35m'
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;94m'
normal='\033[0m'
bold='\033[1m'

# Packages
dependencies="rofi-lbonn-wayland-only-git hyprland kitty pcmanfm-gtk3 swaybg lxsession wl-gammarelay-rs grim slurp playerctl alsa-utils bc neovim wl-clipboard"
fonts="ttf-nerd-fonts-symbols noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra"
icons="sardi-icons"
optional_stuff="firefox github-cli pavucontrol"
paru_dependencies="cargo git"
starship_dependencies="fish lsd neofetch"
dunst_dependencies="pod2man dbus libxinerama libxrandr libxss glib pango libnotify xdg-utils"

print_header() {
  echo -e "\n${purple}==> ${bold}$1${normal}"
  sleep 0.2
}

install() {
  paru -S --needed --noconfirm $1
  if [ $? -ne 0 ]; then
    echo -e "${red}Failed to install: $1${normal}"
    exit 1
  fi
}

install_paru() {
  print_header "Installing paru (AUR helper)"
  git clone https://aur.archlinux.org/paru.git || { echo "Git failed"; exit 1; }
  cd paru
  makepkg -si --noconfirm || { echo "Paru build failed"; exit 1; }
  cd ..
  rm -rf paru
}

install_starship() {
  install "$starship_dependencies"
  install "starship"
  chsh -s "$(which fish)"
}

install_vencord() {
  install "npm discord"
  sudo npm i -g pnpm
  git clone https://github.com/Vendicated/Vencord
  cd Vencord
  pnpm install --frozen-lockfile
  pnpm build
  sudo pnpm inject
  cd ..
  rm -rf Vencord
}

install_dunst() {
  install "$dunst_dependencies"
  git clone -b progress-styling https://github.com/k-vernooy/dunst/
  cd dunst
  make && sudo make install
  cd ..
  rm -rf dunst
}

install_nvim() {
  rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
  git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim
}

install_gtk_theme() {
  sudo cp -a themes/adw-gtk3-dark/ /usr/share/themes
  gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
}

backup_config() {
  mkdir -p ~/.config.bak
  cp -r ~/.config/* ~/.config.bak/ 2>/dev/null
}

install_config() {
  git clone -b arch https://github.com/etasoet/dotfiles ~/dotfiles
  cp -ar ~/dotfiles/.config/. ~/.config/
  cp -ar ~/dotfiles/home/. ~/
}

main() {
  print_header "Checking if paru is installed"
  if ! command -v paru &> /dev/null; then
    install_paru
  fi

  print_header "Installing core dependencies"
  install "$dependencies"

  print_header "Installing fonts"
  install "$fonts"

  print_header "Installing icons"
  install "$icons"

  print_header "Installing Neovim config"
  install_nvim

  print_header "Installing Discord (Vencord)"
  install_vencord

  print_header "Installing Fish + Starship"
  install_starship

  print_header "Installing Dunst"
  install_dunst

  print_header "Installing GTK Theme"
  install_gtk_theme

  print_header "Installing Optional Packages"
  install "$optional_stuff"

  print_header "Backing up existing configs"
  backup_config

  print_header "Applying dotfiles"
  install_config

  echo -e "\n${green}✅ All done! Reboot and start flexin'.${normal}"
}

main
