defmodule ParserCombinator.Core do
  @type input :: String.t()
  @type parse_result(result) :: {:ok, result, input} | {:error, String.t()}
  @type parser(result) :: (input -> parse_result(result))

  @spec run(parser(result), input) :: parse_result(result) when result: var
  def run(parser, input), do: parser.(input)

  @spec pure(result) :: parser(result) when result: var
  def pure(value) do
    fn input -> {:ok, value, input} end
  end

  @spec bind(parser(result), (result -> parser(next))) :: parser(next)
        when result: var, next: var
  def bind(parser, f) do
    fn input ->
      case parser.(input) do
        {:ok, value, rest} ->
          f.(value).(rest)

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec map(parser(result), (result -> next)) :: parser(next)
        when result: var, next: var
  def map(parser, f) do
    bind(parser, fn value -> pure(f.(value)) end)
  end

  @spec satisfy((String.t() -> boolean), String.t()) :: parser(String.t())
  def satisfy(predicate, label) do
    fn
      "" ->
        {:error, "expected #{label}, got end of input"}

      <<char::utf8, rest::binary>> = _input ->
        if predicate.(<<char::utf8>>) do
          {:ok, <<char::utf8>>, rest}
        else
          {:error, "expected #{label}"}
        end
    end
  end

  @spec char(String.t()) :: parser(String.t())
  def char(expected) when is_binary(expected) and byte_size(expected) == 1 do
    satisfy(fn ch -> ch == expected end, inspect(expected))
  end

  @spec string(String.t()) :: parser(String.t())
  def string(expected) do
    fn input ->
      if String.starts_with?(input, expected) do
        rest = String.slice(input, String.length(expected)..-1//1)
        {:ok, expected, rest}
      else
        {:error, "expected #{inspect(expected)}"}
      end
    end
  end

  @spec seq(parser(a), parser(b)) :: parser({a, b}) when a: var, b: var
  def seq(pa, pb) do
    bind(pa, fn a -> map(pb, fn b -> {a, b} end) end)
  end

  @spec choice(parser(result), parser(result)) :: parser(result)
        when result: var
  def choice(pa, pb) do
    fn input ->
      case pa.(input) do
        {:ok, _, _} = ok -> ok
        {:error, _} -> pb.(input)
      end
    end
  end

  @spec many(parser(result)) :: parser([result]) when result: var
  def many(parser) do
    fn input ->
      do_many(parser, input, [])
    end
  end

  defp do_many(parser, input, acc) do
    case parser.(input) do
      {:ok, value, rest} -> do_many(parser, rest, [value | acc])
      {:error, _} -> {:ok, Enum.reverse(acc), input}
    end
  end

  @spec many1(parser(result)) :: parser([result]) when result: var
  def many1(parser) do
    bind(parser, fn first ->
      map(many(parser), fn rest -> [first | rest] end)
    end)
  end

  @spec optional(parser(result)) :: parser(result | nil) when result: var
  def optional(parser) do
    choice(parser, pure(nil))
  end

  @spec eof() :: parser(:eof)
  def eof do
    fn
      "" -> {:ok, :eof, ""}
      _ -> {:error, "expected end of input"}
    end
  end
end
