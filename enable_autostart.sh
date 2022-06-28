#!/bin/bash

sed -i 's/x-restart-policy: \&restart-policy "no"/x-restart-policy: \&restart-policy "unless-stopped"/g' docker-compose.yml
docker-compose up -d
