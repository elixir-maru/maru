defmodule Homemount do
  use Lazymaru.Router

  resource :mount_test do

    mount Homepage
    mount Homepage2

    get "test/:a/:b" do
      IO.puts "mount test"
      IO.inspect params
    end
  end
end