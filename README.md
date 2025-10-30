# Custom Mouse Buttons for GNOME

## Why this exists

Many modern mice have extra buttons that go unused on GNOME or Linux systems. This project
provides a simple and flexible way to remap those buttons to useful actions like media control,
shortcuts, or custom scripts.
Wayland has strict input restrictions, so these scripts are designed primarily for X11-based GNOME
sessions. They provide an easy way to make your mouse more productive.

---

## Installation

The script will be installed in `/usr/local/bin/`, and a systemd user service will automatically enable it on
login.

### Debian / Ubuntu

```bash
sudo apt update sudo apt install xdotool xbindkeys x11-utils playerctl git
git clone https://github.com/athamour1/custom_mouse_buttons_gnome.git
cd custom_mouse_buttons_gnome
sudo cp custom-mouse.sh /usr/local/bin/custom-mouse.sh
sudo chmod +x /usr/local/bin/custom-mouse.sh
mkdir -p ~/.config/systemd/user
cp custom-mouse.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now custom-mouse.service
```

### Fedora

```bash
sudo dnf install xdotool xbindkeys xorg-x11-utils playerctl git
git clone https://github.com/athamour1/custom_mouse_buttons_gnome.git
cd custom_mouse_buttons_gnome
sudo cp custom-mouse.sh /usr/local/bin/custom-mouse.sh
sudo chmod +x /usr/local/bin/custom-mouse.sh
mkdir -p ~/.config/systemd/user
cp custom-mouse.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now custom-mouse.service
```

### Arch Linux

```bash
sudo pacman -S xdotool xbindkeys xorg-xev playerctl git
git clone https://github.com/athamour1/custom_mouse_buttons_gnome.git
cd custom_mouse_buttons_gnome
sudo cp custom-mouse.sh /usr/local/bin/custom-mouse.sh
sudo chmod +x /usr/local/bin/custom-mouse.sh
mkdir -p ~/.config/systemd/user
cp custom-mouse.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now custom-mouse.service
```

---

## Usage

Once enabled, the script will run automatically at login and remap the extra buttons according to your
configuration.
To manually start or stop it:
```bash systemctl --user start custom-mouse.service systemctl --user stop custom-mouse.service ```
To check status:
```bash systemctl --user status custom-mouse.service ```

---

## Notes

- Works best on **Xorg**. Wayland does not support global button remapping via `xdotool`. - You can
modify `/usr/local/bin/custom-mouse.sh` to suit your device’s button mappings