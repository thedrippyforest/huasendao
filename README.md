# 花森島《好好吃頓飯》Project Hub 多人協作版

這是一個可真正多人同步的版本，使用 Supabase：
- Email/密碼登入
- 共用任務資料庫
- 即時同步任務、甘特圖、會議與會議摘要
- 每個人可切換只看自己的工作
- 邦尼可看全案追蹤台
- 會議決議可直接建立甘特任務

## 建置步驟

### 1. 建立 Supabase 專案
到 Supabase 建立一個新專案。

### 2. 建立資料表
進入 SQL Editor，依序執行：
1. `schema.sql`
2. 若你想直接用 SQL 匯入初始任務，再執行 `seed_tasks.sql`

若 Supabase 已開啟 Row Level Security，匿名 public key 不能直接匯入資料。這時可以改用 `setup.html`：

1. 先建立至少一個團隊帳號
2. 用本機網址開啟 `setup.html`
3. 登入後按「匯入初始任務」
4. 完成後回到 `index.html` 使用正式平台

### 3. 設定前端
把 `config.example.js` 複製成 `config.js`，填入：
- Project URL
- anon public key

這兩個值在 Supabase：
Project Settings → API

### 4. 本機預覽
使用任何簡單靜態伺服器開啟，例如：

```bash
python3 -m http.server 8080
```

然後開啟：
`http://localhost:8080`

初始匯入頁：
`http://localhost:8080/setup.html`

不要直接用 file:// 開啟，登入與模組載入可能被瀏覽器限制。

### 5. 建立四個帳號
四位夥伴各自用自己的 Email 註冊：
- 邦尼
- maomao
- 小花果
- 物物島

可在 Supabase Authentication → Users 查看。

### 6. 上線
可部署到：
- Netlify
- Vercel
- Cloudflare Pages
- GitHub Pages

只要上傳整個資料夾即可。

本專案 GitHub repository：
`https://github.com/thedrippyforest/huasendao`

GitHub Pages 啟用後，正式網址通常會是：
`https://thedrippyforest.github.io/huasendao/`

## 權限說明
目前所有已登入成員都可以新增、編輯、刪除全部任務，適合四人小團隊快速協作。

若之後要限制：
- 邦尼可編輯全部
- 各組只能編輯自己任務
可以再收緊 Row Level Security 政策。

## 重要
`config.js` 使用的是 anon public key，可以放在前端；不要把 Supabase service_role key 放到網站。

## 已完成連線設定

本版本已填入：
- Supabase URL
- Supabase Publishable Key

接下來請依序完成：

1. 在 Supabase SQL Editor 執行 `schema.sql`
2. 再執行 `seed_tasks.sql`
3. 確認 Table Editor 中出現：
   - profiles
   - tasks
   - meetings
   - meeting_summaries
   - activity_log
4. 若 `tasks` 是空的，開啟 `setup.html` 登入後匯入初始任務
5. 使用靜態網站服務開啟本資料夾，不要直接雙擊 file://
6. 建議部署到 GitHub Pages、Netlify、Vercel 或 Cloudflare Pages

測試帳號流程：
- 四位夥伴分別註冊
- 完成 Email 驗證
- 登入後即可共同編輯
