defmodule Rinku do
  @moduledoc """
  A pattern for composing function calls in a specific order.
  Will stops the chain early on an error or failure.

  The initial value "input" will be provided as the first argument into the chain.
  The result of each link in the chain will be supplied to the next link in the chain.

  The input will always be the first argument provided to the next link in the chain.
  """
  defstruct [:input, :links]

  @opaque t() :: %__MODULE__{}
  @type link_function() :: (... -> any() | {:error, any()})
  @type link() ::
          link_function()
          | {link_function(), term() | list()}
          | {module(), atom(), term() | list()}

  @doc """
  Create a new Rinku chain.

  iex> Rinku.new("test")
  %Rinku{ input: "test", links: []}
  """
  @spec new(any()) :: t()
  def new(input \\ nil) do
    %__MODULE__{
      input: input,
      links: []
    }
  end

  @doc """
  Add a new step to the Rinku chain.
  Either an anonymous function that takes one argument or a tuple of `{module, function, arguments}` can be provided.

  iex> Rinku.new("test") |> Rinku.link({SomeModule, :some_func, 1})
  %Rinku{input: "test", links: [{SomeModule, :some_func, 1}]}
  """
  @spec link(t(), link()) :: t()
  def link(%__MODULE__{links: links} = chain, new_link) do
    %__MODULE__{chain | links: [new_link | links]}
  end

  @doc """
  Execute a built rinku chain.
  """
  @spec run(t()) :: {:ok, any()} | {:error, any()}
  def run(%__MODULE__{input: chain_input, links: links}) do
    links
    |> Enum.reverse()
    |> Enum.reduce_while(chain_input, fn link, link_input ->
      process_link(link, link_input)
      |> case do
        {:error, _error} = error -> {:halt, error}
        output -> {:cont, output}
      end
    end)
  end

  defp process_link({mod, func, arguments}, link_input) do
    arguments =
      case is_list(arguments) do
        true -> [link_input | arguments]
        false -> [link_input, arguments]
      end

    apply(mod, func, arguments)
  end

  defp process_link({func, arguments}, link_input) do
    arguments =
      case is_list(arguments) do
        true -> [link_input | arguments]
        false -> [link_input, arguments]
      end

    apply(func, arguments)
  end

  defp process_link(func, link_input) do
    apply(func, [link_input])
  end
end
