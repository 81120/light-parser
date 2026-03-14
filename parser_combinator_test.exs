defmodule ParserCombinatorTest do
  use ExUnit.Case, async: true
  doctest ParserCombinator

  alias ParserCombinator, as: P

  test "pure returns value without consuming input" do
    assert P.run(P.pure(42), "abc") == {:ok, 42, "abc"}
  end

  test "bind sequences parsers" do
    parser = P.bind(P.char("a"), fn _ -> P.char("b") end)
    assert P.run(parser, "abc") == {:ok, "b", "c"}
    assert P.run(parser, "axc") == {:error, "expected \"b\""}
  end

  test "map transforms parser output" do
    parser = P.map(P.char("a"), fn _ -> :ok end)
    assert P.run(parser, "abc") == {:ok, :ok, "bc"}
  end

  test "satisfy and char" do
    assert P.run(P.satisfy(fn ch -> ch == "x" end, "x"), "xyz") ==
             {:ok, "x", "yz"}

    assert P.run(P.char("x"), "abc") == {:error, "expected \"x\""}
  end

  test "string matches prefix" do
    assert P.run(P.string("hello"), "hello world") == {:ok, "hello", " world"}
    assert P.run(P.string("hello"), "hey") == {:error, "expected \"hello\""}
  end

  test "seq combines results" do
    parser = P.seq(P.char("a"), P.char("b"))
    assert P.run(parser, "abc") == {:ok, {"a", "b"}, "c"}
  end

  test "choice tries first then second" do
    parser = P.choice(P.char("a"), P.char("b"))
    assert P.run(parser, "abc") == {:ok, "a", "bc"}
    assert P.run(parser, "bcd") == {:ok, "b", "cd"}
    assert P.run(parser, "cde") == {:error, "expected \"b\""}
  end

  test "many and many1" do
    parser = P.many(P.char("a"))
    assert P.run(parser, "aaab") == {:ok, ["a", "a", "a"], "b"}
    assert P.run(parser, "bbb") == {:ok, [], "bbb"}

    parser1 = P.many1(P.char("a"))
    assert P.run(parser1, "aaab") == {:ok, ["a", "a", "a"], "b"}
    assert P.run(parser1, "bbb") == {:error, "expected \"a\""}
  end

  test "optional" do
    parser = P.optional(P.char("a"))
    assert P.run(parser, "abc") == {:ok, "a", "bc"}
    assert P.run(parser, "bc") == {:ok, nil, "bc"}
  end

  test "eof" do
    assert P.run(P.eof(), "") == {:ok, :eof, ""}
    assert P.run(P.eof(), "a") == {:error, "expected end of input"}
  end

  test "between" do
    parser = P.between(P.char("("), P.char(")"), P.string("ok"))
    assert P.run(parser, "(ok)!") == {:ok, "ok", "!"}
  end

  test "sep_by" do
    parser = P.sep_by(P.char("a"), P.char(","))
    assert P.run(parser, "a,a,a") == {:ok, ["a", "a", "a"], ""}
    assert P.run(parser, "") == {:ok, [], ""}
  end

  test "digit and integer" do
    assert P.run(P.digit(), "7z") == {:ok, "7", "z"}
    assert P.run(P.integer(), "-120x") == {:ok, -120, "x"}
    assert P.run(P.integer(), "42") == {:ok, 42, ""}
  end

  test "whitespace, spaces, token" do
    assert P.run(P.whitespace(), " \n") == {:ok, " ", "\n"}
    assert P.run(P.spaces(), "   \txyz") == {:ok, "   \t", "xyz"}

    parser = P.token(P.string("hi"))
    assert P.run(parser, "hi   there") == {:ok, "hi", "there"}
  end
end
