defmodule Searcher do
  @wiki_base "https://en.wikipedia.org"

  def search(page) do
    # get the page
    pages =
      page
      |> normalize_wiki()
      |> Req.get!()
      |> Map.fetch!(:body)
      |> Floki.parse_document!()
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> Enum.filter(&is_wiki_link?(&1))

    # get page links

    {:ok, pages}
  end

  defp is_wiki_link?(<<"/wiki/", link::binary>>) do
    # A valid link starts with /wiki/ and does not contain the characters :, otherwise it's gonna be some special Wikipedia page
    # href[6:] removes the '/wiki/' part
    not String.contains?(link, ":")
  end

  defp is_wiki_link?(_link), do: false

  defp normalize_wiki(<<"https://en.wikipedia.org", _rest::binary>> = link), do: link
  defp normalize_wiki(<<"/", rest::binary>> = _link), do: "#{@wiki_base}/#{rest}"
end
