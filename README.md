# 个人博客

Elixir 生成的静态个人博客。Markdown 为内容源，HEEx 渲染页面，Tailwind 处理样式，Vercel 托管静态输出。

## 开发

使用 Elixir 1.19 / Erlang OTP 28（与 CI 一致）。

```sh
mix deps.get
mix site.check
mix site.build
mix site.serve
```

`mix site.check` 检查 Frontmatter 标题与日期、重复章节、代码围栏、图表代码块及本地图片，并指出文章文件和行号。会导致构建失败的问题以错误结束命令；缺图、机器本地路径及重复文章 URL ID 会给出警告，避免历史文章阻断整站发布。`mix site.build` 先执行同一检查，再生成页面并确认 HTML 产物完整。提交后 GitHub Actions 会运行 `mix site.build`，通过后才继续 Vercel 部署。预览：http://localhost:8093。构建不会启动服务器。

```sh
mix format --check-formatted
mix test
mix credo
```

## 结构

- `pages/posts/`：文章，文件名 `YYYY-MM-DD-文章ID.md`，保留 ID 以保持链接稳定。
- `pages/about.md`、`pages/404.md`：独立页面。
- `lib/wangcw/`：内容模型、渲染和预览服务。
- `lib/mix/tasks/`：构建与预览命令。
- `assets/`：样式、字体、图片。
- `output/`：静态生成物，不提交。
- `migrations/`：停用的轨迹功能历史 SQL，不再随博客部署执行。
- `AGENTS.md`：AI 开发入口与项目约束。
- `docs/architecture.md`：公众号、Zotonic 与语言选择评估。

文章元数据为 Elixir map，以 `---` 分隔正文，只允许可信内容。公众号发布尚未实现。

## 部署

`vercel.json` 执行 `mix deps.get && mix site.build`，输出 `output/`。GitHub Actions 使用锁定依赖，验证格式和代码质量，再构建部署。博客不再需要数据库或 Node 运行时接口；CI 的 Node 仅用于 Vercel CLI。

## Acknowledgement

源于 [Fly.io 的 Elixir SSG 文章](https://fly.io/phoenix-files/crafting-your-own-static-site-generator-using-phoenix/) 与 [Jorin 的个人博客](https://github.com/jorinvo/me)。

## License

内容：[CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)。代码：[MIT](https://opensource.org/licenses/MIT)。
