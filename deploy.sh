#!/bin/bash

# Parâmetros
NETWORK_NAME=fabrica-network
NETWORK_NAME_NGINX=fabrica-nginx-proxy-network
DOCKER_COMPOSE_FILE=docker-compose.yml
DOCKER_COMPOSE_BUILD=true
CONTAINER_NAME=eventos-comp-back

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "Erro: $1"
    exit 1
}

# Parar os containers em execução
echo "Parando os containers..."
docker compose down || error_exit "Não foi possível parar os containers"

# Criar a rede NETWORK_NAME se ela não existir.
if [ ! "$(docker network ls --format '{{.Name}}' | grep $NETWORK_NAME)" ]; then
    echo "Criando a rede $NETWORK_NAME..."
    docker network create $NETWORK_NAME || error_exit "Não foi possível criar a rede $NETWORK_NAME"
fi

# Subir os containers novamente com as novas mudanças
echo "Subindo os containers..."
if [ "$DOCKER_COMPOSE_BUILD" = true ]; then
    docker compose -f $DOCKER_COMPOSE_FILE up -d --build || error_exit "Não foi possível subir os containers"
else
    docker compose -f $DOCKER_COMPOSE_FILE up -d || error_exit "Não foi possível subir os containers"
fi

# Verificar se a rede NETWORK_NAME_NGINX está conectada ao container fabrica-prod-web
if [ ! "$(docker network inspect -f '{{range .Containers}}{{.Name}}{{end}}' $NETWORK_NAME_NGINX | grep $CONTAINER_NAME)" ]; then
    echo "Conectando a rede $NETWORK_NAME_NGINX ao container $CONTAINER_NAME..."
    docker network connect $NETWORK_NAME_NGINX $CONTAINER_NAME || error_exit "Não foi possível conectar a rede $NETWORK_NAME_NGINX ao container $CONTAINER_NAME"
fi

echo "Deploy finalizado com sucesso!"
