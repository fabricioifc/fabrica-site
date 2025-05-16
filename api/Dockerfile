# Use imagem base com Node
FROM node:18-alpine

# Cria diretório de trabalho
WORKDIR /app

# Copia arquivos de dependências
COPY package*.json ./

# Instala dependências (prod + dev)
RUN npm install

# Copia todo o restante do código-fonte
COPY . .

# Compila o TypeScript
RUN npm run build

# Expõe a porta usada pela app
EXPOSE 1111

# Inicia a aplicação
CMD ["node", "dist/app.js"]
