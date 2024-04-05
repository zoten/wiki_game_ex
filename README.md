# WikiGame

A naive implementation of the [Wiki Game](https://en.wikipedia.org/wiki/Wikipedia:Wiki_Game) through a parallel hashed workers pool.
Thanks to [nappa85](https://github.com/nappa85) for making me lose some hours this evening.

## Build

``` bash
MIX_ENV=prod mix escript.build
```

This will create a `wiki_game` executable in this same folder.

## Usage

```
./wiki_game [-s start_page] [-t target_page] [-w num_workers] [-b base_url] [-h]
```

e.g.

``` bash
./wiki_game -s Pokémon -t Super_Mario -w 10
```

## Notes

Hey, this is a game.

This is by no way good code, ok? This has no tests, a lot of `escript` specific madness and some debatale practices. As an example, it seems there is no modern HTTP client for Elixir that is escript-friendly. Also, applications initialization and shutdown are sparse in different modules. Sorry for that.
Output is from `Logger` and you can expect some `stdout` from Erlang applications stopping after the last output from the program. Deal with it.

The current implementation may not find the shortest path, just the first that happens. It is possible to improve it by tweaking the cache.

Sometimes `:httpc` will not stop in time and you'll see a giant red error. I'm sorry pals.

I hope URL encoding is working decently well, tried with `Pokémon` with good results but no more than that.

There is no termination guard, be ready with `CTRL^C`. There is as little validation as possible, e.g. be sure the target page exists. Also the source, jsut to be sure.

This is still interestingly showing a couple of things about how to write decent software for a trivial scraping problem, how to write CLI tools in Elixir and maybe other things I'll reason about.


## Things I'd like to add someday

 * [ ] a really decent graceful shutdown
 * [ ] other implementations of the game
   * [ ] a graph based one
   * [ ] an explore/exploit one
 * [ ] tests and hex architecture for academic purpose

Will I? Probably not. But I had fun.
