个人博客

很多方便好用的开源md解析博客应用，但是想学习下elixir，fork了这个仓，利用vercel免费部署静态网页，希望后期能坚持更新文章。

## 结构

- `pages/` 发布文章
- `assets/` 图片等多媒体资源
- `lib/` 生成html代码
- `output/` 静态网页


## 运行

- `mix deps.get` 安装依赖
- `mix compile` 编译
- `iex -S mix` 本地运行


## Acknowledgement

Thanks to [fly.io's post on SSG using Elixir](https://fly.io/phoenix-files/crafting-your-own-static-site-generator-using-phoenix/) for helping me getting started.

Implements By [Jorin's personal blog](https://github.com/jorinvo/me).


## License

[![Creative Commons Attribution-ShareAlike 3.0 Unported License](https://licensebuttons.net/l/by-sa/3.0/80x15.png)](https://creativecommons.org/licenses/by-sa/3.0/)

The content is licensed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](https://creativecommons.org/licenses/by-sa/3.0/). The code is licensed under the [MIT license](https://opensource.org/licenses/MIT).