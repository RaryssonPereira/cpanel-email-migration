#!/bin/bash

# === SCRIPT: migration-emails.sh ===
# Este script migra todas as mensagens da Caixa de Entrada e Enviados das contas de e-mail de um cPanel para outro.
# Ele verifica se está rodando dentro de uma sessão segura com Byobu, coleta dados da conta de origem e prepara o caminho para migração.

# === PARTE 1: Verificação do Byobu ===
echo -e "\n🔍 Verificando se o script está sendo executado dentro do Byobu..."

# Verifica se a variável de ambiente $BYOBU_BACKEND está definida, indicando que estamos dentro do Byobu.
if [ -n "$BYOBU_BACKEND" ]; then
    echo "✅ O script está sendo executado dentro de uma sessão do Byobu. Continuando normalmente..."
else
    echo -e "⚠️  O script **não está sendo executado dentro do Byobu**."
    echo -e "ℹ️  Recomendamos fortemente o uso do Byobu para evitar a perda de conexão durante a migração de e-mails."

    # Pergunta se o usuário deseja entrar no Byobu.
    read -rp $'\n❓ Deseja entrar no Byobu antes de continuar? (s/n): ' RESPOSTA

    # Se o usuário responder "s" ou "S", inicia o processo de instalação ou orientação para uso do Byobu.
    if [[ "$RESPOSTA" =~ ^[sS]$ ]]; then
        echo -e "\n📦 Verificando se o Byobu está instalado..."

        # Carrega informações da distribuição do sistema operacional.
        source /etc/os-release

        # Verifica se o comando "byobu" existe.
        if ! command -v byobu &>/dev/null; then
            echo -e "🔧 Instalando o Byobu..."

            # Para distribuições baseadas em RHEL/CentOS/AlmaLinux.
            if [[ "$ID" =~ ^(centos|rhel|almalinux)$ ]]; then
                yum install -y epel-release byobu

            # Para distribuições baseadas em Debian/Ubuntu.
            elif [[ "$ID" =~ ^(ubuntu|debian)$ ]]; then
                apt update && apt install -y byobu

            # Se não for possível identificar a distribuição.
            else
                echo "❌ Distribuição '$ID' não reconhecida para instalação automática do Byobu."
                exit 1
            fi

            echo "✅ Byobu instalado com sucesso."
        else
            echo "✅ Byobu já está instalado."
        fi

        # Informa o usuário como entrar no Byobu e executar o script novamente.
        SCRIPT_NAME=$(basename "$0")
        echo -e "\n🚪 Agora você pode entrar no Byobu com o comando:\n"
        echo -e "   👉  byobu\n"
        echo -e "🔁 Depois disso, execute novamente este script com:\n"
        echo -e "   👉  ./$SCRIPT_NAME\n"
        echo -e "💡 Isso garante que, mesmo em caso de desconexão, a migração continue normalmente."
        exit 0
    else
        echo -e "\n⚠️  Continuando a execução fora do Byobu conforme sua escolha."
    fi
fi

# === PARTE 2: Coleta de informações ===
echo -e "\n🧾 Vamos coletar as informações da conta de e-mail que será migrada."

# Lista os diretórios em /home para sugerir usuários disponíveis.
echo -e "\n📁 Usuários disponíveis no diretório /home:"
if ls /home &>/dev/null; then
    ls /home
else
    echo "⚠️  Não foi possível listar os diretórios em /home (permissão negada ou diretório ausente)."
fi

# Solicita ao operador o nome do usuário do cPanel.
read -rp $'\n👤 Qual o USUÁRIO do cPanel (ex: aguardiacom)? ' USUARIO_EMAIL

# Verifica se o diretório do usuário existe, caso contrário interrompe.
if [ ! -d "/home/$USUARIO_EMAIL" ]; then
    echo -e "❌ O diretório /home/$USUARIO_EMAIL não existe. Verifique o nome e tente novamente."
    exit 1
fi

# Lista os domínios existentes no diretório de e-mail desse usuário.
echo -e "\n📬 Domínios encontrados em /home/$USUARIO_EMAIL/mail:"
if ls "/home/$USUARIO_EMAIL/mail" &>/dev/null; then
    ls "/home/$USUARIO_EMAIL/mail"
