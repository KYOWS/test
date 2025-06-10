#!/bin/bash

    traefik_domain='TESTE.vom.com'
    
    sudo mkdir -p /dockerr
    
    # Entra no diretório /docker para criar os arquivos
    cd /dockerr || { echo -e "${RED}❌ Não foi possível mudar para o diretório /docker.${NC}"; exit 1; }

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
      regex = "^https?://www\\.(.+)"
      replacement = "https://$${1}"

# NOVO: Definição do middleware de segurança de cabeçalhos HTTP
[http.middlewares.securityHeaders.headers]
  browserXssFilter = true
  contentTypeNosniff = true
  frameDeny = true
  sslRedirect = true
  # HSTS (Strict-Transport-Security) - Descomente se tiver certeza! Força o navegador a usar HTTPS para seu domínio por um período. Cuidado ao habilitar: se o HTTPS quebrar, seus usuários não conseguirão acessar por um tempo.
  # strictTransportSecurity = true
  # stsSeconds = 31536000 # 1 ano
  # stsIncludeSubdomains = true  

[http.routers.api]
  rule = "Host(\`$traefik_domain\`)"
  entrypoints = ["websecure"]
  middlewares = ["simpleAuth", "securityHeaders"]
  service = "api@internal"
  [http.routers.api.tls]
    certResolver = "lets-encrypt"
EOL
    echo -e "${GREEN}✅ traefik_dynamic.toml criado com sucesso.${NC}"
