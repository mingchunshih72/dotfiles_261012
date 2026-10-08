# Neovim 快捷鍵總表（C 開發）

> `<Space>` = Leader 鍵（空白鍵）。
> 忘記鍵位時：按 `<Space>` 停住 → which-key 會列出所有可按的鍵；
> 或 `<Space>fk` 用模糊搜尋找任何快捷鍵；或 `<Space>ch` 看 NvChad 內建表。

---

## 0. 一分鐘上手：開一個 C 專案要做的事

```bash
cd ~/work/myproject
mkidx            # ★ 建索引：cscope.out + tags + compile_commands.json
nvim
```

| 想做什麼 | 按鍵 |
|---|---|
| 找檔案 | `<Space>ff` |
| 全專案搜關鍵字 | `<Space>fw` |
| 搜游標下的字（全專案） | `<Space>fW` |
| 跳到函式定義 | `gd`（LSP）或 `<Space>cg`（cscope） |
| 誰呼叫了這個函式 | `<Space>cc`（列表）/ `<Space>cu`（樹狀） |
| 跳回上一個位置 | `<C-o>` |
| 本檔所有 function 列表 | `<Space>ls` |
| 編譯 | `<Space>mm`，錯誤用 `]q` / `[q` 跳 |

---

## 1. 搜尋

### 1-1 全域搜尋（整個專案）★ 需要 ripgrep

| 按鍵 | 功能 | 說明 |
|---|---|---|
| `<Space>fw` | 全專案即時搜尋 | 邊打邊找（live grep），右側即時預覽 |
| `<Space>fW` | 全專案搜游標下的字 | 關鍵字固定，少按幾下 |
| `<Space>fw` | **visual**：搜選取的文字 | 關鍵字**預填好、還能繼續改** |
| `<Space>fW` | **visual**：搜選取的文字 | 關鍵字固定不給改 |
| `<Space>fz` | **visual**：本檔搜選取的文字 | |
| `*` / `#` | **visual**：本檔搜選取的文字，往下／往上 | Neovim 內建 |
| `<Space>fG` | grep → quickfix | 結果量很大時比 Telescope 好用 |
| `:grep <pattern>` | 同上（手打） | 已設成走 ripgrep |
| `<Space>lS` | 全專案 symbol 搜尋 | LSP 語意級，只找 function/變數名 |
| `<Space>ct` | cscope 文字搜尋 | 不依賴 LSP，大型 C 專案很快 |
| `<Space>ce` | cscope egrep 搜尋 | 支援正規表示式 |

**在 Telescope 搜尋框裡：**

| 按鍵 | 功能 |
|---|---|
| `<C-j>` / `<C-k>` | 上下選 |
| `<C-q>` | **把全部結果丟進 quickfix**（之後可 `]q` 逐一處理、或批次取代） |
| `<C-d>` / `<C-f>` | 預覽視窗上下捲 |
| `<Esc>` / `q` | 關閉 |
| `<Tab>` | 多選（加入 multi-selection） |

### 1-2 區域搜尋（當前檔案）

| 按鍵 | 功能 |
|---|---|
| `/pattern` | 往下搜 |
| `?pattern` | 往上搜 |
| `n` / `N` | 下一個 / 上一個（畫面自動居中） |
| `*` / `#` | 搜游標下的字，往下 / 往上 |
| `<Esc>` | 清除搜尋高亮 |
| `<Space>fz` | 本檔模糊搜尋（有預覽） |
| `<Space>ls` | 本檔 function / 變數 列表 |
| `:%s/old/new/gc` | 逐一確認取代 |

> 搜尋預設 **不分大小寫**；但只要你輸入中含大寫字母就自動變成分大小寫（smartcase）。

### 1-3 找檔案 / buffer

| 按鍵 | 功能 |
|---|---|
| `<Space>ff` | 找檔案 |
| `<Space>fa` | 找所有檔案（含隱藏檔、含 .gitignore 的） |
| `<Space>fb` | 找已開啟的 buffer |
| `<Space>fo` | 最近開過的檔案 |
| `<Space>fr` | 回到上一次的搜尋結果（resume） |
| `<Space>fq` | 瀏覽 quickfix |
| `<Space>ft` | 找所有 TODO / FIXME / XXX / HACK |
| `<Space>fM` | 找 mark |
| `<Space>fk` | **搜尋所有快捷鍵**（忘記鍵位用這個） |
| `<Space>fh` | 搜尋說明文件 |
| `F9` / `F10` | 開關 / focus 檔案樹（右側） |

