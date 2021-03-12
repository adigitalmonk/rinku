# Rinku

Rinku is a simple abstraction to enable linking a series of steps, stepping through them one by one, and returning the result of the final link in the chain.
If an error occurs along the way, it will stop early and return the error.

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
  |> Rinku.run()
```

See [Practical Examples](#practical-examples) for more realistic use cases.

## Developing

For the Elixir/Erlang versions, please refer to the supplied `.tool-versions` (compatible with `asdf`).

## Practical Examples

A scenario where we want to accept an arbitrary map, convert it into an Ecto schema, then save it to a database.

```elixir
defmodule SomeSchema do
  @callback changeset(params :: map()) :: Ecto.Changeset.t()
  @callback coerce(changeset :: Ecto.Changeset.t()) :: t() | {:error, Ecto.Changeset.t()}
  @callback save(t(), access_token) :: {:ok, t()} | {:error, :forbidden}
end

defmodule SomeContext do
  def create(record_params, access_token) do
    record_params
    |> Rinku.new()
    |> Rinku.link({SomeSchema, :changeset, []})
    |> Rinku.link({SomeSchema, :coerce, []})
    |> Rinku.link({SomeSchema, :save, access_token})
    |> Rinku.run()
    |> case do
      {:error, %Ecto.Changeset{}} = error -> error
      {:error, :forbbiden} -> {:error, :not_allowed_to_save}
      {:ok, _result} = result -> result
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
