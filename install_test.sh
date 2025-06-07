#!/bin/bash

# Cores
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
NC='\e[0m' # No Color

# Definindo um HTPASSWD_CMD simulado para teste
# Ele apenas retorna um valor fixo, não gera um hash real
HTPASSWD_CMD_TEST() {
    echo "traefik:\$apr1\$abc.123\$xyz.456" # Hash simulado
}
HTPASSWD_CMD="HTPASSWD_CMD_TEST" # Aponta para a função simulada

# Função para mostrar spinner de carregamento (mantida para simulação visual)
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    # Em um script de teste, você pode querer um spinner mais curto ou desativá-lo
    # Para demonstração, vamos simular uma execução rápida.
    for i in {1..5}; do # Simula 5 iterações rápidas
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Função para verificar requisitos do sistema (SIMULADA)
check_system_requirements() {
    echo -e "${BLUE}Verificando requisitos do sistema (SIMULADO)...${NC}"
    # Valores simulados para sucesso
    local free_space=15 # Simula 15GB livres
    local total_mem=4   # Simula 4GB de RAM

    if [ "$free_space" -lt 10 ]; then
        echo -e "${RED}❌ Erro SIMULADO: Espaço em disco insuficiente.${NC}"
        return 1
    fi

    if [ "$total_mem" -lt 2 ]; then
        echo -e "${RED}❌ Erro SIMULADO: Memória RAM insuficiente.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Requisitos do sistema atendidos (SIMULADO)${NC}"
    return 0
}

# Função para verificar se o Docker já está instalado (SIMULADA)
check_docker_installed() {
    echo -e "${BLUE}Verificando Docker (SIMULADO)...${NC}"
    # Para o teste, vamos simular que o Docker não está instalado para testar o fluxo de instalação
    # Mude '1' para '0' para simular que já está instalado.
    return 1 # Simula que o Docker NÃO está instalado
}

# Logo animado
show_animated_logo() {
    clear
    echo -e "${GREEN}"
    echo -e "  _____       _____ _  __  _________       _______  ______ ____    ____ _______ "
    echo -e " |  __ \ /\   / ____| |/ / |__   __\ \    / /  __ \|  ____|  _ \ / __ \__   __|"
    echo -e " | |__) /  \ | |    | ' /    | |   \ \  / /| |__) | |__  | |_) | |  | | | |   "
    echo -e " |  ___/ /\ \| |    |  <     | |    \  / / |  ___/|  __| |  _ <| |  | | | |   "
    echo -e " | |  / ____ \ |____| . \    | |     | |  | |    | |____| |_) | |__| | | |   "
    echo -e " |_| /_/    \_\_____|_|\_\   |_|     |_|  |_|    |______|____/ \____/  |_|   "
    echo -e "${NC}"
    sleep 0.5 # Tempo menor para teste
}

# Função para mostrar um banner colorido
function show_banner() {
    echo -e "${GREEN}=============================================================================="
    echo -e "=                                                                            ="
    echo -e "=              ${YELLOW}Preencha as informações solicitadas abaixo${GREEN}              ="
    echo -e "=                 (Este é um script de TESTE - NADA será instalado)        ="
    echo -e "=                                                                            ="
    echo -e "==============================================================================${NC}"
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
            echo -ne "="
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

# Função para validar domínio (formato básico)
validate_domain() {
    local domain_regex="^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
    if [[ $1 =~ $domain_regex ]]; then
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

# --- PARA TESTE RÁPIDO E AUTOMATIZADO, DESCOMENTE AS LINHAS ABAIXO E COMENTE AS "read -p" ---
#email="teste@exemplo.com"
#traefik_domain="traefik.teste.com"
#traefik_senha="SenhaSegura123!"
#portainer_domain="portainer.teste.com"
#edge_domain="edge.teste.com"
#TRAEFIK_PASSWORD_HASH=$($HTPASSWD_CMD -nb traefik "$traefik_senha")
# --- FIM DAS ENTRADAS PRÉ-DEFINIDAS ---

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
    read -s -p "🔑 Senha do Traefik (mínimo 8 caracteres, com maiúscula, minúscula, número e especial): " traefik_senha
    echo "" # Quebra de linha após a entrada da senha oculta
    if validate_password_complexity "$traefik_senha"; then
        # Gerar hash da senha para maior segurança no docker-compose.yml (simulado)
        TRAEFIK_PASSWORD_HASH=$($HTPASSWD_CMD traefik "$traefik_senha") # Chama a função simulada
        echo -e "${GREEN}✅ Senha aceita.${NC}"
        break
    fi
done
echo ""

show_step 4
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

show_step 5
while true; do
    read -p "🌐 Dominio do Edge (ex: edge.seudominio.com): " edge_domain
    if validate_domain "<span class="math-inline">edge\_domain"; then
echo \-e "</span>{GREEN}✅ Domínio válido.<span class="math-inline">\{NC\}"
break
else
echo \-e "</span>{RED}❌ Domínio inválido. Por favor, insira um domínio válido.${NC}"
    fi # <--- Esta linha estava faltando ou incorreta
done
echo ""

# Verificação de dados
clear
echo -e "${BLUE}📋 Resumo das Informações${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "📧 Seu E-mail: ${YELLOW}$email${NC}"
echo -e "🌐 Dominio do Traefik: ${YELLOW}$traefik_domain${NC}"
echo -e "🔑 Senha do Traefik: ${YELLOW}******** (hash gerado simulado)${NC}" # Apenas para visualização
echo -e "🌐 Dominio do Portainer: ${YELLOW}$portainer_domain${NC}"
echo -e "🌐 Dominio do Edge: ${YELLOW}$edge_domain${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

read -p "As informações estão certas? (y/n): " confirma1
if [ "$confirma1" == "y" ]; then
    clear

    # Verificar requisitos do sistema (SIMULADO)
    check_system_requirements || { echo -e "${RED}❌ Instalação cancelada devido a requisitos do sistema não atendidos (SIMULADO).${NC}"; exit 1; }

    echo -e "${BLUE}🚀 Iniciando instalação (SIMULADA)...${NC}"

    #########################################################
    # INSTALANDO DEPENDENCIAS (SIMULADO)
    #########################################################
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
