defmodule Maru.Builder.DSLs do
  @moduledoc """
  General DSLs for parsing router.
  """

  alias Maru.Router.Resource
  alias Maru.Router.Path, as: MaruPath

  @doc """
  Define path prefix of current router.
  """
  defmacro prefix(path) do
    path = MaruPath.split path
    quote do
      %Resource{path: path} = resource = @resource
      @resource %{resource | path: path ++ (unquote path)}
    end
  end


  @doc """
  Define params block of current endpoint.
  """
  defmacro params(block) do
    quote do
      import Maru.Builder.Namespaces, only: []
      import Kernel, except: [use: 1]
      import Maru.Builder.Params
      @group []
      unquote(block)
      import Maru.Builder.Params, only: []
      import Kernel
      import Maru.Builder.Namespaces
    end
  end


  @doc """
  Define version of current router.
  """
  defmacro version(v) do
    quote do
      @version unquote(v)
    end
  end

  @doc """
  version: "v1", do ... end:
    Version of endpoints within block.

  version: "v2", extend: "v1", at: V1
    Define version and extended router of current router.
  """
  defmacro version(v, [do: block]) do
    quote do
      version = @version
      @version unquote(v)
      unquote(block)
      @version version
    end
  end

  defmacro version(v, [{:extend, _}, {:at, _} | _]=opts) do
    quote do
      @version unquote(v)
      @extend {Maru.Plugs.Extend, [{:version, unquote(v)} | unquote(opts)], true}
    end
  end

  @doc """
  Import helpers used by current router.
  """
  defmacro helpers([do: block]) do
    quote do
      import Maru.Helpers.Params
      import Kernel, except: [use: 1]
      unquote(block)
    end
  end

  defmacro helpers({_, _, mod}) do
    module = Module.concat mod
    quote do
      import Maru.Helpers.Params
      import unquote(module)
      unquote(module).__shared_params__ |> Enum.each(&(@shared_params &1))
    end
  end

  @doc """
  Define description do current endpoint.
  """
  defmacro desc(desc) do
    quote do
      @desc unquote(desc)
    end
  end

  @doc """
  Mount another router to current router.
  """
  defmacro mount({_, _, mod}) do
    module = Module.concat mod
    quote do
      @maru_router_plugs {Maru.Plugs.Router, [router: unquote(module), resource: @resource, version: @version], true}
    end
  end
end
