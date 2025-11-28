# Arena Breakout Infinite - Database Offline (ABIDB)

**Versão 0.9.7 (Criado por: Fabiopsyduck)**

Uma ferramenta de console para catalogar e consultar rapidamente qualquer item do Arena Breakout Infinite.

Este script funciona como sua enciclopédia pessoal e 100% offline para o ABI. Você pode adicionar seus próprios itens, editar estatísticas e usar o menu "Busca com Filtro" para encontrar o melhor equipamento (capacetes, coletes, armas) para sua necessidade, com base em critérios de ordenação complexos.

O projeto **já inclui um banco de dados pré-carregado (`Database ABI`)** com dados atualizados (24/11/2025) para você começar a usar imediatamente.

## ✨ Recursos Principais

  * **Banco de Dados Incluído:** Comece a usar imediatamente com uma base de dados completa (dados de 24/11/2025).
  * **Gerenciamento Completo (CRUD):** Adicione, edite e apague itens em mais de 19 categorias.
  * **Categorias Suportadas:**
      * Armas
      * Munições (e gerenciamento de Calibres)
      * Arremessáveis (Granadas)
      * Capacetes
      * Máscaras (Táticas e de Gás)
      * Fones de Ouvido (Headsets)
      * Coletes (Balísticos, Blindados e Rigs Táticos)
      * Mochilas
      * Itens Médicos (Kits, Analgésicos, Cirúrgicos, etc.)
      * Consumíveis (Comidas e Bebidas)
  * **Busca com Filtro Avançado:** A funcionalidade principal. Filtre e ordene itens usando múltiplos critérios de desempate (ex: ordenar capacetes por `Cl Max Masc`, depois `Classe de Blindagem`, `Durabilidade`, `Bloqueio` e `Peso`).
  * **Comparador de Armas:** Um menu dedicado para comparar 2 ou 3 armas lado a lado, exibindo suas estatísticas principais e as tabelas de munição de seus respectivos calibres.
  * **Gerenciador de Compatibilidade:** Crie e edite listas de quais máscaras são compatíveis com quais capacetes. O script usa essa informação para a ordenação `Cl Max Masc`.
  * **Sistema de Ajuda Integrado:** Uma seção "Tira Dúvidas" que explica em detalhes como funciona a lógica de ordenação de cada tela de busca.
  * **Verificador de Atualização:** O script pode verificar este repositório no GitHub para notificar o usuário sobre novas versões.
  * **Interface de Console Moderna:** Menus de seleção interativos, navegação por teclas (F1, F2, F3...) e um design "flicker-free" (sem piscar).

## 🚀 Requisitos

  * Windows 10 ou 11.
  * PowerShell 5.1 (que vem com o Windows) ou, **preferencialmente**, PowerShell 7 ou superior.
  * **Windows Terminal** (Recomendado para a melhor experiência visual e para evitar que a tela pisque).

## 🛠️ Instalação e Uso

Como o banco de dados já está incluído, a instalação é muito simples.

### 1\. Baixando o Projeto

1.  Vá para a página de **[Releases](https://github.com/fabiopsyduck/Arena-Breakout-Infinite-Offline-Database/releases)** deste repositório.

2.  Na versão mais recente, baixe o arquivo `Source code (zip)`.

3.  Descompacte o arquivo `.zip` em um local de sua preferência (ex: `C:\Jogos\ABIDB`).

4.  Após descompactar, você terá a estrutura de pastas correta, com o script e a base de dados lado a lado:

    ```
    SuaPasta/
    ├── ABIDB.ps1               (O Script)
    └── Database ABI/           (A pasta com todos os dados)
    ```

### 2\. Como Executar

1.  Abra seu terminal (Windows Terminal ou PowerShell).
2.  Navegue até a pasta que você acabou de descompactar:
    ```powershell
    cd C:\Caminho\Para\SuaPasta
    ```
3.  Execute o script:
    ```powershell
    .\ABIDB.ps1
    ```

### Solução de Problemas

Se o script não executar e você receber um erro vermelho sobre "execution policy" ou "scripts desabilitados":

  * Execute este comando no seu PowerShell **uma única vez** para permitir a execução de scripts locais:
    ```powersshell
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
    ```
  * Pressione `S` (ou `Y`) e Enter para confirmar.
  * Tente executar `.\ABIDB.ps1` novamente.

## 📄 Licença

Este projeto é distribuído sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
