defmodule Searcher do
  @wiki_base "https://en.wikipedia.org"

  def search(page) do
    pages =
      page
      |> normalize_wiki()
      |> get!()
      # |> Req.get!()
      |> Map.fetch!(:body)
      |> Floki.parse_document!()
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> Enum.filter(&is_wiki_link?(&1))

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

  defp get!(url) do
    url = ~c"#{url}"
    headers = [{~c"accept", ~c"application/json"}]

    http_request_opts = [
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    {:ok, {status, headers, body}} = :httpc.request(:get, {url, headers}, http_request_opts, [])
    %{status: status, headers: headers, body: List.to_string(body)}
  end
end
