defmodule ParserCombinator.Extras do
  alias ParserCombinator.Core

  @type input :: String.t()
  @type parse_result(result) :: {:ok, result, input} | {:error, String.t()}
  @type parser(result) :: (input -> parse_result(result))

  @spec between(parser(term()), parser(term()), parser(result)) ::
          parser(result)
        when result: var
  def between(open, close, parser) do
    Core.bind(open, fn _ ->
      Core.bind(parser, fn value ->
        Core.map(close, fn _ -> value end)
      end)
    end)
  end

  @spec sep_by(parser(result), parser(term())) :: parser([result])
        when result: var
  def sep_by(parser, sep) do
    Core.choice(sep_by1(parser, sep), Core.pure([]))
  end

  @spec sep_by1(parser(result), parser(term())) :: parser([result])
        when result: var
  def sep_by1(parser, sep) do
    Core.bind(parser, fn first ->
      Core.bind(Core.many(Core.bind(sep, fn _ -> parser end)), fn rest ->
        Core.pure([first | rest])
      end)
    end)
  end

  @spec digit() :: parser(String.t())
  def digit do
    Core.satisfy(fn ch -> ch >= "0" and ch <= "9" end, "digit")
  end

  @spec integer() :: parser(integer)
  def integer do
    sign = Core.optional(Core.char("-"))

    Core.bind(sign, fn sign_char ->
      Core.bind(Core.many1(digit()), fn digits ->
        number = digits |> Enum.join() |> String.to_integer()
        value = if sign_char == "-", do: -number, else: number
        Core.pure(value)
      end)
    end)
  end

  @spec whitespace() :: parser(String.t())
  def whitespace do
    Core.satisfy(fn ch -> ch in [" ", "\t", "\n", "\r"] end, "whitespace")
  end

  @spec spaces() :: parser(String.t())
  def spaces do
    Core.map(Core.many(whitespace()), fn ws -> Enum.join(ws) end)
  end

  @spec token(parser(result)) :: parser(result) when result: var
  def token(parser) do
    Core.bind(spaces(), fn _ ->
      Core.bind(parser, fn value ->
        Core.map(spaces(), fn _ -> value end)
      end)
    end)
  end
end
