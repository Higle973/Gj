 
#!/bin/bash

# تعيين القيم الافتراضية
username="user"
password="root"
chrome_remote_desktop_url="https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"
CRP=""
Pin="123456"
Autostart=true

# تسجيل الرسائل
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# تثبيت الحزم
install_package() {
    package_url=$1
    log "Downloading $package_url"
    wget -q --show-progress "$package_url"
    log "Installing $(basename $package_url)"
    sudo dpkg --install $(basename $package_url)
    log "Fixing broken dependencies"
    sudo apt-get install --fix-broken -y
    rm $(basename $package_url)
}

# خطوات التثبيت
log "Starting installation"

# إنشاء المستخدم
log "Creating user '$username'"
sudo useradd -m "$username"
echo "$username:$password" | sudo chpasswd
sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd

# تثبيت Chrome Remote Desktop
install_package "$chrome_remote_desktop_url"

# تثبيت بيئة سطح المكتب KDE Plasma أو Cinnamon
log "Installing KDE Plasma or Cinnamon desktop environment"
sudo apt update
sudo apt install -y kde-plasma-desktop xfce4 desktop-base wget

# إعداد جلسة Chrome Remote Desktop
log "Setting up Chrome Remote Desktop session"
echo "exec /etc/X11/Xsession /usr/bin/startkde" | sudo tee /etc/chrome-remote-desktop-session
sudo apt install --assume-yes xscreensaver
sudo systemctl disable lightdm.service

# تثبيت متصفح Google Chrome
log "Installing Google Chrome"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg --install google-chrome-stable_current_amd64.deb
sudo apt install --assume-yes --fix-broken

# طلب قيمة CRP
read -p "Enter CRP value: " CRP
log "Finalizing"
if [ "$Autostart" = true ]; then
    mkdir -p "/home/$username/.config/autostart"
    link="https://technical-dose.blogspot.com/"
    colab_autostart="[Desktop Entry]\nType=Application\nName=Colab\nExec=sh -c 'sensible-browser $link'\nIcon=\nComment=Open a predefined notebook at session signin.\nX-GNOME-Autostart-enabled=true"
    echo -e "$colab_autostart" | sudo tee "/home/$username/.config/autostart/colab.desktop"
    sudo chmod +x "/home/$username/.config/autostart/colab.desktop"
    sudo chown "$username:$username" "/home/$username/.config"
fi

sudo adduser "$username" chrome-remote-desktop
command="$CRP --pin=$Pin"
sudo su - "$username" -c "$command"
sudo service chrome-remote-desktop start

log "Installation completed successfully"
while true; do sleep 10; done

