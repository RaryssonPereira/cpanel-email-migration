#!/bin/bash

# === SCRIPT: migration-emails.sh ===
# O processo é guiado, seguro e documentado, garantindo flexibilidade e controle sobre a migração.

# === PARTE 1: Verificação do Byobu ===
# Esta parte do script verifica se ele está sendo executado dentro de uma sessão Byobu.
# O Byobu é uma camada visual para ferramentas como tmux/screen que mantém sessões persistentes no terminal.
# Ele é muito útil para tarefas longas ou sensíveis à desconexão, como migração de e-mails.

echo -e "\n🔍 Verificando se o script está sendo executado dentro do Byobu..."
# Mostra uma mensagem informando que será feita a verificação da presença do Byobu.

# Verifica se a variável de ambiente $BYOBU_BACKEND está definida (não vazia)
# Essa variável é automaticamente setada pelo próprio Byobu quando uma sessão está ativa.
# A opção `-n` do `test` (ou `[...]`) verifica se a variável tem conteúdo (não está vazia).
if [ -n "$BYOBU_BACKEND" ]; then
    echo "✅ O script está sendo executado dentro de uma sessão do Byobu. Continuando normalmente..."
    # Se a variável $BYOBU_BACKEND estiver definida, informa que o Byobu está ativo e segue com o script.
else
    # Caso contrário (Byobu não está ativo)...

    echo -e "⚠️  O script **não está sendo executado dentro do Byobu**."
    # Alerta visual sobre a ausência do Byobu.

    echo -e "ℹ️  Recomendamos fortemente o uso do Byobu para evitar a perda de conexão durante a migração de e-mails."
    # Explica o motivo da recomendação: evitar que a migração seja interrompida caso a conexão com o terminal caia.

    # Pergunta ao usuário se ele quer entrar no Byobu antes de continuar.
    read -rp $'\n❓ Deseja entrar no Byobu antes de continuar? (s/n): ' RESPOSTA
    # `-r` impede que o bash interprete caracteres especiais.
    # `-p` define o prompt da pergunta.
    # O resultado (s/n) será armazenado na variável RESPOSTA.

    # Se a resposta for "s" ou "S" (aceitando iniciar o Byobu)...
    if [[ "$RESPOSTA" =~ ^[sS]$ ]]; then
        echo -e "\n📦 Verificando se o Byobu está instalado..."
        # Informa que o script irá verificar (e instalar, se necessário) o Byobu.

        source /etc/os-release
        # Lê e carrega as variáveis do arquivo `/etc/os-release`, que identifica a distribuição Linux atual.
        # Isso permite saber se está rodando em Ubuntu, Debian, CentOS, AlmaLinux, etc.

        if ! command -v byobu &>/dev/null; then
            # Usa `command -v` para checar se o comando `byobu` existe (está disponível no sistema).
            # Redireciona a saída padrão e de erro para /dev/null para não mostrar nada se não encontrar.

            echo -e "🔧 Instalando o Byobu..."
            # Se não estiver instalado, informa que fará a instalação.

            if [[ "$ID" =~ ^(centos|rhel|almalinux)$ ]]; then
                # Se o ID do sistema for um dos relacionados ao ecossistema Red Hat (CentOS, RHEL, AlmaLinux)...

                yum install -y epel-release byobu
                # Usa o gerenciador `yum` para instalar o repositório EPEL (se necessário) e o pacote `byobu`.

            elif [[ "$ID" =~ ^(ubuntu|debian)$ ]]; then
                # Se for baseado em Debian, como Ubuntu ou Debian puro...

                apt update && apt install -y byobu
                # Atualiza a lista de pacotes e instala o Byobu usando o `apt`.

            else
                # Se o ID da distro não for reconhecido...

                echo "❌ Distribuição '$ID' não reconhecida para instalação automática do Byobu."
                # Informa erro ao usuário e diz que não poderá instalar o Byobu.

                exit 1
                # Encerra o script com erro, pois não é seguro continuar sem a proteção do Byobu em sistemas desconhecidos.
            fi

            echo "✅ Byobu instalado com sucesso."
            # Confirma que a instalação ocorreu sem erros.
        else
            echo "✅ Byobu já está instalado."
            # Caso o Byobu já esteja presente, informa que não será necessário instalar.
        fi

        # Pega o nome do script atual (sem caminho) usando `basename "$0"` e guarda na variável SCRIPT_NAME.
        SCRIPT_NAME=$(basename "$0")
        # Isso serve para sugerir ao usuário como executar novamente o script após entrar no Byobu.

        echo -e "\n🚪 Agora você pode entrar no Byobu com o comando:\n"
        echo -e "   👉  byobu\n"
        # Instrui o usuário a iniciar uma nova sessão do Byobu no terminal.

        echo -e "🔁 Depois disso, execute novamente este script com:\n"
        echo -e "   👉  ./$SCRIPT_NAME\n"
        # Mostra o comando exato para reexecutar o script de dentro da sessão Byobu.

        echo -e "💡 Isso garante que, mesmo em caso de desconexão, a migração continue normalmente."
        # Reforça a principal vantagem de usar o Byobu: resiliência contra perda de conexão SSH.

        exit 0
        # Sai do script para que o usuário possa iniciar o Byobu e voltar.
    else
        echo -e "\n⚠️  Continuando a execução fora do Byobu conforme sua escolha."
        # Caso o usuário tenha optado por não usar o Byobu, o script continua normalmente.
        # Ainda assim, exibe um alerta leve, sugerindo que o uso do Byobu é mais seguro.
    fi
