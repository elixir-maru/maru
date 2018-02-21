defmodule Maru.Types.Boolean do
  @moduledoc """
  Buildin Type: Boolean
  """

  use Maru.Type

  @doc false
  def parse(true, _), do: true
  def parse("true", _), do: true
  def parse(nil, _), do: false
  def parse(false, _), do: false
  def parse("false", _), do: false
end