else
    echo "⚠️  Não foi possível listar os domínios (talvez o diretório não exista ou esteja vazio)."
fi

# Solicita ao operador o nome do domínio cujas contas serão migradas.
read -rp $'\n🌐 Qual o domínio que deseja migrar (ex: aguardidanoticia.com.br)? ' DOMINIO_EMAIL

# Define os caminhos possíveis para os arquivos de e-mail:
# - Se o script for rodado como root (WHM), usa o caminho completo.
# - Se for rodado dentro do terminal do cPanel do usuário, usa caminho relativo.
CAMINHO_WHM="/home/$USUARIO_EMAIL/mail/$DOMINIO_EMAIL"
CAMINHO_CPANEL="mail/$DOMINIO_EMAIL"

# Verifica se o script está sendo executado por root (EUID 0 = root).
if [ "$EUID" -eq 0 ]; then
    CAMINHO_FINAL="$CAMINHO_WHM"
else
    CAMINHO_FINAL="$CAMINHO_CPANEL"
fi

# Verifica se o diretório final com as contas de e-mail existe.
if [ ! -d "$CAMINHO_FINAL" ]; then
    echo -e "\n❌ O diretório de e-mails '$CAMINHO_FINAL' não foi encontrado."
    echo "🔎 Verifique se o usuário e o domínio estão corretos, ou se você está no ambiente certo (root ou cPanel)."
    exit 1
fi

# Mostra um resumo dos dados coletados antes de seguir.
echo -e "\n📂 Diretório de origem identificado:"
echo "   ✅ Usuário  : $USUARIO_EMAIL"
echo "   ✅ Domínio  : $DOMINIO_EMAIL"
echo "   📌 Caminho  : $CAMINHO_FINAL"

# Aguarda confirmação do operador antes de prosseguir com a migração.
read -rp $'\n🔁 Pressione [Enter] para continuar com a migração ou CTRL+C para cancelar...'

# === PARTE 3: Seleção de contas de e-mail a migrar ===
echo -e "\n📥 Listando todas as contas de e-mail encontradas no domínio '$DOMINIO_EMAIL'..."

# Lista todos os diretórios dentro do domínio (essas são as contas de e-mail).
if ! CONTAS_TODAS=($(ls -1 "$CAMINHO_FINAL")); then
    echo "❌ Erro ao listar contas dentro de '$CAMINHO_FINAL'. Verifique permissões ou existência do diretório."
    exit 1
fi

# Mostra as contas disponíveis.
echo -e "\n📧 Contas encontradas:"
for conta in "${CONTAS_TODAS[@]}"; do
    echo "   - $conta"
done

# Pergunta quais contas devem ser ignoradas, se houver.
read -rp $'\n🛑 Deseja ignorar alguma conta da migração? Digite os nomes separados por espaço (ou pressione Enter para migrar todas): ' IGNORADAS_INPUT

# Converte a entrada do usuário em array, separando por espaços.
IFS=' ' read -r -a CONTAS_IGNORADAS <<<"$IGNORADAS_INPUT"

# Compara todas as contas disponíveis com as ignoradas para filtrar apenas as que serão migradas.
CONTAS_MIGRAR=()
for conta in "${CONTAS_TODAS[@]}"; do
    IGNORAR=false
    for ignorada in "${CONTAS_IGNORADAS[@]}"; do
        if [[ "$conta" == "$ignorada" ]]; then
            IGNORAR=true
            break
        fi
    done

    # Adiciona à lista de migração apenas se não estiver na lista de ignoradas.
    if [ "$IGNORAR" = false ]; then
        CONTAS_MIGRAR+=("$conta")
    fi
done

# Exibe as contas finais que serão migradas.
echo -e "\n✅ Contas que serão migradas:"
for conta in "${CONTAS_MIGRAR[@]}"; do
    echo "   📤 $conta"
done

# Confirma com o operador antes de seguir para a próxima parte.
read -rp $'\n🔁 Pressione [Enter] para iniciar a migração das contas acima ou CTRL+C para cancelar...'
