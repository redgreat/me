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
        document.querySelectorAll('code').forEach(function(el) {
          el.contentEditable = true
        });
        function scrollToTop() {
          window.scrollTo({top: 0, behavior: 'smooth'});
        };
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerYear = document.getElementById('footer-cr');
          let wlink = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          let elink = '<a href="https://erlang.org" target="_blank">Elixir/OTP</a>';
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
      |> Enum.sort_by(fn {date, _posts} -> date end, {:desc, Date})

    assigns = Map.put(assigns, :grouped_posts, grouped_posts)

    ~H"""
    <.layout
      title={Content.site_title()}
      route="/"
    >
      <div class="posts">
        <%= for {date, posts} <- @grouped_posts do %>
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
          let elink = '<a href="https://erlang.org" target="_blank">Elixir/OTP</a>';
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
      |> Enum.sort_by(fn {date, _posts} -> date end, {:desc, Date})

    assigns = Map.put(assigns, :grouped_posts, grouped_posts)

    ~H"""
    <.layout
      title={Content.site_title()}
      route="/"
    >
      <h1>归档</h1>
      <div class="posts">
        <%= for {date, posts} <- @grouped_posts do %>
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
          let elink = '<a href="https://erlang.org" target="_blank">Elixir/OTP</a>';
          let vlink = '<a href="https://vercel.com" target="_blank">Vercel</a>';
          footerYear.innerHTML = "Generate Use " + elink + " Publish at " + vlink + "<br>Copyright © " + wlink + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
    </.layout>
    """
  end

  def routes(assigns) do
    ~H"""
    <.layout
      title={Content.site_title()}
      route="/routes/"
    >
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.css" />
      <div class="route-page" id="route-app" data-endpoint="/api/locations">
      <div class="route-header">
          <h1>轨迹</h1>
        <p>展示某一天的定位点轨迹，地图底图来自 OpenStreetMap。</p>
        <p class="route-tip" id="route-tip">请输入日期后加载定位数据。</p>
        </div>
        <div class="route-controls">
          <label for="route-date">日期</label>
          <input type="date" id="route-date" />
          <button id="route-load">加载</button>
          <span class="route-status" id="route-status"></span>
        </div>
        <div class="route-stats">
          <div class="route-stat">
            <span class="route-stat-label">点数</span>
            <span class="route-stat-value" id="route-count">-</span>
          </div>
          <div class="route-stat">
            <span class="route-stat-label">时间范围</span>
            <span class="route-stat-value" id="route-range">-</span>
          </div>
        </div>
        <div id="route-map" class="route-map"></div>
      </div>
      <footer>
        <p id="footer-cr"></p>
      </footer>
      <script src="https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.js"></script>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          let currentYear = new Date().getFullYear();
          let footerYear = document.getElementById('footer-cr');
          let wlink = '<a href="https://www.wongcw.cn" target="_blank">wangcw</a>';
          let elink = '<a href="https://erlang.org" target="_blank">Elixir/OTP</a>';
          let vlink = '<a href="https://vercel.com" target="_blank">Vercel</a>';
          footerYear.innerHTML = "Generate Use " + elink + " Publish at " + vlink + "<br>Copyright © " + wlink + " 2020-" + currentYear + " All Rights Reserved";
        });
      </script>
      <script>
        const routeApp = document.getElementById('route-app');
        const dateInput = document.getElementById('route-date');
        const loadButton = document.getElementById('route-load');
        const statusEl = document.getElementById('route-status');
        const countEl = document.getElementById('route-count');
        const rangeEl = document.getElementById('route-range');
        const endpoint = routeApp.dataset.endpoint || '';
        let map;
        let trackLayer;
        let startMarker;
        let endMarker;

        const now = new Date();
        const localDate = new Date(now.getTime() - now.getTimezoneOffset() * 60000)
          .toISOString()
          .slice(0, 10);

        const params = new URLSearchParams(window.location.search);
        const initialDate = params.get('date') || localDate;
        dateInput.value = initialDate;

        function setStatus(text, tone) {
          statusEl.textContent = text || '';
          statusEl.dataset.tone = tone || '';
        }

        function setTip(text, tone) {
          const tipEl = document.getElementById('route-tip');
          if (!tipEl) return;
          tipEl.textContent = text || '';
          tipEl.dataset.tone = tone || '';
        }

        function formatTime(value) {
          if (!value) return '';
          const date = new Date(value);
          if (Number.isNaN(date.getTime())) return '';
          const pad = (num) => String(num).padStart(2, '0');
          return `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
        }

        function normalizePoints(data) {
          if (Array.isArray(data)) return data;
          if (data && Array.isArray(data.points)) return data.points;
          return [];
        }

        function toLatLng(point) {
          const lat = point.lat ?? point.latitude;
          const lng = point.lng ?? point.lon ?? point.longitude;
          const latNumber = Number(lat);
          const lngNumber = Number(lng);
          if (!Number.isFinite(latNumber) || !Number.isFinite(lngNumber)) return null;
          return [latNumber, lngNumber];
        }

        function ensureMap(center) {
          if (!map) {
            map = L.map('route-map', { preferCanvas: true });
            L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
              maxZoom: 19,
              attribution: '&copy; OpenStreetMap contributors'
            }).addTo(map);
            L.control.scale().addTo(map);
          }
          map.setView(center, 12);
        }

        function renderTrack(points) {
          const latlngs = points
            .map(toLatLng)
            .filter((item) => item);

          if (latlngs.length === 0) {
            setStatus('没有可用的定位点', 'empty');
            setTip('该日期没有可用数据。', 'empty');
            countEl.textContent = '0';
            rangeEl.textContent = '-';
            return;
          }

          ensureMap(latlngs[0]);

          if (trackLayer) map.removeLayer(trackLayer);
          if (startMarker) map.removeLayer(startMarker);
          if (endMarker) map.removeLayer(endMarker);

          trackLayer = L.polyline(latlngs, { color: '#2f4bff', weight: 3 });
          trackLayer.addTo(map);
          map.fitBounds(trackLayer.getBounds(), { padding: [20, 20] });

          startMarker = L.circleMarker(latlngs[0], { radius: 5, color: '#10b981' }).addTo(map);
          endMarker = L.circleMarker(latlngs[latlngs.length - 1], { radius: 5, color: '#ef4444' }).addTo(map);

          countEl.textContent = String(latlngs.length);
          const startTime = formatTime(points[0]?.ts || points[0]?.time || points[0]?.timestamp);
          const endTime = formatTime(points[points.length - 1]?.ts || points[points.length - 1]?.time || points[points.length - 1]?.timestamp);
          rangeEl.textContent = startTime && endTime ? `${startTime} - ${endTime}` : '-';
          setStatus('加载成功', 'success');
          setTip('数据来自后端接口。', 'success');
        }

        async function fetchPoints(date) {
          if (!endpoint) {
            throw new Error('missing-endpoint');
          }
          const response = await fetch(`${endpoint}?date=${date}`);
          if (!response.ok) {
            throw new Error(`status:${response.status}`);
          }
          return response.json();
        }

        async function loadDate(date) {
          if (!date) return;
          setStatus('加载中...', 'loading');
          setTip('正在从后端获取数据...', 'loading');
          try {
            const data = await fetchPoints(date);
            renderTrack(normalizePoints(data));
          } catch (error) {
            setStatus('加载失败', 'error');
            setTip('接口不可用或数据为空，请稍后重试。', 'error');
            countEl.textContent = '-';
            rangeEl.textContent = '-';
          }
        }

        loadButton.addEventListener('click', function() {
          const date = dateInput.value;
          const url = new URL(window.location.href);
          url.searchParams.set('date', date);
          window.history.replaceState({}, '', url.toString());
          loadDate(date);
        });

        dateInput.addEventListener('change', function() {
          loadButton.click();
        });

        if (!endpoint) {
          setStatus('接口未配置', 'error');
          setTip('当前未配置后端接口，无法加载定位数据。', 'error');
        } else {
          loadDate(initialDate);
        }
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
          let elink = '<a href="https://erlang.org" target="_blank">Elixir/OTP</a>';
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
            <a href="/routes/">轨迹</a>
            <a href="/about/">关于</a>
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
