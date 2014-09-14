defmodule Lazymaru.Config do
  @defaults [ port: 4000, ssl: false ]

  def servers do
    for {k, v} <- Application.get_all_env(:lazymaru),
    not k in [:included_applications] do
      {k, v}
    end
  end

  def is_server?(module) do
    case Application.get_env :lazymaru, module do
      nil -> false
      _ -> true
    end
  end

end