fi

# === PARTE 2: Verificação e decisão sobre uso do sshpass ===
# Esta seção trata da escolha de utilizar ou não o sshpass, uma ferramenta que permite automatizar o envio de senha via SSH,
# o que facilita bastante scripts como este que usam rsync entre servidores que exigem senha.

echo -e "\n🔐 O utilitário sshpass pode ser usado para automatizar o envio da senha no rsync."
# Mostra uma mensagem informativa para o usuário explicando o que é o sshpass e por que ele pode ser útil.

echo "Isso evita que você precise digitar a senha manualmente toda vez que uma conta for migrada."
# Complementa a explicação anterior, destacando o benefício prático do sshpass na automação do processo.

# Pergunta se o usuário deseja usar o sshpass
read -rp $'\n❓ Deseja usar sshpass para automatizar a digitação da senha SSH? (s/n): ' USAR_SSHPASS
# Usa o comando `read` com `-r` (não interpretar backslashes) e `-p` (prompt na mesma linha) para solicitar ao usuário
# uma resposta se deseja usar o sshpass. A resposta é armazenada na variável USAR_SSHPASS.

if [[ "$USAR_SSHPASS" =~ ^[sS]$ ]]; then
    # Verifica se a resposta do usuário foi "s" ou "S" (sim). O uso da expressão regular `^[sS]$` garante que só seja aceito exatamente "s" ou "S".

    echo -e "\n🔍 Verificando se sshpass está instalado..."
    # Informa que será feita a checagem de presença do sshpass na máquina.

    if command -v sshpass &>/dev/null; then
        # Usa `command -v` para verificar se o sshpass está disponível no PATH do sistema.
        # Redireciona qualquer saída padrão e de erro para /dev/null para suprimir mensagens.

        echo "✅ sshpass está instalado. Continuando com suporte a senha automática via rsync..."
        # Confirma para o usuário que o sshpass está instalado.

        USAR_SSHPASS=true
        # Altera o valor da variável USAR_SSHPASS para `true`, indicando que o script pode utilizar sshpass mais adiante.
    else
        echo -e "⚠️  sshpass não está instalado. Tentando instalar automaticamente..."
        # Informa ao usuário que o sshpass não está presente e tentará instalar automaticamente.

        source /etc/os-release
        # Carrega as variáveis de identificação da distribuição Linux (`ID`, `VERSION_ID`, etc.) que estão no arquivo /etc/os-release.
        # Isso é usado para determinar o gerenciador de pacotes correto.

        if [[ "$ID" =~ ^(centos|rhel|almalinux)$ ]]; then
            # Se a distribuição for baseada em Red Hat, como CentOS, RHEL ou AlmaLinux...

            yum install -y epel-release sshpass
            # Usa o gerenciador de pacotes `yum` para instalar o `epel-release` (repositório adicional) e o `sshpass`.

        elif [[ "$ID" =~ ^(ubuntu|debian)$ ]]; then
            # Se a distribuição for baseada em Debian, como Ubuntu ou Debian puro...

            apt update && apt install -y sshpass
            # Atualiza a lista de pacotes com `apt update` e instala o `sshpass` automaticamente com `apt install`.

        else
            echo "❌ Distribuição '$ID' não reconhecida. Instale sshpass manualmente e reexecute o script."
            # Caso o ID da distribuição não seja reconhecido, o script informa isso ao usuário e orienta a instalação manual.

            exit 1
            # Sai do script com erro, pois não pode continuar sem sshpass se o usuário quis usá-lo.
        fi

        # Após a tentativa de instalação, verifica novamente se o sshpass foi instalado com sucesso:
        if command -v sshpass &>/dev/null; then
            echo "✅ sshpass instalado com sucesso. Continuando com suporte a senha automática via rsync..."
            # Confirma que a instalação foi bem-sucedida.

            echo "ℹ️ Caso encontre qualquer erro mais adiante, recomendamos relançar o script manualmente."
            # Dá uma dica extra ao usuário sobre possíveis falhas futuras e como proceder.

            USAR_SSHPASS=true
            # Define a variável como `true` novamente para uso no restante do script.
        else
            echo "❌ A instalação do sshpass falhou. Por favor, instale manualmente e reexecute o script."
            # Informa que mesmo após tentativa automática, não foi possível instalar o sshpass.

            exit 1
            # Encerra o script com código de erro.
        fi
    fi
