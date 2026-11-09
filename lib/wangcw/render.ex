defmodule CunweiWong.Render do
  @moduledoc false
  use Phoenix.Component
  alias CunweiWong.Content
  import Phoenix.HTML

  def format_post_date(date), do: Calendar.strftime(date, "%Y.%m.%d")

  def post(assigns) do
    ~H"""
    <.layout title={"#{@title} — #{Content.site_title()}"} route={@route} description={@description || Content.site_description()}>
      <article>
        <header class="article-header">
          <time datetime={Date.to_iso8601(@date)}><%= format_post_date(@date) %></time>
          <h1><%= @title %></h1>
        </header>
        <div class="prose prose-zinc dark:prose-invert"><%= raw(@body) %></div>
      </article>
    </.layout>
    """
  end

  def index(assigns) do
    ~H"""
    <.layout title={Content.site_title()} route="/">
      <h1 class="site-title"><%= Content.site_title() %></h1>
      <.post_list posts={@posts} />
      <a class="archive-link" href="/archive/">归档 <span aria-hidden="true">↗</span></a>
    </.layout>
    """
  end

  def archive(assigns) do
    groups = assigns.posts |> Enum.group_by(& &1.date.year) |> Enum.sort_by(&elem(&1, 0), :desc)
    assigns = Map.put(assigns, :groups, groups)

    ~H"""
    <.layout title={"归档 — #{Content.site_title()}"} route="/archive/">
      <h1 class="site-title">归档</h1>
      <section :for={{year, posts} <- @groups} class="archive-year">
        <h2><%= year %></h2>
        <.post_list posts={posts} />
      </section>
    </.layout>
    """
  end

  attr(:posts, :list, required: true)

  def post_list(assigns) do
    ~H"""
    <ol class="post-list">
      <li :for={post <- @posts}>
        <a href={post.route}>
          <time datetime={Date.to_iso8601(post.date)}><%= format_post_date(post.date) %></time>
          <span><%= post.title %></span>
        </a>
      </li>
    </ol>
    """
  end

  def page(assigns) do
    ~H"""
    <.layout title={"#{@title} — #{Content.site_title()}"} route={@route}>
      <h1 class="site-title"><%= @title %></h1>
      <article class="prose prose-zinc dark:prose-invert"><%= raw(@body) %></article>
    </.layout>
    """
  end

  attr(:title, :string, required: true)
  attr(:route, :string, required: true)
  attr(:description, :string, default: Content.site_description())
  slot(:inner_block, required: true)

  def layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="utf-8" />
        <title><%= @title %></title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="author" content={Content.site_author()} />
        <meta name="description" content={@description} />
        <meta name="color-scheme" content="light dark" />
        <meta property="og:title" content={@title} />
        <meta property="og:description" content={@description} />
        <meta property="og:url" content={Content.site_url() <> @route} />
        <link rel="canonical" href={Content.site_url() <> @route} />
        <link rel="stylesheet" href="/assets/app.css" />
        <link rel="icon" href="/favicon.ico" />
      </head>
      <body>
        <div class="site-shell">
          <header class="site-header">
            <a class="brand" href="/">wangcw<span aria-hidden="true">.</span></a>
            <nav aria-label="主导航">
              <a :for={{label, path} <- [{"主页", "/"}, {"归档", "/archive/"}, {"关于", "/about/"}]} href={path} aria-current={if @route == path, do: "page", else: nil}><%= label %></a>
            </nav>
          </header>
          <main><%= render_slot(@inner_block) %></main>
          <footer class="site-footer">© <%= Date.utc_today().year %> wangcw</footer>
        </div>
      </body>
    </html>
    """
  end

  def redirect(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN">
      <head>
        <meta charset="utf-8" />
        <title><%= Content.site_title() %></title>
        <link rel="canonical" href={@target} />
        <meta name="robots" content="noindex" />
        <meta http-equiv="refresh" content={"0; url=#{@target}"} />
      </head>
      <body><a href={@target}><%= Content.site_title() %></a></body>
    </html>
    """
  end
end
