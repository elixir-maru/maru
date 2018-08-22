defmodule Maru.ServerTest do
  use ExUnit.Case, async: true

  describe "server test" do
    Application.put_env(:maru_test_otp_app, Maru.ServerTest.S, [plug: Maru.ServerTest.R])
    Application.get_all_env(:maru_test_otp_app)
    defmodule S do
      use Maru.Server, otp_app: :maru_test_otp_app

      def init(:supervisor, opts), do: {:ok, opts}
      def init(:runtime, opts), do: {:ok, Keyword.put(opts, :port, 7113)}
    end

    defmodule R do
      use S

      get do
        text(conn, "ok")
      end
    end

    test "supervisor child spec" do
      assert %{
        id: {:ranch_listener_sup, Maru.ServerTest.R.HTTP},
        modules: [:ranch_listener_sup],
        restart: :permanent,
        shutdown: :infinity,
        start: {:ranch_listener_sup, :start_link,
                [
                  Maru.ServerTest.R.HTTP,
                  100,
                  :ranch_tcp,
                  [
                    num_acceptors: 100,
                    max_connections: 16384,
                    ip: {127, 0, 0, 1},
                    port: 4000
                  ],
                  :cowboy_clear,
                  %{
                    env: %{
                      dispatch: [
                        {:_, [],
                         [{:_, [], Plug.Adapters.Cowboy2.Handler, {Maru.ServerTest.R, []}}]}
                      ]
                    }
                  }
                ]},
        type: :supervisor
      } = S.child_spec([])
    end

    test "runtime server" do
      {:ok, _pid} = S.start_link([])
      assert {:ok, {_, _, 'ok'}} = :httpc.request('http://127.0.0.1:7113')
      :ok = Plug.Adapters.Cowboy2.shutdown(Maru.ServerTest.R.HTTP)
    end
  end
end
