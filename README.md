# Rinku

![Continuous Integration Status](https://github.com/adigitalmonk/rinku/actions/workflows/elixir.yaml/badge.svg)

Rinku is a simple abstraction to enable linking a series of steps.

To begin, multiple steps are linked together using `Rinku.link`.
Once we've built a chain of steps, the `run` function will accept an initial input and begin the chain.
One by one, each function is called in the order added to the chain.

At the end of a function's execution, the result is passed the first argument for the next.
The chain will end immediately if any function returns a tuple with `:error` as the first element.
Once the chain exhausts all of it's links, the `result` function will extract the final result.

```elixir
3 =
  Rinku.new()
  |> Rinku.link(fn input -> input + 1 end)
  |> Rinku.link(fn input -> input + 1 end)
  |> Rinku.run(1)
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
  Rinku.new()
  |> Rinku.link(fn _input -> :result1 end, :step1)
  |> Rinku.link(fn _input -> :result2 end, :step2)
  |> Rinku.link(fn _input -> :result3 end, :step3)
  |> Rinku.run(:input_value, :input_name)

assert processed_chain |> Rinku.link_result(:input_name) == :input_value
assert processed_chain |> Rinku.link_result(:step1) == :result1
assert processed_chain |> Rinku.link_result(:step2) == :result2
assert processed_chain |> Rinku.link_result(:step3) == :result3
```

See [Practical Examples](#practical-examples) for more realistic use cases.

## Developing

For the Elixir/Erlang versions, please refer to the supplied `.tool-versions` (compatible with `asdf`).

## Practical Examples

A scenario where we want to accept an arbitrary map, convert it into an Ecto schema, then save it to a database.
In the `SomeContext` module, there are two functions showcasing the same logic.
One function uses a `with` chain, the other uses a `Rinku` chain.

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
    Rinku.new()
    |> Rinku.link({SomeSchema, :changeset, []})
    |> Rinku.link({SomeSchema, :coerce, []})
    |> Rinku.link({SomeSchema, :save, access_token})
    |> Rinku.run(record_params)
    |> Rinku.result()
    |> case do
      {:error, %Ecto.Changeset{} = error_changeset} -> {:error, :invalid_params, error_changeset}
      {:error, :forbbiden} -> {:error, :not_allowed_to_save}
      {:ok, _result} = result -> result
    end
  end

  def create_via_rinku_alt(record_params, access_token) do
    Rinku.new()
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
    |> Rinku.run(record_params)
    |> Rinku.result()
  end
end
```

## Installation

Rinku is not currently in Hex.
You can install it directly via Git.

```elixir
  def deps do
    [
        {:rink, github: "adigitalmonk/rinku", branch: "master"}
    ]
  end
```
