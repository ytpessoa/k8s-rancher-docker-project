# 1 - Criar 4 VMs na Cloud

#####################################################################
# 2 - Deixar todas as portas liberadas pelo Firewall entre as VMs   #
#####################################################################

##################################################
# 3 -  Instalação do Docker                      #
##################################################

# VM-RANCHER SERVER
gcloud beta compute ssh --zone "us-central1-a" "rancher-server"  --project "lab-rancher-k8s-docker"
ou
$ ssh -i /home/ytallo/.ssh/private-key <user>@<ip_externo>
#Instalação Docker(Script da Rancher):
sudo curl https://releases.rancher.com/install-docker/19.03.sh | sh
echo $USER
# nevesdinizd_gmail_com
sudo usermod -aG docker $USER
newgrp docker
# Test:
docker ps
docker run hello-world

# VM- K8S1
gcloud beta compute ssh --zone "us-central1-a" "k8s-1"  --project "lab-rancher-k8s-docker"
sudo curl https://releases.rancher.com/install-docker/19.03.sh | sh && \
    sudo usermod -aG docker $USER && \
    newgrp docker && \
    docker ps && \
    docker run hello-world


# VM-K8S2
gcloud beta compute ssh --zone "us-central1-a" "k8s-2"  --project "lab-rancher-k8s-docker"
sudo curl https://releases.rancher.com/install-docker/19.03.sh | sh 
sudo usermod -aG docker $USER 
newgrp docker 
docker ps 
docker run hello-world


# VM-K8S3
gcloud beta compute ssh --zone "us-central1-a" "k8s-3"  --project "lab-rancher-k8s-docker"




################################
# Domínio                      #
################################
italoedebora.com.br

Subdominios:
    rancher.italoedebora.com.br-------> record A --> <ip externo rancher-server-vm> 
    *.rancher.italoedebora.com.br-----> record A --> <ips externos k8s1,2,3> 

################################
# Aplicação                    #
################################
Aplicação: source code app NodeJS

# 1-Logar na VM rancher-server: 
gcloud beta compute ssh --zone "us-central1-a" "rancher-server"  --project "lab-rancher-k8s-docker"

# 2- Instalar pacotes
sudo apt-get update
#Git
sudo apt-get install git -y
#Docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version

#Clonando Source Code da Aplicacao:
cd ~
git clone https://github.com/jonathanbaraldi/devops
cd devops/exercicios/app
ls
# docker-compose.yml  limpar-host.md  nginx/  node/  readme.md  redis/  volumeteste/

### Container Redis ###

# redis/
# └── Dockerfile
#--------Dockerfile-------------------------------------
FROM redis
MAINTAINER Jonathan Baraldi
# Atualizar o repositório e instalar o server do Redis
# RUN apt-get update && apt-get install -y redis-server
# Expor Redis na porta 6379
EXPOSE 6379
# Rodar Redis Server
# ENTRYPOINT  ["/usr/bin/redis-server"]
#--------------------------------------------------------
        
cd redis/
docker image build -t docker-hub-user/image:tag .
docker image build -t ytpessoa/redis:devops .
docker image ls
# REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
# ytpessoa/redis      devops              ddd319943279        40 seconds ago      105MB
# redis               latest              de974760ddb2        7 days ago          105MB
docker container run -d --name redis -p 6379:6379 my-image
docker container run -d --name redis -p 6379:6379 ytpessoa/redis:devops
docker container ps
docker container logs redis
# Ready to accept connections


### Container NODE que contém a Aplicação ###
cd ../node
ls
# db  Dockerfile  index.js  node_modules  package.json  package-lock.json
#--------Dockerfile----------------------------------------------
# FROM node:alpine
FROM daveamit/node-alpine-grpc
MAINTAINER Jonathan Baraldi
# Prover camada de cached para os módulos do Node
RUN cd /tmp && npm install
RUN mkdir -p /src
# Instalar MariaDB SQL e rodar o script para injetar o SQL
RUN npm install mysql
# Definir diretório de trabalho
WORKDIR /src
ADD . /src
# Expor porta 80
EXPOSE  8080
# Rodar o app usando nodemon
CMD ["node", "/src/index.js"]
#------------------------------------------------------------------

docker image build -t ytpessoa/node:devops .

