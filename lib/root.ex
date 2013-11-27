defmodule Root do
  # require Homemount
  use Lazymaru.Router

  mount Homemount
  get "/abcd/:id" do
    IO.puts "root get params"
    IO.inspect params
  end

  get do
    IO.puts "root get"
  end
end