else
    # Se o usuário não respondeu "s" ou "S" (ou seja, optou por não usar sshpass)...

    echo -e "\n⚠️  O script continuará **sem** usar sshpass."
    # Informa ao usuário que a execução seguirá sem o uso de sshpass.

    echo "📌 Você precisará digitar a senha toda vez que o rsync solicitar conexão com o servidor remoto."
    # Alerta que, sem o sshpass, a senha SSH será solicitada manualmente em cada etapa da migração.

    USAR_SSHPASS=false
    # Define a variável como `false`, para que o restante do script saiba que o sshpass não está habilitado.
fi

# === PARTE 3: Coleta de informações dos diretórios ===
# Esta seção coleta os dados necessários para saber de qual conta e domínio os e-mails serão migrados,
# verificando a estrutura de diretórios e validando entradas.

echo -e "\n🧾 Vamos coletar as informações da conta de e-mail que será migrada."
# Exibe uma mensagem inicial indicando que começa a etapa de coleta de dados.

# Lista os diretórios em /home para sugerir usuários disponíveis.
echo -e "\n📁 Usuários disponíveis no diretório /home:"
# Informa ao operador que vai listar os usuários disponíveis para facilitar a escolha do usuário cPanel.

if ls /home &>/dev/null; then
    ls /home
    # Se o comando `ls /home` não gerar erro, lista os diretórios (usuários) dentro de /home.
else
    echo "⚠️  Não foi possível listar os diretórios em /home (permissão negada ou diretório ausente)."
    # Se o `ls /home` gerar erro (ex: permissão negada), exibe uma mensagem de alerta.
fi

# Solicita ao operador o nome do usuário do cPanel.
read -rp $'\n👤 Qual o USUÁRIO do cPanel (ex: batata)? ' USUARIO_EMAIL
# Usa `read` com prompt customizado para capturar o nome de usuário cPanel.
# A entrada será salva na variável `USUARIO_EMAIL`.

