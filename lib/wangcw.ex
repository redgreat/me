defmodule CunweiWong do
  @moduledoc """
  All functionality for rendering and building the site
  """

  require Logger
  alias CunweiWong.Content
  alias CunweiWong.Render

  @output_dir "./output"

  def assert_uniq_page_ids!(pages) do
    ids = pages |> Enum.map(& &1.id)
    dups = Enum.uniq(ids -- Enum.uniq(ids))

    if dups |> Enum.empty?() do
      :ok
    else
      raise "Duplicate pages: #{inspect(dups)}"
    end
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
    pages = Content.all_pages()
    all_posts = Content.all_posts()
    all_routes = Content.all_routes()
    about_page = Content.about_page()
    assert_uniq_page_ids!(pages)
    render_file("index.html", Render.index(%{posts: Content.active_posts()}))
    render_file("404.html", Render.page(Content.not_found_page()))
    render_file(about_page.html_path, Render.page(about_page))
    render_file("archive/index.html", Render.archive(%{posts: all_posts}))
    render_file("routes/index.html", Render.routes(%{routes: all_routes}))
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

  defp route_file do
    src_dir = Path.join(File.cwd!(), "pages/routes")
    tar_dir = Path.join(@output_dir, "routes")

    if File.exists?(src_dir) do
      File.mkdir_p!(tar_dir)
      File.cp_r!(src_dir, tar_dir)
      Logger.info("Copied all HTML files to #{tar_dir}")
    else
      Logger.warning("HTML source directory #{src_dir} does not exist. Skipping copy.")
    end
  end

  def build_all() do
    Logger.info("Clear output directory")
    File.rm_rf!(@output_dir)
    File.mkdir_p!(@output_dir)
    Logger.info("Copying static files")
    File.cp_r!("assets/static", @output_dir)
    Logger.info("Copying Routes files")
    route_file()
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
