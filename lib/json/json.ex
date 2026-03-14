defmodule ParserCombinator.JSON do
  @moduledoc """
  JSON parser built on ParserCombinator.
  """

  alias ParserCombinator, as: P

  @type json_value ::
          nil
          | boolean
          | number
          | String.t()
          | [json_value]
          | %{optional(String.t()) => json_value}

  @spec parser() :: P.parser(json_value)
  def parser do
    lexeme(value_parser())
  end

  @spec parse(String.t()) :: P.parse_result(json_value)
  def parse(input) do
    parser =
      parser()
      |> P.bind(fn value ->
        P.eof()
        |> P.map(fn _ -> value end)
      end)

    P.run(parser, input)
  end

  defp lexeme(parser), do: P.token(parser)

  defp lazy(fun) when is_function(fun, 0) do
    fn input -> fun.().(input) end
  end

  defp value_parser do
    object_parser()
    |> P.choice(array_parser())
    |> P.choice(string_parser())
    |> P.choice(number_parser())
    |> P.choice(true_parser())
    |> P.choice(false_parser())
    |> P.choice(null_parser())
  end

  defp null_parser do
    "null"
    |> P.string()
    |> P.map(fn _ -> nil end)
  end

  defp true_parser do
    "true"
    |> P.string()
    |> P.map(fn _ -> true end)
  end

  defp false_parser do
    "false"
    |> P.string()
    |> P.map(fn _ -> false end)
  end

  defp number_parser do
    sign = P.optional(P.char("-"))

    integer =
      P.choice(
        P.map(P.char("0"), fn _ -> "0" end),
        P.bind(non_zero_digit(), fn first ->
          P.map(P.many(P.digit()), fn rest -> first <> Enum.join(rest) end)
        end)
      )

    fraction =
      P.optional(
        P.bind(P.char("."), fn _ ->
          P.bind(P.many1(P.digit()), fn digits ->
            P.pure("." <> Enum.join(digits))
          end)
        end)
      )

    exponent =
      P.optional(
        P.bind(P.choice(P.char("e"), P.char("E")), fn e ->
          P.bind(P.optional(P.choice(P.char("+"), P.char("-"))), fn exp_sign ->
            P.bind(P.many1(P.digit()), fn digits ->
              sign_str = exp_sign || ""
              P.pure(e <> sign_str <> Enum.join(digits))
            end)
          end)
        end)
      )

    P.bind(sign, fn sign_char ->
      P.bind(integer, fn int_part ->
        P.bind(fraction, fn frac_part ->
          P.bind(exponent, fn exp_part ->
            sign_str = sign_char || ""
            frac_str = frac_part || ""
            exp_str = exp_part || ""
            number_str = sign_str <> int_part <> frac_str <> exp_str

            value =
              if frac_part != nil or exp_part != nil do
                float_str =
                  if exp_part != nil and frac_part == nil do
                    sign_str <> int_part <> ".0" <> exp_str
                  else
                    number_str
                  end

                {float_value, ""} = Float.parse(float_str)
                float_value
              else
                String.to_integer(number_str)
              end

            P.pure(value)
          end)
        end)
      end)
    end)
  end

  defp non_zero_digit do
    P.satisfy(fn ch -> ch >= "1" and ch <= "9" end, "non-zero digit")
  end

  defp string_parser do
    quote = P.char("\"")
    char = P.choice(escaped_char(), unescaped_char())

    P.bind(quote, fn _ ->
      P.bind(P.many(char), fn chars ->
        P.map(quote, fn _ -> Enum.join(chars) end)
      end)
    end)
  end

  defp unescaped_char do
    P.satisfy(
      fn ch ->
        ch != "\"" and ch != "\\" and
          case ch do
            <<codepoint::utf8>> -> codepoint >= 0x20
          end
      end,
      "string character"
    )
  end

  defp escaped_char do
    P.bind(P.char("\\"), fn _ ->
      P.choice(unicode_escape(), simple_escape())
    end)
  end

  defp simple_escape do
    P.bind(escape_code(), fn code ->
      P.pure(escape_value(code))
    end)
  end

  defp escape_code do
    P.satisfy(
      fn ch -> ch in ["\"", "\\", "/", "b", "f", "n", "r", "t"] end,
      "escape code"
    )
  end

  defp escape_value("\""), do: "\""
  defp escape_value("\\"), do: "\\"
  defp escape_value("/"), do: "/"
  defp escape_value("b"), do: "\b"
  defp escape_value("f"), do: "\f"
  defp escape_value("n"), do: "\n"
  defp escape_value("r"), do: "\r"
  defp escape_value("t"), do: "\t"

  defp unicode_escape do
    P.bind(P.char("u"), fn _ ->
      P.bind(hex_digit(), fn d1 ->
        P.bind(hex_digit(), fn d2 ->
          P.bind(hex_digit(), fn d3 ->
            P.bind(hex_digit(), fn d4 ->
              codepoint = String.to_integer(d1 <> d2 <> d3 <> d4, 16)
              P.pure(<<codepoint::utf8>>)
            end)
          end)
        end)
      end)
    end)
  end

  defp hex_digit do
    P.satisfy(
      fn ch ->
        (ch >= "0" and ch <= "9") or (ch >= "A" and ch <= "F") or
          (ch >= "a" and ch <= "f")
      end,
      "hex digit"
    )
  end

  defp array_parser do
    value = lexeme(lazy(&value_parser/0))
    elements = P.sep_by(value, lexeme(P.char(",")))

    P.between(lexeme(P.char("[")), lexeme(P.char("]")), elements)
  end

  defp object_parser do
    value = lexeme(lazy(&value_parser/0))
    key = lexeme(string_parser())

    member =
      P.bind(key, fn parsed_key ->
        P.bind(lexeme(P.char(":")), fn _ ->
          P.bind(value, fn parsed_value ->
            P.pure({parsed_key, parsed_value})
          end)
        end)
      end)

    members = P.sep_by(member, lexeme(P.char(",")))

    P.map(
      P.between(lexeme(P.char("{")), lexeme(P.char("}")), members),
      fn pairs ->
        Map.new(pairs)
      end
    )
  end
end