# Verifica se o diretório do usuário existe, caso contrário interrompe.
if [ ! -d "/home/$USUARIO_EMAIL" ]; then
    echo -e "❌ O diretório /home/$USUARIO_EMAIL não existe. Verifique o nome e tente novamente."
    # Caso o diretório não exista (ou seja, o usuário informado é inválido), exibe erro...

    exit 1
    # ... e encerra o script imediatamente para evitar falhas futuras.
fi

# Lista os domínios existentes no diretório de e-mail desse usuário.
echo -e "\n📬 Domínios encontrados em /home/$USUARIO_EMAIL/mail:"
# Exibe uma mensagem explicando que os domínios serão listados.

if ls "/home/$USUARIO_EMAIL/mail" &>/dev/null; then
    ls "/home/$USUARIO_EMAIL/mail"
    # Lista os subdiretórios (normalmente domínios) dentro de /home/usuario/mail/
else
    echo "⚠️  Não foi possível listar os domínios (talvez o diretório não exista ou esteja vazio)."
    # Se não conseguir listar (ex: diretório vazio ou com permissão negada), mostra um alerta.
fi

# Solicita ao operador o nome do domínio cujas contas serão migradas.
read -rp $'\n🌐 Qual o domínio que deseja migrar (ex: aguardidanoticia.com.br)? ' DOMINIO_EMAIL
# Pede ao operador que informe o domínio, salvando a resposta em `DOMINIO_EMAIL`.

# Define os caminhos possíveis para os arquivos de e-mail:
# - Se o script for rodado como root (em WHM), o caminho absoluto é necessário.
# - Se for rodado dentro do terminal de um usuário cPanel, o caminho é relativo ao diretório pessoal.
CAMINHO_WHM="/home/$USUARIO_EMAIL/mail/$DOMINIO_EMAIL"
CAMINHO_CPANEL="mail/$DOMINIO_EMAIL"
# Define as duas possibilidades de caminho com base no contexto de execução.

# Verifica se o script está sendo executado por root (UID 0).
if [ "$EUID" -eq 0 ]; then
    CAMINHO_FINAL="$CAMINHO_WHM"
    # Se o script estiver sendo executado como root, define o caminho completo.
else
    CAMINHO_FINAL="$CAMINHO_CPANEL"
    # Se não for root (usuário comum do cPanel), define o caminho relativo.
fi

# Verifica se o diretório final com as contas de e-mail existe.
if [ ! -d "$CAMINHO_FINAL" ]; then
    echo -e "\n❌ O diretório de e-mails '$CAMINHO_FINAL' não foi encontrado."
    echo "🔎 Verifique se o usuário e o domínio estão corretos, ou se você está no ambiente certo (root ou cPanel)."
    # Se o diretório de e-mails não existir no caminho final (calculado acima), alerta o operador
    # e sugere revisar os dados ou o contexto de execução (root ou não).

    exit 1
    # Encerra o script para evitar seguir com caminho inválido.
fi

# Mostra um resumo dos dados coletados antes de seguir.
echo -e "\n📂 Diretório de origem identificado:"
echo "   ✅ Usuário  : $USUARIO_EMAIL"
echo "   ✅ Domínio  : $DOMINIO_EMAIL"
echo "   📌 Caminho  : $CAMINHO_FINAL"
# Resume para o operador as informações chave: nome do usuário, domínio e caminho completo de onde os e-mails serão migrados.
# Isso permite revisar visualmente antes de prosseguir.

# Aguarda confirmação do operador antes de prosseguir com a migração.
read -rp $'\n🔁 Pressione [Enter] para continuar com a migração ou CTRL+C para cancelar...'
# Aguarda o usuário pressionar ENTER para confirmar que está tudo certo.
# Ou, se quiser abortar, pode usar CTRL+C antes de seguir.

# === PARTE 4: Seleção de contas de e-mail a migrar ===
# Esta parte permite ao operador escolher quais contas de e-mail do domínio informado devem ser migradas.
# O script lista todas as contas existentes e oferece a opção de ignorar algumas antes de prosseguir.

