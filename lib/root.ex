defmodule Root do
  require Homemount
  use Lazymaru.Router

  mount Homemount
end