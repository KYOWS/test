#!/bin/bash

GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[94m'
NC='\e[0m' # No Color

###############################################################
##### Função para verificar a instalação do apache2-utils #####
###############################################################

check_apache2_utils() {
    echo -e "${BLUE}Verificando a instalação do apache2-utils...${NC}"
    if ! command -v htpasswd &> /dev/null; then
        echo -e "${YELLOW}Instalando apache2-utils...${NC}"

        (sudo apt-get update -y && sudo apt-get install apache2-utils -y) > /dev/null 2>&1 & spinner $!
                
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

#######################################################
##### Definição da função de instalação do Docker #####
#######################################################

install_docker_function() {
    sudo apt-get update -y && \
    sudo apt-get install ca-certificates curl -y && \
    sudo install -m 0755 -d /etc/apt/keyrings && \
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    sudo chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    sudo apt-get update -y && \
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

#########################
###### Logo animado #####
#########################

show_animated_logo() {
    clear
    echo -e "${BLUE}"
    echo -e "██      ▄██████▄  ▄██████▄  ███████▄  ██  ██  █▄    ██"
    echo -e "██      ██    ██  ██    ██  ██    ██  ██  ██  ███▄  ██"
    echo -e "██      ██    ██  ██    ██  ███████▀  ██  ██  ██▀██▄██"
    echo -e "██      ██    ██  ██    ██  ██        ██  ██  ██  ▀███"
    echo -e "██████  ▀██████▀  ▀██████▀  ██        ██  ██  ██    ▀█"
    echo -e "${NC}"   
}

##################################################
##### Função para mostrar um banner colorido #####
##################################################

function show_banner() {

    echo -e "${BLUE}"
    echo -e "█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█"    
    echo -e "█     Preencha as informações solicitadas abaixo     █"   
    echo -e "█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█"
    echo -e "${NC}"
}

############################################################################
##### Função para mostrar uma mensagem de etapa com barra de progresso #####
############################################################################

function show_step() {
    local current=$1
    local total=6
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
sleep 1
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

clear
show_animated_logo
show_banner
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

clear
show_animated_logo
show_banner
echo ""

show_step 3
while true; do
    read -p "👮 Usuário do Traefik (ex: admin): " traefik_user
    if validate_user "$traefik_user"; then
        echo -e "${GREEN}✅ Usuário válido.${NC}"
        break
    else
        echo -e "${RED}❌ Usuário inválido. Por favor, insira um usuário válido. Mínimo de 4 caracteres.${NC}"
    fi
done

clear
show_animated_logo
show_banner
echo ""

show_step 4
while true; do
    read -s -p "🔑 Senha do Traefik (mínimo 8 caracteres, com maiúscula, minúscula, número e especial): " traefik_senha
    echo "" # Quebra de linha após a entrada da senha oculta
    read -s -p "🔁 Confirme a Senha do Traefik: " traefik_senha_confirm
    echo "" # Quebra de linha após a entrada da senha de confirmação oculta

    if [[ "$traefik_senha" == "$traefik_senha_confirm" ]]; then
        if validate_password_complexity "$traefik_senha"; then
            echo -e "${GREEN}✅ Senha aceita.${NC}"
            break
        fi
    else
        echo -e "${RED}❌ As senhas não coincidem. Por favor, tente novamente.${NC}"
    fi
done

clear
show_animated_logo
show_banner
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

clear
show_animated_logo
show_banner
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

################################
##### Verificação de dados #####
################################

clear
echo -e "${BLUE}📋 Resumo das Informações${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "📧 Seu E-mail: ${YELLOW}$email${NC}"
echo -e "🌐 Dominio do Traefik: ${YELLOW}$traefik_domain${NC}"
echo -e "👮 Usuário do Traefik: ${YELLOW}$traefik_user${NC}"
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
    
    (sudo apt-get update -y && sudo apt-get upgrade -y) > /dev/null 2>&1 & spinner $!
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erro ao atualizar o sistema e instalar dependências. Verifique sua conexão ou permissões.${NC}"
        exit 1
    fi
    check_apache2_utils || { echo -e "${RED}❌ Não foi possível instalar o apache2-utils. Saindo.${NC}"; exit 1; }
    
    encrypted_password=$(htpasswd -nb -B -C 10 "$traefik_user" "$traefik_senha")
    
    echo -e "${GREEN}✅ Sistema atualizado e dependências básicas instaladas.${NC}"

    ###################################################################
    ##### Verificar se o Docker já está instalado, senão instalar #####
    ###################################################################   
    
    if ! check_docker_installed; then
        echo -e "${YELLOW}🐳 Instalando Docker...${NC}"

        install_docker_function > /dev/null 2>&1 & spinner $!
               
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Erro ao instalar o Docker. Por favor, verifique a saída do comando.${NC}"
            exit 1
        fi
        echo -e "${GREEN}✅ Docker instalado com sucesso.${NC}"
    fi

    echo -e "${YELLOW}📁 Criando diretórios e configurando...${NC}"
    (sudo mkdir -p /docker/traefik && sudo mkdir -p /docker/portainer/data) > /dev/null 2>&1 & spinner $!
    wait $!
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erro ao criar diretórios. Verifique suas permissões.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Diretórios criados com sucesso.${NC}"    
   
    ######################################
    ##### CRIANDO DOCKER-COMPOSE.YML #####
    ######################################

    # Entra no diretório /docker para criar os arquivos
    cd /docker || { echo -e "${RED}❌ Não foi possível mudar para o diretório /docker.${NC}"; exit 1; }
    
   echo -e "${YELLOW}📝 Criando docker-compose.yml...${NC}"
    cat <<EOL | sudo tee docker-compose.yml > /dev/null
version: '3.8'
    
services:  
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped 
    networks:
      - web
    ports:
      - 80:80
      - 443:443
    volumes:
      - /etc/localtime:/etc/localtime
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /docker/traefik/traefik.toml:/traefik.toml
      - /docker/traefik/traefik_dynamic.toml:/traefik_dynamic.toml
      - /docker/traefik/acme.json:/acme.json
    logging:
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "traefik", "healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 3

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /docker/portainer/data:/data
    ports:
      - 8000:8000
      - 9000:9000
      - 9443:9443
    networks:
      - web
    labels:
      - "traefik.enable=true"
    # Roteador e Serviço para a interface principal do Portainer (porta 9000)
      - "traefik.http.routers.portainer.rule=Host(\`$portainer_domain\`) || Host(\`www.$portainer_domain\`)"
      - "traefik.http.routers.portainer.tls=true"
      - "traefik.http.routers.portainer.tls.certresolver=lets-encrypt"
      - "traefik.http.services.portainer-main.loadbalancer.server.port=9000" # Define um serviço Traefik chamado 'portainer-main'
      - "traefik.http.routers.portainer.service=portainer-main" # O roteador 'portainer' usa o serviço 'portainer-main'
      - "traefik.http.routers.portainer.middlewares=redirect-www-to-main@file" # Adicionado o middleware para redirecionamento
    # Roteador e Serviço para o endpoint Edge do Portainer (porta 8000)
      - "traefik.http.routers.edge.rule=Host(\`$edge_domain\`) || Host(\`www.$edge_domain\`)"
      - "traefik.http.routers.edge.entrypoints=websecure"
      - "traefik.http.services.portainer-edge.loadbalancer.server.port=8000" # Define um serviço Traefik chamado 'portainer-edge'
      - "traefik.http.routers.edge.service=portainer-edge" 
      - "traefik.http.routers.edge.tls.certresolver=lets-encrypt"
      - "traefik.http.routers.edge.middlewares=redirect-www-to-main@file" # Adicionado o middleware para redirecionamento
      - "traefik.docker.network=web"
    logging:
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9000/api/status || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  web:
    external: true
EOL
    echo -e "${GREEN}✅ docker-compose.yml criado com sucesso.${NC}"

 ################################
 ##### CRIANDO TRAEFIK.TOML #####
 ################################

# Entra no diretório /docker para criar os arquivos
    cd /docker/traefik || { echo -e "${RED}❌ Não foi possível mudar para o diretório /docker/traefik.${NC}"; exit 1; } 
    
   echo -e "${YELLOW}📝 Criando traefik.toml...${NC}"
    cat <<EOL | sudo tee traefik.toml > /dev/null
[entryPoints]
  [entryPoints.web]
    address = ":80"
    
    [entryPoints.web.http]
      [entryPoints.web.http.redirections]
        [entryPoints.web.http.redirections.entryPoint]
          to = "websecure"
          scheme = "https"
          permanent = true

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
  keyType = "EC256"
  [certificatesResolvers.lets-encrypt.acme.tlsChallenge]

[providers.docker]
  watch = true
  network = "web"
  exposedByDefault = false
  endpoint = "unix:///var/run/docker.sock"

[providers.file]
  filename = "traefik_dynamic.toml"
  watch = true
EOL
    echo -e "${GREEN}✅ traefik.toml criado com sucesso.${NC}"
    
########################################
##### CRIANDO TRAEFIK_DYNAMIC.TOML #####
########################################

   echo -e "${YELLOW}📝 Criando traefik_dynamic.toml...${NC}"
    cat <<EOL | sudo tee traefik_dynamic.toml > /dev/null
[http.middlewares.simpleAuth.basicAuth]
  users = [
    "$encrypted_password"
  ]

# Use with traefik.http.routers.myRouter.middlewares: "redirect-www-to-main@file"
[http.middlewares]
  [http.middlewares.redirect-www-to-main.redirectregex]
      permanent = true
      regex = "^https?://www\\\\.(.+)"
      replacement = "https://\${1}"

# NOVO: Definição do middleware de segurança de cabeçalhos HTTP
[http.middlewares.securityHeaders.headers]
  browserXssFilter = true
  contentTypeNosniff = true
  frameDeny = true
  sslRedirect = true
  referrerPolicy = "strict-origin-when-cross-origin"
  contentSecurityPolicy = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
  # HSTS (Strict-Transport-Security) - Descomente se tiver certeza! Força o navegador a usar HTTPS para seu domínio por um período. Cuidado ao habilitar: se o HTTPS quebrar, seus usuários não conseguirão acessar por um tempo.
  # strictTransportSecurity = true
  forceSTSHeader = true
  stsPreload = true # Opcional: Para incluir seu domínio na lista de pré-carregamento HSTS dos navegadores. Use com extrema cautela.
  stsSeconds = 31536000 # 1 ano
  stsIncludeSubdomains = true  

[http.middlewares.rateLimitMiddleware.rateLimit]
  burst = 100
  average = 50

[http.routers.api]
  rule = "Host(\`$traefik_domain\`) || Host(\`www.$traefik_domain\`)"
  entrypoints = ["websecure"]
  middlewares = ["simpleAuth", "securityHeaders", "rateLimitMiddleware", "redirect-www-to-main@file"]
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
      (sudo touch acme.json && sudo chmod 600 acme.json) > /dev/null 2>&1 & spinner $! 
    fi
    
    echo -e "${GREEN}✅ Permissões para acme.json configuradas.${NC}"

    ###############################
    ##### INICIANDO CONTAINER #####
    ###############################
    
    # Entra no diretório /docker para criar os arquivos

    cd || { echo -e "${RED}❌ Não foi possível mudar para o diretório /docker.${NC}"; exit 1; }

    if ! sudo docker network ls | grep -q "web"; then
    echo -e "${YELLOW}🌐 Criando rede Docker 'web'...${NC}"
    (sudo docker network create web) > /dev/null 2>&1 & spinner $!
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erro ao criar a rede Docker 'web'.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Rede Docker 'web' criada com sucesso.${NC}"
    else
    echo -e "${GREEN}✅ Rede Docker 'web' já existe.${NC}"
    fi
    
    cd /docker || { echo -e "${RED}❌ Não foi possível mudar para o diretório /docker.${NC}"; exit 1; }
    
    echo -e "${YELLOW}🚀 Iniciando containers Docker...${NC}"    
    
    (sudo docker compose up -d) > /dev/null 2>&1 & spinner $!    
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erro ao iniciar os containers Docker. Verifique a saída de 'sudo docker compose up'.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Containers iniciados com sucesso.${NC}"
    sleep 3
    
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
    echo -e "${BLUE}➡️ Criado por Wallison Santos${NC}"
else
    echo -e "${RED}❌ Instalação cancelada. Por favor, inicie novamente se desejar prosseguir.${NC}"
    exit 0
fi
