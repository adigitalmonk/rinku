defmodule Rinku.Link do
  @moduledoc """
  Structure of a link in a Rinku chain.
  """

  defstruct [:name, :callback]
  alias Rinku.Resolved

  @type t :: %__MODULE__{
          name: String.t() | atom(),
          callback: Rinku.link_callback()
        }

  @spec new(callback :: Rinku.link_callback(), name :: String.t() | atom()) :: t()
  def new(callback, name) do
    %__MODULE__{
      name: name,
      callback: callback
    }
  end

  @doc false
  @spec resolve(t(), any) :: Resolved.t()
  def resolve(%__MODULE__{name: name, callback: {mod, func, arguments}}, link_input) do
    arguments = [link_input | put_into_list(arguments)]

    apply(mod, func, arguments)
    |> Resolved.new(name)
  end

  def resolve(%__MODULE__{name: name, callback: {func, arguments}}, link_input) do
    arguments = [link_input | put_into_list(arguments)]

    apply(func, arguments)
    |> Resolved.new(name)
  end

  def resolve(%__MODULE__{name: name, callback: func}, link_input) do
    apply(func, [link_input])
    |> Resolved.new(name)
  end

  defp put_into_list(item) when is_list(item), do: item
  defp put_into_list(item), do: [item]
end
