defmodule CunweiWong.SiteTest do
  use ExUnit.Case, async: true
  alias CunweiWong.{Content, Page, Render}

  defp html(rendered), do: rendered |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  test "existing Unicode article routes remain stable" do
    page = Page.build("pages/posts/2024-01-02-数据库.md", %{title: "数据库"}, "<p>正文</p>")
    assert page.route == "/数据库/"
    assert page.html_path == "数据库/index.html"
  end

  test "archive metadata points to archive and navigation has no map" do
    output = html(Render.archive(%{posts: Content.all_posts()}))
    assert output =~ ~s(href="#{Content.site_url()}/archive/")
    assert output =~ ~s(aria-current="page")
    refute output =~ "/routes/"
    refute output =~ "<script"
  end

  test "deduplication preserves the earliest article" do
    newer = %{id: "same", date: ~D[2026-01-01]}
    older = %{id: "same", date: ~D[2024-01-01]}
    assert CunweiWong.dedup_by_id([newer, older]) == [older]
  end

  test "article headings are escaped while trusted Markdown is rendered" do
    page = Page.build("pages/posts/2024-01-02-test.md", %{title: "<script>"}, "<p>正文</p>")
    output = html(Render.post(page))
    assert output =~ "&lt;script&gt;"
    assert output =~ "<p>正文</p>"
    refute output =~ "contentEditable"
  end
end
