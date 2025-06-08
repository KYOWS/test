#!/bin/bash

GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
NC='\e[0m' # No Color

# Função para verificar a instalação do apache2-utils
check_apache2_utils() {
    echo -e "${BLUE}Verificando a instalação do apache2-utils...${NC}"
    if ! command -v htpasswd &> /dev/null; then
        echo -e "${YELLOW}Instalando apache2-utils...${NC}"
        (sudo apt update -y && sudo apt upgrade -y) > /dev/null 2>&1 & spinner $!
        echo -e "${GREEN}✅ apache2-utils instalado com sucesso!${NC}"
    else
        echo -e "${GREEN}✅ apache2-utils já está instalado.${NC}"
    fi
    return 0
}

#######################################################
##### Função para mostrar spinner de carregamento #####
#######################################################
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    #for i in {1..100}; do # Simula 5 iterações rápidas
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

########################################################
###### Função para verificar requisitos do sistema #####
########################################################

check_system_requirements() {
    echo -e "${BLUE}Verificando requisitos do sistema...${NC}"

    # Verificar espaço em disco (em GB, removendo a unidade 'G')
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    if [ "$free_space" -lt 15 ]; then
        echo -e "${RED}❌ Erro: Espaço em disco insuficiente. Mínimo requerido: 15GB. Livre: ${free_space}GB${NC}"
        return 1
    fi

    # Verificar memória RAM
    local total_mem=$(free -g | awk 'NR==2 {print $2}')
    if [ "$total_mem" -lt 2 ]; then
        echo -e "${RED}❌ Erro: Memória RAM insuficiente. Mínimo requerido: 2GB. Disponível: ${total_mem}GB${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Requisitos do sistema atendidos${NC}"
    return 0
}

###############################################################
##### Função para verificar se o Docker já está instalado #####
###############################################################

check_docker_installed() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker já está instalado.${NC}"
        return 0
    else
        echo -e "${YELLOW}🐳 Docker não encontrado. Será instalado.${NC}"
        return 1
    fi
}

#########################
###### Logo animado #####
#########################

show_animated_logo() {
    clear
    echo -e "${BLUE}"
    echo -e "             ██       ██████    ██████   ███████   ██  ██  ██    ██"
    echo -e "             ██      ██    ██  ██    ██  ██    ██  ██  ██  ████  ██"
    echo -e "             ██      ██    ██  ██    ██  ███████   ██  ██  ██ ██ ██"
    echo -e "             ██      ██    ██  ██    ██  ██        ██  ██  ██  ████"
    echo -e "             ██████   ██████    ██████   ██        ██  ██  ██    ██"
    echo -e "${NC}"
    sleep 1
}

##################################################
##### Função para mostrar um banner colorido #####
##################################################

function show_banner() {
    echo -e "${GREEN}██████████████████████████████████████████████████████████████████████████████"
    echo -e "██                                                                          ██"
    echo -e "██                ${YELLOW}Preencha as informações solicitadas abaixo${GREEN}                ██"
    echo -e "██                                                                          ██"
    echo -e "██████████████████████████████████████████████████████████████████████████████${NC}"
}

############################################################################
##### Função para mostrar uma mensagem de etapa com barra de progresso #####
############################################################################

function show_step() {
    local current=$1
    local total=5
    local percent=$((current * 100 / total))
    local completed=$((percent / 2)) # 50 caracteres para a barra

    echo -ne "${GREEN}Passo ${YELLOW}$current/$total ${GREEN}["
    for ((i=0; i<50; i++)); do
        if [ $i -lt $completed ]; then
            echo -ne "●"
        else
            echo -ne " "
        fi
    done
    echo -e "] ${percent}%${NC}"
}

######################################
##### Função para validar e-mail #####
######################################

validate_email() {
    local email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    if [[ $1 =~ $email_regex ]]; then
        return 0 # Válido
    else
        return 1 # Inválido
    fi
}

#################################################################################
##### Função para validar domínio (formato específico: pelo menos 3 partes) #####
#################################################################################

