defmodule CunweiWong do
  @moduledoc """
  All functionality for rendering and building the site
  """

  require Logger
  alias CunweiWong.Content
  alias CunweiWong.Render

  @output_dir "./output"

  @doc """
  对页面按 id 去重，当存在重复 id 时保留日期最早的一篇，忽略较晚的
  """
  def dedup_by_id(posts) do
    ids = posts |> Enum.map(& &1.id)
    dups = Enum.uniq(ids -- Enum.uniq(ids))

    if not Enum.empty?(dups) do
      Logger.warning("Duplicate page ids found, keeping earliest: #{inspect(dups)}")
    end

    posts
    |> Enum.reverse()
    |> Enum.uniq_by(& &1.id)
    |> Enum.reverse()
  end

  def render_posts(posts) do
    for post <- posts do
      render_file(post.html_path, Render.post(post))
    end
  end

  def render_redirects(redirects) do
    for {path, target} <- redirects do
      render_file(path, Render.redirect(%{target: target}))
    end
  end

  def build_pages() do
    all_posts = Content.all_posts() |> dedup_by_id()
    about_page = Content.about_page()
    active_posts = Content.active_posts() |> dedup_by_id()
    render_file("index.html", Render.index(%{posts: active_posts}))
    render_file("404.html", Render.page(Content.not_found_page()))
    render_file(about_page.html_path, Render.page(about_page))
    render_file("archive/index.html", Render.archive(%{posts: all_posts}))
    render_file("routes/index.html", Render.routes(%{routes: []}))
    render_posts(all_posts)
    render_redirects(Content.redirects())
    :ok
  end

  def write_file(path, data) do
    dir = Path.dirname(path)
    output = Path.join([@output_dir, path])

    if dir != "." do
      File.mkdir_p!(Path.join([@output_dir, dir]))
    end

    File.write!(output, data)
  end

  def render_file(path, rendered) do
    safe = Phoenix.HTML.Safe.to_iodata(rendered)
    write_file(path, safe)
  end

  def build_all() do
    Logger.info("Clear output directory")
    File.rm_rf!(@output_dir)
    File.mkdir_p!(@output_dir)
    Logger.info("Copying static files")
    File.cp_r!("assets/static", @output_dir)
    Logger.info("Building pages")

    {micro, :ok} =
      :timer.tc(fn ->
        build_pages()
      end)

    ms = micro / 1000
    Logger.info("Pages built in #{ms}ms")
    Logger.info("Running tailwind")
    # Using mix task because it installs tailwind if not available yet
    Mix.Tasks.Tailwind.run(["default", "--minify"])
  end
end
