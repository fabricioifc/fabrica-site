#!/bin/bash

# Parâmetros
NETWORK_NAME=fabrica-network
BRANCH=main

# Parar os containers em execução
docker compose down

# Puxar as últimas mudanças do GitHub
git pull origin $BRANCH

# Criar a rede fabrica-network, caso não exista
if [ ! "$(docker network ls --format '{{.Name}}' | grep $NETWORK_NAME)" ]; then
    docker network create $NETWORK_NAME
fi

# Subir os containers novamente com as novas mudanças
docker compose up -d --build