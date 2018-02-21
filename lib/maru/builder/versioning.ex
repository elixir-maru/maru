defmodule Maru.Builder.Versioning do
  @moduledoc """
  Base versioning adapter with default functions.
  """

  defmacro __using__(_) do
    quote do
      @doc false
      def get_version_plug(_opts), do: []

      @doc false
      def put_version_plug(_version), do: []

      @doc false
      def path_for_params(path, _version) do
        Enum.filter(path, fn
          {:version} -> false
          _ -> true
        end)
      end

      @doc false
      def conn_for_match(:match, version, path) do
        quote do
          %Plug.Conn{
            path_info: unquote(path_for_match(path)),
            private: %{
              maru_version: unquote(version)
            }
          }
        end
      end

      @doc false
      def conn_for_match(method, version, path) do
        method = method |> to_string |> String.upcase()

        quote do
          %Plug.Conn{
            method: unquote(method),
            path_info: unquote(path_for_match(path)),
            private: %{
              maru_version: unquote(version)
            }
          }
        end
      end

      @doc false
      def path_for_match(path) do
        path
        |> Enum.filter(fn
          {:version} -> false
          _ -> true
        end)
        |> Enum.map(fn
          x when is_atom(x) -> Macro.var(:_, nil)
          x -> x
        end)
      end

      defoverridable get_version_plug: 1,
                     put_version_plug: 1,
                     path_for_params: 2,
                     conn_for_match: 3,
                     path_for_match: 1
    end
  end

  @doc "return adapter by versioning strategy."
  def get_adapter(nil), do: Maru.Builder.Versioning.None
  def get_adapter(:path), do: Maru.Builder.Versioning.Path
  def get_adapter(:accept_version_header), do: Maru.Builder.Versioning.AcceptVersionHeader
  def get_adapter(:param), do: Maru.Builder.Versioning.Parameter
  def get_adapter(:accept_header), do: Maru.Builder.Versioning.AcceptHeader

  def get_adapter(strategy) do
    Maru.Utils.warn("Unsupported versioning strategy: #{strategy}, Ignore.")
    Maru.Builder.Versioning.None
  end
end
