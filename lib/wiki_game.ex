defmodule WikiGame do
  @moduledoc """
  Documentation for `WikiGame`.
  """

  require Logger

  @default_start_page "/wiki/Pokémon"
  @default_target_page "/wiki/Adolf_Hitler"

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

    Coordinator.start_link(
      start_page: start_page,
      num_workers: num_workers,
      target_page: target_page
    )
  end

  defp normalize_wiki(<<"/wiki/", _rest::binary>> = link), do: link
  defp normalize_wiki(<<"wiki/", _rest::binary>> = link), do: "/#{link}"
  defp normalize_wiki(<<link::binary>>), do: "/wiki/#{link}"

  defp setup do
    :inets.start()
    :ssl.start()
  end
end
