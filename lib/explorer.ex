defmodule Explorer do
  use GenServer

  alias __MODULE__

  require Logger

  @cooldown 100

  defstruct name: nil, queue: [], timer: nil, return_to: nil, target_page: nil, num_workers: 0

  # Public interface
  def via(name), do: {:via, Registry, {Registry, name}}
  def add_link(name, link, steps \\ 0), do: GenServer.cast(name, {:add_link, {link, steps}})
  def stop(name), do: GenServer.cast(via(name), :stop)

  def dispatch_link(link, workers, steps \\ []) do
    element = :erlang.phash2(link, workers)

    element
    |> genserver_name()
    |> Explorer.via()
    |> Explorer.add_link(link, steps)
  end

  def genserver_name(n) do
    "explorer#{n}"
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    return_to = Keyword.fetch!(opts, :return_to)
    target_page = Keyword.fetch!(opts, :target_page)
    num_workers = Keyword.fetch!(opts, :num_workers)

    GenServer.start_link(
      Explorer,
      %{name: name, return_to: return_to, target_page: target_page, num_workers: num_workers},
      name: via(name)
    )
  end

  # GenServer impl

  @impl GenServer
  def init(%{name: name, return_to: return_to, target_page: target_page, num_workers: num_workers}) do
    Logger.info("Starting coordinator [#{name}] searching for [#{target_page}]")

    {:ok,
     %Explorer{
       name: name,
       return_to: return_to,
       target_page: target_page,
       num_workers: num_workers
     }}
  end

  @impl GenServer
  def handle_cast(:search, %Explorer{} = state) do
    state = do_search(state)
    {:noreply, state}
  end

  def handle_cast({:add_link, {link, steps}}, %Explorer{queue: queue} = state) do
    state = start_timer(state)

    {:noreply, %Explorer{state | queue: [%Link{link: link, steps: steps} | queue]}}
  end

  def handle_cast(:stop, %Explorer{name: name} = state) do
    Logger.debug("[#{name}] Gracefully stopping")
    {:stop, state}
  end

  @impl GenServer
  def handle_call(:search, _from, %Explorer{} = state) do
    state = do_search(state)
    {:reply, state}
  end

  def handle_call({:add_link, {link, steps}}, _from, %Explorer{queue: queue} = state) do
    state = start_timer(state)

    {:reply, :ok, %Explorer{state | queue: [%Link{link: link, steps: steps} | queue]}}
  end

  @impl GenServer
  def handle_info(:search, %Explorer{} = state) do
    state = do_search(state)
    {:noreply, state}
  end

  defp do_search(
         %Explorer{
           name: name,
           target_page: target_page,
           return_to: return_to,
           num_workers: num_workers,
           queue: [%Link{link: current_link, steps: steps} | t] = _queue
         } = state
       ) do
    state = stop_timer(state)
    Cache.put(current_link)

    Logger.info("[#{name}] Exploring #{current_link}")

    {:ok, links} =
      current_link
      |> Searcher.search()

    wiki_links =
      Enum.filter(links, fn link ->
        not Cache.exists?(link)
      end)

    Logger.debug("[#{name}] got #{wiki_links}")

    if Enum.any?(wiki_links, fn link ->
         link == target_page
       end) do
      full_steps =
        steps |> Enum.reverse() |> Enum.concat([current_link]) |> Enum.concat([target_page])

      GenServer.call(return_to, {:found, {target_page, full_steps}})
    else
      Enum.map(wiki_links, fn link ->
        Explorer.dispatch_link(link, num_workers, [current_link | steps])
      end)
    end

    state = start_timer(state)
    %Explorer{state | queue: t}
  end

  defp start_timer(%Explorer{timer: nil} = state) do
    timer = Process.send_after(self(), :search, @cooldown)
    %Explorer{state | timer: timer}
  end

  defp start_timer(%Explorer{timer: _timer} = state), do: state

  defp stop_timer(%Explorer{timer: nil} = state), do: state

  defp stop_timer(%Explorer{timer: timer} = state) do
    Process.cancel_timer(timer)
    %Explorer{state | timer: nil}
  end
end
