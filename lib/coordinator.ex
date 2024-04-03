defmodule Coordinator do
  use GenServer

  alias __MODULE__

  require Logger

  @target_page "/wiki/Adolf_Hitler"

  defstruct start_at: nil, num_workers: 0

  def start_link(opts) do
    start_page = Keyword.fetch!(opts, :start_page)
    num_workers = Keyword.fetch!(opts, :num_workers)

    GenServer.start_link(Coordinator, %{start_page: start_page, num_workers: num_workers},
      name: Coordinator
    )
  end

  @impl GenServer
  def init(%{start_page: start_page, num_workers: num_workers}) do
    Logger.info("Starting coordinator")
    Cache.init()
    Registry.start_link(keys: :unique, name: Registry)

    pid = self()

    0..num_workers
    |> Enum.map(fn n ->
      Explorer.start_link(
        name: Explorer.genserver_name(n),
        return_to: pid,
        target_page: @target_page,
        num_workers: num_workers
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
    summarize(page, steps)

    now = DateTime.utc_now()
    diff = now |> DateTime.diff(start_at, :second)
    Logger.info("Took: #{diff}s")

    graceful_shutdown(num_workers)

    {:stop, :normal, state}
  end

  defp graceful_shutdown(num_workers) do
    0..num_workers
    |> Enum.each(fn n ->
      n
      |> Explorer.genserver_name()
      |> Explorer.stop()
    end)
  end

  defp summarize(page, steps) do
    Logger.info("You won! It took [#{Enum.count(steps)}] steps to get to [#{page}]!")
    Logger.debug(inspect(steps))
  end
end
