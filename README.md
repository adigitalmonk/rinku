# Rinku

Rinku is a simple abstraction to enable linking a series of steps.

To begin, multiple steps are linked together using `Rinku.link`.
Once we've built a chain of steps, the `run` function will begin the chain.
One by one, each function is called.
At the end of a function's execution, the result is passed the first argument for the next.
The chain will end immediately if any function returns a tuple with `:error` as the first element.
Once the chain exhausts all of it's links, it will return the result of the final link.

```elixir
3 =
  1
  |> Rinku.new()
  |> Rinku.link(fn input -> input + 1 end)
  |> Rinku.link(fn input -> input + 1 end)
  |> Run.run()

{:error, :oh_no} = 
  Rinku.new()
  |> Rinku.link(fn _ -> {:error, :on_no} end)
  |> Rinku.link(fn _input -> 10 end)
  |> Rinku.run()
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
  def create_with_with(record_params, access_token) do
    with {:ok, changeset} <- SomeSchema.changeset(record_params),
         {:ok, struct} <- SomeSchema.coerce(changeset),
         {:ok, result} = result <- SomeSchema.save(struct, access_token) do
         result
    else
      {:error, %Ecto.Changeset{} = error_changeset} -> 
        {:error, :invalid_params, error_changeset}
      {:error, :forbidden} ->
        {:error, :not_allowed_to_save}
    end
  end

  def create_with_rinku(record_params, access_token) do
    record_params
    |> Rinku.new()
    |> Rinku.link({SomeSchema, :changeset, []})
    |> Rinku.link({SomeSchema, :coerce, []})
    |> Rinku.link({SomeSchema, :save, access_token})
    |> Rinku.run()
    |> case do
      {:error, %Ecto.Changeset{} = error_changeset} -> 
        {:error, :invalid_params, error_changeset}
      {:error, :forbbiden} -> 
        {:error, :not_allowed_to_save}
      {:ok, _result} = result -> 
        result
    end
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
