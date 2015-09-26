defmodule Maru.Config do
  @defaults [ port: 4000, ssl: false ]

  @doc false
  def servers do
    for {k, v} <- Application.get_all_env(:maru),
    not k in [:included_applications] do
      {k, v}
    end
  end

  @doc false
  def server_config(module) do
    Application.get_env :maru, module
  end

end
