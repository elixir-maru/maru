defmodule Homepage do
  use Lazymaru.Router

  resource :hp do
    post do
      IO.puts "hp post"
      IO.inspect params
    end

    route_param :id do
      get do
        IO.puts "hp id get"
        IO.inspect params
      end
    end
  end

  # resources :hello do
  #   desc "post desc hello"
  #   post do
  #     IO.puts "post hello"
  #   end

  #   resources :world do
  #     desc "desc hello world"
  #     get do
  #       IO.puts "hello world"
  #     end

  #     group :hi do
  #       desc "desc hello world hi"
  #       get do
  #         IO.puts "hello world hi"
  #       end

  #       post do
  #         IO.puts "post hello world hi"
  #       end

  #       route_param :id do
  #         get do
  #           IO.puts "id param id"
  #           IO.inspect params
  #         end
  #       end

  #     end
  #   end
  # end
end