echo -e "\n📥 Listando todas as contas de e-mail encontradas no domínio '$DOMINIO_EMAIL'..."
# Exibe uma mensagem indicando que o script vai buscar as contas de e-mail existentes para esse domínio.

# Lista todos os diretórios dentro do domínio (essas são as contas de e-mail).
# Cada diretório representa uma conta de e-mail (ex: contato@dominio.com → /mail/dominio.com/contato).
if ! CONTAS_TODAS=($(ls -1 "$CAMINHO_FINAL")); then
    # Tenta executar `ls -1` (um item por linha) no diretório do domínio de e-mail.
    # Os nomes dos diretórios (contas) são armazenados como array na variável CONTAS_TODAS.
    # O `!` antes significa que, se o comando falhar, o bloco será executado.

    echo "❌ Erro ao listar contas dentro de '$CAMINHO_FINAL'. Verifique permissões ou existência do diretório."
    # Se a listagem falhar, exibe uma mensagem de erro personalizada.

    exit 1
    # Encerra a execução do script imediatamente, pois não há como continuar sem as contas.
fi

# Mostra as contas disponíveis.
echo -e "\n📧 Contas encontradas:"
for conta in "${CONTAS_TODAS[@]}"; do
    echo "   - $conta"
done
# Faz um loop em todas as contas armazenadas em CONTAS_TODAS (ou seja, diretórios encontrados).
# Exibe cada uma com um marcador visual.

# Pergunta quais contas devem ser ignoradas, se houver.
read -rp $'\n🛑 Deseja ignorar alguma conta da migração? Digite os nomes separados por espaço (ou pressione Enter para migrar todas): ' IGNORADAS_INPUT
# Solicita ao operador que informe, opcionalmente, uma lista de contas a serem **ignoradas**.
# Exemplo: "contato financeiro teste" → serão ignoradas contato@, financeiro@ e teste@.

# Converte a entrada do usuário em array, separando por espaços.
IFS=' ' read -r -a CONTAS_IGNORADAS <<<"$IGNORADAS_INPUT"
# Usa o separador de campos `IFS=' '` para dividir a entrada em palavras.
# Isso gera um array chamado `CONTAS_IGNORADAS` com cada conta a ser ignorada.

# Compara todas as contas disponíveis com as ignoradas para filtrar apenas as que serão migradas.
CONTAS_MIGRAR=()
# Inicializa o array que irá conter apenas as contas que **devem ser migradas**.

for conta in "${CONTAS_TODAS[@]}"; do
    # Percorre cada conta disponível.

    IGNORAR=false
    # Inicializa uma flag para dizer se a conta deve ser ignorada ou não.

    for ignorada in "${CONTAS_IGNORADAS[@]}"; do
        # Para cada conta da lista de ignoradas...

        if [[ "$conta" == "$ignorada" ]]; then
            # Verifica se a conta atual está na lista de ignoradas.

            IGNORAR=true
            break
            # Se encontrar correspondência, define a flag como `true` e quebra o loop interno.
        fi
    done

    # Adiciona à lista de migração apenas se não estiver na lista de ignoradas.
    if [ "$IGNORAR" = false ]; then
        CONTAS_MIGRAR+=("$conta")
        # Se a conta **não** estiver na lista de ignoradas, adiciona ao array `CONTAS_MIGRAR`.
    fi
done

# Exibe as contas finais que serão migradas.
echo -e "\n✅ Contas que serão migradas:"
for conta in "${CONTAS_MIGRAR[@]}"; do
    echo "   📤 $conta"
done
# Lista final das contas que serão migradas, formatadas com ícone de envio.

# Confirma com o operador antes de seguir para a próxima parte.
read -rp $'\n🔁 Pressione [Enter] para iniciar a migração das contas acima ou CTRL+C para cancelar...'
# Dá uma pausa final, aguardando o operador validar visualmente se as contas estão corretas.
# ENTER → continua | CTRL+C → cancela

