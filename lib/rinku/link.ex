defmodule Rinku.Link do
  @moduledoc false

  @type t() :: %__MODULE__{}
  @type callback() :: Linku.link()

  defstruct [:name, :callback, :result]

  @spec new(callback :: callback(), name :: String.t() | atom()) :: t()
  def new(callback, name) do
    %__MODULE__{
      name: name,
      callback: callback
    }
  end

  @spec result(t(), any()) :: t()
  def result(link, value) do
    %__MODULE__{
      link
      | result: value
    }
  end

  @doc false
  @spec process_link(t(), any) :: any
  def process_link(%__MODULE__{callback: {mod, func, arguments}} = link, link_input) do
    arguments = [link_input | put_into_list(arguments)]

    result(link, apply(mod, func, arguments))
  end

  def process_link(%__MODULE__{callback: {func, arguments}} = link, link_input) do
    arguments = [link_input | put_into_list(arguments)]

    result(link, apply(func, arguments))
  end

  def process_link(%__MODULE__{callback: func} = link, link_input) do
    result(link, apply(func, [link_input]))
  end

  defp put_into_list(item) when is_list(item), do: item
  defp put_into_list(item), do: [item]
end
