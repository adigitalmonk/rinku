defmodule Rinku.Resolved do
  @moduledoc """
  Structure of a resolved link
  """

  defstruct [:name, :result]

  @type t :: %__MODULE__{
          name: String.t() | atom(),
          result: any()
        }

  @doc false
  @spec new(result :: any(), name :: String.t() | atom()) :: t()
  def new(result, name) do
    %__MODULE__{
      name: name,
      result: result
    }
  end
end
