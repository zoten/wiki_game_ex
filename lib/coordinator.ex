defmodule Coordinator do
  use GenServer

  alias __MODULE__

  require Logger

  defstruct start_at: nil, num_workers: 0

  def start_link(opts) do
    start_page = Keyword.fetch!(opts, :start_page)
    num_workers = Keyword.fetch!(opts, :num_workers)
    target_page = Keyword.fetch!(opts, :target_page)
    base_url = Keyword.fetch!(opts, :base_url)

    GenServer.start_link(
      Coordinator,
      %{
        start_page: start_page,
        num_workers: num_workers,
        target_page: target_page,
        base_url: base_url
      },
      name: Coordinator
    )
  end

  @impl GenServer
  def init(%{
        start_page: start_page,
        num_workers: num_workers,
        target_page: target_page,
        base_url: base_url
      }) do
    Logger.info("Starting coordinator")
    Cache.init()
    Registry.start_link(keys: :unique, name: Registry)

    pid = self()

    0..num_workers
    |> Enum.map(fn n ->
      Explorer.start_link(
        name: Explorer.genserver_name(n),
        return_to: pid,
        target_page: target_page,
        num_workers: num_workers,
        base_url: base_url
      )
    end)

    Explorer.dispatch_link(start_page, num_workers)

    now = DateTime.utc_now()

    {:ok, %Coordinator{start_at: now, num_workers: num_workers}}
  end

  @impl GenServer
  def handle_call(
        {:found, {page, steps}},
        _from,
        %Coordinator{start_at: start_at, num_workers: num_workers} = state
      ) do
    now = DateTime.utc_now()
    diff = now |> DateTime.diff(start_at, :second)

    graceful_shutdown_workers(num_workers)

    summarize(page, steps)
    Logger.info("Took: #{diff}s")

    graceful_shutdown()

    {:stop, :normal, state}
  end

  defp graceful_shutdown_workers(num_workers) do
    0..num_workers
    |> Enum.each(fn n ->
      n
      |> Explorer.genserver_name()
      |> Explorer.stop()
    end)

    :timer.sleep(500)
  end

  defp graceful_shutdown do
    :ssl.stop()
    :inets.stop()

    System.stop(0)
  end

  defp summarize(page, steps) do
    Logger.info("You won! It took [#{Enum.count(steps)}] steps to get to [#{page}]!")
    Logger.debug(inspect(steps))
  end
end