# === PARTE 5: Quais caixas serão migradas ===
# Esta seção permite ao operador definir quais pastas internas (caixas) de cada conta de e-mail devem ser incluídas na migração.
# Por padrão, uma conta de e-mail no cPanel usa "cur" e "new" para a Caixa de Entrada, e tem outras pastas como .Sent, .Trash, etc.

echo -e "\n📂 Agora vamos definir quais caixas (pastas internas) serão migradas em cada conta."
# Informa ao operador que o próximo passo será escolher as pastas internas (caixas) da conta que serão migradas.

# Explicação didática para o usuário
echo -e "\n🔎 Cada conta de e-mail possui várias pastas. Por padrão, as principais são:"
echo "   - Caixa de Entrada  → cur e new"
echo "   - Enviados          → .Sent"
echo "   - Rascunhos         → .Drafts"
echo "   - Lixeira           → .Trash"
echo "   - Spam / Lixo       → .Junk ou .spam"
# Mostra ao operador uma explicação amigável das principais pastas que compõem a estrutura de uma conta de e-mail no cPanel.

echo -e "\n📌 O script sempre irá copiar os diretórios 'cur' e 'new' de cada pasta escolhida."
# Esclarece que, independentemente da pasta (ex: .Sent), o conteúdo que será migrado vem de `cur` e `new` dentro de cada uma.

# Pergunta ao usuário quais caixas devem ser migradas (entrada livre, separada por espaço)
read -rp $'\n✏️  Quais caixas você deseja migrar? (ex: .Sent .Trash .Drafts) \nPara migrar apenas a Caixa de Entrada, deixe em branco e pressione Enter: ' CAIXAS_PERSONALIZADAS
# Aqui o script pede ao operador para digitar as pastas que quer migrar além da Caixa de Entrada.
# Exemplo de entrada: `.Sent .Trash .Drafts`
# O valor será salvo como string na variável `CAIXAS_PERSONALIZADAS`.

# Se o usuário não preencher nada, migramos apenas a caixa de entrada padrão
if [ -z "$CAIXAS_PERSONALIZADAS" ]; then
    # A opção `-z` testa se a variável está vazia.
    # Se estiver vazia (ENTER foi pressionado sem nada), considera que o operador quer migrar apenas a Caixa de Entrada.

    echo -e "\n📨 Apenas a Caixa de Entrada (cur e new) será migrada."
    # Informa isso ao usuário.

    CAIXAS_MIGRAR=()
    # Inicializa `CAIXAS_MIGRAR` como um array vazio. O restante do script saberá que só "cur" e "new" da raiz devem ser migrados.
else
    # Se o usuário digitou algo, significa que há caixas extras a migrar.

    # Converte a entrada do usuário em array
    IFS=' ' read -r -a CAIXAS_MIGRAR <<<"$CAIXAS_PERSONALIZADAS"
    # Divide a string da variável `CAIXAS_PERSONALIZADAS` em um array, com base nos espaços em branco.
    # Exemplo: `.Sent .Trash` → `CAIXAS_MIGRAR[0]=.Sent`, `CAIXAS_MIGRAR[1]=.Trash`

    # Mostra o resumo das caixas que serão migradas
    echo -e "\n📤 Além da Caixa de Entrada, serão migradas as seguintes caixas:"
    for caixa in "${CAIXAS_MIGRAR[@]}"; do
        echo "   - $caixa"
    done
    # Faz um loop sobre o array `CAIXAS_MIGRAR` e imprime uma a uma.
    # Isso permite ao operador revisar visualmente as pastas que indicou para migração.
fi

# Confirma antes de prosseguir
read -rp $'\n🔁 Pressione [Enter] para continuar com a migração conforme as caixas escolhidas, ou CTRL+C para cancelar...'
# Pausa a execução, dando ao operador uma chance final de revisar e cancelar se tiver informado algo errado.
# ENTER → continua | CTRL+C → cancela

