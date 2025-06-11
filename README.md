# Migração Automática de E-mails entre Servidores Cpanel

### 👤 Autor

**Rarysson Pereira**  
Analista de Desenvolvimento de Sistemas e Infraestrutura | Brasileiro 🇧🇷  
🗓️ Criado em: 09/06/2025  
[LinkedIn](https://www.linkedin.com/in/rarysson-pereira?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app) • [Instagram](https://www.instagram.com/raryssonpereira?igsh=MXhhb3N2MW1yNzl3cA==)

---

## 🤔 Por que Automatizar a Migração de Contas de E-mail entre Servidores Cpanel?

Migrar apenas as contas de e-mail entre servidores Cpanel pode ser um grande desafio, principalmente em cenários onde o site está hospedado em outro local (como um servidor Cloud) e você não deseja mover o ambiente inteiro.

Algumas dificuldades comuns que motivam a automação desse processo incluem:

- **Evitar o backup completo do Cpanel:**  
  O backup tradicional do Cpanel gera um arquivo único contendo todos os dados do usuário (arquivos do site, bancos de dados, configurações, e-mails, etc). Muitas vezes, só é necessário migrar os e-mails, mas não o site, especialmente quando o site já foi migrado para um ambiente dedicado ou Cloud. Automação permite selecionar e migrar apenas as caixas de e-mail, sem levar arquivos desnecessários.

- **Limitações de armazenamento e performance:**  
  Em ambientes Cpanel com grandes volumes de dados (por exemplo, 300GB a 500GB), o processo de backup via painel web pode ser extremamente demorado ou até inviável. É comum o processo de geração do arquivo `cpmove` falhar com timeout após algumas horas, tornando impossível concluir a exportação pelo painel.

- **Necessidade de atuação via terminal:**  
  Por conta das limitações do painel, muitas migrações acabam exigindo o uso do terminal para transferir apenas as pastas e arquivos relevantes das contas de e-mail. Automatizar esse fluxo economiza tempo, minimiza erros humanos e permite um controle mais granular sobre o que está sendo migrado.

- **Redução de indisponibilidade:**  
  Scripts automatizados permitem migrar os dados com mais eficiência e agilidade, reduzindo o tempo de indisponibilidade para o cliente final.

- **Repetibilidade e documentação:**  
  Utilizar scripts padronizados garante que o procedimento possa ser repetido de forma segura em diferentes clientes e situações, além de facilitar o suporte e a auditoria do processo de migração.

Esses fatores tornam essencial a criação de ferramentas e rotinas automáticas, proporcionando um fluxo de trabalho mais confiável e produtivo para quem gerencia múltiplos ambientes Cpanel e precisa lidar com grandes volumes de e-mails.

---

## 🛬 Script `email-migration-destination.sh` — Execução no Servidor Destino  
[🔗 Ver script no GitHub](https://github.com/RaryssonPereira/cpanel-email-migration/blob/main/email-migration-destination.sh)

Este script deve ser executado **no servidor de destino**, para onde as contas de e-mail serão migradas. Ele foi criado para facilitar a importação dos e-mails, mesmo quando o servidor de origem não oferece acesso ao terminal.

### **Antes de começar**

O script verifica automaticamente se as ferramentas `byobu`, `sshpass` e `git clone` estão disponíveis, mas recomenda-se conferir previamente se você pode instalá-las no servidor de destino, evitando surpresas durante a migração.

### **Por que migrar pelo destino?**

Muitos provedores não permitem acesso ao terminal no Cpanel de origem, dificultando transferências diretas. Com este script, todo o processo é iniciado do destino: basta que o servidor de origem aceite conexões SSH (usadas pelo `rsync`). Não é necessário acessar manualmente o terminal do Cpanel de origem.

### **Principais vantagens:**

- Não precisa acessar o terminal do Cpanel de origem.
- Não exige root no servidor de origem; no destino, o recomendado é executar como root.
- Transfere todas as caixas e dados das contas de e-mail.
- Evita limitações comuns das hospedagens de origem.
- Permite migração de múltiplas contas ou domínios.

---

## 🚀 Script `email-migration-origin.sh` — Execução no Servidor de Origem  
[🔗 Ver script no GitHub](https://github.com/RaryssonPereira/cpanel-email-migration/blob/main/email-migration-origin.sh)

Este script deve ser executado **no servidor de origem**, ou seja, onde estão as contas de e-mail atualmente. Ele é recomendado para cenários em que você possui acesso ao terminal/SSH do Cpanel de origem, com permissões suficientes para instalar e rodar ferramentas no ambiente.

### **O que conferir antes de usar o script**

- **Acesso ao terminal/SSH:** Certifique-se de que o seu plano de hospedagem permite acesso ao terminal/SSH.  
- **Permissão para usar `git clone`:** O ideal é que seja possível clonar este repositório diretamente via `git clone` no servidor. Caso contrário, você terá dificuldade para baixar e executar os scripts.
- **Instalação dos utilitários necessários:** Recomendo verificar previamente se consegue instalar as ferramentas `byobu` e `sshpass`.  
  - Essas ferramentas são importantes para garantir que a transferência será realizada de forma mais prática e robusta, evitando interrupções e facilitando o acompanhamento do processo.
  - O próprio script já faz uma checagem automática dos utilitários e pergunta se você deseja utilizá-los, mas é bom conferir manualmente se você tem permissão para instalar pacotes no servidor.

### **Como funciona o processo**

O funcionamento é semelhante ao script de destino, porém neste caso a migração é **iniciada a partir do servidor de origem**: você envia (ou “empurra”) as contas de e-mail do servidor de origem para o servidor de destino, usando SSH/rsync para a transferência dos dados.

### **Principais pontos:**
- Execução no terminal do servidor de origem (onde estão as contas atualmente).
- Garante flexibilidade para realizar transferências de grandes volumes de e-mails.
- Permite o uso opcional de utilitários como `byobu` (para sessões persistentes) e `sshpass` (para automação do SSH).
- Ótima opção para ambientes onde você tem mais controle ou acesso sobre o servidor de origem.



