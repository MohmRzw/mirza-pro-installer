#!/bin/bash
# =============================================
# Mirza Pro Manager - Version 2.0.0 - Fully Tested
# Create By : @mohmrzw 
# =============================================

mirza_logo() {
    clear
    echo -e "\e[1;96m"
    cat << EOF
███╗   ███╗██╗██████╗ ███████╗ █████╗     ██████╗ ██████╗  ██████╗ 
████╗ ████║██║██╔══██╗╚══███╔╝██╔══██╗    ██╔══██╗██╔══██╗██╔═══██╗
██╔████╔██║██║██████╔╝  ███╔╝ ███████║    ██████╔╝██████╔╝██║   ██║
██║╚██╔╝██║██║██╔══██╗ ███╔╝  ██╔══██║    ██╔═══╝ ██╔══██╗██║   ██║
██║ ╚═╝ ██║██║██║  ██║███████╗██║  ██║    ██║     ██║  ██║╚██████╔╝
╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝
EOF
    echo -e "\e[0m"
}
wait_for_apt() {
    while fuser /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
        echo -e "\e[1;33mWaiting for apt locks to be released... (10 seconds)\e[0m"
        sleep 10
    done
}

fix_mirza_errors() {
    cd /var/www/mirza_pro || return
    echo -e "\e[1;96mApplying fixes and adjustments...\e[0m"

    [ ! -f version ] && echo "3.0" > version
    chown www-data:www-data version 2>/dev/null
    chmod 644 version 2>/dev/null

    for file in *.php; do
        [[ -f "$file" ]] || continue
        sed -i 's|define("index",.*);|if(!defined("index")) define("index", true);|g' "$file" 2>/dev/null
        sed -i 's|require_once("config.php");|if(!defined("index")) require_once("config.php");|g' "$file" 2>/dev/null
        sed -i 's|include("config.php");|if(!defined("index")) include("config.php");|g' "$file" 2>/dev/null
        sed -i 's|require("config.php");|if(!defined("index")) require("config.php");|g' "$file" 2>/dev/null
    done

    # Fix alireza_single.php
    if [ -f alireza_single.php ]; then
        echo -e "\e[1;96mRenaming alireza_single.php → alireza.php ...\e[0m"
        mv alireza_single.php alireza.php 2>/dev/null
        # Fix require in panels.php
        sed -i "s|require_once __DIR__ . '/alireza_single.php';|require_once __DIR__ . '/alireza.php';|g" panels.php
        echo -e "\e[1;92mRenaming and require adjustment completed successfully ✔\e[0m"
    else
        echo -e "\e[1;93malireza_single.php not found — no changes needed\e[0m"
    fi

    # Fix database tables
    if [ ! -f table.php ]; then
        curl -s -o table.php https://raw.githubusercontent.com/mahdiMGF2/mirza_pro/main/table.php
    fi

    if [ -f table.php ]; then
        if sudo -u www-data php table.php >/dev/null 2>&1; then
            echo -e "\e[1;92mTables created successfully ✅\e[0m"
        else
            echo -e "\e[1;93mTables likely already exist\e[0m"
        fi
        rm -f table.php
    fi

    chown -R www-data:www-data /var/www/mirza_pro 2>/dev/null
    chmod -R 755 /var/www/mirza_pro 2>/dev/null
    echo -e "\e[1;92mAll fixes applied — Mirza Pro is ready 🔥\e[0m\n"
}
install_mirza() {
    mirza_logo
    echo -e "\e[1;96m                  Starting Mirza Pro Installation - 100% Tested\e[0m\n"
    wait_for_apt

    [[ ! $(command -v openssl) ]] && apt-get install -y openssl
    if ! apt-cache search php8.2 | grep -q php8.2; then
        apt-get install -y software-properties-common gnupg
        add-apt-repository ppa:ondrej/php -y
        wait_for_apt
        apt-get update
    fi

    read -p "Domain (e.g., bot.example.com): " DOMAIN
    read -p "Bot Token: " BOT_TOKEN
    read -p "Admin ID: " ADMIN_ID
    read -p "Bot Username (without @, e.g., mirzabot): " BOT_USERNAME
    read -p "Database Name (Enter = default: mirza_pro): " DB_NAME; DB_NAME=${DB_NAME:-mirza_pro}
    read -p "Database User (Enter = default: mirza_user): " DB_USER; DB_USER=${DB_USER:-mirza_user}
    read -p "Database Password (Enter = generate automatically): " DB_PASS_INPUT
    
    if [[ -z "$DB_PASS_INPUT" ]]; then
        DB_PASS=$(openssl rand -base64 32 | tr -d /=+ | cut -c -32)
        echo -e "\e[1;33mAuto-generated database password\e[0m"
    else
        DB_PASS="$DB_PASS_INPUT"
    fi

    mirza_logo
    echo -e "\e[1;33m┌────────────────────────────────────────────────────┐\e[0m"
    echo -e "\e[1;33m│                  Preview Information               │\e[0m"
    echo -e "\e[1;37m│ Domain:       $DOMAIN\e[0m"
    echo -e "\e[1;37m│ Token:        ${BOT_TOKEN:0:25}...\e[0m"
    echo -e "\e[1;37m│ Admin ID:     $ADMIN_ID\e[0m"
    echo -e "\e[1;37m│ Bot Username: $BOT_USERNAME\e[0m"
    echo -e "\e[1;37m│ Database:     $DB_NAME\e[0m"
    echo -e "\e[1;37m│ DB User:      $DB_USER\e[0m"
    echo -e "\e[1;37m│ DB Password:  \e[1;31m$DB_PASS\e[0m\e[0m"
    echo -e "\e[1;33m└────────────────────────────────────────────────────┘\e[0m\n"
    echo -e "\e[1;31m↑↑↑ Copy your database password! (Also saved at /root/mirza_pass.txt)\e[0m\n"
    read -p "Is everything correct? Press Enter to continue (Ctrl+C to cancel) " 

    echo "$DB_PASS" > /root/mirza_pass.txt

    wait_for_apt
    echo -e "\e[1;33mInstalling packages...\e[0m"
    apt-get install -y apache2 mariadb-server git curl ufw phpmyadmin certbot python3-certbot-apache \
        php8.2 libapache2-mod-php8.2 php8.2-{mysql,curl,mbstring,xml,zip,gd,bcmath} 2>/dev/null

    ufw allow 22/tcp >/dev/null 2>&1
    ufw allow OpenSSH >/dev/null 2>&1
    ufw allow 'Apache Full' >/dev/null 2>&1
    ufw --force enable >/dev/null 2>&1
    a2enmod rewrite >/dev/null 2>&1
    a2enmod ssl >/dev/null 2>&1
    a2enmod headers >/dev/null 2>&1

    mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

    rm -rf /var/www/mirza_pro
    if git clone https://github.com/mahdiMGF2/mirza_pro.git /var/www/mirza_pro; then
        chown -R www-data:www-data /var/www/mirza_pro
        chmod -R 755 /var/www/mirza_pro
    else
        echo -e "\e[1;31mFailed to clone repository — /var/www/mirza_pro is empty! Check internet or git.\e[0m"
        return 1
    fi

    # ================== CONFIG.PHP 100% ==================
    cat > /var/www/mirza_pro/config.php <<EOF
<?php
if(!defined("index")) define("index", true);

\$dbname     = '$DB_NAME';
\$usernamedb = '$DB_USER';
\$passworddh = '$DB_PASS';

\$connect = mysqli_connect("localhost", \$usernamedb, \$passworddh, \$dbname);
if (!\$connect) die("Database connection failed!");

mysqli_set_charset(\$connect, "utf8mb4");

try {
    \$pdo = new PDO("mysql:host=localhost;dbname=$DB_NAME;charset=utf8mb4", \$usernamedb, \$passworddh, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
} catch(Exception \$e) {
    die("PDO connection error");
}

\$APIKEY       = '$BOT_TOKEN';
\$adminnumber  = '$ADMIN_ID';
\$domainhosts  = 'https://$DOMAIN';
\$usernamebot  = '$BOT_USERNAME';
?>

EOF
    # ===================================================================

    chown www-data:www-data /var/www/mirza_pro/config.php
    chmod 640 /var/www/mirza_pro/config.php

    cat > /etc/apache2/sites-available/mirza-pro.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/mirza_pro
    <Directory /var/www/mirza_pro>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    Alias /phpmyadmin /usr/share/phpmyadmin
    ErrorLog \${APACHE_LOG_DIR}/mirza_error.log
    CustomLog \${APACHE_LOG_DIR}/mirza_access.log combined
</VirtualHost>
EOF

    a2ensite mirza-pro.conf >/dev/null 2>&1
    a2dissite 000-default.conf >/dev/null 2>&1

    fix_mirza_errors

    certbot --apache -d "$DOMAIN" --non-interactive --agree-tos --redirect -m admin@$DOMAIN >/dev/null 2>&1 || true
    
    curl -s "https://api.telegram.org/bot$BOT_TOKEN/setWebhook?url=https://$DOMAIN/index.php" | grep -q '"ok":true' && \
        echo -e "\e[1;92mWebhook set successfully ✅\e[0m" || echo -e "\e[1;93mWebhook not set (set it manually later)\e[0m"

    systemctl restart apache2

    mirza_logo
    echo -e "\e[1;92m╔══════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[1;92m║        Installation completed successfully!      ║\e[0m"
    echo -e "\e[1;92m║ Your domain:      https://$DOMAIN                 ║\e[0m"
    echo -e "\e[1;92m║ phpMyAdmin:       https://$DOMAIN/phpmyadmin      ║\e[0m"
    echo -e "\e[1;92m║ Database info:    /root/mirza_pass.txt           ║\e[0m"
    echo -e "\e[1;92m╚══════════════════════════════════════════════════╝\e[0m\n"
    echo -e "\e[1;93m     Go to your bot and send /start 🔥\e[0m\n"
}

# ====================== منوی اصلی ======================
while true; do
    mirza_logo
    echo -e "\e[1;33m       Mirza Pro Manager - Easy Installer\e[0m"
    echo -e "\e[1;37m           Created by: @mohmrzw\e[0m\n"
    echo -e "\e[1;34m   Youtube: https://youtube.com/@mohmrzw\e[0m"
    echo -e "\e[1;34m   Telegram: https://t.me/ExploreTechIR\e[0m"
    echo -e "\e[1;34m   Original Mirza Pro: https://github.com/mahdiMGF2/mirza_pro/\e[0m\n"
    echo -e "\e[1;32m╔══════════════════════════════════════════╗\e[0m"
    echo -e "\e[1;37m║  1. Install Mirza Pro                    ║\e[0m"
    echo -e "\e[1;37m║  2. Delete Mirza Pro 🛠️ Disabled        ║\e[0m"
    echo -e "\e[1;37m║  3. Update + Fix 🛠️ Disabled            ║\e[0m"
    echo -e "\e[1;37m║  4. Edit config.php 📝                   ║\e[0m"
    echo -e "\e[1;37m║  5. Webhook status 🔗                    ║\e[0m"
    echo -e "\e[1;31m║  6. Exit 🚪                              ║\e[0m"
    echo -e "\e[1;32m╚══════════════════════════════════════════╝\e[0m\n"
    read -p "Choose an option (1-6): " choice

    case $choice in
        1) install_mirza ;;
        2) echo -e "\e[1;31m⚠️ This option is under development. Do not use!\e[0m"; sleep 2 ;;
        3) echo -e "\e[1;31m⚠️ This option is under development. Do not use!\e[0m"; sleep 2 ;;
        4) nano /var/www/mirza_pro/config.php; systemctl restart apache2 ;;
        5) TOKEN=$(grep -oE "[0-9]+:[A-Za-z0-9_-]{20,}" /var/www/mirza_pro/config.php 2>/dev/null)
           curl -s https://api.telegram.org/bot$TOKEN/getWebhookInfo | grep -E "(url|pending|last_error|has_custom_certificate)" || echo "Token not found" ;;
        6) mirza_logo; echo -e "\e[1;33mGood luck! Stay strong — @mohmrzw\e[0m"; sleep 2; exit 0 ;;
        *) echo -e "\e[1;31mPlease choose a number between 1 and 6!\e[0m"; sleep 1 ;;
    esac
    read -p "Press Enter to return to menu..." dummy
done
