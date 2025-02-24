# Manual de Uso e Configuração

Este manual tem como objetivo auxiliar na configuração de usuários e da sua aplicação para que possa ser utilizada com o NGINX Proxy. Este manual se aplica a todos os projetos que estão rodando no servidor `fsw-ifc.brdrive.net`.

## Criação de Usuários (ADMINISTRADOR/PROFESSOR)

Cada desenvolvedor deve ter um usuário no servidor. Para criar um novo usuário, execute o comando:

```bash
sudo adduser NOME_DO_USUARIO
```

Este usuário não deve ter permissões de superusuário. Contudo, pode fazer parte do grupo `docker` e fazer parte do grupo `dev`. O grupo `dev` é um grupo criado para facilitar o acesso dos usuários às pastas dos projetos.

```bash
sudo usermod -aG docker NOME_DO_USUARIO
sudo usermod -aG dev NOME_DO_USUARIO
```

Encaminhe os dados para o usuário criado para que ele possa acessar o servidor.

```json
{
    "HOST": "fsw-ifc.brdrive.net",
    "PORTA": "2222",
    "USUARIO": "NOME_DO_USUARIO",
    "SENHA": "SENHA_DO_USUARIO"
}
```

> **Atenção:** Peça para o usuário trocar a senha assim que acessar o servidor pela primeira vez. Este acesso é permitiro apenas dentro da faixa de IP da instituição, ou seja, apenas dentro da rede do IFC Videira. Para obter acesso externo, entre em contato com o administrador do servidor através do e-mail `fabricadesoftware.videira@ifc.edu.br`. Seu pedido será avaliado e, se aprovado, será liberado o acesso.


## Configurando seu Projeto com Docker Compose

Todos os projetos em produção devem estar na pasta `/opt`. No momento, a estrutura de pastas está organizada da seguinte forma:

```bash
|-- /opt
    |-- /fabrica-cogercon # rodando na porta 8000
    |-- /e-stagio # rodando na porta 5000
    |-- /fabrica-web # rodando na porta 8090
    |-- /fabrica-nginx-proxy-letsencrypt # rodando na porta 80 (http) e 443 (https).
    |-- /seuprojeto # deve ser criado na pasta /opt e rodar em outra porta
```

Seu projeto precisa ter pelo menos os seguintes arquivos:

- `docker-compose.yml`: Arquivo de configuração do Docker Compose.
- `Dockerfile`: Arquivo de configuração do Docker (opcional).
- `deploy.sh`: Script para facilitar o deploy da aplicação.


O arquivo `docker-compose.yml` do seu projeto deve conter as seguintes configurações mínimas:

```yaml
services:
  web:
    build: .
    container_name: NOME_DO_PROJETO-prod-web
    ports:
      - "PORTA:PORTA"
    volumes:
      - .:/app
    networks:
      - NOME_DO_PROJETO-network
    
networks:
  NOME_DO_PROJETO-network:
    external: true
```

- `NOME_DO_PROJETO`: Nome do seu projeto. Sugiro que siga o padrão de nomeclatura `NOME_DO_PROJETO-prod-web`. Exemplo: `meuprojeto-prod-web`.
- `PORTA`: Porta que a aplicação está rodando. Sugiro que siga o padrão de porta `PORTA:PORTA`. Exemplo: `8080:8080`.
- `NOME_DO_PROJETO-network`: Nome da rede do seu projeto. Sugiro que siga o padrão de nomeclatura `NOME_DO_PROJETO-network`. Exemplo: `meuprojeto-network`.

Configure um script `deploy.sh` para facilitar o deploy da aplicação. O script deve conter as seguintes configurações mínimas:

```bash
#!/bin/bash

# Parâmetros
GITHUB_URL=LINK_DO_REPOSITORIO_NO_GITHUB
NETWORK_NAME=NOME_DO_PROJETO-network
NETWORK_NAME_NGINX=fabrica-nginx-proxy-network
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

# Verificar se a rede NETWORK_NAME_NGINX está conectada ao container fabrica-prod-web
if [ ! "$(docker network inspect -f '{{range .Containers}}{{.Name}}{{end}}' $NETWORK_NAME_NGINX | grep fabrica-prod-web)" ]; then
    echo "Conectando a rede $NETWORK_NAME_NGINX ao container fabrica-prod-web..."
    docker network connect $NETWORK_NAME_NGINX fabrica-prod-web || error_exit "Não foi possível conectar a rede $NETWORK_NAME_NGINX ao container fabrica-prod-web"
fi

echo "Deploy finalizado com sucesso!"
```

- `GITHUB_URL`: Link do repositório no GitHub. Exemplo: `https://github.con/fabricioifc/fabrica-site.git`
- `NETWORK_NAME`: Nome da rede do seu projeto. Sugiro que siga o padrão de nomeclatura `NOME_DO_PROJETO-network`. Exemplo: `meuprojeto-network`.

### Permissões da Pasta do Projeto (ADMINISTRADOR/PROFESSOR)

Para que os usuários do grupo `dev` possam acessar a pasta do projeto, é necessário alterar as permissões da pasta do projeto. Para isso, execute o comando:

```bash
sudo chown -R $USER:dev /opt/NOME_DO_PROJETO
sudo chmod -R 775 /opt/NOME_DO_PROJETO
```

> **Atenção:** Substitua `NOME_DO_PROJETO` pelo nome do seu projeto.

Desta forma, todos os usuários do grupo `dev` terão acesso à pasta do projeto. Isso permite que os usuários possam fazer alterações no projeto e subir as alterações para o repositório.

## Dúvidas

Em caso de dúvidas, entre em contato com o administrador do servidor através do e-mail `fabricadesoftware.videira@ifc.edu.br`.