defmodule Searcher do
  @base_url "https://en.wikipedia.org"

  def search(page, opts \\ []) do
    base_url = Keyword.get(opts, :base_url, @base_url)

    pages =
      page
      |> normalize_wiki(base_url)
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

  defp normalize_wiki(<<"/", rest::binary>> = _link, base_url), do: "#{base_url}/#{rest}"
  defp normalize_wiki(<<"https", _rest>> = link, _base_url), do: link

  defp get!(url) do
    url = URI.encode(url)
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
