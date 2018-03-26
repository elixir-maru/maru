defmodule Maru.Test do
  @moduledoc """
  Unittest wrapper for designated router.
  """

  @doc false
  defmacro __using__(opts) do
    root =
      Keyword.get(opts, :root) ||
        case Maru.servers() do
          [{key, _}] ->
            key

          _any ->
            # TODO: more friendly information here
            raise "YOU HAVE MORE THAN ONE SERVER, MAKE CHOICE FROM FOLLOW ROOTS"
        end

    [
      quote do
        import Plug.Test, except: [conn: 2, conn: 3]
        import Maru.Test
        import Plug.Conn

        defp make_response(conn, method, path) do
          # TODO: if root using path for version, warning to put version in path
          root = unquote(root)
          body_or_params = conn.private[:maru_test_body_or_params]
          conn = conn |> Plug.Adapters.Test.Conn.conn(method, path, body_or_params)
          refute_received {:plug_conn, :sent}
          result = root.call(conn, [])

          case result do
            %Plug.Conn{state: :sent} ->
              receive do
                {_ref, {_code, _headers, _body}} -> :ok
              end

            _ ->
              :ok
          end

          receive do
            {:plug_conn, :sent} -> :ok
          end

          result
        end
      end
      | for method <- [:get, :post, :put, :patch, :delete, :head, :options] do
          quote do
            defp unquote(method)(%Plug.Conn{} = conn, path) do
              make_response(conn, unquote(method), path)
            end

            defp unquote(method)(path) do
              unquote(method)(build_conn(), path)
            end
          end
        end
    ]
  end

  @doc """
  Create a test connection.

  `get("/")` is used to test a simple request.
  `build_conn/0` is useful when test a complex request with headers or params.

  ## Examples

      get("/", "v1")
      build_conn() |> put_body_or_params("body params") |> post("/path", "v2")
      build_conn() |> put_req_header("Authorisation", "something") |> get("/path")

  """
  def build_conn() do
    %Plug.Conn{}
  end

  @doc """
  Put body or params into conn.
  """
  def put_body_or_params(%Plug.Conn{} = conn, body_or_params) do
    Plug.Conn.put_private(conn, :maru_test_body_or_params, body_or_params)
  end

  @doc """
  Get response from conn as text.
  """
  def text_response(conn) do
    conn.resp_body
  end

  @doc """
  Get response from conn as json.
  """
  def json_response(conn) do
    Jason.decode!(conn.resp_body)
  end
end
