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
        echo -e "${YELLOW}htpasswd não encontrado. Instalando apache2-utils...${NC}"
        
        echo -e "${GREEN}✅ apache2-utils instalado com sucesso!${NC}"
    else
        echo -e "${GREEN}✅ apache2-utils já está instalado.${NC}"
    fi
    return 0
}

# Função para mostrar spinner de carregamento
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

# Função para verificar requisitos do sistema
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

# Função para verificar se o Docker já está instalado
check_docker_installed() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker já está instalado.${NC}"
        return 0
    else
        echo -e "${YELLOW}🐳 Docker não encontrado. Será instalado.${NC}"
        return 1
    fi
}

# Logo animado
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

# Função para mostrar um banner colorido
function show_banner() {
    echo -e "${GREEN}██████████████████████████████████████████████████████████████████████████████"
    echo -e "██                                                                          ██"
    echo -e "██                ${YELLOW}Preencha as informações solicitadas abaixo${GREEN}                ██"
    echo -e "██                                                                          ██"
    echo -e "██████████████████████████████████████████████████████████████████████████████${NC}"
}

# Função para mostrar uma mensagem de etapa com barra de progresso
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

# Função para validar e-mail
validate_email() {
    local email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    if [[ $1 =~ $email_regex ]]; then
        return 0 # Válido
    else
        return 1 # Inválido
    fi
}

# Função para validar domínio (formato específico: pelo menos 3 partes)
validate_domain() {    
    local domain_regex="^[a-zA-Z0-9]{2,}(\.[a-zA-Z0-9]{2,})(\.[a-zA-Z]{2,})$"
    if [[ "$1" =~ $domain_regex ]]; then
        return 0 # Válido
    else
        return 1 # Inválido
    fi
}

# Função para validar usuário
validate_user() {    
    local domain_regex="^[a-zA-Z0-9]{4,}$"
    if [[ "$1" =~ $domain_regex ]]; then
        return 0 # Válido
    else
        return 1 # Inválido
    fi
}

# Função para validar complexidade da senha
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

# Mostrar banner inicial
clear
show_animated_logo
show_banner
echo ""

# Solicitar informações do usuário com validação
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
    if validate_user "$traefik_domain"; then
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
        # Gerar hash da senha para maior segurança no docker-compose.yml
        #TRAEFIK_PASSWORD_HASH=$("$traefik_user" "$traefik_senha")
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

# Verificação de dados
clear
echo -e "${BLUE}📋 Resumo das Informações${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "📧 Seu E-mail: ${YELLOW}$email${NC}"
echo -e "🌐 Dominio do Traefik: ${YELLOW}$traefik_domain${NC}"
echo -e "🔑 Senha do Traefik: ${YELLOW}********${NC}" # Apenas para visualização
echo -e "🌐 Dominio do Portainer: ${YELLOW}$portainer_domain${NC}"
echo -e "🌐 Dominio do Edge: ${YELLOW}$edge_domain${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

read -p "As informações estão certas? (y/n): " confirma1
if [ "$confirma1" == "y" ]; then
    clear

    # Verificar requisitos do sistema (SIMULADO)
    check_system_requirements || { echo -e "${RED}❌ Instalação cancelada devido a requisitos do sistema não atendidos.${NC}"; exit 1; }

    echo -e "${BLUE}🚀 Iniciando instalação (SIMULADA)...${NC}"
    
    ### INSTALANDO DEPENDENCIAS

    check_apache2_utils || { echo -e "${RED}❌ Não foi possível instalar o apache2-utils. Saindo.${NC}"; exit 1; }
   
    echo -e "${YELLOW}📦 Atualizando sistema e instalando dependências (SIMULADO)...${NC}"
    # Nenhuma execução real aqui, apenas simulação de tempo
    sleep 1 && spinner $$ # Simulando um PID
    echo -e "${GREEN}✅ Sistema atualizado e dependências básicas instaladas (SIMULADO).${NC}"

    # Verificar se o Docker já está instalado, senão instalar (SIMULADO)
    if ! check_docker_installed; then
        echo -e "${YELLOW}🐳 Instalando Docker (SIMULADO)...${NC}"
        # Nenhuma execução real aqui, apenas simulação de tempo
        sleep 1 && spinner $$
        echo -e "${GREEN}✅ Docker instalado com sucesso (SIMULADO).${NC}"
    fi

    # Adicionar o usuário atual ao grupo docker para não precisar de sudo (SIMULADO)
    echo -e "${YELLOW}Adicionando ${USER} ao grupo 'docker' para gerenciar Docker sem 'sudo' (SIMULADO)...${NC}"
    # Nenhuma execução real aqui
    echo -e "${YELLOW}Por favor, faça logout e login novamente para que as alterações no grupo entrem em vigor (SIMULADO).${NC}"
    echo -e "${BLUE}Pressione qualquer tecla para continuar (o script pode precisar ser reexecutado após o login) (SIMULADO).${NC}"
    read -n 1 -s
    clear

    # Simular criação/verificação de diretório
    echo -e "${YELLOW}Simulando criação do diretório '$HOME/Portainer' e navegação...${NC}"
    # Não cria o diretório de verdade, apenas simula a lógica
    if [ ! -d "$HOME/Portainer_TEST" ]; then # Usando _TEST para não conflitar com o real
        echo -e "${GREEN}✅ Diretório '$HOME/Portainer_TEST' seria criado.${NC}"
    else
        echo -e "${YELLOW}Diretório '$HOME/Portainer_TEST' já existiria. Usando o existente.${NC}"
    fi
    # Não faz 'cd' real, apenas simula o sucesso
    echo -e "${GREEN}✅ Simulação de navegação para '$HOME/Portainer_TEST' bem-sucedida.${NC}"

    sleep 0.5
    clear

    #########################################################
    # CRIANDO DOCKER-COMPOSE.YML (SIMULADO)
    #########################################################
    echo -e "${YELLOW}📝 Conteúdo do docker-compose.yml seria gerado com suas informações:${NC}"
    echo -e "${BLUE}--- INÍCIO DO CONTEÚDO SIMULADO ---${NC}"
    cat <<EOL
