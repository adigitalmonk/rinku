# Rinku

![Continuous Integration Status](https://github.com/adigitalmonk/rinku/actions/workflows/elixir.yaml/badge.svg)

Rinku is a simple abstraction to enable linking a series of steps.

To begin a new `Rinku.new/2` chain is created with some initial value (`nil` by default).
Then, multiple links / function calls are added together using `Rinku.link/2`.
Once we've built the chain, the `Rinku.run/1` function resolve the links in the order they were added.
The first argument to a link is always the result of the previous link's execution.

At the end of a function's execution, the result is passed the first argument for the next.
The chain will end immediately if any function returns a tuple with `:error` as the first element.
Once the chain exhausts all of it's links, the `Rinku.result/1` function will extract the final result.

```elixir
3 =
  1
  |> Rinku.new()
  |> Rinku.link(fn input -> input + 1 end)
  |> Rinku.link(fn input -> input + 1 end)
  |> Rinku.run()
  |> Rinku.result()
```

You can provide extra arguments to individual steps (from a number of ways) instead of just feeding data through the chain.

```elixir
previous_result = 
  1
  |> Rinku.new()
  |> Rinku.link({fn input, four -> input + four end, 4})
  |> Rinku.run()
  |> Rinku.result()

assert previous_result == 5

new_result = 
  5
  |> Rinku.new()
  |> Rinku.link(fn input -> input + previous_result end)
  |> Rinku.run()
  |> Rinku.result()

assert new_result == 10
```

Additional arguments are provided to module calls using the common tuple format, `{SomeModule, :function, [:one, :two]}`.
The input from the previous step will always be injected as the first argument, other arguments will be added subsequently.

```elixir
defmodule SomeMod do
  def combine(init, a, b), do: init + a + b
end

5 = 
  1
  |> Rinku.new()
  |> Rinku.link({SomeMod, :combine, [2, 2]})
  |> Rinku.run()
  |> Rinku.result()
```

If a function returns an `:error` along the way, it'll halt execution.
Errors can be either just the atom `:error`, or an error tuple of any length. 
E.g., `{:error, :thing}`, `{:error, :thing, :other}`, `{:error, :thing, :other, :more}`.

```elixir
{:error, :oh_no} = 
  Rinku.new()
  |> Rinku.link(fn _ -> {:error, :oh_no} end)
  |> Rinku.link(fn _input -> 10 end)
  |> Rinku.run()
  |> Rinku.result()
```

If for some reason you need to recover an earlier result, you can name your steps and recover the results that way.
You can name the input as well, if you have a need or desire to do that.
Naming is optional, but you'll need a unique name to get the correct result for a step.

```elixir
processed_chain = 
  Rinku.new(:input_value, :input_name)
  |> Rinku.link(fn _input -> :result1 end, :step1)
  |> Rinku.link(fn _input -> :result2 end, :step2)
  |> Rinku.link(fn _input -> :result3 end, :step3)
  |> Rinku.run()

assert processed_chain |> Rinku.link_result(:input_name) == :input_value
assert processed_chain |> Rinku.link_result(:step1) == :result1
assert processed_chain |> Rinku.link_result(:step2) == :result2
assert processed_chain |> Rinku.link_result(:step3) == :result3
assert processed_chain |> Rinku.result() == :result3
```

A completed chain can also be appended and re-run if necessary.
All steps are re-run, not just the newly added ones.

```elixir
chain =
  1
  |> Rinku.new()
  |> Rinku.link(fn input -> input + 1 end)

value =
  chain
  |> Rinku.run()
  |> Rinku.result()

assert value == 2

other_value =
  chain
  |> Rinku.link(fn input ->
    input + 1
  end)
  |> Rinku.run()
  |> Rinku.result()

assert other_value == 3
```

See [Practical Examples](#practical-examples) for a few realistic use cases.

## Developing

For the Elixir/Erlang versions, please refer to the supplied `.tool-versions` (compatible with `asdf`).

## Practical Examples

A scenario where we want to accept an arbitrary map, convert it into an Ecto schema, then save it to a database.
In the `SomeContext` module, there are three functions showcasing the same logic.
One function uses a `with` chain, the other two use a `Rinku` chain.

```elixir
defmodule SomeSchema do
  @callback changeset(params :: map()) :: Ecto.Changeset.t()
  @callback coerce(changeset :: Ecto.Changeset.t()) :: t() | {:error, Ecto.Changeset.t()}
  @callback save(t(), access_token) :: {:ok, t()} | {:error, :forbidden}
end

defmodule SomeContext do
  def create_via_with(record_params, access_token) do
    with {:ok, changeset} <- SomeSchema.changeset(record_params),
         {:ok, struct} <- SomeSchema.coerce(changeset),
         {:ok, result} = result <- SomeSchema.save(struct, access_token) do
         result
    else
      {:error, %Ecto.Changeset{} = error_changeset} -> {:error, :invalid_params, error_changeset}
      {:error, :forbidden} -> {:error, :not_allowed_to_save}
    end
  end

  def create_via_rinku(record_params, access_token) do
    record_params
    |> Rinku.new()
    |> Rinku.link({SomeSchema, :changeset, []})
    |> Rinku.link({SomeSchema, :coerce, []})
    |> Rinku.link({SomeSchema, :save, access_token})
    |> Rinku.run()
    |> Rinku.result()
    |> case do
      {:error, %Ecto.Changeset{} = error_changeset} -> {:error, :invalid_params, error_changeset}
      {:error, :forbbiden} -> {:error, :not_allowed_to_save}
      {:ok, _result} = result -> result
    end
  end

  def create_via_rinku_alt(record_params, access_token) do
    record_params
    |> Rinku.new()
    |> Rinku.link(fn params -> 
      SomeSchema.changeset(params) 
    end)
    |> Rinku.link(fn changeset -> 
      case SomeSchema.coerce(changeset) do
        {:error, changeset} -> {:error, :invalid_params, changeset}
        instance -> {:ok, instance}
      end 
    end)
    |> Rinku.link(fn {:ok, instance} -> 
      case SomeSchema.save(instance) do
        {:ok, _result} = result -> result
        {:error, :forbidden} -> {:error, :not_allowed_to_save}
      end
    end)
    |> Rinku.run()
    |> Rinku.result()
  end
end
```

## Installation

Rinku is not in Hex.
You can install it directly via Git.

```elixir
  def deps do
    [
        {:rink, github: "adigitalmonk/rinku", branch: "master"}
    ]
  end
```
