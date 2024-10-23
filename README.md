#
个人博客

## Structure

- `pages/` contains the markdown and YAML content I regularly publish
- `assets/` contains static content
- `lib/` contains the code generating the side
- `output/` is where the generated files are rendered


## Running

- `mix deps.get` to install dependencies
- `mix compile` compiles code and generates the site during the compile step. This runs on commits using a Github Action.
- `iex -S mix` runs a dev server serving the side for local development


## Acknowledgement

Thanks to [fly.io's post on SSG using Elixir](https://fly.io/phoenix-files/crafting-your-own-static-site-generator-using-phoenix/) for helping me getting started.

Implements By [Jorin's personal blog](https://github.com/jorinvo/me).


## License

[![Creative Commons Attribution-ShareAlike 3.0 Unported License](https://licensebuttons.net/l/by-sa/3.0/80x15.png)](https://creativecommons.org/licenses/by-sa/3.0/)

The content is licensed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](https://creativecommons.org/licenses/by-sa/3.0/). The code is licensed under the [MIT license](https://opensource.org/licenses/MIT).