services:
  traefik:
    container_name: traefik
    image: "traefik:latest"
    restart: always
    command:
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --api.dashboard=true
      - --providers.docker
      - --log.level=ERROR
      - --certificatesresolvers.leresolver.acme.httpchallenge=true
      - --certificatesresolvers.leresolver.acme.email=$email
      - --certificatesresolvers.leresolver.acme.storage=/etc/traefik/acme.json
      - --certificatesresolvers.leresolver.acme.httpchallenge.entrypoint=web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./acme.json:/etc/traefik/acme.json" # Montado no container
    labels:
      - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
      - "traefik.http.routers.http-catchall.entrypoints=web"
      - "traefik.http.routers.http-catchall.middlewares=redirect-to-https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
      - "traefik.http.routers.traefik-dashboard.rule=Host(\`$traefik_domain\`)"
      - "traefik.http.routers.traefik-dashboard.entrypoints=websecure"
      - "traefik.http.routers.traefik-dashboard.service=api@internal"
      - "traefik.http.routers.traefik-dashboard.tls.certresolver=leresolver"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=$TRAEFIK_PASSWORD_HASH"
      - "traefik.http.routers.traefik-dashboard.middlewares=traefik-auth"
  portainer:
    image: portainer/portainer-ce:latest
    command: -H unix:///var/run/docker.sock
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer-frontend.rule=Host(\`$portainer_domain\`)"
      - "traefik.http.routers.portainer-frontend.entrypoints=websecure"
      - "traefik.http.services.portainer-frontend.loadbalancer.server.port=9000"
      - "traefik.http.routers.portainer-frontend.tls.certresolver=leresolver"
      - "traefik.http.routers.portainer-edge.rule=Host(\`$edge_domain\`)"
      - "traefik.http.routers.portainer-edge.entrypoints=websecure"
      - "traefik.http.services.portainer-edge.loadbalancer.server.port=8000"
      - "traefik.http.routers.portainer-edge.tls.certresolver=leresolver"
volumes:
  portainer_data:
EOL
    echo -e "${BLUE}--- FIM DO CONTEÚDO SIMULADO ---${NC}"
    echo -e "${GREEN}✅ docker-compose.yml seria criado com sucesso.${NC}"

    #########################################################
    # CERTIFICADOS LETSENCRYPT (SIMULADO)
    #########################################################
    echo -e "${YELLOW}📝 Configurando permissões para acme.json (SIMULADO)...${NC}"
    echo -e "${GREEN}✅ Permissões para acme.json seriam configuradas.${NC}"

    #########################################################
    # INICIANDO CONTAINER (SIMULADO)
    #########################################################
    echo -e "${YELLOW}🚀 Iniciando containers Docker (SIMULADO)...${NC}"
    sleep 1 && spinner $$
    echo -e "${GREEN}✅ Containers seriam iniciados com sucesso.${NC}"

    clear
    show_animated_logo

    echo -e "${GREEN}🎉 Simulação de instalação concluída com sucesso!${NC}"
    echo -e "${BLUE}📝 Informações de Acesso (SIMULADAS):${NC}"
    echo -e "${GREEN}================================${NC}"
    echo -e "🔗 Portainer: ${YELLOW}https://$portainer_domain${NC}"
    echo -e "🔗 Traefik: ${YELLOW}https://$traefik_domain${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${BLUE}💡 Dica: Aguarde alguns minutos para que os certificados SSL sejam gerados pelo Let's Encrypt (SIMULADO).${NC}"
    echo -e "${BLUE}➡️ Lembre-se de configurar os registros DNS (A/AAAA) para os domínios acima apontarem para este servidor!${NC}"
    echo -e "${GREEN}🌟 Visite: https://packtypebot.com.br${NC}"
else
    echo -e "${RED}❌ Simulação de instalação cancelada. Por favor, inicie novamente se desejar prosseguir.${NC}"
    exit 0
fi
