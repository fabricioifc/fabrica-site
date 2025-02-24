# Manual de Uso e Configuração

Este manual tem como objetivo auxiliar na configuração da sua aplicação para que possa ser utilizada com o NGINX Proxy. Este manual se aplica a todos os projetos que estão rodando no servidor `fsw-ifc.brdrive.net`.

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

## Antes de Subir a Aplicação

Antes de subir a aplicação, é necessário verificar se os container dos projetos estão rodando. Neste momento, os projetos que devem estar rodando são: 

 - `fabrica-prod-web`
 - `cogercon-prod-web`
 - `estagios-prod-web`
 - `seuprojeto-prod-web`

Para verificar se os containers estão rodando, execute o comando:

```bash
docker ps | grep "\-prod-web"
```
> Caso um dos containers acima não estejam rodando, não será possível subir esta aplicação com NGINX pois a aplicação estará `UNHEALTHY`. Se isso acontecer, entre em contato com o administrador do servidor através do e-mail `fabricadesoftware.videira@ifc.edu.br`.

## Subindo a aplicação

Para facilitar o deploy da aplicação, foi criado um script chamado `deploy.sh` que faz a checagem dos containers e sobe a aplicação. Para subir a aplicação, faça os devidos ajustes nos parâmetros do arquivo `deploy.sh`.

- `PROJECTS`: Adicione seu projeto na lista de projetos. Isso você configura no arquivo `docker-compose.yml` do seu projeto. Sugiro que siga o padrão de nomeclatura `NOME_DO_PROJETO-prod-web`.
- `NETWORKS`: Adicione sua rede na lista de redes. Isso você configura no arquivo `docker-compose.yml` do seu projeto. Sugiro que siga o padrão de nomeclatura `NOME_DO_PROJETO-network`.

```bash
# Projetos que precisam estar em execução para rodar o nginx-proxy
PROJECTS=("fabrica-prod-web" "cogercon-prod-web" "estagios-prod-web")
# Networks que precisam estar conectadas ao nginx-proxy
NETWORKS=("cogercon-network" "fabrica-network" "estagios-network")
```

Após configurar o arquivo `deploy.sh`, execute o comando:

```bash
./deploy.sh
```

> O script irá verificar se os containers dos projetos estão rodando e, conectar os containers à rede `fabrica-nginx-proxy-network`, baixar possíveis alterações do repositório, executar o comando `docker-compose down` e `docker-compose up -d` para subir a aplicação.

## Rede de Containers

Para que a aplicação funcione corretamente, é necessário que os containers estejam na mesma rede ou que a rede dos containers esteja configurada corretamente. O projeto que roda o NGINX utiliza a rede `fabrica-nginx-proxy-network` para que o NGINX possa se comunicar com os containers dos projetos. É uma rede externa, criada manualmente.

Para verificar se os containers estão na mesma rede, execute o comando:

```bash
docker network inspect fabrica-nginx-proxy-network | grep "\-prod-web"
```

O resultado esperado deve ser algo como:

```json
    "Name": "fabrica-prod-web",
    "Name": "estagios-prod-web",
    "Name": "cogercon-prod-web",
```