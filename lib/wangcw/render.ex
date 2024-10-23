defmodule CunweiWong.Render do
  @moduledoc false

  use Phoenix.Component
  alias CunweiWong.Content
  import Phoenix.HTML

  def format_iso_date(date = %DateTime{}) do
    DateTime.to_iso8601(date)
  end

  def format_iso_date(date = %Date{}) do
    date
    |> DateTime.new!(~T[06:00:00])
    |> format_iso_date()
  end

  def format_post_date(date) do
    Calendar.strftime(date, "%Y年%m月%d日")
  end

  def format_rss_date(date = %DateTime{}) do
    Calendar.strftime(date, "%a, %d %b %Y %H:%M:%S %z")
  end

  def format_rss_date(date = %Date{}) do
    date
    |> DateTime.new!(~T[06:00:00])
    |> format_rss_date()
  end

  def rss_post_limit() do
    20
  end

  def count_words(text) do
    text |> HtmlSanitizeEx.strip_tags() |> String.split() |> Enum.count()
  end

  def post(assigns) do
    ~H"""
    <.layout
      title={"#{@title} — #{Content.site_title()}"}
      description={@description}
      og_type="article"
      route={@route}
      date={@date}
      keywords={@keywords}
      wordcount={count_words(@description <>" " <> @body)}
    >
      <div class="post-header">
        <small class="post-meta"><span class="author">wangcw - </span><%= format_post_date(@date) %></small>
        <a href={@route}>
          <h1><%= @title %></h1>
        </a>
      </div>
      <article class="post-content">
        <p><%= @description %></p>
        <%= raw @body %>
      </article>
      <hr>
      <p class="text-center">
        文档发布时间: <%= format_post_date(@date) %>
      </p>
      <footer>
        <p class="text-center"></p>
      </footer>
      <script>
        document.querySelectorAll('code').forEach(function(el) {
          el.contentEditable = true
        })
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerP = document.querySelector('footer p');
          let link = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          footerP.innerHTML = "Copyright © " + link + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end

  def index(assigns) do
    ~H"""
    <.layout
      title={Content.site_title()}
      description={Content.site_description()}
      route="/"
      og_type="website"
    >
      <div class="posts">
        <a :for={post <- @posts} href={post.route} class="post-link alternate">
          <div class="post">
            <small class="post-meta"><%= format_post_date(post.date) %></small>
            <h2 class="post-title"><%= post.title %></h2>
            <div class="post-summary"><%= post.description %></div>
          </div>
        </a>
      </div>
      <hr />
      <p><i>阅读更多文章 <a href="/archive/">archive</a></i></p>
      <footer>
        <p class="text-center"></p>
      </footer>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerP = document.querySelector('footer p');
          let link = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          footerP.innerHTML = "Copyright © " + link + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end

  def archive(assigns) do
    ~H"""
    <.layout
      title={Content.site_title()}
      description={Content.site_description()}
      route="/"
      og_type="website"
    >
      <h1>Archive</h1>
      <div class="posts">
        <a :for={post <- @posts} href={post.route} class="post-link alternate">
          <div class="archive-post">
            <small class="post-meta"><%= format_post_date(post.date) %></small>
            <div class="post-summary"><%= post.title %></div>
          </div>
        </a>
      </div>
      <footer>
        <p class="text-center"></p>
      </footer>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerP = document.querySelector('footer p');
          let link = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          footerP.innerHTML = "Copyright © " + link + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end

  def page(assigns) do
    ~H"""
    <.layout
      title={"#{@title} — #{Content.site_title()}"}
      description={@description}
      og_type="website"
      route={@route}
    >
      <div class="post-header">
        <a href={@route}>
          <h1><%= @title %></h1>
        </a>
      </div>
      <article class="post-content">
        <%= raw @body %>
      </article>
      <footer>
        <p class="text-center"></p>
      </footer>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerP = document.querySelector('footer p');
          let link = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          footerP.innerHTML = "Copyright © " + link + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end

  def layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <title><%= @title %></title>
        <meta name="description" content={@description} />
        <meta name="author" content={Content.site_author()} />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link href="/index.xml" rel="alternate" type="application/rss+xml" title={Content.site_title()} />
        <meta name="ROBOTS" content="INDEX, FOLLOW" />
        <meta property="og:title" content={@title} />
        <meta property="og:description" content={@description} />
        <meta property="og:type" content={@og_type} />
        <meta property="og:url" content={"#{Content.site_url()}#{@route}"}>
        <meta name="twitter:card" content="summary" />
        <meta name="twitter:title" content={@title} />
        <meta name="twitter:description" content={@description} />
        <meta itemprop="name" content={@title} />
        <meta itemprop="description" content={@description} />
        <%= if @og_type == "article" do %>
          <meta itemprop="datePublished" content={format_iso_date(@date)} />
          <meta itemprop="dateModified" content={format_iso_date(@date)} />
          <meta itemprop="wordCount" content={@wordcount} />
          <meta itemprop="keywords" content={Enum.join(@keywords, ",")} />
          <meta property="article:author" content={Content.site_author()} />
          <meta property="article:section" content="Software" />
          <meta :for={keyword <- @keywords} property="article:tag" content={keyword} />
          <meta property="article:published_time" content={format_iso_date(@date)} />
          <meta property="article:modified_time" content={format_iso_date(@date)} />
        <% end %>
        <link rel="canonical" href={"#{Content.site_url()}#{@route}"} />
        <link rel="stylesheet" href="/assets/app.css" />
      </head>
      <body>
        <header>
          <div class="social">
            <a href="/">主页</a>
            <a href="/about/">关于</a>
            <a type="application/rss+xml" href="/index.xml">RSS</a>
            <a href="https://github.com/redgreat">Github</a>
            <a href="https://twitter.com/rubygreat9">Twitter</a>
          </div>
        </header>
        <%= render_slot(@inner_block) %>
      </body>
    </html>
    """
  end

  def reads_index(assigns) do
    ~H"""
    <.layout
      title="Reads"
      description="A list of articles I read and recommend."
      og_type="website"
      route="/reads/"
    >
      <div class="post-header">
        <a href="/reads/">
          <h1>Reads</h1>
        </a>
      </div>
      <article class="post-content">
        <ul class="posts">
          <li :for={page <- @pages}>
            <a href={URI.encode(page.route)} class="post-link">
              <%= page.title %>
            </a>
          </li>
        </ul>
      </article>
      <footer>
        <p class="text-center"></p>
      </footer>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerP = document.querySelector('footer p');
          let link = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          footerP.innerHTML = "Copyright © " + link + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end

  def rss(posts) do
    XmlBuilder.element(:rss, %{version: "2.0", "xmlns:atom": "http://www.w3.org/2005/Atom"}, [
      {:channel,
       [
         {:title, Content.site_title()},
         {:link, Content.site_url()},
         {:description, "Recent content on #{Content.site_title()}"},
         {:language, "en-us"},
         {:managingEditor, "#{Content.site_author()} (#{Content.site_email()})"},
         {:webMaster, "#{Content.site_author()} (#{Content.site_email()})"},
         {:copyright, Content.site_copyright()},
         {:lastBuildDate, format_rss_date(DateTime.utc_now())},
         {:"atom:link",
          %{href: "#{Content.site_url()}/index.xml", rel: "self", type: "application/rss+xml"}}
       ] ++
         for post <- Enum.take(posts, rss_post_limit()) do
           {:item,
            [
              {:title, post.title},
              {:link, Content.site_url() <> post.route},
              {:pubDate, format_rss_date(post.date)},
              {:author, "#{Content.site_author()} (#{Content.site_email()})"},
              {:guid, Content.site_url() <> post.route},
              {:description, post.description}
            ]}
         end}
    ])
    |> XmlBuilder.generate()
  end

  def sitemap(pages) do
    {:urlset,
     %{
       xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9",
       "xmlns:xhtml": "http://www.w3.org/1999/xhtml"
     },
     [
       {:url, [{:loc, Content.site_url()}, {:lastmod, format_iso_date(DateTime.utc_now())}]}
       | for page <- pages do
           {:url,
            [{:loc, Content.site_url() <> page.route}, {:lastmod, format_iso_date(page.date)}]}
         end
     ]}
    |> XmlBuilder.document()
    |> XmlBuilder.generate()
  end

  def redirect(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en-us">
      <head>
        <title><%= @target%></title>
        <link rel="canonical" href={@target}>
        <meta name="robots" content="noindex">
        <meta charset="utf-8">
        <meta http-equiv="refresh" content={"0; url=#{@target}"}>
      </head>
    </html>
    """
  end

  def reads(assigns) do
    ~H"""
    <.layout
      title={"#{@title} — #{Content.site_title()}"}
      description={@description}
      og_type="website"
      route={@route}
    >
      <div class="post-header">
        <a href={@route}>
          <h1><%= @title %></h1>
        </a>
      </div>
      <article class="post-content">
        <p><%= @description %></p>
        <ul class="hide-list">
          <li :for={link <- @links}>
            <a href={ link["url"] } rel="nofollow">
              <img src={"https://www.google.com/s2/favicons?domain=#{ URI.parse(link["url"]).host }"} />
              <%= link["title"] %>
            </a>
          </li>
        </ul>
      </article>
      <footer>
        <p class="text-center"></p>
      </footer>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerP = document.querySelector('footer p');
          let link = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          footerP.innerHTML = "Copyright © " + link + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end
end
