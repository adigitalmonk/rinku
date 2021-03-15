defmodule Rinku.Link do
  @moduledoc false

  @opaque t() :: %__MODULE__{}
  @type link_function() :: (... -> any() | {:error, any()})
  @type link() ::
          link_function()
          | {link_function(), term() | list()}
          | {module(), atom(), term() | list()}

  defstruct [:name, :callback, :output]

  @spec new(link(), any) :: Rinku.Link.t()
  def new(callback, name \\ "Link") do
    %__MODULE__{
      name: name,
      callback: callback
    }
  end

  @doc false
  @spec process_link(Rinku.Link.t(), any) :: any
  def process_link(%__MODULE__{callback: {mod, func, arguments}}, link_input) do
    arguments =
      case is_list(arguments) do
        true -> [link_input | arguments]
        false -> [link_input, arguments]
      end

    apply(mod, func, arguments)
  end

  def process_link(%__MODULE__{callback: {func, arguments}}, link_input) do
    arguments =
      case is_list(arguments) do
        true -> [link_input | arguments]
        false -> [link_input, arguments]
      end

    apply(func, arguments)
  end

  def process_link(%__MODULE__{callback: func}, link_input) do
    apply(func, [link_input])
  end
end
