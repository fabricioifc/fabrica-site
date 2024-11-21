#!/bin/bash

# Parâmetros
GITHUB_URL=https://github.con/fabricioifc/fabrica-site.git
NETWORK_NAME=fabrica-network
DOCKER_COMPOSE_FILE=docker-compose.yml
BRANCH=main

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "Erro: $1"
    exit 1
}

# Verificar se o branch existe no repositório remoto
if ! git ls-remote --exit-code --heads origin "$BRANCH" &>/dev/null; then
    error_exit "Branch '$BRANCH' não existe no repositório remoto."
fi

# Parar os containers em execução
echo "Parando os containers..."
docker compose down || error_exit "Não foi possível parar os containers"

# Puxar as últimas mudanças do GitHub
echo "Puxando as últimas mudanças do GitHub..."
git pull origin $BRANCH || error_exit "Não foi possível puxar as últimas mudanças do GitHub ($BRANCH)"

# Criar a rede fabrica-nginx-proxy-network se ela não existir. Essa rede é necessária para o nginx-proxy
if [ ! "$(docker network ls --format '{{.Name}}' | grep $NETWORK_NAME)" ]; then
    echo "Criando a rede $NETWORK_NAME..."
    docker network create $NETWORK_NAME || error_exit "Não foi possível criar a rede $NETWORK_NAME"
fi

# Subir os containers novamente com as novas mudanças
echo "Subindo os containers..."
docker compose -f $DOCKER_COMPOSE_FILE up -d --build || error_exit "Não foi possível subir os containers"

echo "Deploy finalizado com sucesso!"
