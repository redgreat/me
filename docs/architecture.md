# 架构评估与演进

评估日期：2026-11-09。

## 当前系统

Elixir + NimblePublisher 读取 Markdown，Phoenix.Component 生成静态 HTML，Tailwind 生成 CSS，Vercel 托管输出。使用 HEEx 并不等于拥有 Phoenix 后台或 LiveView 会话。没有文章编辑后台、登录、素材管理、公众号适配器或发布记录。适合继续作为个人博客，没必要因为 TS/Python 流行就重写。

依赖核查确认 NimblePublisher 2.2 使用 MDEx，已清除未使用的 Earmark、YAML、XML 和 HTML sanitizer 依赖，改用实际生效的 comrak_options。Hex 对旧 phoenix_html 4.3.0 报告安全公告，已定向升级到 4.4.0。

此次保留文章路径和源内容，合并布局和列表组件，去掉地图页面与数据接口，拆分显式构建/预览命令，修正归档 canonical。主页在去重后取 20 篇，避免先截断导致展示数量不足。数据库迁移停止随博客部署执行，历史 SQL 保留，不操作已有数据库。

## 公众号

可以共用文章源，但当前站点不能直接充当公众号发布后台。推荐先做独立的 Elixir 命令行适配器：Markdown → 微信专用 HTML/内联样式 → 图片和封面素材 → 草稿 → 人工审核 → 提交发布 → 查询最终状态。博客样式不能原样假定在微信中可用。发布与群发应视为独立操作。

账号是否拥有草稿/发布权限，必须在实际公众号后台核实。此次无法读取微信官方接口文档正文，也未读取账号权限，不能承诺个人账号能自动发布。不需要现在提供密钥。

未来需增加：仅服务端保存 AppSecret/token、token 缓存与互斥刷新、图片内容哈希、源文件版本、草稿 ID、发布 ID、失败记录、超时后状态确认和防重复发布。不能因网络超时就盲目重新提交发布。不要将凭证放在静态产物或 Git。先解决图片完整性和排版，再接 API；如果无发布权限，采用 HTML 导出后人工发布。

只有确实需要浏览器编辑、定时发布和任务历史时，再引入 Phoenix/LiveView + PostgreSQL + 持久任务队列。常驻 BEAM 服务单独部署在适合运行服务的主机上，公开博客继续静态托管。进程重启能力不等于任务数据持久化，不能只靠 GenServer 内存保存发布状态。

官方接口入口（待接入时核实权限和契约）：
- https://developers.weixin.qq.com/doc/service/api/draftbox/draftmanage/api_draft_add
- https://developers.weixin.qq.com/doc/service/api/public/api_freepublish_submit
- https://developers.weixin.qq.com/doc/service/api/public/api_freepublish_get

## Zotonic 借鉴

参考 https://github.com/zotonic/zotonic 和 https://zotonic.com/developer-guide 。Zotonic 是 Erlang Web Framework 与 CMS，应用、模块、模型、控制器、模板分工明确，有资源及关联关系、媒体管理、权限边界、事件通知等机制。

值得学习的是内容与展示解耦、复用模板、把媒体当作独立资源、在服务边界校验权限、通过独立模块扩展发布渠道。对于几百篇 Markdown 的个人博客，不需要照搬通用资源图谱、多站点和完整 CMS。将来真需要成熟编辑后台且愿意维护 Erlang 系统时，才比较直接用 Zotonic 与自建 Phoenix 后台的成本。

## Erlang / Elixir / OCaml 的价值

Erlang 的进程、消息、监督树和故障隔离知识直接适用于 Elixir/OTP。适合个人设备连接、MQTT 消息处理、实时状态、任务协调和长期运行的服务。单纯静态博客没有高并发运行时需求，不必为了使用 OTP 而制造复杂度。

Elixir 可以继续做博客生成与后续发布工作流；Python 承担数据处理/模型 SDK，TS 承担确实需要复杂交互的客户端。语言按职责选择，没必要每个项目都集齐。OCaml 的代数数据类型、模式匹配与不可变数据经验对建模发布状态、解析配置、编译/转换流程仍然有用，但目前没有理由给博客增加 OCaml 服务。

## 后续优化优先级

1. 修复文章中的缺失本地图片：已有文章引用 image-1.png、image-2.png 等文件，需补原图或改正确地址，不能凭空生成替代技术截图。
2. 构建发现 12 组重复文章 ID，沿用保留最早一篇的兼容规则。检查重复选题、内容准确性与文章标题质量；源文章不自动删改。
3. 再按需求补 RSS、sitemap、全文搜索、草稿/预约发布日期。日期过滤需要约定时区和触发重建策略，不能只加字段便称为定时发布。
4. 若扩大内容来源，替换可执行 Elixir frontmatter 为安全的数据格式，并制定 HTML 白名单；当前仅支持可信仓库内容。
5. 明确内容许可证：README 为 CC BY-SA 3.0，旧 Content.site_copyright 为 4.0，未擅自改动授权。



## 本次验证

- 本机临时 Elixir 1.19.5 / 已安装 OTP 29，CI 配置仍为 OTP 28；本次没有运行远程 CI 或部署。
- `mix test`：4 项通过；`mix credo`、`mix format --check-formatted` 通过；`mix hex.audit` 无退休包或安全公告。
- 静态构建生成 397 个 HTML。GitHub 独立 Tailwind 二进制下载过慢，本地改用临时 npm 安装的同版 Tailwind 3.2.4，通过运行时路径覆盖完成同一构建流程；仓库默认构建方式不变。
- Chromium 检查主页、归档、关于及中文文章路由均为 200，不存在路径与已删除轨迹路径为 404。390px 手机宽度无横向溢出，浅色主页、深色文章已截图检查，没有页面 JavaScript 错误。
- 未接入公众号，未验证其账号权限，未发布到生产环境。
