defmodule Homemount do
  use Lazymaru.Router

  resource :mount_test do
    mount Homepage
    mount Homepage2
  end
end