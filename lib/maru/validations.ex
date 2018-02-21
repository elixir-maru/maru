defmodule Maru.Validations do
  defmodule Regexp do
    @moduledoc """
    Param Validator: check whether param and regexp matched.
    """

    @doc false
    def validate_param!(attr_name, values, option) when is_list(values) do
      for value <- values do
        validate_param!(attr_name, value, option)
      end
    end

    def validate_param!(attr_name, value, option) do
      value |> to_string =~ option ||
        Maru.Exceptions.Validation
        |> raise(param: attr_name, validator: :regexp, value: value, option: option)
    end
  end

  defmodule Values do
    @moduledoc """
    Param Validator: check whether param in list or range.
    """

    @doc false
    def validate_param!(attr_name, value, option) do
      value in option ||
        Maru.Exceptions.Validation
        |> raise(param: attr_name, validator: :values, value: value, option: option)
    end
  end

  defmodule AllowBlank do
    @moduledoc """
    Param Validator: check whether black value is illegal.
    """

    @doc false
    def validate_param!(_, _, true), do: true

    def validate_param!(attr_name, value, false) do
      not Maru.Utils.is_blank(value) ||
        Maru.Exceptions.Validation
        |> raise(param: attr_name, validator: :allow_blank, value: value, option: false)
    end
  end

  defmodule MutuallyExclusive do
    @moduledoc """
    Param Validator: raise when exclusive params present at the same time.
    """

    @doc false
    def validate!(attr_names, params) do
      unless Enum.count(attr_names, &(not is_nil(params[&1]))) <= 1 do
        Maru.Exceptions.Validation
        |> raise(param: attr_names, validator: :mutually_exclusive, value: params)
      end

      true
    end
  end

  defmodule ExactlyOneOf do
    @moduledoc """
    Param Validator: make sure only one of designated params present.
    """

    @doc false
    def validate!(attr_names, params) do
      unless Enum.count(attr_names, &(not is_nil(params[&1]))) == 1 do
        Maru.Exceptions.Validation
        |> raise(param: attr_names, validator: :exactly_one_of, value: params)
      end

      true
    end
  end

  defmodule AtLeastOneOf do
    @moduledoc """
    Param Validator: make sure at least one of designated params present.
    """

    @doc false
    def validate!(attr_names, params) do
      unless Enum.count(attr_names, &(not is_nil(params[&1]))) >= 1 do
        Maru.Exceptions.Validation
        |> raise(param: attr_names, validator: :at_least_one_of, value: params)
      end

      true
    end
  end

  defmodule AllOrNoneOf do
    @moduledoc """
    Param Validator: make sure all or none of designated params present.
    """

    @doc false
    def validate!(attr_names, params) do
      unless Enum.count(attr_names, &(not is_nil(params[&1]))) in [0, length(attr_names)] do
        Maru.Exceptions.Validation
        |> raise(param: attr_names, validator: :all_or_none_of, value: params)
      end

      true
    end
  end
end
