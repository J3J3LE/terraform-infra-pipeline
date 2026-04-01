#!/bin/bash

#Instalar Docker, Git, jq e AWS CLI
sudo dnf update -y
sudo dnf install git -y
sudo dnf install docker -y
sudo dnf install jq -y
# instala expect
sudo dnf install expect -y

#Instalar AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo dnf install unzip -y
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker ssm-user
id ec2-user ssm-user
sudo newgrp docker

#Ativar docker
sudo systemctl enable docker.service
sudo systemctl start docker.service

#Instalar docker compose 2
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

#Adicionar swap
sudo dd if=/dev/zero of=/swapfile bs=128M count=32
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

#Instalar node e npm
curl -fsSL https://rpm.nodesource.com/setup_21.x | sudo bash -
sudo dnf install -y nodejs

#Configurar python 3.11 e uv para uso com mcp servers da aws
sudo dnf install python3.11 -y
sudo ln -sf /usr/bin/python3.11 /usr/bin/python3

sudo -u ec2-user bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/ec2-user/.bashrc

# Criar pasta
mkdir -p /home/ec2-user/.ssh

# Puxar chave do Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id github-ssh-key \
  --query SecretString \
  --output text > /home/ec2-user/.ssh/id_ed25519

# Permissões
chmod 600 /home/ec2-user/.ssh/id_ed25519
chown -R ec2-user:ec2-user /home/ec2-user/.ssh

# Evitar erro SSH
ssh-keyscan github.com >> /home/ec2-user/.ssh/known_hosts
chown ec2-user:ec2-user /home/ec2-user/.ssh/known_hosts

# Clone
sudo -u ec2-user git clone git@github.com:J3J3LE/bia.git /home/ec2-user/bia

# No seu user_data:
cd /home/ec2-user/
curl --proto '=https' --tlsv1.2 -sSf 'https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-x86_64-linux.zip' -o 'kirocli.zip'
unzip kirocli.zip
rm -rf kirocli.zip

# executa automatizado (pressionando ENTER)
sudo -u ec2-user bash <<'EOF'
cd /home/ec2-user/kirocli

export HOME=/home/ec2-user

expect <<EOL
spawn ./install.sh
expect {
    "modify your shell config" { send "\r" }
    timeout { send "\r" }
}
expect eof
EOL

EOF

sleep 5
grep "kiro-cli login" /var/log/cloud-init-output.log | sed 's/.*: //' > /home/ec2-user/login_command.txt

chown ec2-user:ec2-user /home/ec2-user/login_command.txt
uv venv
uv pip install awslabs-ecs-mcp-server

sleep 5

cd /home/ec2-user/bia/
sudo docker compose up -d

# 2. Definir a variável (pegando do output do Terraform ou fixo)
ECR_REGISTRY="${ECR_REGISTRY}" 

# 3. Login (A região deve ser a mesma do ECR)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

cd /home/ec2-user/bia/
docker build -t bia .
docker tag bia:latest $ECR_REGISTRY/bia:latest
docker push $ECR_REGISTRY/bia:latest

docker pull j3j3le/ras:latest
docker tag j3j3le/ras:latest $ECR_REGISTRY/app-java:latest
docker push $ECR_REGISTRY/app-java:latest

sleep 10

sudo docker run -p 80:8080 j3j3le/ras:latest