# === PARTE 6: Preparação da transferência via rsync ===
# Esta parte do script coleta os dados de acesso ao servidor de destino e testa a conexão SSH,
# garantindo que o `rsync` poderá ser usado para transferir os arquivos de e-mail.

echo -e "\n🚀 Vamos configurar a conexão com o servidor de destino para iniciar a transferência."
# Imprime uma mensagem visual para o operador informando que agora será configurada a conexão com o servidor de destino (remoto).

# Solicita os dados de conexão do servidor destino

read -rp $'\n🌐 Host ou IP do servidor de destino (ex: us129.serverdo.in): ' DEST_HOST
# Solicita ao operador que digite o **hostname ou IP do servidor destino**.
# O valor é armazenado na variável `DEST_HOST`.

read -rp $'\n🔐 Usuário SSH do destino (ex: root): ' DEST_USER
# Solicita o nome do **usuário SSH** que será usado para conectar ao servidor (ex: root).
# O valor é armazenado na variável `DEST_USER`.

read -rp $'\n📡 Porta SSH (ex: 22 ou 51439): ' DEST_PORT
# Pergunta a **porta SSH** usada para a conexão.
# Essa etapa é importante porque servidores gerenciados muitas vezes usam portas não padrão por segurança.

read -rsp $'\n🔑 Senha do usuário SSH: ' DEST_SENHA
# Solicita a senha do usuário SSH, usando `-s` para que a entrada não seja exibida no terminal (modo silencioso).
# O valor é armazenado em `DEST_SENHA`.

echo ""
# Apenas imprime uma quebra de linha para manter a interface visual organizada após a entrada da senha.

# Testa a conectividade com o servidor remoto
echo -e "\n🔎 Testando conectividade SSH com o servidor destino..."
# Informa ao operador que a conexão será testada antes de prosseguir com a migração.

# Tenta conexão e captura a saída de erro
ERRO_SSH=$(sshpass -p "$DEST_SENHA" ssh -p "$DEST_PORT" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    "$DEST_USER@$DEST_HOST" \
    "echo '✅ Conexão estabelecida com sucesso.'" 2>&1)
# Esta linha executa o teste real de conexão SSH:
# - Usa o `sshpass` com a senha fornecida para autenticação automática (sem prompt).
# - Conecta-se ao servidor remoto usando a porta, usuário e host informados.
# - Usa as opções:
#   - `StrictHostKeyChecking=no`: evita travar por causa da pergunta de "yes/no" da primeira conexão.
#   - `ConnectTimeout=10`: limita o tempo de tentativa de conexão a 10 segundos.
# - Se a conexão for bem-sucedida, imprime uma mensagem simples no terminal remoto.
# - Toda a saída padrão e de erro é redirecionada para `ERRO_SSH`, permitindo capturar mensagens de falha se houver.

# Verifica o resultado do teste de conexão
if [ $? -ne 0 ]; then
    # A variável `$?` contém o **código de saída** do último comando executado.
    # Se for diferente de zero (`-ne 0`), significa que o comando SSH falhou.

    echo -e "❌ Não foi possível conectar-se ao servidor remoto com os dados fornecidos."
    # Exibe mensagem de erro genérica.

    echo -e "📄 Detalhes do erro SSH:\n"
    echo "$ERRO_SSH"
    # Exibe a mensagem de erro real retornada pelo SSH, capturada anteriormente.

    echo -e "\n🔁 Verifique se o host, porta, usuário e senha estão corretos."
    # Sugere que o operador revise os dados fornecidos.

    exit 1
    # Sai do script com erro, pois não é possível continuar a migração sem acesso SSH ao servidor remoto.
else
    echo -e "\n✅ Conexão SSH testada com sucesso. Pronto para iniciar a migração."
    # Caso o SSH retorne código de saída 0, a conexão foi bem-sucedida.
    # Informa ao operador que o ambiente está pronto para iniciar o processo de `rsync`.
fi
