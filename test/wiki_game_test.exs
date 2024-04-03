defmodule WikiGameTest do
  use ExUnit.Case
  doctest WikiGame

  test "greets the world" do
    assert WikiGame.hello() == :world
  end
end
