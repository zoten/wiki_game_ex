defmodule WikiGame do
  @moduledoc """
  Documentation for `WikiGame`.
  """

  require Logger

  # @start_page "John_MacKay_Bernard"
  @default_start_page "/wiki/Minecraft"

  @default_num_workers 5

  def start(opts \\ []) do
    num_workers = Keyword.get(opts, :num_workers, @default_num_workers)

    start_page =
      opts
      |> Keyword.get(:start_page, @default_start_page)
      |> normalize_wiki()

    Coordinator.start_link(start_page: start_page, num_workers: num_workers)
  end

  defp normalize_wiki(<<"/wiki/", _rest::binary>> = link), do: link
  defp normalize_wiki(<<"wiki/", _rest::binary>> = link), do: "/#{link}"
  defp normalize_wiki(<<link::binary>>), do: "/wiki/#{link}"
end
