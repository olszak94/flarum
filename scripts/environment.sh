#! /bin/bash

block="
    server {
        listen 80;

        root /vagrant;
        index index.html index.htm index.php;

        # Make site accessible from ...
        server_name flarum.dev 192.168.29.29.xip.io;

        access_log /var/log/nginx/flarum-access.log;
        error_log  /var/log/nginx/flarum-error.log error;

        charset utf-8;

        location / {
            try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location /api {
            try_files \$uri \$uri/ /api.php?\$query_string;
        }

        location /admin {
            try_files \$uri \$uri/ /admin.php?\$query_string;
        }

        location = /favicon.ico { log_not_found off; access_log off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        # pass the PHP scripts to php5-fpm
        # Note: .php$ is susceptible to file upload attacks
        # Consider using: \"location ~ ^/(index|app|app_dev|config).php(/|$) {\"
        location ~ \.php$ {
            try_files \$uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            # With php5-fpm:
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_param LARA_ENV local; # Environment variable for Laravel
            fastcgi_param HTTPS off;
        }

        # Deny .htaccess file access
        location ~ /\.ht {
            deny all;
        }
    }
"

echo "$block" | sudo tee /etc/nginx/sites-available/vagrant
sudo service nginx restart

### Setup NPM globals and create necessary directories ###
sudo chown -R vagrant:vagrant /home/vagrant

cp /vagrant/scripts/aliases ~/.aliases

### Create rc file ###
echo "source ~/.aliases" >> ~/.bashrc

mysql -u root -proot -e 'create database if not exists flarum'

### Setup flarum/core and install dependencies ###
cd /vagrant/flarum/core
git pull
composer install --prefer-dist
bash scripts/compile.sh

cd /vagrant/flarum
composer install --prefer-dist
composer dump-autoload
php flarum install --defaults
