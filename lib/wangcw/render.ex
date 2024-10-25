defmodule CunweiWong.Render do
  @moduledoc false

  use Phoenix.Component
  alias CunweiWong.Content
  import Phoenix.HTML

  def format_post_date(date) do
    Calendar.strftime(date, "%Y年%m月%d日")
  end

  def post(assigns) do
    ~H"""
    <.layout
      title={"#{@title} — #{Content.site_title()}"}
      route={@route}
      date={@date}
    >
      <div class="post-header">
        <small class="post-meta"><span class="author">wangcw - </span><%= format_post_date(@date) %></small>
        <a href={@route}>
          <h1><%= @title %></h1>
        </a>
      </div>
      <article class="post-content">
        <%= raw @body %>
      </article>
      <hr>
      <div class="posts-footer">
        <div class="left"><p>文档发布时间: <%= format_post_date(@date) %></p></div>
        <div class="right" onclick="scrollToTop()" style="cursor: pointer;">返回顶部</div>
      </div>
      <footer>
        <p id="footer-cr"></p>
      </footer>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerYear = document.getElementById('footer-cr');
          let wlink = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          let elink = '<a href="https://www.erlang.org" target="_blank">Elixir/OTP</a>';
          let vlink = '<a href="https://vercel.com" target="_blank">Vercel</a>';
          footerYear.innerHTML = "Generate Use " + elink + " Publish at " + vlink + "<br>Copyright © " + wlink + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end

  def index(assigns) do
    grouped_posts =
      assigns.posts
      |> Enum.group_by(& &1.date)

    ~H"""
    <.layout
      title={Content.site_title()}
      route="/"
    >
      <div class="posts">
        <%= for {date, posts} <- grouped_posts do %>
          <div class="post-date"><%= format_post_date(date) %></div>
          <%= for post <- posts do %>
            <a href={post.route} class="post-link alternate">
              <div class="post">
                <div class="post-title"><%= post.title %></div>
              </div>
            </a>
          <% end %>
        <% end %>
      </div>
      <hr />
      <p><i>阅读更多文章 <a href="/archive/">归档</a></i></p>
      <footer>
        <p id="footer-cr"></p>
      </footer>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerYear = document.getElementById('footer-cr');
          let wlink = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          let elink = '<a href="https://www.erlang.org" target="_blank">Elixir/OTP</a>';
          let vlink = '<a href="https://vercel.com" target="_blank">Vercel</a>';
          footerYear.innerHTML = "Generate Use " + elink + " Publish at " + vlink + "<br>Copyright © " + wlink + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end

  def archive(assigns) do
    grouped_posts =
      assigns.posts
      |> Enum.group_by(& &1.date)

    ~H"""
    <.layout
      title={Content.site_title()}
      route="/"
    >
      <h1>归档</h1>
      <div class="posts">
        <%= for {date, posts} <- grouped_posts do %>
          <div class="post-date"><%= format_post_date(date) %></div>
          <%= for post <- posts do %>
            <a href={post.route} class="post-link alternate">
              <div class="archive-post">
                <div class="archive-title"><%= post.title %></div>
              </div>
            </a>
          <% end %>
        <% end %>
      </div>
      <footer>
        <p id="footer-cr"></p>
      </footer>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerYear = document.getElementById('footer-cr');
          let wlink = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          let elink = '<a href="https://www.erlang.org" target="_blank">Elixir/OTP</a>';
          let vlink = '<a href="https://vercel.com" target="_blank">Vercel</a>';
          footerYear.innerHTML = "Generate Use " + elink + " Publish at " + vlink + "<br>Copyright © " + wlink + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end

  def page(assigns) do
    ~H"""
    <.layout
      title={"#{@title} — #{Content.site_title()}"}
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
        <p id="footer-cr"></p>
      </footer>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerYear = document.getElementById('footer-cr');
          let wlink = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          let elink = '<a href="https://www.erlang.org" target="_blank">Elixir/OTP</a>';
          let vlink = '<a href="https://vercel.com" target="_blank">Vercel</a>';
          footerYear.innerHTML = "Generate Use " + elink + " Publish at " + vlink + "<br>Copyright © " + wlink + " 2020-" + currentYear + " All Rights Reserved";
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
        <meta name="author" content={Content.site_author()} />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="ROBOTS" content="INDEX, FOLLOW" />
        <meta property="og:title" content={@title} />
        <meta property="og:url" content={"#{Content.site_url()}#{@route}"}>
        <link rel="stylesheet" href="/assets/app.css" />
      </head>
      <body>
        <header>
          <div class="social">
            <a href="/">主页</a>
            <a href="/about/">关于</a>
            <a href="https://github.com/redgreat">Github</a>
          </div>
        </header>
        <%= render_slot(@inner_block) %>
      </body>
    </html>
    """
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
end