### 1-4 取代

| 按鍵 | 功能 |
|---|---|
| `<Space>rw` | 本檔取代游標下的字（會先填好，你補上新字） |
| `<Space>rw` | 取代選取範圍內（**visual**） |
| `<Space>lr` | **LSP 重新命名**（跨檔、語意正確，改變數/函式名首選） |
| `<Space>rr` | 對 quickfix 清單批次取代（先 `<Space>fw` → `<C-q>`） |
| `<C-n>` | 多光標：選游標下的字 + 跳到下一個同名 |
| `<C-a>` | 多光標：一次選取檔案內所有同名 |

**跨檔批次取代的標準流程：**
```
<Space>fw  →  打關鍵字  →  <C-q>（全丟 quickfix）  →  <Space>rr  →  輸入前/後字串
```

---

## 2. 函式 / 符號跳轉

### 2-1 LSP（clangd）— 語意精確，需要 `compile_commands.json`

> **`gd` / `gr` 不需要先選字** —— LSP 查的是「游標位置」，不是「選取的文字」。
> 游標停在名字上任何一個字母就行。`viw` 選好再按也可以（已支援 visual 模式）。

| 按鍵 | 功能 | 模式 |
|---|---|---|
| `gd` | 跳到**定義** | n + visual |
| `gD` | 跳到**宣告** | n + visual |
| `gi` | 跳到實作 | n + visual |
| `gy` | 跳到型別定義 | n + visual |
| `gr` | 列出**所有參考** —— 本檔和其他檔**同一張清單** | n + visual |
| `K` | 顯示說明（型別 / 函式簽章 / doxygen 註解） |
| `gs` | 函式參數提示 |
| `<C-k>` | 函式參數提示（**insert 模式**，打參數時用） |
| `<Space>ls` | 本檔 function / 變數 列表 |
| `<Space>lS` | 全專案 symbol 搜尋 |
| `<Space>li` | **誰呼叫了這個函式**（incoming calls） |
| `<Space>lo` | **這個函式呼叫了誰**（outgoing calls） |
| `<Space>lr` | 重新命名（跨檔） |
| `<Space>la` | Code Action（快速修正、加 include…） |
| `<Space>lf` | 格式化（clang-format） |
| `<Space>lh` | `.c` ⇄ `.h` 切換（`:CSwitch`，支援 `src/` 與 `include/` 分開放的結構） |
| `<Space>lI` | LSP 狀態（`:LspInfo`） |
| `<Space>lR` | 重啟 LSP |

### 2-2 cscope — 不需要編譯資料庫，大型 C 專案的主力

兩組鍵位等價，用你習慣的：`<Space>c…` 或傳統的 `<C-\>…`

| 按鍵 | 功能 |
|---|---|
| `<Space>cg` / `<C-\>g` | 找**全域定義**（最常用） |
| `<Space>cs` / `<C-\>s` | 找這個 C **symbol**（所有出現處） |
| `<Space>cc` / `<C-\>c` | 找**呼叫這個函式的地方**（callers） |
| `<Space>cd` / `<C-\>d` | 找**這個函式呼叫了誰**（callees） |
| `<Space>ca` / `<C-\>a` | 找**對這個變數賦值的地方** |
| `<Space>ct` / `<C-\>t` | 找這段文字 |
| `<Space>ce` / `<C-\>e` | egrep 正規搜尋 |
| `<Space>cf` / `<C-\>f` | 找這個檔案 |
| `<Space>ci` / `<C-\>i` | 找 `#include` 這個檔案的檔案 |
| `<Space>cu` | **呼叫樹：誰呼叫這個函式**（樹狀展開） |
| `<Space>cD` | **呼叫樹：這個函式呼叫誰** |
| `<Space>cv` | 開/關呼叫樹視窗 |
| `<Space>cb` | 重建 cscope 資料庫 |
| `:TagsBuild` / `<Space>mt` | **重建 cscope.out + tags**（新增檔案後跑這個） |
| `:Cs db show` | 看目前連到哪個 cscope.out |

> 在呼叫樹視窗裡：`<Tab>` 展開/收起、`<CR>` 跳過去、`<C-v>`/`<C-s>` 在分割視窗開、`q` 關閉。

### 2-3 ctags

| 按鍵 | 功能 |
|---|---|
| `<C-]>` | 跳到 tag（順序：cscope → tag 選單 → ctags） |
| `<C-t>` | 跳回來（tag stack） |
| `g]` | 列出所有同名 tag 讓你選 |

