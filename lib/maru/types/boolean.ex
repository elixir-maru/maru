defmodule Maru.Types.Boolean do
  use Maru.Type

  def parse(true, _),    do: true
  def parse("true", _),  do: true
  def parse(nil, _),     do: false
  def parse(false, _),   do: false
  def parse("false", _), do: false

end