docker image ls
# REPOSITORY                  TAG                 IMAGE ID            CREATED             SIZE
# ytpessoa/node               devops              d39f5fa85681        2 minutes ago       69.3MB
# ytpessoa/redis              devops              ddd319943279        33 minutes ago      105MB
# redis                       latest              de974760ddb2        7 days ago          105MB
# hello-world                 latest              d1165f221234        6 weeks ago         13.3kB
# daveamit/node-alpine-grpc   latest              05a8950ce231        3 years ago         63.2MB
docker container ls
# CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                    NAMES
# fef2d65c13ae        ytpessoa/redis:devops   "docker-entrypoint.s…"   20 minutes ago      Up 20 minutes       0.0.0.0:6379->6379/tcp   redis

docker container run -d --name node -p 8080:8080 --link redis ytpessoa/node:devops
docker container ps
# CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                    NAMES
# 71aeadcebc74        ytpessoa/node:devops    "node /src/index.js"     26 seconds ago      Up 25 seconds       0.0.0.0:8080->8080/tcp   node
# fef2d65c13ae        ytpessoa/redis:devops   "docker-entrypoint.s…"   22 minutes ago      Up 22 minutes       0.0.0.0:6379->6379/tcp   redis

$ docker ps 
$ docker logs node
Com isso temos nossa aplicação rodando, e conectada no Redis. A api para verificação pode ser acessada em /redis.


### Container NGINX = será nosso balanceador de carga ###
cd ../nginx
# ├── certificado
# │   ├── certificado.crt
# │   ├── certificado.csr
# │   └── certificado.key
# ├── Dockerfile
# └── nginx.conf

#--------Dockerfile----------------------------------------------
FROM nginx
MAINTAINER Jonathan Baraldi
COPY nginx.conf /etc/nginx/nginx.conf
COPY certificado/certificado.crt  /etc/ssl/certificado.crt
COPY certificado/certificado.key  /etc/ssl/certificado.key
#----------------------------------------------------------------

docker image build -t ytpessoa/nginx:devops .
docker container run -d --name nginx -p 80:80 --link node ytpessoa/nginx:devops
docker container ps

# Teste:
Ip externo VM Rancher Server: 35.225.253.81
# ├── VM Rancher Server(3 containers):
# │   ├── nginx => 35.225.253.81:80
# │   ├── node  => 35.225.253.81:8080
# │   └── redis => 35.225.253.81:6379 ou API: 35.225.253.81/redis

#Containers: nginx => node => redis



#Derrubar todos os 'Containers' e 'Volumes' em Execução:
docker container ps
# CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                    NAMES
# 7d114e0f8725        ytpessoa/nginx:devops   "/docker-entrypoint.…"   17 minutes ago      Up 17 minutes       0.0.0.0:80->80/tcp       nginx
# 46d080a2b08d        ytpessoa/node:devops    "node /src/index.js"     3 hours ago         Up 3 hours          0.0.0.0:8080->8080/tcp   node
# fef2d65c13ae        ytpessoa/redis:devops   "docker-entrypoint.s…"   4 hours ago         Up 4 hours          0.0.0.0:6379->6379/tcp   redis
docker container ps -a -q
# 7d114e0f8725
# 46d080a2b08d
# fef2d65c13ae
# 63280898b0a5
# b0ad88a7aa70

docker container rm -f $(docker container ps -a -q)
docker volume rm $(docker volume ls)


################################
# Usando DockerCompose         #
################################
~/devops/exercicios/app$ ls
# docker-compose.yml  limpar-host.md  nginx  node  readme.md  redis  volumeteste

#--------docker-compose.yml----------------------------------------------
# Versão 2 do Docker-Compose
version: '2'
services:
    nginx:
        restart: "always"
        image: ytpessoa/nginx:devops
        ports:
            - "80:80"
        links:
            # Colocar mais nós para escalar
            - node
            # - node-2
    redis:
        restart: "always"
        image: ytpessoa/redis:devops
        ports:
            - 6379
    mysql:
        restart: "always"
        image: mysql
        ports:
            - 3306
        environment:
            MYSQL_ROOT_PASSWORD: 123
            MYSQL_DATABASE: books
            MYSQL_USER: apitreinamento
            MYSQL_PASSWORD: 123
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    node:
        restart: "always"
        image: ytpessoa/node:devops
        links:
            - redis
            - mysql
        ports:
            - 8080
        volumes:
            -  volumeteste:/tmp/volumeteste
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Mapeamento dos volumes
volumes:
    volumeteste:
        external: false
#------------------------------------------------------------------------

docker-compose -f docker-compose.yml up -d

# Teste:
curl 35.225.253.81:80
# {"Data":"Welcome to Jon's API","Hostname":"3c3ebe6a2769"}

curl 35.225.253.81/redis
# {"Data":"This page has been viewed 1 times!"} 

# Finalizando
docker-compose down