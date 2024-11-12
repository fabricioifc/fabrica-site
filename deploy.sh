#!/bin/bash

# Parar os containers em execução
docker compose down

# Puxar as últimas mudanças do GitHub
git pull origin main

# Navegar novamente para a pasta do docker-compose
cd E-Stagio-Prod/

# Subir os containers novamente com as novas mudanças
docker compose up -d --build