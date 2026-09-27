#!/bin/bash
set -e

echo "========================================="
echo "Iniciando configuração do Maple Storage"
echo "========================================="


# =========================================================
# ATUALIZAÇÃO DO SISTEMA
# =========================================================

dnf update -y

dnf install -y git wget unzip

echo "Instalando Node.js..."

curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -

dnf install -y nodejs

echo "Node.js instalado:"
node -v

echo "NPM instalado:"
npm -v

echo "========================================="
echo "Instalando CloudWatch Agent"
echo "========================================="

wget https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm

rpm -U ./amazon-cloudwatch-agent.rpm

rm amazon-cloudwatch-agent.rpm

echo "CloudWatch Agent instalado!"

echo "Configurando CloudWatch Agent..."

cat <<'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },

  "metrics": {
    "namespace": "MapleStorage/EC2",

    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },

      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,

        "resources": [
          "/"
        ]
      },

      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_user",
          "cpu_usage_system"
        ],

        "metrics_collection_interval": 60,

        "totalcpu": true
      }
    }
  }
}
EOF

echo "Configuração criada!"

echo "Iniciando CloudWatch Agent..."

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "CloudWatch Agent iniciado!"


echo "========================================="
echo "Clonando projeto"
echo "========================================="

cd /home/ec2-user

git clone https://github.com/viniciusMeloR/Cookiesz.git

cd /home/ec2-user/Cookiesz


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

cat <<'EOF' > /home/ec2-user/Cookiesz/ecosystem.config.js
module.exports = {
  apps: [
    {
      name: "cookiesz",
      script: "./app.js",
      env: {
        AMBIENTE_PROCESSO: "producao"
      }
    }
  ]
};
EOF

chown ec2-user:ec2-user /home/ec2-user/Cookiesz/ecosystem.config.js
# =========================================================
# PERMISSÕES
# =========================================================

chown -R ec2-user:ec2-user /home/ec2-user/Cookiesz


# =========================================================
# INSTALAR DEPENDÊNCIAS
# =========================================================

echo "Instalando dependências..."

sudo -u ec2-user npm install


# =========================================================
# AGUARDAR RDS
# =========================================================

echo "========================================="
echo "Aguardando RDS..."
echo "========================================="

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

sudo -u ec2-user pm2 start /home/ec2-user/Cookiesz/ecosystem.config.js

sudo -u ec2-user pm2 save


# =========================================================
# FINAL
# =========================================================

echo "========================================="
echo "Maple Storage configurado com sucesso!"
echo "CloudWatch Agent configurado com sucesso!"
echo "========================================="