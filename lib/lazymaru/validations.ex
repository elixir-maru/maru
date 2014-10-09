defmodule Lazymaru.Validations do
  defmodule Regexp do
    def validate_param!(attr_name, value, option) do
      value |> to_string =~ option ||
        Lazymaru.Exceptions.Validation |> raise [param: attr_name, validator: :regexp, value: value, option: option]
    end
  end

  defmodule Values do
    def validate_param!(attr_name, value, option) do
      value in option ||
        Lazymaru.Exceptions.Validation |> raise [param: attr_name, validator: :values, value: value, option: option]
    end
  end

  defmodule AllowBlank do
    def validate_param!(_, _, true), do: true
    def validate_param!(attr_name, value, false) do
      not value in [nil, "", ''] ||
        Lazymaru.Exceptions.Validation |> raise [param: attr_name, validator: :allow_blank, value: value, option: false]
    end
  end

  # defmodule MutuallyExclusive do
  #   def validator!(params, group, values) do

  #   end
  # end

  # mutually_exclusive
  # exactly_one_of
  # at_least_one_of
  # group
end
