defmodule Homemount do
  require Homepage
  require Homepage2

  use Lazymaru.Router

  resource :mount_test do

    # mount Homepage
    # mount Homepage2

    get "test/:a/:b" do
    # get do
      IO.puts "mount test"
      IO.inspect params
    end
  end
end