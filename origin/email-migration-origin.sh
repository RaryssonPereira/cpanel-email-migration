#!/bin/bash

# === SCRIPT: migration-emails.sh ===
# Processo guiado, seguro e documentado, garantindo flexibilidade e controle sobre a migração.

# (Opcional) Ative log se quiser rastrear tudo:
LOGFILE="migration.log"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOGFILE"; }
# Para desativar o log, basta trocar 'log' por 'echo' nas mensagens abaixo.

# === PARTE 1: Verificação do Byobu ===
# Esta parte garante que o script está sendo executado dentro de uma sessão Byobu (ou tmux/screen), protegendo a migração
# contra quedas de conexão SSH. Também orienta e auxilia o usuário na instalação e uso do Byobu.

echo -e "\n🔍 Verificando se o script está sendo executado dentro do Byobu..."

# Checa se a variável de ambiente do Byobu está setada (indica que a sessão está ativa)
if [ -n "$BYOBU_BACKEND" ]; then
  log "✅ O script está sendo executado dentro de uma sessão do Byobu. Continuando normalmente..."
else
  # Caso não esteja em uma sessão Byobu:
  log "⚠️  O script **não está sendo executado dentro do Byobu**."
  echo -e "ℹ️  Recomendamos fortemente o uso do Byobu para evitar a perda de conexão durante a migração de e-mails."

  # Informa comandos para instalação manual caso o usuário prefira
  echo -e "\nVocê também pode instalar manualmente:"
  echo "  # Para Ubuntu/Debian: sudo apt install byobu"
  echo "  # Para CentOS/RHEL/AlmaLinux: sudo yum install epel-release byobu"

  # Pergunta ao usuário se deseja iniciar uma sessão Byobu antes de continuar
  read -rp $'\n❓ Deseja entrar no Byobu antes de continuar? (s/n): ' RESPOSTA

  if [[ "$RESPOSTA" =~ ^[sS]$ ]]; then
    log "📦 Verificando se o Byobu está instalado..."

    source /etc/os-release # Identifica a distribuição Linux em uso

    # Checa se o Byobu está instalado
    if ! command -v byobu &>/dev/null; then
      log "🔧 Instalando o Byobu..."

      # Instala Byobu conforme o tipo de distribuição detectada
      if [[ "$ID" =~ ^(centos|rhel|almalinux)$ ]]; then
        yum install -y epel-release byobu
      elif [[ "$ID" =~ ^(ubuntu|debian)$ ]]; then
        apt update && apt install -y byobu
      else
        # Caso a distribuição não seja reconhecida, orienta e pede confirmação extra
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

    # Orienta o usuário a iniciar uma sessão Byobu e rodar o script novamente
    SCRIPT_NAME=$(basename "$0")

    echo -e "\n🚪 Agora você pode entrar no Byobu com o comando:\n"
    echo -e "   👉  byobu\n"
    echo -e "🔁 Depois disso, execute novamente este script com:\n"
    echo -e "   👉  ./$SCRIPT_NAME   ou   bash $SCRIPT_NAME\n"
    echo -e "💡 Isso garante que, mesmo em caso de desconexão, a migração continue normalmente."

    sleep 1
    exit 0 # Sai para que o usuário entre no Byobu e execute novamente
  else
    # Caso o usuário opte por não usar Byobu, segue, mas alerta sobre o risco
    log "⚠️  Continuando a execução fora do Byobu conforme sua escolha."
    echo -e "\n⚠️  ATENÇÃO: Se a conexão SSH for perdida, a migração pode ser interrompida e gerar inconsistências.\n"
    sleep 1
  fi
fi

# === PARTE 2: Verificação e decisão sobre uso do sshpass ===
# Nesta etapa, o script pergunta se o usuário quer usar o sshpass para automatizar a digitação da senha SSH.
# O sshpass permite executar comandos como rsync e scp sem precisar digitar a senha manualmente a cada operação.

echo -e "\n🔐 O utilitário sshpass pode ser usado para automatizar o envio da senha no rsync/scp."
echo "Isso evita que você precise digitar a senha manualmente toda vez que uma conta for migrada."

# Pergunta ao usuário se deseja usar o sshpass (responde 's' para sim)
read -rp $'\n❓ Deseja usar sshpass para automatizar a digitação da senha SSH? (s/n): ' USAR_SSHPASS

