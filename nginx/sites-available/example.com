server {
    listen 80 default_server;

    root /usr/share/nginx/example.com;
    index index.php index.html index.htm;

    server_name example.com www.example.com;
    location / {
        try_files $uri $uri/ /index.php;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        include snippets/fastcgi-php.conf;
    }
}
