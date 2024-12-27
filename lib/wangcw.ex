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

  defp copy_html_files do
    source_html_dir = Path.join(File.cwd!(), "pages/html")
    target_html_dir = Path.join(@output_dir, "html")

    if File.exists?(source_html_dir) do
      File.mkdir_p!(target_html_dir)
      File.cp_r!(source_html_dir, target_html_dir)
      Logger.info("Copied all HTML files to #{target_html_dir}")
    else
      Logger.warning("HTML source directory #{source_html_dir} does not exist. Skipping copy.")
    end
  end

  def build_all() do
    Logger.info("Clear output directory")
    File.rm_rf!(@output_dir)
    File.mkdir_p!(@output_dir)
    Logger.info("Copying static files")
    File.cp_r!("assets/static", @output_dir)
    Logger.info("Copying HTML files")
    copy_html_files()
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
