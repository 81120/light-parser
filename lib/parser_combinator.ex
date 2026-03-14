defmodule ParserCombinator do
  @moduledoc """
  A small monadic parser combinator library.

  A parser is a function that takes an input string and returns either a
  successful result with the remaining input or an error.

  ## Examples

      iex> alias ParserCombinator, as: P
      iex> parser = P.token(P.integer())
      iex> P.run(parser, "  -123   ")
      {:ok, -123, ""}

      iex> alias ParserCombinator, as: P
      iex> parser = P.between(P.char("("), P.char(")"), P.integer())
      iex> P.run(parser, "(42)!")
      {:ok, 42, "!"}

      iex> alias ParserCombinator, as: P
      iex> parser = P.sep_by(P.token(P.integer()), P.char(","))
      iex> P.run(parser, "1, 2, 3")
      {:ok, [1, 2, 3], ""}
  """

  @type input :: String.t()
  @type parse_result(result) :: {:ok, result, input} | {:error, String.t()}
  @type parser(result) :: (input -> parse_result(result))

  defdelegate run(parser, input), to: ParserCombinator.Core
  defdelegate pure(value), to: ParserCombinator.Core
  defdelegate bind(parser, f), to: ParserCombinator.Core
  defdelegate map(parser, f), to: ParserCombinator.Core
  defdelegate satisfy(predicate, label), to: ParserCombinator.Core
  defdelegate char(expected), to: ParserCombinator.Core
  defdelegate string(expected), to: ParserCombinator.Core
  defdelegate seq(pa, pb), to: ParserCombinator.Core
  defdelegate choice(pa, pb), to: ParserCombinator.Core
  defdelegate many(parser), to: ParserCombinator.Core
  defdelegate many1(parser), to: ParserCombinator.Core
  defdelegate optional(parser), to: ParserCombinator.Core
  defdelegate eof(), to: ParserCombinator.Core

  defdelegate between(open, close, parser), to: ParserCombinator.Extras
  defdelegate sep_by(parser, sep), to: ParserCombinator.Extras
  defdelegate sep_by1(parser, sep), to: ParserCombinator.Extras
  defdelegate digit(), to: ParserCombinator.Extras
  defdelegate integer(), to: ParserCombinator.Extras
  defdelegate whitespace(), to: ParserCombinator.Extras
  defdelegate spaces(), to: ParserCombinator.Extras
  defdelegate token(parser), to: ParserCombinator.Extras
end