### 2-4 跳轉歷史（**最重要，一定要記**）

| 按鍵 | 功能 | `gd`(LSP) | `<Space>cg`(cscope) | `<C-]>`(ctags) |
|---|---|---|---|---|
| **`<C-o>`** | **跳回上一個位置**（連按可一路往回） | ✅ | ✅ | ✅ |
| `<C-i>` | 再往前跳（`<C-o>` 的反向） | ✅ | ✅ | ✅ |
| `<C-t>` | 跳回來（tag stack） | ❌ 無效 | ✅ | ✅ |
| `:jumps` | 看完整跳轉歷史 | | | |

> **只記 `<C-o>` 就好，它全部通用。**

| 按鍵 | 功能 |
|---|---|
| `<C-^>` / `<Space><Space>` | 切換上一個檔案 |
| `` `` `` | 回到跳轉前的位置（同一檔案內） |
| `]f` / `[f` | 跳到下一個 / 上一個 **function** 開頭 |
| `]F` / `[F` | 跳到下一個 / 上一個 function **結尾** |
| `]b` / `[b` | 跳到下一個 / 上一個 block（`{}`） |
| `]i` / `[i` | 跳到下一個 / 上一個 `if` / `switch` |
| `]l` / `[l` | 跳到下一個 / 上一個 `for` / `while` |
| `%` | 在配對的 `( ) { } [ ]` 之間跳 |
| `[{` / `]}` | 跳到包住游標的大括號開頭 / 結尾 |

### LSP 還是 cscope？

| 情境 | 用哪個 |
|---|---|
| 有 `compile_commands.json`（跑過 `mkidx` 或 `bear -- make`） | **LSP**：`gd` / `gr` / `<Space>lr`，最精確 |
| 只有 Makefile、巨大專案、交叉編譯、clangd 跑不起來 | **cscope**：`<Space>cg` / `<Space>cc` |
| 想看 `#ifdef` 沒編到的那一半 | **cscope**（LSP 看不到沒編進去的分支） |
| 要安全改名 | **LSP** `<Space>lr` |

---

## 3. 大批選取

### 選一個單字 ⭐ 小寫 `w` 與大寫 `W` 的差別

以 `dev->ops->read(buf, len);` 游標在 `dev` 為例（實測）：

| 按鍵 | 選到 | 什麼時候用 |
|---|---|---|
| `viw` | `dev` | 只要**變數名**（遇到 `-` `>` `(` `,` 就停） |
| **`viW`** | `dev->ops->read(buf,` | **到空白為止**（只有空白讓它停） |
| `vaW` | `dev->ops->read(buf, ` | 同上 + 後面空白 |
| `ve` / `vE` | 游標到字尾 / 到「空白前」的尾 | `v3e` 一次吃 3 個字 |

更多實測：

| 原文 | 游標在 | `viw` | `viW` |
|---|---|---|---|
| `char *p_name` | `p` | `p_name` | `*p_name` |
| `#define MAX_BUF_SIZE` | `M` | `MAX_BUF_SIZE` | `MAX_BUF_SIZE` |
| `"hello world"` | `h` | `hello` | `"hello` |
| `foo_bar(a, b);` | `f` | `foo_bar` | `foo_bar(a,` |

**在 visual 裡繼續擴展**（取代連按方向鍵）：

| 按鍵 | 效果（實測） |
|---|---|
| 再按 `iw` | `viw`→`dev`，`viwiw`→`dev->`，`viwiwiw`→`dev->ops` |
| `e` / `3e` | 擴到下一個字尾 / 一次擴 3 個 |
| `t(` / `f(` | 擴到 `(` 之前 / 含 `(` |
| `$` / `g_` / `^` | 擴到行尾 / 行尾(不含尾端空白) / 行首 |

### ⭐ 要改/刪/複製 → 不用先選

`v` 只是為了「看到範圍」。目的是處理文字的話，直接 `動作 + 範圍`：

| 不要這樣 | 直接這樣 |
|---|---|
| `viw` → `d` | **`diw`** |
| `viw` → `c` | **`ciw`** ← 改變數名最常用 |
| `viW` → `y` | **`yiW`** |
| `vi(` → `d` | **`di(`** 清空參數列 |

### 基本

