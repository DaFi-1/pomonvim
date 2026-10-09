# pomonvim.nvim 🍅

Um plugin moderno, minimalista, interativo e de alta performance de Pomodoro e blocos de foco para Neovim.

---

## ✨ Características

- 🖥️ **Interface Centralizada & Minimalista:** Janela flutuante minimalista centralizada na tela, com borda arredondada elegante, fundo escuro Dracula e design limpo sem colchetes ou caracteres desnecessários.
- ⏱️ **Display Digital Retro-Moderno:** Relógio digital em bloco ASCII no topo com espaçamento harmônico para a barra de progresso visual em tempo real (Foco = Verde `#50fa7b`, Descanso = Vermelho `#ff5555`).
- 🧩 **Montador Dinâmico de Ciclos (Esquerda):**
  - **`▶ START POMODORO`** / **`󰏤 PAUSAR POMODORO`**: Inicia ou pausa a sequência montada.
  - **`󰆴 LIMPAR CICLOS`**: Reinicia a lista de ciclos (protegido: exige pausar o timer primeiro).
  - **`󰆓 SALVAR POMODORO`**: Salva a sequência montada com nome personalizado através de um popup centralizado.
  - **Rotinas Salvas no Topo com Preview (``)**: As rotinas gravadas aparecem fixadas no topo. Ao navegar sobre elas com o cursor, o painel da direita exibe instantaneamente o preview dos ciclos.
  - **Carregamento Instantâneo**: Pressione `<Enter>` em uma rotina salva para carregar imediatamente todos os seus ciclos no grupo ativo.
  - **Lista de Tempos Predefinidos**: Opções de `5m`, `10m`, `15m`, `20m`, `25m`, `30m`, ..., até `4h`.
  - **Alternância Automática**: Ao teclar `<Enter>` nos tempos, eles alternam automaticamente entre **Foco** e **Descanso**.
  - **Seletor com Cores Contextuais**: A linha selecionada recebe destaque apropriado conforme o tipo (Verde para Foco, Vermelho para Descanso, Ciano para Salvar, Roxo para rotinas salvas, Amarelo para Ajuda).
  - **`󰋖 HELP` no Final**: Opção dedicada que abre uma janela modal centralizada com explicações completas e teclas de atalho.
- 🌐 **Ajuda Bilíngue com Abas Interativas (`󰋖 HELP` / `?`):**
  - Modal centralizado com abas de idioma (**Português** e **English**).
  - Navegação fluida entre os idiomas através das teclas **`h`** / **`l`**, setas **`←`** / **`→`** ou **`<Tab>`**.
- 📊 **Painel de Ciclos em Tempo Real (Direita):**
  - Visualização limpa: permanece vazio quando não há ciclos montados ou rotina sob o cursor.
  - Indicador ativo (`▶`), checkmarks de conclusão (`✓`), numeração de ciclos e totais fixados no rodapé (`Total Foco` e `Total Descanso`).
- ⚡ **Execução Assíncrona via `vim.uv`:** O cronômetro roda em segundo plano sem travar a interface do Neovim, com transição automática entre ciclos.
- 💾 **Persistência Automática:** Suas rotinas salvas e o progresso da sessão persistem entre reinicializações do Neovim em arquivo JSON local (`stdpath("data")/pomonvim_sessions.json`).
- 🔔 **Alertas Sonoros e Notificações:** Notificações nativas do Neovim e campainha sonora ao concluir ciclos.
- 🎛️ **Integração com Statusline:** Função `require("pomonvim").statusline()` pronta para Lualine, Heirline ou statusline nativa.

---

## 📦 Instalação

### Usando [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "DaFi-1/pomonvim",
  keys = {
    { "<space>p", desc = "Pomonvim Pomodoro Menu" },
  },
  config = function()
    require("pomonvim").setup({
      -- configurações opcionais aqui
    })
  end,
}
```

### Usando [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "DaFi-1/pomonvim",
  config = function()
    require("pomonvim").setup()
  end
}
```

---

## 🚀 Como Usar

Abra o menu a qualquer momento usando o atalho padrão:

```text
<space>p   (no modo Normal)
```

Ou através dos comandos do Neovim:

```vim
:Pomonvim
:Pomo
:Pomoxx
```

---

## ⌨️ Teclas de Atalho

### No Menu Principal:

| Tecla | Ação |
| :--- | :--- |
| `<CR>` (Enter) | **Nos tempos:** adiciona à sequência (alternando foco/descanso)<br>**No START / PAUSE:** inicia ou pausa o cronômetro<br>**No LIMPAR:** reseta a sequência atual<br>**No SALVAR:** abre campo para nomear e salvar a rotina<br>**Nas rotinas salvas (``):** carrega todos os ciclos daquela rotina para o grupo ativo<br>**No HELP (`󰋖`):** abre janela centralizada de ajuda |
| `<Space>` | Iniciar / Pausar timer diretamente a qualquer momento |
| `j` / `<Down>` | Descer o cursor na lista |
| `k` / `<Up>` | Subir o cursor na lista |
| `x` | Excluir a rotina salva selecionada (``) |
| `<BS>` | Remover o último ciclo adicionado |
| `d` | Excluir a rotina salva selecionada ou remover o último ciclo |
| `c` | Limpar todos os ciclos montados |
| `r` | Reiniciar o timer do ciclo ativo |
| `n` | Pular para o próximo ciclo |
| `p` | Voltar para o ciclo anterior |
| `?` | Abrir a janela centralizada de ajuda e atalhos |
| `q` / `<Esc>` | Fechar o menu flutuante (o timer continua rodando em segundo plano) |

### Na Janela de Ajuda (`?` ou item `󰋖 HELP`):

| Tecla | Ação |
| :--- | :--- |
| `h` / `<Left>` | Alternar para a aba **Português** |
| `l` / `<Right>` | Alternar para a aba **English** |
| `<Tab>` | Alternar dinamicamente entre Português e English |
| `j` / `k` | Rolar o conteúdo da ajuda |
| `q` / `<Esc>` / `<CR>` / `?` | Fechar a janela de ajuda e voltar ao menu |

---

## ⚙️ Configuração

Você pode customizar o Pomonvim passando uma tabela de opções para a função `setup()`:

```lua
require("pomonvim").setup({
  width = 88,                -- Largura da janela flutuante
  height = 26,               -- Altura da janela flutuante
  border = "rounded",        -- Estilo da borda ("rounded", "single", "double", etc.)
  keymap = "<space>p",       -- Atalho no modo Normal para abrir o menu (ou false para desabilitar)
  notification = true,       -- Notificações do Neovim ao finalizar ciclos
  sound = true,              -- Alerta sonoro / campainha ao terminar
  auto_start_breaks = true,  -- Transição e início automático para o próximo ciclo
  work_duration = 25 * 60,   -- Duração padrão de foco (em segundos)
  short_break = 5 * 60,      -- Duração padrão de descanso curto (em segundos)
  long_break = 15 * 60,      -- Duração padrão de descanso longo (em segundos)
})
```

---

## 💻 Integração com Statusline (Lualine)

Para exibir o status em tempo real do Pomonvim na sua barra de status:

```lua
require("lualine").setup({
  sections = {
    lualine_x = {
      require("pomonvim").statusline,
    },
  },
})
```

O componente exibe automaticamente:
- Ícone de foco (`🍅`) ou descanso (`☕`).
- Indicador de pausa (`󰏤`) quando pausado.
- Contagem regressiva (`MM:SS` ou `H:MM:SS`).

---

## 🛠️ API Lua

Você também pode controlar o Pomonvim diretamente via Lua no Neovim:

```lua
local pomonvim = require("pomonvim")

pomonvim.toggle()     -- Abre ou fecha o menu flutuante
pomonvim.open()       -- Abre o menu flutuante
pomonvim.close()      -- Fecha o menu flutuante
pomonvim.start()      -- Inicia o cronômetro
pomonvim.pause()      -- Pausa o cronômetro
pomonvim.reset()      -- Reinicia o ciclo ativo
pomonvim.next()       -- Avança para o próximo ciclo
pomonvim.prev()       -- Retorna para o ciclo anterior
pomonvim.get_status() -- Retorna tabela com estado completo do timer
pomonvim.statusline() -- Retorna string formatada para a statusline
```