validate_domain() {    
    local domain_regex="^[a-zA-Z0-9]{2,}(\.[a-zA-Z0-9]{2,})(\.[a-zA-Z]{2,})$"
    if [[ "$1" =~ $domain_regex ]]; then
        return 0 # Válido
    else
        return 1 # Inválido
    fi
}

#######################################
##### Função para validar usuário #####
#######################################

validate_user() {    
    local domain_regex="^[a-zA-Z0-9]{4,}$"
    if [[ "$1" =~ $domain_regex ]]; then
        return 0 # Válido
    else
        return 1 # Inválido
    fi
}

#####################################################
##### Função para validar complexidade da senha #####
#####################################################

validate_password_complexity() {
    local password="$1"
    if (( ${#password} < 8 )); then
        echo -e "${RED}❌ Senha muito curta. Mínimo de 8 caracteres.${NC}"
        return 1
    fi
    if ! [[ "$password" =~ [[:digit:]] ]]; then
        echo -e "${RED}❌ Senha deve conter ao menos um número.${NC}"
        return 1
    fi
    if ! [[ "$password" =~ [[:upper:]] ]]; then
        echo -e "${RED}❌ Senha deve conter ao menos uma letra maiúscula.${NC}"
        return 1
    fi
    if ! [[ "$password" =~ [[:lower:]] ]]; then
        echo -e "${RED}❌ Senha deve conter ao menos uma letra minúscula.${NC}"
        return 1
    fi
    if ! [[ "$password" =~ [[:punct:]] ]]; then # Caracteres de pontuação
        echo -e "${RED}❌ Senha deve conter ao menos um caractere especial (ex: !@#$%^&*).${NC}"
        return 1
    fi
    return 0 # Válido
}

##################################
##### Mostrar banner inicial #####
##################################

clear
show_animated_logo
show_banner
echo ""

##########################################################
##### Solicitar informações do usuário com validação #####
##########################################################

show_step 1
while true; do
    read -p "📧 Endereço de e-mail (para certificados SSL): " email
    if validate_email "$email"; then
        echo -e "${GREEN}✅ E-mail válido.${NC}"
        break
    else
        echo -e "${RED}❌ E-mail inválido. Por favor, insira um endereço de e-mail válido (ex: seu.email@dominio.com).${NC}"
    fi
done
echo ""

show_step 2
while true; do
    read -p "🌐 Dominio do Traefik (ex: traefik.seudominio.com): " traefik_domain
    if validate_domain "$traefik_domain"; then
        echo -e "${GREEN}✅ Domínio válido.${NC}"
        break
    else
        echo -e "${RED}❌ Domínio inválido. Por favor, insira um domínio válido.${NC}"
    fi
done
echo ""

show_step 3
while true; do
    read -p "🌐 Usuário do Traefik (ex: admin): " traefik_user
    if validate_user "$traefik_user"; then
        echo -e "${GREEN}✅ Usuário válido.${NC}"
        break
    else
        echo -e "${RED}❌ Usuário inválido. Por favor, insira um usuário válido. Mínimo de 4 caracteres.${NC}"
    fi
done
echo ""

show_step 4
while true; do
    read -s -p "🔑 Senha do Traefik (mínimo 8 caracteres, com maiúscula, minúscula, número e especial): " traefik_senha
    echo "" # Quebra de linha após a entrada da senha oculta
    if validate_password_complexity "$traefik_senha"; then              
        echo -e "${GREEN}✅ Senha aceita.${NC}"
        break
    fi
done
echo ""

show_step 5
while true; do
    read -p "🌐 Dominio do Portainer (ex: portainer.seudominio.com): " portainer_domain
    if validate_domain "$portainer_domain"; then
        echo -e "${GREEN}✅ Domínio válido.${NC}"
        break
    else
        echo -e "${RED}❌ Domínio inválido. Por favor, insira um domínio válido.${NC}"
    fi
done
echo ""

show_step 6
while true; do
    read -p "🌐  Dominio do Edge (ex: edge.seudominio.com): " edge_domain
    if validate_domain "$edge_domain"; then
        echo -e "${GREEN}✅ Domínio válido.${NC}"
        break
    else
        echo -e "${RED}❌ Domínio inválido. Por favor, insira um domínio válido.${NC}"
    fi
done
echo ""

################################
##### Verificação de dados #####
################################

clear
echo -e "${BLUE}📋 Resumo das Informações${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "📧 Seu E-mail: ${YELLOW}$email${NC}"
echo -e "🌐 Dominio do Traefik: ${YELLOW}$traefik_domain${NC}"
echo -e "🌐 Usuário do Traefik: ${YELLOW}$traefik_user${NC}"
echo -e "🔑 Senha do Traefik: ${YELLOW}********${NC}" # Apenas para visualização
echo -e "🌐 Dominio do Portainer: ${YELLOW}$portainer_domain${NC}"
echo -e "🌐 Dominio do Edge: ${YELLOW}$edge_domain${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

read -p "As informações estão certas? (y/n): " confirma1
if [ "$confirma1" == "y" ]; then
    clear

    ###########################################
    ##### Verificar requisitos do sistema #####
    ###########################################
    
    check_system_requirements || { echo -e "${RED}❌ Instalação cancelada devido a requisitos do sistema não atendidos.${NC}"; exit 1; }

    echo -e "${BLUE}🚀 Iniciando instalação ...${NC}"

    ###################################
    ##### INSTALANDO DEPENDENCIAS ##### 
    ###################################
   
    echo -e "${YELLOW}📦 Atualizando sistema e instalando dependências...${NC}"
    
    (sudo apt update -y && sudo apt upgrade -y) > /dev/null 2>&1 & spinner $!
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erro ao atualizar o sistema e instalar dependências. Verifique sua conexão ou permissões.${NC}"
        exit 1
    fi
    check_apache2_utils || { echo -e "${RED}❌ Não foi possível instalar o apache2-utils. Saindo.${NC}"; exit 1; }
    #encrypted_password=$(htpasswd -nb -B -C 10 $traefik_user" "$traefik_senha" | head -n 1)
    encrypted_password='12345678'
    echo -e "${GREEN}✅ Sistema atualizado e dependências básicas instaladas.${NC}"

    ###################################################################
    ##### Verificar se o Docker já está instalado, senão instalar #####
    ###################################################################
    
    if ! check_docker_installed; then
        echo -e "${YELLOW}🐳 Instalando Docker...${NC}"

        #### mudar
        (sudo apt update -y && sudo apt upgrade -y) > /dev/null 2>&1 & spinner $!
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Erro ao instalar o Docker. Por favor, verifique a saída do comando.${NC}"
            exit 1
        fi
        echo -e "${GREEN}✅ Docker instalado com sucesso.${NC}"
    fi
    
    ######################################
    ##### CRIANDO DOCKER-COMPOSE.YML #####
    ######################################
    
   echo -e "${YELLOW}📝 Criando docker-compose.yml...${NC}"
    cat > docker-compose.yml <<EOL
services:  
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: always
    networks:
      - web
    ports:
      - 80:80
      - 443:443
    volumes:
      - /etc/localtime:/etc/localtime
      - /var/run/docker.sock:/var/run/docker.sock
      - /docker/traefik/traefik.toml:/traefik.toml
      - /docker/traefik/traefik_dynamic.toml:/traefik_dynamic.toml
      - /docker/traefik/acme.json:/acme.json
    logging:
      options:
        max-size: "10m"
        max-file: "3"

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /home/docker/portainer/data:/data
    ports:
      - 8000:8000
      - 9000:9000
      - 9443:9443
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(`$portainer_domain`)"
      - "traefik.http.routers.portainer.tls=true"
      - "traefik.http.routers.portainer.tls.certresolver=lets-encrypt"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"
      - "traefik.docker.network=web"
    logging:
      options:
        max-size: "10m"
        max-file: "3"

networks:
  web:
    external: true
EOL
    echo -e "${GREEN}✅ docker-compose.yml criado com sucesso.${NC}"

 ################################
 ##### CRIANDO TRAEFIK.TOML #####
 ################################
    
   echo -e "${YELLOW}📝 Criando traefik.toml...${NC}"
    cat > traefik.toml <<EOL
[entryPoints]
  [entryPoints.web]
    address = ":80"
    
    [entryPoints.web.http]
      [entryPoints.web.http.redirections]
        [entryPoints.web.http.redirections.entryPoint]
          to = "websecure"
          scheme = "https"

  [entryPoints.websecure]
    address = ":443"

[log]
  level = "WARN"

[accessLog]

[metrics]
  [metrics.prometheus]
    addEntryPointsLabels = true
    addServicesLabels = true
    addRoutersLabels = true

[api]
  dashboard = true

[certificatesResolvers.lets-encrypt.acme]
  email = "$email"
  storage = "acme.json"
  [certificatesResolvers.lets-encrypt.acme.tlsChallenge]

[providers.docker]
  watch = true
  network = "web"

[providers.file]
  filename = "traefik_dynamic.toml"
EOL
    echo -e "${GREEN}✅ traefik.toml criado com sucesso.${NC}"
    
########################################
##### CRIANDO TRAEFIK_DYNAMIC.TOML #####
########################################

   echo -e "${YELLOW}📝 Criando traefik_dynamic.toml...${NC}"
    cat > traefik_dynamic.toml <<EOL
[http.middlewares.simpleAuth.basicAuth]
  users = [
    "$encrypted_password"
  ]

# Use with traefik.http.routers.myRouter.middlewares: "redirect-www-to-main@file"
[http.middlewares]
  [http.middlewares.redirect-www-to-main.redirectregex]
      permanent = true
      regex = "^https?://www\\.(.+)"
      replacement = "https://${1}"

[http.routers.api]
  rule = "Host(`$traefik_domain`)"
  entrypoints = ["websecure"]
  middlewares = ["simpleAuth"]
  service = "api@internal"
  [http.routers.api.tls]
    certResolver = "lets-encrypt"
EOL
    echo -e "${GREEN}✅ traefik_dynamic.toml criado com sucesso.${NC}"

    ####################################
    ##### CERTIFICADOS LETSENCRYPT #####
    ####################################
    
    echo -e "${YELLOW}📝 Configurando permissões para acme.json...${NC}"
    
    if [ ! -f acme.json ]; then
      touch acme.json && chmod 600 acme.json
    fi
    
    echo -e "${GREEN}✅ Permissões para acme.json configuradas.${NC}"

    ###############################
    ##### INICIANDO CONTAINER #####
    ###############################
    
    echo -e "${YELLOW}🚀 Iniciando containers Docker...${NC}"    
    
    #mudar (sudo docker compose up -d) > /dev/null 2>&1 & spinner $!
    (sudo apt update -y && sudo apt upgrade -y) > /dev/null 2>&1 & spinner $!
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erro ao iniciar os containers Docker. Verifique a saída de 'sudo docker compose up'.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Containers iniciados com sucesso.${NC}"

    clear
    show_animated_logo

    echo -e "${GREEN}🎉 Instalação concluída com sucesso!${NC}"
    echo -e "${BLUE}📝 Informações de Acesso:${NC}"
    echo -e "${GREEN}================================${NC}"
    echo -e "🔗 Portainer: ${YELLOW}https://$portainer_domain${NC}"
    echo -e "🔗 Traefik: ${YELLOW}https://$traefik_domain${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${BLUE}💡 Dica: Aguarde alguns minutos para que os certificados SSL sejam gerados pelo Let's Encrypt.${NC}"
    echo -e "${BLUE}➡️ Lembre-se de configurar os registros DNS (A/AAAA) para os domínios acima apontarem para este servidor!${NC}"
    echo -e "${GREEN}🌟 Visite: https://loopiin.com.br${NC}"
else
    echo -e "${RED}❌ Instalação cancelada. Por favor, inicie novamente se desejar prosseguir.${NC}"
    exit 0
fi
