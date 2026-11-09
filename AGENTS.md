# AI 开发入口

## 定位与边界
这是单作者的 Elixir 静态个人博客，不是 Phoenix 在线 CMS。保留 Markdown 内容和已有文章 URL，不迁移 TS/Python，不引入数据库、账号系统或前端 SPA。公众号只做架构评估；未实现、未授权的发布能力不能声称可用。

## 阅读顺序
README.md → lib/wangcw/page.ex → lib/wangcw/content.ex → lib/wangcw/render.ex → lib/wangcw.ex。架构决策见 docs/architecture.md。

## 职责
- pages/posts：可信仓库内容，Elixir map 元数据 + `---` + Markdown。元数据会执行 Elixir 表达式，绝不能直接接收外部不可信投稿。
- Page：解析日期、稳定 ID 和输出路径。
- Content：聚合文章和站点配置。
- Render：HEEx 页面、共享布局和列表组件。
- CunweiWong：静态文件构建；不得在模块编译时执行构建。
- Mix.Tasks.Site.Build / Site.Serve：独立构建与本地预览。
- assets/app.css：排版、响应式、明暗主题；output 为生成物。

## 设计约束
纯个人博客，只保留主页、归档、关于和文章。不要添加口号、副标题、教学说明、装饰性小字、标签堆叠或轨迹展示。必要的导航、日期及可访问名称可以保留。正文使用系统字体，代码使用等宽字体。不要擅自改写文章或批量删除内容。

## 验证
`mix deps.get`、`mix format --check-formatted`、`mix test`、`mix site.build`、`mix credo`。
本地预览 `mix site.serve`，地址 http://localhost:8093。检查主页、归档、文章、关于、404、中文路径、移动端和暗色主题。报告真实执行结果；不能把代码审查当作实际浏览器验证。
构建和测试不能启动 HTTP 服务。CI 使用 mix.lock，不在部署中升级依赖。发布生产环境必须有用户的发布指令。
