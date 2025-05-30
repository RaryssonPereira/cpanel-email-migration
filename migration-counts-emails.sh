#!/bin/bash

# === SCRIPT: migration-emails.sh ===
# Processo guiado, seguro e documentado, garantindo flexibilidade e controle sobre a migração.

# (Opcional) Ative log se quiser rastrear tudo:
LOGFILE="migration.log"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOGFILE"; }
# Para desativar o log, basta trocar 'log' por 'echo' nas mensagens abaixo.

echo -e "\n🔍 Verificando se o script está sendo executado dentro do Byobu..."

if [ -n "$BYOBU_BACKEND" ]; then
  log "✅ O script está sendo executado dentro de uma sessão do Byobu. Continuando normalmente..."
else
  log "⚠️  O script **não está sendo executado dentro do Byobu**."
  echo -e "ℹ️  Recomendamos fortemente o uso do Byobu para evitar a perda de conexão durante a migração de e-mails."

  # Dica para instalação manual (caso o usuário prefira)
  echo -e "\nVocê também pode instalar manualmente:"
  echo "  # Para Ubuntu/Debian: sudo apt install byobu"
  echo "  # Para CentOS/RHEL/AlmaLinux: sudo yum install epel-release byobu"

  read -rp $'\n❓ Deseja entrar no Byobu antes de continuar? (s/n): ' RESPOSTA

  if [[ "$RESPOSTA" =~ ^[sS]$ ]]; then
    log "📦 Verificando se o Byobu está instalado..."

    source /etc/os-release

    if ! command -v byobu &>/dev/null; then
      log "🔧 Instalando o Byobu..."

      if [[ "$ID" =~ ^(centos|rhel|almalinux)$ ]]; then
        yum install -y epel-release byobu
      elif [[ "$ID" =~ ^(ubuntu|debian)$ ]]; then
        apt update && apt install -y byobu
      else
        log "❌ Distribuição '$ID' não reconhecida para instalação automática do Byobu."
        read -rp $'\n❓ Deseja continuar mesmo assim, assumindo o risco? (s/n): ' CONTINUA
        if [[ ! "$CONTINUA" =~ ^[sS]$ ]]; then
          log "Encerrando script conforme escolha do usuário."
          sleep 1
          exit 1
        fi
      fi

      log "✅ Byobu instalado com sucesso."
    else
      log "✅ Byobu já está instalado."
    fi

    SCRIPT_NAME=$(basename "$0")

    echo -e "\n🚪 Agora você pode entrar no Byobu com o comando:\n"
    echo -e "   👉  byobu\n"
    echo -e "🔁 Depois disso, execute novamente este script com:\n"
    echo -e "   👉  ./$SCRIPT_NAME   ou   bash $SCRIPT_NAME\n"
    echo -e "💡 Isso garante que, mesmo em caso de desconexão, a migração continue normalmente."

    sleep 1
    exit 0
  else
    log "⚠️  Continuando a execução fora do Byobu conforme sua escolha."
    echo -e "\n⚠️  ATENÇÃO: Se a conexão SSH for perdida, a migração pode ser interrompida e gerar inconsistências.\n"
    sleep 1
  fi
fi

# A partir daqui, começa o restante do seu script de migração.
