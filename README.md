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

Este script deve ser executado **no servidor de origem**, onde estão as contas de e-mail atualmente. É indicado para cenários em que você tem acesso ao terminal/SSH do Cpanel de origem, com permissão para instalar ferramentas.

### **Antes de usar**

- Verifique se o acesso ao terminal/SSH está liberado no servidor de origem.
- Confirme se é possível usar `git clone` para baixar o repositório.
- Tente instalar previamente os utilitários `byobu` e `sshpass`. O script já checa e orienta sobre eles, mas é bom garantir que você consegue instalar pacotes no ambiente.

### **Como funciona**

Diferente do script de destino, aqui a migração é **iniciada no servidor de origem**: você envia ("empurra") as contas de e-mail para o servidor de destino via SSH/rsync.

### **Principais pontos:**
- Executado diretamente no servidor de origem.
- Ideal para transferências de grandes volumes de e-mails.
- Utilização opcional de `byobu` e `sshpass` para facilitar e tornar o processo mais seguro.
- Indicado para ambientes onde você tem mais controle sobre o servidor de origem.

