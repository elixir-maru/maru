defmodule Lazymaru.Router.Params do

  defstruct parsers: [], params: []

  # TODO raise exception when param name repeated
  def merge(p, nil), do: p
  def merge(nil, p), do: p
  def merge(%__MODULE__{parsers: parsers1, params: params1},
            %__MODULE__{parsers: parsers2, params: params2}) do
    %__MODULE__{
      parsers: (parsers1 ++ parsers2) |> Enum.uniq,
      params: (params1 ++ params2) |> Enum.uniq(& &1[:param]),
    }
  end

  def default do
    %__MODULE__{
      parsers: [Plug.Parsers.URLENCODED, Plug.Parsers.MULTIPART],
      params: [],
    }
  end

end
