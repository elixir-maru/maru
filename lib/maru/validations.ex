defmodule Maru.Validations do
  defmodule Regexp do
    def validate_param!(attr_name, value, option) do
      value |> to_string =~ option ||
        Maru.Exceptions.Validation |> raise [param: attr_name, validator: :regexp, value: value, option: option]
    end
  end

  defmodule Values do
    def validate_param!(attr_name, value, option) do
      value in option ||
        Maru.Exceptions.Validation |> raise [param: attr_name, validator: :values, value: value, option: option]
    end
  end

  defmodule AllowBlank do
    def validate_param!(_, _, true), do: true
    def validate_param!(attr_name, value, false) do
      not value in [nil, "", ''] ||
        Maru.Exceptions.Validation |> raise [param: attr_name, validator: :allow_blank, value: value, option: false]
    end
  end

  defmodule MutuallyExclusive do
    def validate!(attr_names, params) do
      unless Enum.count(attr_names, &(not is_nil(params[&1]))) <= 1 do
        Maru.Exceptions.Validation |> raise [param: attr_names, validator: :mutually_exclusive, value: params]
      end
      true
    end
  end

  defmodule ExactlyOneOf do
    def validate!(attr_names, params) do
      unless Enum.count(attr_names, &(not is_nil(params[&1]))) == 1 do
        Maru.Exceptions.Validation |> raise [param: attr_names, validator: :exactly_one_of, value: params]
      end
      true
    end
  end

  defmodule AtLeastOneOf do
    def validate!(attr_names, params) do
      unless Enum.count(attr_names, &(not is_nil(params[&1]))) >= 1 do
        Maru.Exceptions.Validation |> raise [param: attr_names, validator: :at_least_one_of, value: params]
      end
      true
    end
  end
end
