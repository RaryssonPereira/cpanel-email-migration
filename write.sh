#!/bin/bash

# === PARTE 5: Quais caixas serão migradas ===
# Esta seção define automaticamente as caixas internas de cada conta a serem migradas.
# Caixa de Entrada é sempre incluída. O operador pode ignorar algumas caixas padrão.
# Caixas personalizadas serão migradas automaticamente.

echo -e "\n📂 Agora vamos definir quais caixas (pastas internas) serão migradas em cada conta."

# Explicação didática para o operador
echo -e "\n🔎 Cada conta de e-mail possui várias pastas. Por padrão, as principais são:"
echo "   - Caixa de Entrada  → cur e new"
echo "   - Enviados          → .Sent"
echo "   - Rascunhos         → .Drafts"
echo "   - Lixeira           → .Trash"
echo "   - Spam / Lixo       → .Junk ou .spam"
echo -e "\n📌 O script sempre irá copiar os diretórios 'cur' e 'new' de cada pasta."

# Lista de caixas padrão para possível exclusão
CAIXAS_PADRAO=(.Sent .Trash .Drafts .Junk .spam)

# Pergunta ao usuário quais dessas deseja ignorar para TODAS as contas
echo -e "\n🛑 Você pode optar por NÃO migrar algumas das caixas padrão abaixo:"
for caixa in "${CAIXAS_PADRAO[@]}"; do
    echo "   - $caixa"
done
read -rp $'\n✏️  Digite as caixas padrão que deseja ignorar (separadas por espaço), ou pressione [Enter] para migrar todas: ' IGNORADAS_INPUT
IFS=' ' read -r -a CAIXAS_IGNORADAS <<<"$IGNORADAS_INPUT"

# Confirma a escolha com o operador
echo -e "\n✅ As seguintes caixas padrão serão ignoradas:"
for ignorada in "${CAIXAS_IGNORADAS[@]}"; do
    echo "   - $ignorada"
done
echo -e "\n📩 Todas as demais caixas padrão e personalizadas serão migradas automaticamente."

read -rp $'\n🔁 Pressione [Enter] para continuar com a migração, ou CTRL+C para cancelar...'
