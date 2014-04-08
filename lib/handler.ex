defmodule Lazymaru.Handler do
  def init(_tran, req, service) do
    {:ok, req, service}
  end

  def handle(req, mod) do
    {method, _} = :cowboy_req.method(req)
    method = method |> String.downcase |> binary_to_atom
    {path, _} = :cowboy_req.path_info(req)
    # TODO rescue 404
    try do
      case mod.service(method, path, req) do
        {:ok, new_req} -> {:ok, new_req, mod}
        _ -> {:ok, req, mod}
      end
    rescue
      FunctionClauseError ->
        IO.puts "404 NotFound: #{path}"
    end
  end

  def terminate(_, _, _) do
    :ok
  end
end