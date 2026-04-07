# Arena Breakout Infinite - Database Offline (ABIDB)

**Versão 1.0.0 (Criado por: Fabiopsyduck)**

Uma aplicação de desktop completa e intuitiva para catalogar, comparar e consultar rapidamente qualquer item do Arena Breakout Infinite.

O ABIDB funciona como sua enciclopédia pessoal e 100% offline para o ABI. Através de uma interface gráfica rica, você pode adicionar seus próprios itens, editar estatísticas, comparar armamentos e usar o menu "Busca com Filtro" para encontrar o melhor equipamento (capacetes, coletes, armas) para sua necessidade, com base em critérios de ordenação complexos.

⚠️ **IMPORTANTE:** O aplicativo (motor) e o Banco de Dados (arquivos CSV) agora possuem atualizações independentes. **Você precisará baixar os dados separadamente** (veja as instruções de instalação abaixo).

## ✨ Recursos Principais

  * **Interface Gráfica Completa (GUI):** Navegação por abas, janelas pop-up de edição, tabelas de dados interativas (DataGrid) e menus suspensos. Muito mais fácil e visual do que nunca!
  * **Gerenciamento Completo (CRUD):** Adicione, edite e apague itens em mais de 19 categorias através de painéis visuais.
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
  * **Exportação de Relatórios:** Salve os resultados das suas buscas e filtros diretamente em arquivos CSV com um único clique.
  * **Comparador de Armas Avançado:** Um menu visual dedicado para comparar de 2 a 3 armas lado a lado, exibindo suas estatísticas principais e as tabelas de munição de seus respectivos calibres.
  * **Módulo de Atualização Inteligente:** O aplicativo verifica este repositório e o repositório da Database independentemente, notificando você se há novas versões do programa ou novos itens do jogo disponíveis.

## 🚀 Requisitos

  * Windows 10 ou 11.
  * PowerShell 5.1 (nativo do Windows) ou superior.
  * Conexão com a internet (Apenas para o módulo de verificação de atualizações).

## 🛠️ Instalação e Uso

Como o aplicativo e os dados são separados, você precisará baixar ambos e colocá-los na mesma pasta.

### 1. Baixando o Aplicativo (ABIDB)
Vá para a página de **[Releases](https://github.com/fabiopsyduck/Arena-Breakout-Infinite-Offline-Database/releases)** deste repositório e baixe o `ABIDB.exe` (ou o script `ABIDB.ps1` se preferir o código-fonte).

### 2. Baixando o Banco de Dados
Acesse o repositório oficial da base de dados em:
**🔗 [ABIDB-Database](https://github.com/fabiopsyduck/-ABIDB-Database)**
Baixe a versão mais recente e extraia a pasta chamada **`Database ABI`**.

### 3. Estrutura de Pastas (Muito Importante)
Coloque o executável (ou script) e a pasta do banco de dados no mesmo diretório de sua preferência. A estrutura final deve ficar exatamente assim:
```text
SuaPastaDedicada/
 ├── ABIDB.exe           (O Aplicativo)
 └── Database ABI/       (A pasta com todos os dados .csv)
```

### 4. Como Executar
Basta dar um duplo clique no `ABIDB.exe` e o programa abrirá instantaneamente. 

*(Se você optou por usar a versão em script `.ps1`, clique com o botão direito nele e escolha "Executar com PowerShell". Pode ser necessário usar o comando `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` uma vez no seu computador para permitir a execução).*

---

## 💻 Para Desenvolvedores: Como converter o script para `.exe`

Se você baixou o código-fonte (`abdb.ps1`) e deseja compilar o seu próprio executável para ter uma experiência sem a tela preta do console em background, siga os passos abaixo usando o módulo `ps2exe`:

1. Abra o PowerShell como Administrador e instale o módulo:
   ```powershell
   Install-Module -Name ps2exe -Force
   ```
2. Navegue até a pasta onde está o seu `abdb.ps1`.
3. Execute o seguinte comando para compilar com suporte gráfico moderno (STA) e configurações de High-DPI para o Windows 10/11:
   ```powershell
   Invoke-ps2exe -inputFile "abdb.ps1" -outputFile "ABIDB.exe" -noConsole -apartment STA -title "Arena Breakout Infinite - Database Offline" -description "Banco de dados offline para ABI (Licença MIT)" -version "1.0.0" -company "Fabiopsyduck" -product "ABIDB" -copyright "Copyright (c) 2026 Fabiopsyduck - MIT License" -supportOS
   ```
   *(Opcional: Se você possuir um arquivo de ícone, pode adicionar o parâmetro `-iconFile "seu_icone.ico"` ao comando).*

## 📄 Licença

Este projeto é distribuído sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
