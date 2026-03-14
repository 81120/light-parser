defmodule ParserCombinatorJSONTest do
  use ExUnit.Case, async: true

  alias ParserCombinator.JSON, as: J

  test "parses null, true, false" do
    assert J.parse("null") == {:ok, nil, ""}
    assert J.parse("true") == {:ok, true, ""}
    assert J.parse("false") == {:ok, false, ""}
  end

  test "parses numbers" do
    assert J.parse("0") == {:ok, 0, ""}
    assert J.parse("-10") == {:ok, -10, ""}
    assert J.parse("3.14") == {:ok, 3.14, ""}
    assert J.parse("-2.0") == {:ok, -2.0, ""}
    assert J.parse("1e3") == {:ok, 1000.0, ""}
    assert J.parse("1E-2") == {:ok, 0.01, ""}
  end

  test "parses strings with escapes" do
    assert J.parse("\"hello\"") == {:ok, "hello", ""}
    assert J.parse("\"a\\\\b\"") == {:ok, "a\\b", ""}
    assert J.parse("\"line\\nfeed\"") == {:ok, "line\nfeed", ""}
    assert J.parse("\"quote: \\\"\"") == {:ok, "quote: \"", ""}
    assert J.parse("\"unicode: \\u263A\"") == {:ok, "unicode: ☺", ""}
  end

  test "parses arrays" do
    assert J.parse("[]") == {:ok, [], ""}
    assert J.parse("[1,2,3]") == {:ok, [1, 2, 3], ""}
    assert J.parse("[true, null, \"x\"]") == {:ok, [true, nil, "x"], ""}
  end

  test "parses objects" do
    assert J.parse("{}") == {:ok, %{}, ""}

    assert J.parse("{\"a\":1,\"b\":true}") ==
             {:ok, %{"a" => 1, "b" => true}, ""}
  end

  test "parses nested values" do
    input = "{\"arr\":[1, {\"x\":false}, [null]], \"n\":2}"

    assert J.parse(input) ==
             {:ok, %{"arr" => [1, %{"x" => false}, [nil]], "n" => 2}, ""}
  end

  test "ignores whitespace" do
    input = "  { \"a\" : [ 1 , 2 , 3 ] , \"b\" : true }  "

    assert J.parse(input) == {:ok, %{"a" => [1, 2, 3], "b" => true}, ""}
  end

  test "parses .mcp.json" do
    input = File.read!(".mcp.json")

    assert {:ok, %{"mcpServers" => servers}, ""} = J.parse(input)
    assert is_map(servers)
  end
end
