#!/bin/bash

# === PARTE 5: Coleta dos dados de acesso ao servidor de destino ===
# Esta parte coleta as informações necessárias para conectar ao servidor destino via SSH
# (host, usuário, porta e senha), e testa a conectividade para garantir que o rsync funcionará.

echo -e "\n🚀 Vamos configurar a conexão com o servidor de destino para iniciar a transferência."

# Solicita o hostname ou IP do servidor destino
read -rp $'\n🌐 Host ou IP do servidor de destino (ex: us129.serverdo.in): ' DEST_HOST

# Solicita o usuário SSH do destino (ex: root)
read -rp $'\n🔐 Usuário SSH do destino (ex: root): ' DEST_USER

# Solicita a porta SSH
read -rp $'\n📡 Porta SSH (ex: 22 ou 51439): ' DEST_PORT

# Solicita a senha do usuário SSH, entrada oculta
read -rsp $'\n🔑 Senha do usuário SSH: ' DEST_SENHA
echo ""  # Quebra de linha após a senha

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
