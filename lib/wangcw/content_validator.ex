defmodule CunweiWong.ContentValidator do
  @moduledoc "Checks Markdown sources and generated pages before deployment."

  @image_pattern ~r/!\[[^\]]*\]\(([^)]+)(?:\s+[^)]*)?\)/

  def validate_sources!(paths \\ Path.wildcard("pages/**/*.md")) do
    {errors, warnings} =
      paths
      |> Enum.sort()
      |> Enum.reduce({[], []}, fn path, {errors, warnings} ->
        source = File.read!(path)
        {source_errors, source_warnings} = check_source(path, source)
        {errors ++ source_errors, warnings ++ source_warnings}
      end)

    duplicate_id_warnings = duplicate_id_warnings(paths)
    warnings = warnings ++ duplicate_id_warnings

    report(warnings, "Markdown warnings")
    report(errors, "Markdown errors")

    if errors != [], do: raise("Markdown validation failed with #{length(errors)} error(s)")
    :ok
  end

  def validate_output!(output_dir \\ "output") do
    errors =
      Path.wildcard(Path.join(output_dir, "**/*.html"))
      |> Enum.flat_map(fn path ->
        html = File.read!(path)

        if Regex.match?(~r/\A\s*<!doctype html|\A\s*<html/i, html) do
          []
        else
          ["#{path}:1: generated file is not a complete HTML document"]
        end
      end)

    report(errors, "Generated HTML errors")
    if errors != [], do: raise("Generated HTML validation failed with #{length(errors)} error(s)")
    :ok
  end

  defp duplicate_id_warnings(paths) do
    paths
    |> Enum.filter(&String.starts_with?(&1, "pages/posts/"))
    |> Enum.group_by(fn path ->
      path |> Path.basename() |> Path.rootname() |> String.split("-", parts: 4) |> List.last()
    end)
    |> Enum.flat_map(fn
      {_id, [_]} ->
        []

      {id, duplicates} ->
        [
          "#{Enum.join(duplicates, ", ")}:1: duplicate article URL ID #{inspect(id)}; all but the first article are hidden"
        ]
    end)
  end

  defp check_source(path, source) do
    lines = String.split(source, ~r/\r?\n/)
    frontmatter_line = Enum.find_index(lines, &(String.trim(&1) == "---"))

    if is_nil(frontmatter_line) do
      {[issue(path, 1, "missing frontmatter separator (---)")], []}
    else
      {frontmatter, body_lines} = Enum.split(lines, frontmatter_line)
      {errors, warnings} = check_frontmatter(path, frontmatter)
      check_body(path, body_lines, frontmatter_line + 2, errors, warnings)
    end
  end

  defp check_frontmatter(path, lines) do
    title_line =
      Enum.find_index(lines, fn line ->
        String.match?(line, ~r/^\s*title\s*:/)
      end)

    errors =
      cond do
        is_nil(title_line) ->
          [issue(path, 1, "frontmatter is missing title")]

        String.trim(lines |> Enum.at(title_line) |> String.replace(~r/^\s*title\s*:\s*/, "")) ==
            "" ->
          [issue(path, title_line + 1, "title must not be empty")]

        true ->
          []
      end

    date_errors =
      case Enum.find_index(lines, &String.match?(&1, ~r/^\s*date\s*:/)) do
        nil -> []
        index -> validate_date(path, Enum.at(lines, index), index + 1)
      end

    {errors ++ date_errors, []}
  end

  defp validate_date(path, line, line_number) do
    case Regex.run(~r/\d{4}-\d{2}-\d{2}/, line) do
      [date] ->
        case Date.from_iso8601(date) do
          {:ok, _} -> []
          _ -> [issue(path, line_number, "invalid date #{inspect(date)}")]
        end

      _ ->
        [issue(path, line_number, "date must use YYYY-MM-DD or ~D[YYYY-MM-DD] format")]
    end
  end

  # A line-by-line state machine keeps fenced code and Markdown headings in sync.
  defp check_body(path, lines, first_line, errors, warnings) do
    {errors, warnings, fence, _heading_stack} =
      lines
      |> Enum.with_index(first_line)
      |> Enum.reduce({errors, warnings, nil, []}, &check_body_line(path, &1, &2))

    errors =
      case fence do
        nil -> errors
        _ -> errors ++ [issue(path, length(lines) + first_line, "unclosed fenced code block")]
      end

    {image_errors, image_warnings} = check_images(path, lines, first_line)
    {errors ++ image_errors, warnings ++ image_warnings}
  end

  defp check_body_line(path, {line, number}, {errors, warnings, nil, headings}) do
    cond do
      Regex.match?(~r/^\s*```/, line) ->
        open_fence(path, line, number, errors, warnings, headings)

      Regex.match?(~r/^\s*\#{1,6}(?:\s|$)/, line) ->
        check_heading(path, line, number, errors, warnings, headings)

      true ->
        {errors, warnings, nil, headings}
    end
  end

  defp check_body_line(_path, {line, _number}, {errors, warnings, fence, headings}) do
    if Regex.match?(~r/^\s*```\s*$/, line) do
      {errors, warnings, nil, headings}
    else
      {errors, warnings, fence, headings}
    end
  end

  defp open_fence(path, line, number, errors, warnings, headings) do
    language =
      line
      |> String.trim_leading()
      |> String.trim_leading("```")
      |> String.trim()
      |> String.downcase()

    warnings =
      if language in ["mermaid", "mindmap", "markmap", "plantuml", "graphviz"] do
        warnings ++
          [
            issue(
              path,
              number,
              "diagram fence #{inspect(language)} is not rendered by this site"
            )
          ]
      else
        warnings
      end

    {errors, warnings, language, headings}
  end

  defp check_heading(path, line, number, errors, warnings, headings) do
    trimmed = String.trim_leading(line)

    level =
      trimmed
      |> String.graphemes()
      |> Enum.take_while(&(&1 == "#"))
      |> length()

    text =
      trimmed
      |> String.trim_leading("#")
      |> String.trim()
      |> String.trim_trailing("#")
      |> String.trim()

    prior =
      Enum.find(headings, fn {old_level, old_text, _old_line} ->
        old_level == level and normalize(old_text) == normalize(text)
      end)

    heading_errors =
      if text == "", do: [issue(path, number, "heading must not be empty")], else: []

    warnings = warnings ++ repeated_heading_warning(path, prior, level, text, number)

    stack = [
      {level, text, number}
      | Enum.reject(headings, fn {old_level, _text, _line} -> old_level == level end)
    ]

    {errors ++ heading_errors, warnings, nil, stack}
  end

  defp repeated_heading_warning(_path, nil, _level, _text, _number), do: []

  defp repeated_heading_warning(path, {_old_level, _old_text, old_line}, level, text, number) do
    [
      issue(
        path,
        number,
        "repeated H#{level} heading #{inspect(text)} (first at line #{old_line})"
      )
    ]
  end

  defp check_images(path, lines, first_line) do
    lines
    |> Enum.with_index(first_line)
    |> Enum.reduce({[], []}, &check_image_line(path, &1, &2))
  end

  defp check_image_line(path, {line, number}, acc) do
    @image_pattern
    |> Regex.scan(line, capture: :all_but_first)
    |> Enum.reduce(acc, fn [src], acc -> check_image_src(path, src, number, acc) end)
  end

  defp check_image_src(path, src, number, {errors, warnings}) do
    cond do
      String.starts_with?(src, ["https://", "http://", "data:", "#", "/"]) ->
        {errors, warnings}

      String.match?(src, ~r/^[a-zA-Z]:[\\\/]/) ->
        {errors, warnings ++ [issue(path, number, "image uses an absolute local path: #{src}")]}

      image_file?(path, src) ->
        {errors, warnings}

      true ->
        {errors, warnings ++ [issue(path, number, "image file not found: #{src}")]}
    end
  end

  defp image_file?(path, src) do
    image_path = Path.expand(Path.join(Path.dirname(path), src))
    root = Path.expand("assets/static")

    file =
      if String.starts_with?(image_path, root),
        do: image_path,
        else: Path.expand(Path.join(root, src))

    File.regular?(file)
  end

  defp normalize(text), do: text |> String.downcase() |> String.replace(~r/[\s[:punct:]]/u, "")
  defp issue(path, line, message), do: "#{path}:#{line}: #{message}"

  defp report([], _heading), do: :ok

  defp report(issues, heading) do
    IO.puts("\n#{heading}:")

    issues
    |> Enum.take(40)
    |> Enum.each(&IO.puts("  - #{&1}"))

    if length(issues) > 40, do: IO.puts("  ... #{length(issues) - 40} additional issue(s)")
  end
end
