#!/bin/bash
docker compose down
docker compose build
docker compose up -d
docker compose exec web /bin/bash service nginx start
docker compose exec web /bin/bash service php7.4-fpm start
