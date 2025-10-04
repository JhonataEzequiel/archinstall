#!/usr/bin/env bash

# Diretório dos wallpapers
WALLPAPER_DIR="/mnt/Arquivos/Imagens/Wallpapers"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Verifica se o diretório existe
if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "Erro: Diretório $WALLPAPER_DIR não encontrado."
  exit 1
fi

# Seleciona um wallpaper aleatório usando find e shuf
NEW_WP=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

# Verifica se um wallpaper foi selecionado
if [[ -z "$NEW_WP" ]]; then
  echo "Erro: Nenhum arquivo encontrado em $WALLPAPER_DIR."
  exit 1
fi

# Verifica se o arquivo é válido
if [[ ! -f "$NEW_WP" ]]; then
  echo "Erro: O arquivo $NEW_WP não é válido."
  exit 1
fi

# Cria ou limpa o arquivo de configuração
: > "$HYPRPAPER_CONF"

# Escreve as configurações no hyprpaper.conf
{
  echo "preload = $NEW_WP"
  echo "wallpaper = ,$NEW_WP" # Usa ',' para aplicar a todos os monitores
  echo "splash = false"
} >> "$HYPRPAPER_CONF"

# Mata o processo hyprpaper, se estiver rodando
pkill hyprpaper 2>/dev/null

# Inicia o hyprpaper em background
hyprpaper &

# Verifica se o hyprpaper foi iniciado com sucesso
if [[ $? -eq 0 ]]; then
  echo "Papel de parede aplicado com sucesso: $NEW_WP"
else
  echo "Erro ao iniciar hyprpaper."
  exit 1
fi