| 按鍵 | 功能 |
|---|---|
| `v` | 字元選取 |
| `V` | **整行**選取 |
| `<C-v>` | **區塊（直行）選取** — 只適合「多行同一欄」，選單一個字用小寫 `v` |
| `<Space>a` | 全選整個檔案 |
| `gv` | 重新選取上一次的 visual 區塊 |
| `gV` | 選取剛剛貼上 / 修改的區塊 |
| `gnn` | **語法層選取**：從游標開始 |
| `<CR>` | （在 visual 中）往外擴一層：變數 → 表達式 → 整行 → block → 整個 function |
| `<BS>` | （在 visual 中）縮回一層 |

### 語法級文字物件（搭配 `v` / `d` / `y` / `c` 使用）

> 以下是 **C 檔案實測可用** 的清單（treesitter 的 C query 有定義的才列）。

| 物件 | 範圍 | 例 |
|---|---|---|
| `af` / `if` | **整個 function** / function 的 body | `vaf` 選整個函式、`dif` 清空函式內容 |
| `ac` / `ic` | 整個 `struct`/`union`/`enum` / 其欄位部分 | `vac` 選整個結構體 |
| `ai` / `ii` | 整個 `if`/`switch` / **它的條件式** | `cii` 直接改條件、`dai` 刪整個 if |
| `al` / `il` | 整個 `for`/`while`/`do` / 迴圈 body | `val` 選整個迴圈、`dil` 清空迴圈內容 |
| `aa` / `ia` | 一個參數（含逗號）/ 參數本身 | `daa` 刪掉一個參數、`cia` 改參數 |
| `ab` | `{ … }` 區塊（含大括號） | `vab` 選整塊 |
| `am` | 一個函式呼叫 `foo(a, b)` | `dam` 刪掉整個呼叫 |
| `a/` | 整段註解 | `da/` 刪掉註解區塊 |

> ⚠ C 的 treesitter query **沒有** `ib`（inner block）。要選大括號「內部」請用內建的 `i{`。

### 內建文字物件

| 物件 | 範圍 | 例 |
|---|---|---|
| `iw` / `aw` | 一個字 / 含空白 | `ciw` 改掉這個字 |
| `i"` `a"` `i'` `i\`` | 引號內 / 含引號 | `ci"` 改字串內容 |
| `i(` `i)` `ib` | 小括號內 | `di(` 清空參數列 |
| `i{` `i}` `iB` | 大括號內 | `yi{` 複製整個 block |
| `i[` `i]` | 中括號內 | |
| `it` / `at` | tag 內 | |
| `ip` / `ap` | 一個段落 | `vap` 選整段 |

> 口訣：`動作` + `i/a` + `範圍`。`i`=inner（內部），`a`=around（含邊界）。
> 例：`ci(` = 改小括號內容、`ya{` = 複製含大括號的整塊、`vaf` = 選整個函式。

### 多光標（vim-visual-multi）

| 按鍵 | 功能 |
|---|---|
| `<C-n>` | 選游標下的字，再按一次跳到下一個同名並一起選 |
| `<C-a>` | 一次選取檔案內**所有**同名 |
| `<C-x>` | 跳過這一個（不選它）— **只在多光標模式中有效** |
| `<C-p>` | 取消上一個加入的 — **只在多光標模式中有效** |
| `<C-Down>` / `<C-Up>` | 往下 / 往上多加一個光標 |
| 然後 `c` `i` `I` `A` `d` | 同時編輯所有光標處 |
| `<Esc>` | 離開多光標模式 |

---

## 4. 大批註解

| 按鍵 | 功能 |
|---|---|
| `gcc` | 註解 / 取消註解**本行** |
| `5gcc` | 註解**往下 5 行** |
| `gc` + 動作 | 註解一個範圍 |
| `gcap` | 註解整個段落 |
| `gcG` | 從這行註解到檔尾 |
| `gcif` | 註解整個 function 的 body |
| `gcil` | 註解整個迴圈 body |
| `gc`（visual） | 註解選取的行 |
| `<Space>/` | 同 `gcc` / visual 的 `gc` |
| `<C-/>` | 同上（部分終端送出的是 `<C-_>`，兩個都綁了） |

> Neovim 內建只有行註解（`gc` 系列），**沒有** `gb` 區塊註解。
> C 要產生 `/* */` 包住多行，用 `V` 選 → `ysS*`（surround）或手動。

> 常用組合：`V` 選幾行 → `j`/`k` 調範圍 → `gc`。或直接 `10gcc`。

---

## 5. 大批位移 / 縮排