if [[ "$USAR_SSHPASS" =~ ^[sS]$ ]]; then
  log "🔍 Verificando se sshpass está instalado..."

  # Verifica se o sshpass já está instalado
  if command -v sshpass &>/dev/null; then
    log "✅ sshpass está instalado. Continuando com suporte a senha automática via rsync/scp..."
    USAR_SSHPASS=true
  else
    log "⚠️  sshpass não está instalado. Tentando instalar automaticamente..."

    source /etc/os-release # Carrega informações da distribuição Linux

    # Instala sshpass conforme a distribuição detectada
    if [[ "$ID" =~ ^(centos|rhel|almalinux)$ ]]; then
      yum install -y epel-release sshpass
    elif [[ "$ID" =~ ^(ubuntu|debian)$ ]]; then
      apt update && apt install -y sshpass
    else
      log "❌ Distribuição '$ID' não reconhecida. Instale sshpass manualmente e reexecute o script."
      exit 1
    fi

    # Confirma se a instalação foi bem-sucedida
    if command -v sshpass &>/dev/null; then
      log "✅ sshpass instalado com sucesso. Continuando com suporte a senha automática via rsync/scp..."
      log "ℹ️ Caso encontre qualquer erro mais adiante, recomendamos relançar o script manualmente."
      USAR_SSHPASS=true
    else
      log "❌ A instalação do sshpass falhou. Por favor, instale manualmente e reexecute o script."
      exit 1
    fi
  fi
else
  # Se o usuário optar por não usar sshpass, segue em modo manual (senha digitada a cada conexão)
  log "⚠️  O script continuará **sem** usar sshpass."
  echo "📌 Você precisará digitar a senha toda vez que o rsync ou scp solicitar conexão com o servidor remoto."
  USAR_SSHPASS=false
fi

# === PARTE 3: Verificação do caminho ===
# Esta parte pede o usuário do cPanel e o domínio e monta o caminho necessário para localizar as caixas de e-mail que serão migradas.
# valida se o diretório existe e lista as contas encontradas para confirmação antes de seguir.

echo -e "\nInforme o seu usuário do cPanel (/home/USUARIO):"
read -rp "Usuário: " USUARIO_EMAIL # Pede o nome do usuário do cPanel

echo -e "\nInforme o domínio do e-mail (/home/$USUARIO_EMAIL/mail/DOMINIO):"
read -rp "Domínio: " DOMINIO_EMAIL # Pede o domínio do e-mail

# Monta o caminho completo para as caixas de e-mail do domínio informado
CAMINHO_FINAL="/home/$USUARIO_EMAIL/mail/$DOMINIO_EMAIL"

# Verifica se o diretório existe, aborta se não existir (evita falhas futuras)
if [ ! -d "$CAMINHO_FINAL" ]; then
  echo "Diretório '$CAMINHO_FINAL' não encontrado. Verifique usuário ou domínio."
  exit 1
fi

# Lista as contas de e-mail (subdiretórios) encontradas, permitindo conferência visual
echo -e "\nContas de e-mail encontradas em $CAMINHO_FINAL:"
ls "$CAMINHO_FINAL"

# Pausa para confirmação: ENTER para seguir, CTRL+C para cancelar
read -rp $'\nPressione [Enter] para continuar ou CTRL+C para cancelar...'

# === PARTE 4: Seleção de contas de e-mail a migrar ===
# Esta parte permite escolher quais contas de e-mail do domínio informado serão migradas.
# O script lista todas as contas encontradas e permite ignorar as indesejadas.

echo -e "\n📥 Listando todas as contas de e-mail encontradas no domínio '$DOMINIO_EMAIL'..."

# Lista todos os diretórios dentro do domínio, cada um é uma conta de e-mail
if ! CONTAS_TODAS=($(ls -1 "$CAMINHO_FINAL")); then
  echo "❌ Erro ao listar contas dentro de '$CAMINHO_FINAL'. Verifique permissões ou existência do diretório."
  exit 1
fi

# Exibe as contas de e-mail disponíveis
echo -e "\n📧 Contas encontradas:"
for conta in "${CONTAS_TODAS[@]}"; do
  echo "   - $conta"
done

# Pergunta ao operador se deseja ignorar alguma conta da migração
read -rp $'\n🛑 Deseja ignorar alguma conta da migração? Digite os nomes separados por espaço (ou pressione Enter para migrar todas): ' IGNORADAS_INPUT

