defmodule Cli do
  require Logger

  @default_start_page "/wiki/Pokémon"
  @default_target_page "/wiki/Adolf_Hitler"
  @default_workers 5

  def main(args) do
    System.no_halt(true)

    opts =
      parse_opts(args)

    maybe_execute(opts)

    :timer.sleep(:infinity)
  end

  defp maybe_execute(%{help: true}) do
    Logger.info("""
    Welcome to the wiki game! This program works by starting with a en.wikipedia page and
    finding a way to an end page to see how many hops we need from one to the other.

    Historically, target page is /wiki/Adolf_Hitler , because of the internet.

    More information: https://en.wikipedia.org/wiki/Wikipedia:Wiki_Game

    Options

     * --start-page    -s    Starting page. Defaults to "#{@default_start_page}" (you can omit the /wiki/ prefix)
     * --target-page   -t    Ending page. Defaults to"#{@default_target_page}" (you can omit the /wiki/ prefix)
     * --num-workers   -w    Number of parallel workers. Defaults to "#{@default_workers}"
     * --help          -h    Come on.

     Look, this is a silly game so I'm doing the bare minimum validation here. Please make sure pages exist or things will
     break with obscure messages.
    """)
  end

  defp maybe_execute(opts) do
    opts
    |> defaults()
    |> Map.to_list()
    |> WikiGame.start()
  end

  defp defaults(opts) do
    %{
      start_page: @default_start_page,
      target_page: @default_target_page,
      num_workers: @default_workers,
      help: false
    }
    |> Map.merge(opts)
  end

  defp parse_opts(args) do
    case args
         |> OptionParser.parse(
           strict: [
             start_page: :string,
             target_page: :string,
             num_workers: :integer,
             help: :boolean
           ],
           aliases: [
             v: :verbose,
             h: :help,
             t: :target_page,
             s: :start_page,
             w: :num_workers
           ]
         ) do
      {valid_opts, [], []} ->
        valid_opts |> Enum.into(%{})

      {_, _, invalid_options} ->
        Logger.error("You probably passed some wrong option. Check [#{inspect(invalid_options)}]")
        exit(1)
    end
  end
end
