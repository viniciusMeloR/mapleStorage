#!/bin/bash
set -e

echo "========================================="
echo "Iniciando configuração do Maple Storage"
echo "========================================="

#Dando update no gerenciador de pacotes
dnf update -y

#Baixar git,wget e unzip
dnf install -y git wget unzip

echo "Instalando Node.js"

#Instalar o node
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -

dnf install -y nodejs

echo "Node.js instalado:"
node -v

echo "NPM instalado:"
npm -v

#Clonando o projeto

cd /home/ec2-user

git clone https://github.com/viniciusMeloR/mapleStorage.git

cd /home/ec2-user/mapleStorage


echo "Criando arquivo .env..."

cat <<EOF > .env
AMBIENTE_PROCESSO=producao
APP_HOST=0.0.0.0
APP_PORT=${app_port}

DB_HOST=${rds_endpoint}
DB_DATABASE=${rds_database}
DB_USER=${rds_username}
DB_PASSWORD=${rds_password}
DB_PORT=3306
EOF

# =========================================================
# CONFIGURAÇÃO DO PM2
# =========================================================
#Fazendo o pm2 rodar o app.js
cat <<'EOF' > /home/ec2-user/mapleStorage/ecosystem.config.js
module.exports = {
  apps: [
    {
      name: "mapleStorage",
      script: "./app.js",
      env: {
        AMBIENTE_PROCESSO: "producao"
      }
    }
  ]
};
EOF

chown ec2-user:ec2-user /home/ec2-user/mapleStorage/ecosystem.config.js
# =========================================================
# PERMISSÕES
# =========================================================

chown -R ec2-user:ec2-user /home/ec2-user/mapleStorage


#instalar npm

sudo -u ec2-user npm install


echo "========================================="
echo "Aguardando RDS..."
echo "========================================="
#Teste para abrir uma conexao na porta e ver se o rds esta criado para
#aceitar conexões
until timeout 2 bash -c "</dev/tcp/${rds_endpoint}/3306" 2>/dev/null
do
    echo "RDS ainda não está disponível..."
    sleep 10
done

echo "RDS disponível!"


# =========================================================
# PM2
# =========================================================

echo "Instalando PM2..."

npm install -g pm2

#Executar o pm2 com a configuração que acabamos de criar
sudo -u ec2-user pm2 start /home/ec2-user/mapleStorage/ecosystem.config.js

#salvar o processo do pm2 para reiniciar a aplicacao
sudo -u ec2-user pm2 save


# =========================================================
# FINAL
# =========================================================

echo "========================================="
echo "Maple Storage configurado com sucesso!"
echo "========================================="