| 按鍵 | 功能 |
|---|---|
| `<A-j>` / `<A-k>` | **本行往下 / 往上搬移**（normal 與 insert 都可） |
| `<A-j>` / `<A-k>` | **選取區整塊往下 / 往上搬移**（visual） |
| `J` / `K`（visual） | 同上（終端吃掉 Alt 鍵時的備用鍵） |
| `>>` / `<<` | 本行增加 / 減少縮排 |
| `3>>` | 往下 3 行一起縮排 |
| `>` / `<`（visual） | 選取區縮排（**按完仍保持選取，可連按**） |
| `<Tab>` / `<S-Tab>`（visual） | 同上 |
| `==` | 自動修正本行縮排 |
| `=ap` | 自動修正整段縮排 |
| `=G` | 自動修正到檔尾 |
| `gg=G` | **自動修正整個檔案縮排** |
| `<Space>sa` / `<Space>sA` | 把參數往後 / 往前換位置 |
| `ga` + 字元（visual） | **對齊**：如 `ga=` 對齊等號、`ga,` 對齊逗號 |

> 搬移整塊程式：`V` 選行 → `<A-j>` / `<A-k>`（縮排會自動跟著調整）。

---

## 6. 批次包圍 / 改括號（nvim-surround）

| 按鍵 | 功能 |
|---|---|
| `ysiw"` | 把一個字包成 `"字"` |
| `yss)` | 把整行包成 `(…)` |
| `ysaf{` | 把整個 function 包進 `{…}` |
| `S"`（visual） | 把選取範圍包成 `"…"` |
| `cs"'` | 把 `"…"` 改成 `'…'` |
| `cs({` | 把 `(…)` 改成 `{…}` |
| `ds"` | 刪掉外面的 `"` |

---

## 7. 編譯與錯誤處理

| 按鍵 | 功能 |
|---|---|
| `<Space>mm` | 存檔 + `make`，錯誤自動進 quickfix |
| `<Space>mc` | `make clean` |
| `<Space>ma` | `make <target>`（會問 target） |
| `<Space>mb` | **`bear -- make` 產生 `compile_commands.json`** 並重啟 LSP |
| `<Space>mf` | 產生 `compile_flags.txt`（沒有 bear 時的後備方案） |
| `<Space>mt` | 重建 `cscope.out` + `tags` |
| `]q` / `[q` | **下一個 / 上一個編譯錯誤** |
| `]Q` / `[Q` | 最後 / 第一個 |
| `<Space>qo` / `<Space>qc` | 開 / 關 quickfix 視窗 |
| `<Space>ql` | quickfix（Trouble 漂亮 UI） |
| `:make -j8` | 手動指定參數 |

> 在 quickfix 視窗裡：`<CR>` 跳過去、`q` 關閉。

---

## 8. 診斷（錯誤 / 警告）

| 按鍵 | 功能 |
|---|---|
| `<Space>d` | 顯示本行的診斷訊息（浮窗） |
| `]d` / `[d` | 下一個 / 上一個診斷 |
| `]e` / `[e` | 下一個 / 上一個**錯誤**（跳過警告） |
| `<Space>dl` | 全專案診斷清單（Trouble） |
| `<Space>db` | 本檔診斷清單 |
| `<Space>dt` | 開 / 關診斷顯示（畫面太亂時關掉） |
| `<Space>ds` | 診斷丟進 location list |
| `<Space>la` | Code Action — 自動修正 |

---

## 9. 視窗 / 分割 / buffer

| 按鍵 | 功能 |
|---|---|
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | 在分割視窗間移動 |
| `<Space>sv` / `<Space>sh` | 垂直 / 水平分割 |
| `<Space>sq` | 關閉這個分割 |
| `<Space>so` | 只留這個分割 |
| `<C-Left>` / `<C-Right>` | 視窗變窄 / 變寬 |
| `<C-Up>` / `<C-Down>` | 視窗變高 / 變矮 |
| `<Tab>` / `<S-Tab>` | 下一個 / 上一個 buffer |
| `<Space>x` | 關閉 buffer |
| `<Space>b` | 新 buffer |
| `<Space><Space>` | 切換上一個檔案 |
| `F9` / `F10` | 開關 / focus 檔案樹 |

### 內建終端

| 按鍵 | 功能 |
|---|---|
| `<A-i>` | 浮動終端 |
| `<A-h>` / `<A-v>` | 水平 / 垂直終端 |
| `<C-x>` | 從終端模式回到 normal（在終端裡按） |

---

## 10. 其他常用

