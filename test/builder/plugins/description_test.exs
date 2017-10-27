defmodule Maru.Builder.DescriptionTest do
  use ExUnit.Case, async: true

  test "description" do
    defmodule DescTest do
      use Maru.Router

      desc "desc test"

      def d, do: @desc
    end

    assert %{summary: "desc test"} = DescTest.d
  end

  test "description with block" do
    defmodule DescTestWithBlock do
      use Maru.Router

      desc "desc test" do
        detail """
        this is detail
        """

        responses do
          status 200, desc: "ok"
          status 500, desc: "error"
        end
      end

      def d, do: @desc
    end
    assert %{
      summary: "desc test",
      detail:  "this is detail\n",
      responses: [
        %{code: 200, description: "ok"},
        %{code: 500, description: "error"},
      ]
    } = DescTestWithBlock.d
  end
end
