#!/bin/bash

sed -i 's/#    restart: unless-stopped/    restart: unless-stopped/g' docker-compose.yml
docker-compose up -d
