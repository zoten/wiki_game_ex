defmodule WikiGame do
  @moduledoc """
  Documentation for `WikiGame`.
  """

  require Logger

  @default_start_page "/wiki/Pokémon"
  @default_target_page "/wiki/Adolf_Hitler"
  @default_base_url "https://en.wikipedia.org"

  @default_num_workers 5

  def start(opts \\ []) do
    setup()

    num_workers = Keyword.get(opts, :num_workers, @default_num_workers)

    start_page =
      opts
      |> Keyword.get(:start_page, @default_start_page)
      |> normalize_wiki()

    target_page =
      opts
      |> Keyword.get(:target_page, @default_target_page)
      |> normalize_wiki()

    base_url =
      opts
      |> Keyword.get(:base_url, @default_base_url)
      |> wiki_base_or_mobile()

    Coordinator.start_link(
      start_page: start_page,
      num_workers: num_workers,
      target_page: target_page,
      base_url: base_url
    )
  end

  defp normalize_wiki(<<"/wiki/", _rest::binary>> = link), do: link
  defp normalize_wiki(<<"wiki/", _rest::binary>> = link), do: "/#{link}"
  defp normalize_wiki(<<link::binary>>), do: "/wiki/#{link}"

  defp wiki_base_or_mobile(<<"https://m.wikipedia.org">> = link),
    do: link

  defp wiki_base_or_mobile(<<"https://", _lang::binary-size(2), ".wikipedia.org">> = link),
    do: link

  defp wiki_base_or_mobile(link), do: raise("Invalid wiki link [#{link}]")

  defp setup do
    :inets.start()
    :ssl.start()
  end
end
