defmodule Cache do
  @table_name :cache

  def init() do
    :ets.new(@table_name, [:public, :named_table])
    :ok
  end

  def exists?(item) do
    case :ets.lookup(@table_name, item) do
      [] -> false
      _ -> true
    end
  end

  def put(item) do
    true = :ets.insert_new(@table_name, {item, item})
    :ok
  end
end
