defmodule Acme.CLI do
  alias Acme.{JSON, BankOfHours}

  def main(args) do
    switches = [
      configs: :string,
      entries: :string
    ]

    aliases = [
      c: :configs,
      e: :entries
    ]

    case OptionParser.parse(
           args,
           switches: switches,
           aliases: aliases
         ) do
      {[entries: entries, configs: configs], _, _} ->
        with {:ok, configs_json} <- JSON.get_file(configs),
             {:ok, entries_json} <- JSON.get_file(entries) do
          BankOfHours.run(configs_json, entries_json)
        else
          _ -> IO.puts("Os argumentos `entries` e `configs` devem ser JSONs válidos!")
        end

      _ ->
        IO.puts("Os argumentos `entries` e `configs` são obrigatórios!")
    end
  end
end