# Converte a lista digitada em array (se houver contas para ignorar)
IFS=' ' read -r -a CONTAS_IGNORADAS <<<"$IGNORADAS_INPUT"

# Filtra as contas para migrar (remove as que estão na lista de ignoradas)
CONTAS_MIGRAR=()
for conta in "${CONTAS_TODAS[@]}"; do
  IGNORAR=false
  for ignorada in "${CONTAS_IGNORADAS[@]}"; do
    if [[ "$conta" == "$ignorada" ]]; then
      IGNORAR=true
      break
    fi
  done
  if [ "$IGNORAR" = false ]; then
    CONTAS_MIGRAR+=("$conta")
  fi
done

# Exibe as contas finais que serão migradas
echo -e "\n✅ Contas que serão migradas:"
for conta in "${CONTAS_MIGRAR[@]}"; do
  echo "   📤 $conta"
done

# Confirmação final antes de iniciar a migração
read -rp $'\n🔁 Pressione [Enter] para iniciar a migração das contas acima ou CTRL+C para cancelar...'

# === PARTE 5: Coleta dos dados de acesso ao servidor de destino ===
# Esta parte coleta as informações necessárias para conectar ao servidor destino via SSH
# (host, usuário, porta e senha), e testa a conectividade para garantir que o rsync funcionará.

echo -e "\n🚀 Vamos configurar a conexão com o servidor de destino para iniciar a transferência."

# Solicita o hostname ou IP do servidor destino
read -rp $'\n🌐 Host ou IP do servidor de destino (ex: br69.exemplo): ' DEST_HOST

# Solicita o usuário SSH do destino (ex: root)
read -rp $'\n🔐 Usuário SSH do destino (ex: root): ' DEST_USER

# Solicita a porta SSH
read -rp $'\n📡 Porta SSH (ex: 22 ou 51439): ' DEST_PORT

# Solicita a senha do usuário SSH, entrada oculta
read -rsp $'\n🔑 Senha do usuário SSH: ' DEST_SENHA
echo "" # Quebra de linha após a senha

# Testa a conectividade SSH com os dados fornecidos
echo -e "\n🔎 Testando conectividade SSH com o servidor destino..."

ERRO_SSH=$(sshpass -p "$DEST_SENHA" ssh -p "$DEST_PORT" \
  -o StrictHostKeyChecking=no \
  -o ConnectTimeout=10 \
  "$DEST_USER@$DEST_HOST" \
  "echo '✅ Conexão estabelecida com sucesso.'" 2>&1)

# Verifica se a conexão foi bem-sucedida
if [ $? -ne 0 ]; then
  echo -e "❌ Não foi possível conectar-se ao servidor remoto com os dados fornecidos."
  echo -e "📄 Detalhes do erro SSH:\n"
  echo "$ERRO_SSH"
  echo -e "\n🔁 Verifique se o host, porta, usuário e senha estão corretos."
  exit 1
else
  echo -e "\n✅ Conexão SSH testada com sucesso. Pronto para iniciar a migração."
fi

# === PARTE 6: Execução da migração via rsync ===
# Esta etapa percorre as contas selecionadas e transfere toda a estrutura de pastas/arquivos de cada conta de e-mail
# do servidor de origem para o servidor de destino, utilizando rsync via SSH.

echo -e "\n🚚 Iniciando migração via rsync para cada conta selecionada..."

for conta in "${CONTAS_MIGRAR[@]}"; do
  echo -e "\n📤 Migrando conta: $conta@$DOMINIO_EMAIL"

  # Define o caminho local (origem) e remoto (destino) da conta
  ORIGEM="$CAMINHO_FINAL/$conta/"
  DESTINO="/home/$USUARIO_EMAIL/mail/$DOMINIO_EMAIL/$conta/"

  # Executa o rsync, copiando tudo da conta (todas as caixas e arquivos)
  sshpass -p "$DEST_SENHA" rsync -az --delete -e "ssh -p $DEST_PORT -o StrictHostKeyChecking=no" \
    "$ORIGEM" "$DEST_USER@$DEST_HOST:$DESTINO"

  if [ $? -eq 0 ]; then
    echo "✅ Conta $conta migrada com sucesso."
  else
    echo "❌ Falha ao migrar a conta $conta. Verifique a conexão e permissões."
  fi
done

echo -e "\n🏁 Migração concluída para todas as contas selecionadas."
