defmodule Rinku do
  @moduledoc """
  A pattern for composing function calls in a specific order.
  Will stops the chain early on an error or failure.

  The initial value "input" will be provided as the first argument into the chain.
  The result of each link in the chain will be supplied to the next link in the chain.

  The input will always be the first argument provided to the next link in the chain.
  """
  defstruct [:links, :result]
  alias Rinku.Link

  @type t() :: %__MODULE__{}
  @type link() ::
          (... -> any() | {:error, any()})
          | {(... -> any() | {:error, any()}), term() | list()}
          | {module(), atom(), term() | list()}

  @doc """
  Create a new Rinku chain.

  iex> Rinku.new()
  %Rinku{links: []}
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      links: []
    }
  end

  @doc """
  Add a new step to the Rinku chain.
  Either an anonymous function that takes one argument or a tuple of `{module, function, arguments}` can be provided.

  iex> Rinku.new() |> Rinku.link({SomeModule, :some_func, 1}, :some_link)
  %Rinku{
    links: [
      %Rinku.Link{
        name: :some_link,
        callback: {SomeModule, :some_func, 1}
      }
    ]
  }
  """
  @spec link(chain :: t(), new_link :: link(), link_name :: String.t() | atom()) :: t()
  def link(%__MODULE__{links: links} = chain, new_link, link_name \\ nil) do
    link = Link.new(new_link, link_name)
    %__MODULE__{chain | links: [link | links]}
  end

  @doc """
  Execute a built rinku chain.
  """
  @spec run(t()) :: t()
  def run(%__MODULE__{links: links} = chain, input \\ nil, first_data_name \\ :seed) do
    initial_link = %Link{result: input, name: first_data_name}

    [final | _] =
      processed_links =
      links
      |> Enum.reverse()
      |> Enum.reduce_while([initial_link], fn link, [previous | _processed] = links ->
        processed_link = Link.process_link(link, previous.result)

        end_loop(processed_link.result, [processed_link | links])
      end)

    %__MODULE__{
      chain
      | links: processed_links,
        result: final.result
    }
  end

  @spec end_loop(Link.t(), list()) :: {:cont, any()} | {:halt, any()}
  defp end_loop(result, updated_links) when is_tuple(result) do
    if elem(result, 0) == :error do
      {:halt, updated_links}
    end
  end

  defp end_loop(:error, updated_links), do: {:halt, updated_links}
  defp end_loop(_loop_result, updated_links), do: {:cont, updated_links}

  @doc """
  Get the result from a processed chain.
  """
  @spec result(t()) :: any() | {:error, any()}
  def result(%__MODULE__{result: result}), do: result

  @spec link_result(t(), link_name :: String.t()) :: any() | {:error, any()}
  def link_result(%__MODULE__{links: links}, link_name) do
    case Enum.find(links, &(&1.name == link_name)) do
      nil -> nil
      link -> link.result
    end
  end
end
