Enum.each(Path.wildcard("pages/posts/*.md"), fn file ->
  content = File.read!(file)
  case String.split(content, ~r/\r?\n---\r?\n/, parts: 2) do
    [frontmatter, _body] ->
      if String.starts_with?(frontmatter, "%{") do
        try do
          Code.eval_string(frontmatter, [])
        rescue
          e ->
            IO.puts("\n=== ERROR IN FRONTMATTER OF: #{file} ===")
            IO.inspect(e)
            IO.puts("FRONTMATTER CONTENTS:")
            IO.puts(frontmatter)
            IO.puts("===================")
        catch
          :error, e ->
            IO.puts("\n=== CATCH IN FRONTMATTER OF: #{file} ===")
            IO.inspect(e)
            IO.puts("FRONTMATTER CONTENTS:")
            IO.puts(frontmatter)
            IO.puts("===================")
        end
      end
    [single] ->
      if String.starts_with?(single, "%{") do
        try do
          Code.eval_string(single, [])
        rescue
          e ->
            IO.puts("\n=== ERROR IN ENTIRE FILE: #{file} ===")
            IO.inspect(e)
        catch
          :error, e ->
            IO.puts("\n=== CATCH IN ENTIRE FILE: #{file} ===")
            IO.inspect(e)
        end
      end
  end
end)
