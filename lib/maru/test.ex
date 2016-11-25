defmodule Maru.Test do
  @moduledoc """
  Unittest wrapper for designated router.
  """

  @doc """
  Prepare for Maru Test
  """
  def start do
    Maru.Builder.MountLink.start
    Mix.Project.compile_path
    |> to_char_list
    |> :cover.compile_beam_directory
    for module <- :cover.modules do
      if {:__mounted_modules__, 0} in module.__info__(:functions) do
        Enum.each(module.__mounted_modules__, fn mounted ->
          Maru.Builder.MountLink.put_father(mounted, module)
        end)
      end
    end
  end

  @doc false
  defmacro __using__(opts) do
    router = Keyword.fetch! opts, :for
    with_exception_handlers = Keyword.get(opts, :with_exception_handlers, false)
    warning_keys = Keyword.drop(opts, [:for, :with_exception_handlers]) |> Keyword.keys

    [router | fathers] =
      router
      |> Maru.Utils.split_router
      |> Enum.reverse

    [ quote do
        Maru.Utils.warning_unknown_opts(__MODULE__, unquote(warning_keys))

        import Plug.Test, except: [conn: 2, conn: 3]
        import Maru.Test
        import Plug.Conn

        @router unquote(router)
        @fathers unquote(fathers)
        @with_exception_handlers unquote(with_exception_handlers)
        @before_compile Maru.Builder.TestRouter

        # Deprecated
        defp make_response(conn), do: make_response(conn, nil)
        defp make_response(conn, version) do
          Maru.Utils.warn """
          warning: make_response/2 is deprecated. See build_conn/0 for more details.
          """

          router = unquote(router)
          version = version || router.__version__
          conn
          |> put_private(:maru_test, true)
          |> put_private(:maru_version, version)
          |> maru_test_call
        end

        defp make_response(conn, method, path) do
          make_response(conn, method, path, nil)
        end

        defp make_response(conn, method, path, version) do
          router         = unquote(router)
          version        = version || router.__version__
          body_or_params = conn.private[:maru_test_body_or_params]
          plugs          = conn.private[:maru_test_plugs] || []
          conn =
            conn
            |> put_private(:maru_version, version)
            |> Plug.Adapters.Test.Conn.conn(method, path, body_or_params)
          Enum.reduce(plugs, conn, fn {plug, opts}, conn ->
            plug.call(conn, plug.init(opts))
          end) |> maru_test_call
        end
      end |

      for method <- [:get, :post, :put, :patch, :delete, :head, :options] do
        quote do
          defp unquote(method)(%Plug.Conn{}=conn, path) do
            make_response(conn, unquote(method), path)
          end

          defp unquote(method)(%Plug.Conn{}=conn, path, version) do
            make_response(conn, unquote(method), path, version)
          end

          defp unquote(method)(path) do
            unquote(method)(build_conn(), path)
          end

          defp unquote(method)(path, version) do
            unquote(method)(build_conn(), path, version)
          end
        end
      end
    ]
  end

  @doc false
  def conn(method, path, params_or_body \\ nil) do
    Maru.Utils.warn """
    warning: using conn/3 to build a connection is deprecated. Use build_conn/0 instead.
    """
    Plug.Test.conn(method, path, params_or_body)
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
    %Plug.Conn{} |> Plug.Conn.put_private(:maru_test, true)
  end

  @doc """
  Put a plug called before endpoint into conn.
  """
  def put_plug(%Plug.Conn{}=conn, plug, opts) do
    plugs = (conn.private[:maru_test_plugs] || []) ++ [{plug, opts}]
    Plug.Conn.put_private(conn, :maru_test_plugs, plugs)
  end

  @doc """
  Put body or params into conn.
  """
  def put_body_or_params(%Plug.Conn{}=conn, body_or_params) do
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
    conn.resp_body |> Poison.decode!
  end

end
