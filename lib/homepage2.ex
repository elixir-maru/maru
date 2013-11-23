defmodule Homepage2 do
  use Lazymaru.Router

  resource :hp2 do
    get do
      IO.puts "hp2 get"
      IO.inspect params
    end

    route_param :id do
      delete do
        IO.puts "delete hp2 id"
        IO.inspect params
      end
    end
  end

end