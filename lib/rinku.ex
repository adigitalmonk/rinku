defmodule Rinku do
  @moduledoc """
  A pattern for composing functions to execute in a chain.
  Execution will stop when all links in the chain have been resolved, or any link in the chain returns an error.

  The initial input will be provided as the first argument in the chain.
  The result of each link in the chain will be supplied to the next link in the chain.

  The input will always be the first argument provided to the next link in the chain.
  """
  defstruct [:links, :resolved, :result]
  alias Rinku.Link
  alias Rinku.Resolved

  @type t() :: %__MODULE__{
          links: [Link.t()],
          resolved: [Resolved.t()],
          result: any()
        }

  @type link_callback() ::
          (... -> any() | {:error, any()})
          | {(... -> any() | {:error, any()}), term() | list()}
          | {module(), atom(), term() | list()}

  @doc """
  Create a new Rinku chain.

      iex> Rinku.new()
      %Rinku{
        links: [],
        resolved: [
          %Rinku.Resolved{
            name: :seed,
            result: nil
          }
        ],
        result: nil
      }
  """
  @spec new(initial_value :: any(), input_name :: String.t() | atom()) :: t()
  def new(intial_value \\ nil, input_name \\ :seed) do
    %__MODULE__{
      links: [],
      resolved: [%Resolved{result: intial_value, name: input_name}],
      result: nil
    }
  end

  @doc """
  Add a new link to the Rinku chain.
  """
  @spec link(rinku :: t(), new_link :: link_callback(), link_name :: String.t() | atom()) :: t()
  def link(%__MODULE__{links: links} = rinku, new_link, link_name \\ nil) do
    link = Link.new(new_link, link_name)
    %__MODULE__{rinku | links: [link | links]}
  end

  @doc """
  Execute a built rinku chain.
  """
  @spec run(rinku :: t()) :: t()
  def run(%__MODULE__{links: links, resolved: resolved} = rinku) do
    [final | _] =
      resolved_links =
      links
      |> Enum.reverse()
      |> Enum.reduce_while(resolved, fn link, [previous | _resolved] = links ->
        resolved_link = Link.resolve(link, previous.result)

        end_loop(resolved_link.result, [resolved_link | links])
      end)

    %__MODULE__{
      rinku
      | resolved: resolved_links,
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

      iex> Rinku.new() |> Rinku.link(fn _ -> 1 end) |> Rinku.run() |> Rinku.result()
      1
  """
  @spec result(rinku :: t()) :: any() | {:error, any()}
  def result(%__MODULE__{result: result}), do: result

  @doc """
  Get the result for a specific named execution step.

      iex> Rinku.new() |> Rinku.link(fn _ -> 1 end, :step1) |> Rinku.link(fn _ -> 2 end, :step2) |> Rinku.run() |> Rinku.link_result(:step1)
      1
  """
  @spec link_result(rinku :: t(), link_name :: String.t()) :: any() | {:error, any()}
  def link_result(%__MODULE__{resolved: resolved}, resolved_name) do
    case Enum.find(resolved, &(&1.name == resolved_name)) do
      nil -> nil
      resolved -> resolved.result
    end
  end
end