| 按鍵 | 功能 |
|---|---|
| `<C-s>` | 存檔 |
| `;` | 等於 `:`（不用按 Shift） |
| `jk` | insert 模式離開（等於 `<Esc>`） |
| `<Space>Q` | 全部離開 |
| `<Space>y` | 複製到系統剪貼簿 |
| `<Space>p`（visual） | 貼上但**不覆蓋**剪貼簿內容 |
| `<Space>+` / `<Space>-` | 數字 +1 / -1（原本的 `<C-a>` 給多光標用了） |
| `<Space>n` / `<Space>rn` | 開關行號 / 相對行號 |
| `<Space>ch` | NvChad 內建快捷鍵表 |
| `<Space>fk` | **搜尋所有快捷鍵** |
| `<Space>wK` | which-key 列出全部 |
| `u` / `<C-r>` | 復原 / 重做（關掉 nvim 後仍保留歷史） |
| `.` | 重複上一個動作 |
| `zz` / `zt` / `zb` | 把游標行移到畫面中 / 上 / 下 |

---

## 11. 常見問題

**`<Space>fw` 全域搜尋沒反應 / 搜不到東西**
→ **先確認 `:pwd`**。全域搜尋是從 nvim 的工作目錄往下找。在家目錄打
   `nvim ~/work/proj/main.c` 會去搜整個家目錄。正確：`cd ~/work/proj` 再 `nvim`；
   已經開著就 `:cd ~/work/proj`。
→ `ripgrep` 沒安裝。`sudo apt install ripgrep`，然後 `:checkhealth telescope` 確認。
   注意：shell 裡打 `rg` 有反應不代表真的裝了（可能是 shell function），用 `command -v rg` 確認。

**按了某個鍵完全沒反應，怎麼查**
→ `:verbose nmap <Space>fw`（normal）/ `:verbose xmap <Space>fw`（visual）
   —— 會說綁到什麼、在哪個檔案第幾行設的；沒綁會回 `No mapping found`。
→ **最常見原因：那個鍵只綁了 normal 模式。**
→ 或 `<Space>fk` 模糊搜尋所有鍵位。

**`gr` 只列出當前檔案，其他檔案的參考都沒出現**
→ **缺 `compile_commands.json`**。clangd 要有它才知道專案裡有哪些編譯單元可以建索引。
   實測同一專案：有它 → `gr` 找到 4 筆（跨 4 檔）；只有 `compile_flags.txt` → 只 1 筆。
→ 解法：`<Space>mb`（或終端 `mkidx`），再 `<Space>lR` 重啟 LSP。
→ 第一次開大專案，clangd 的 background index 要跑幾秒到幾十秒，太早按會不全。

**手動跑 `bear -- make`，compile_commands.json 不完整**
→ **要先 `make clean`**。`.o` 檔還在的話 make 會說 nothing to be done，bear 攔不到東西。
   實測沒 clean 只抓到 1 個編譯單元，clean 後抓到 3 個。
→ 正確：`make clean && bear -- make`，或用 alias `mbc`。
→ `<Space>mb` 和 `mkidx` 已經自動先 clean，不用自己記。

**`gd` 跳不過去 / `gr` 找不到參考**
→ clangd 缺 `compile_commands.json`。在專案根目錄跑 `mkidx`（或 `<Space>mb`）。
→ 檢查：`:LspInfo`（`<Space>lI`）看 clangd 是否 attached、root_dir 對不對。
→ 退一步用 `<Space>mf` 產生 `compile_flags.txt`，或直接改用 cscope（`<Space>cg`）。

**cscope 查不到東西**
→ 沒有 `cscope.out`。跑 `mkidx` 或在 nvim 裡 `<Space>mt`（`:TagsBuild`）。
→ `:Cs db show` 看現在連到哪個資料庫。
→ 新增檔案後要重建：`<Space>mt`。

**`<A-j>` 搬移整行沒反應**
→ 終端把 Alt 吃掉了。用 visual 模式的 `J` / `K` 代替，或在終端設定裡開啟
   「Use Alt as Meta key」（Windows Terminal / WSL 常見）。

**顏色不對 / 很醜**
→ 在 tmux 裡要 `set -g default-terminal "tmux-256color"`（已在 `.tmux.conf.local` 設好）。
→ `:checkhealth` 看 `termguicolors` 警告。

**啟動變慢**
→ `nvim --startuptime /tmp/st.txt` 看哪個外掛慢；`:Lazy profile` 看載入時間。

**想看完整健康檢查**
→ `:checkhealth`
