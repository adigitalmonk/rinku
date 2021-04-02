defmodule Sample do
  def init(value), do: value
  def first(value), do: value + 1
  def second(value), do: value + 2
  def third(value), do: value + 3
end

defmodule WithRinku do
  def run do
    1
    |> Rinku.new()
    |> Rinku.link({Sample, :init, []})
    |> Rinku.link({Sample, :first, []})
    |> Rinku.link({Sample, :second, []})
    |> Rinku.link({Sample, :third, []})
    |> Rinku.run()
    |> Rinku.result()
  end
end

defmodule WithWith do
  def run do
    with init <- Sample.init(1),
         first <- Sample.first(init),
         second <- Sample.second(first),
         third <- Sample.third(second) do
      third
    end
  end
end

Benchee.run(
  %{
    "via_rinku" => fn -> WithRinku.run() end,
    "via_with" => fn -> WithWith.run() end
  },
  warmup: 1,
  time: 5
)
