defmodule CunweiWong.Content do
  @moduledoc false

  alias CunweiWong.Page

  use NimblePublisher,
    build: Page,
    from: "./pages/**/*.md",
    as: :pages,
    highlighters: [:makeup_elixir, :makeup_js, :makeup_html],
    earmark_options: [breaks: true]

  def site_title() do
    "無糧不聚兵"
  end

  def site_description() do
    "个人博客"
  end

  def site_author() do
    "wangcw"
  end

  def site_url() do
    "https://me.wongcw.cn"
  end

  def site_email() do
    "rubygreat@msn.com"
  end

  def site_copyright() do
    "This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License."
  end

  def redirects() do
    %{
      "/post/index.html" => "/",
      "/posts/index.html" => "/"
    }
  end

  def all_posts do
    @pages |> Enum.filter(&(&1.type == :post)) |> Enum.sort_by(& &1.date, {:desc, Date})
  end

  def active_posts do
    all_posts() |> Enum.reject(& &1.archive)
  end

  def about_page do
    @pages |> Enum.find(&(&1.id == "about"))
  end

  def generate_slug(title) do
    title
    |> String.replace(~r/[^\w\s]/u, "")
    |> String.replace(" ", "-")
    |> String.downcase()
    |> URI.encode()
  end

  def page_url(page) do
    path = Path.join("pages", generate_slug(page.title) <> ".md")
    URI.encode(path)
  end

  def not_found_page do
    @pages |> Enum.find(&(&1.id == "404"))
  end

  def all_pages do
    [about_page()] ++ all_posts()
  end
end
