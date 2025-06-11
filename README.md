# Migração Automática de E-mails entre Servidores Cpanel

### 👤 Autor

**Rarysson Pereira**  
Analista de Desenvolvimento de Sistemas e Infraestrutura | Brasileiro 🇧🇷  
🗓️ Criado em: 09/06/2025  
[LinkedIn](https://www.linkedin.com/in/rarysson-pereira?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app) • [Instagram](https://www.instagram.com/raryssonpereira?igsh=MXhhb3N2MW1yNzl3cA==)

---

## 🤔 Por que Automatizar a Migração de Contas de E-mail entre Servidores Cpanel?

Migrar apenas as contas de e-mail entre servidores Cpanel pode ser complicado, principalmente quando o site já está em outro ambiente e não se deseja mover tudo.

Principais motivos para automatizar:

- **Evita o backup completo do Cpanel:** Permite migrar só os e-mails, sem transferir arquivos desnecessários do site.
- **Melhora a performance e supera limitações:** Garante migração mesmo em ambientes com grandes volumes de dados, onde o backup do painel pode falhar.
- **Uso do terminal facilita e reduz erros:** Automatizar o processo torna tudo mais rápido, seguro e sob controle.
- **Menos indisponibilidade:** Scripts automáticos aceleram a migração e minimizam o tempo offline do cliente.
- **Procedimento seguro e repetível:** Scripts documentados facilitam o suporte e podem ser reutilizados em várias situações.

Assim, ferramentas automáticas tornam a rotina de migração muito mais eficiente e confiável para quem gerencia diversos Cpanels e grandes volumes de e-mail.

---

## 🛬 Script `email-migration-destination.sh` — Execução no Servidor Destino  
[🔗 Ver script no GitHub](https://github.com/RaryssonPereira/cpanel-email-migration/blob/main/destination/email-migration-destination.sh)

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

---

## ✅ Considerações finais

Esses scripts foram criados para tornar a migração de contas de e-mail entre servidores Cpanel muito mais simples, rápida e confiável, especialmente em cenários com restrições de acesso ao terminal ou grandes volumes de dados.  

Antes de executar qualquer um dos scripts, é altamente recomendado que você leia o guia detalhado correspondente ao fluxo que pretende usar:

- [Guia de uso do script email-migration-destination.sh (migração iniciada no destino)](https://github.com/RaryssonPereira/cpanel-email-migration/blob/main/email-migration-destination-guide.md)
- [Guia de uso do script email-migration-origin.sh (migração iniciada na origem)](https://github.com/RaryssonPereira/cpanel-email-migration/blob/main/email-migration-origin-guide.md)

Esses guias apresentam o passo a passo de cada etapa do processo, dicas de preparação do ambiente e instruções para garantir uma migração segura.

Caso encontre qualquer dúvida, sugestão ou melhoria, fique à vontade para abrir uma issue no repositório.

Boas migrações!
