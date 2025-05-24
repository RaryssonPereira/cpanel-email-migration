#!/bin/bash

# =======================
# Verificação do Byobu
# =======================

echo -e "\n🔍 Verificando se o script está sendo executado dentro do byobu..."

# Verifica se está dentro do byobu
if [ -n "$BYOBU_BACKEND" ]; then
    echo "✅ O script está sendo executado dentro de uma sessão do byobu. Continuando..."
else
    echo -e "⚠️  O script **não** está rodando dentro de uma sessão byobu."

    # Verifica se o byobu está instalado
    if ! command -v byobu &> /dev/null; then
        echo -e "\n📦 Byobu não está instalado. Tentando instalar..."

        # Verifica a distribuição
        if [ -f /etc/centos-release ] || grep -qi "centos" /etc/os-release; then
            yum install -y epel-release byobu
        elif [ -f /etc/redhat-release ]; then
            dnf install -y byobu
        elif [ -f /etc/debian_version ]; then
            apt update && apt install -y byobu
        else
            echo "❌ Distribuição não reconhecida para instalação automática do Byobu."
            exit 1
        fi

        echo "✅ Byobu instalado com sucesso."
    else
        echo "✅ Byobu já está instalado."
    fi

    echo -e "\n🚨 Por favor, execute o comando abaixo para iniciar uma sessão byobu antes de rodar o script novamente:\n"
    echo -e "  👉  byobu\n"
    echo -e "💡 Depois disso, execute novamente este script."
    exit 1
fi
