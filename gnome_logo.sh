#!/bin/bash
# Criar o perfil do GDM se não existir
mkdir -p /etc/dconf/profile
cat <<EOF > /etc/dconf/profile/gdm
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
EOF

# Criar o diretório para overrides do GDM
mkdir -p /etc/dconf/db/gdm.d

# Arquivo para remover o logo (pode chamar como quiser, ex: 00-remove-logo)
cat <<EOF > /etc/dconf/db/gdm.d/00-remove-logo
[org/gnome/login-screen]
logo=''
EOF

# Atualizar o banco de dados dconf
dconf update
