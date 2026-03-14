# ParserCombinator

一个简洁优雅的 Elixir 单子式解析器组合子库。

## 项目简介

ParserCombinator 是一个基于函数式编程理念的解析器组合子库，采用单子（Monad）设计模式实现。它提供了一套简洁、可组合的 API，让开发者能够轻松构建复杂的文本解析器。

### 核心特性

- **单子式设计**：基于 `bind` 和 `pure` 操作，支持函数式组合
- **高度可组合**：小型解析器可以组合成复杂的解析器
- **类型安全**：完整的类型规范，提供良好的编译时检查
- **零依赖**：纯 Elixir 实现，无需外部依赖
- **完整 JSON 解析器**：内置完整的 JSON 解析器实现作为示例

## 设计架构

### 核心概念

#### Parser 类型

解析器本质上是一个函数，接收输入字符串，返回解析结果：

```elixir
@type parser(result) :: (input -> parse_result(result))
@type parse_result(result) :: {:ok, result, input} | {:error, String.t()}
```

- **成功**：返回 `{:ok, 解析结果, 剩余输入}`
- **失败**：返回 `{:error, 错误信息}`

#### 三层架构

项目采用分层设计：

```
┌─────────────────────────────────────┐
│   ParserCombinator (主模块)          │  对外统一接口
├─────────────────────────────────────┤
│   ParserCombinator.Core             │  核心原语
│   ParserCombinator.Extras           │  常用组合器
│   ParserCombinator.JSON             │  应用示例
└─────────────────────────────────────┘
```

1. **Core 层**：提供最基础的解析器原语
   - 单子操作：`pure`, `bind`, `map`
   - 基础匹配：`char`, `string`, `satisfy`
   - 组合操作：`seq`, `choice`, `many`, `many1`
   - 辅助操作：`optional`, `eof`

2. **Extras 层**：基于 Core 构建的实用解析器
   - 数值解析：`digit`, `integer`
   - 空白处理：`whitespace`, `spaces`, `token`
   - 结构解析：`between`, `sep_by`, `sep_by1`

3. **应用层**：使用组合子构建的实际解析器
   - 完整的 JSON 解析器实现

## API 文档

### 核心操作

#### `run(parser, input)`

执行解析器，返回解析结果。

```elixir
alias ParserCombinator, as: P

{:ok, value, rest} = P.run(P.char("a"), "abc")
# => {:ok, "a", "bc"}
```

#### `pure(value)`

创建一个总是成功的解析器，不消耗输入。

```elixir
{:ok, 42, "abc"} = P.run(P.pure(42), "abc")
```

#### `bind(parser, f)`

单子绑定操作，将前一个解析器的结果传递给下一个解析器。

```elixir
parser = P.bind(P.char("a"), fn _ -> P.char("b") end)
{:ok, "b", "c"} = P.run(parser, "abc")
```

#### `map(parser, f)`

转换解析器的结果。

```elixir
parser = P.map(P.char("a"), fn _ -> :ok end)
{:ok, :ok, "bc"} = P.run(parser, "abc")
```

### 基础匹配

#### `char(expected)`

匹配单个字符。

```elixir
{:ok, "x", "yz"} = P.run(P.char("x"), "xyz")
{:error, _} = P.run(P.char("x"), "abc")
```

#### `string(expected)`

匹配字符串前缀。

```elixir
{:ok, "hello", " world"} = P.run(P.string("hello"), "hello world")
```

#### `satisfy(predicate, label)`

根据谓词匹配单个字符。

```elixir
parser = P.satisfy(fn ch -> ch == "x" end, "x")
{:ok, "x", "yz"} = P.run(parser, "xyz")
```

### 组合操作

#### `seq(pa, pb)`

顺序执行两个解析器，返回结果元组。

```elixir
parser = P.seq(P.char("a"), P.char("b"))
{:ok, {"a", "b"}, "c"} = P.run(parser, "abc")
```

#### `choice(pa, pb)`

尝试第一个解析器，失败则尝试第二个。

```elixir
parser = P.choice(P.char("a"), P.char("b"))
{:ok, "a", "bc"} = P.run(parser, "abc")
{:ok, "b", "cd"} = P.run(parser, "bcd")
```

#### `many(parser)` / `many1(parser)`

匹配零次或多次 / 一次或多次。

```elixir
{:ok, ["a", "a", "a"], "b"} = P.run(P.many(P.char("a")), "aaab")
{:ok, [], "bbb"} = P.run(P.many(P.char("a")), "bbb")

{:ok, ["a", "a"], "b"} = P.run(P.many1(P.char("a")), "aab")
{:error, _} = P.run(P.many1(P.char("a")), "bbb")
```

#### `optional(parser)`

可选匹配，失败返回 `nil`。

```elixir
{:ok, "a", "bc"} = P.run(P.optional(P.char("a")), "abc")
{:ok, nil, "bc"} = P.run(P.optional(P.char("a")), "bc")
```

#### `eof()`

匹配输入结束。

```elixir
{:ok, :eof, ""} = P.run(P.eof(), "")
{:error, _} = P.run(P.eof(), "a")
```

### 辅助解析器

#### `between(open, close, parser)`

匹配被包围的内容。

```elixir
parser = P.between(P.char("("), P.char(")"), P.integer())
{:ok, 42, "!"} = P.run(parser, "(42)!")
```

#### `sep_by(parser, sep)` / `sep_by1(parser, sep)`

匹配由分隔符分隔的列表。

```elixir
parser = P.sep_by(P.integer(), P.char(","))
{:ok, [1, 2, 3], ""} = P.run(parser, "1,2,3")
{:ok, [], ""} = P.run(parser, "")
```

#### `digit()` / `integer()`

匹配数字和整数。

```elixir
{:ok, "7", "z"} = P.run(P.digit(), "7z")
{:ok, -120, "x"} = P.run(P.integer(), "-120x")
```

#### `whitespace()` / `spaces()`

匹配空白字符。

```elixir
{:ok, " ", "\n"} = P.run(P.whitespace(), " \n")
{:ok, "   \t", "xyz"} = P.run(P.spaces(), "   \txyz")
```

#### `token(parser)`

匹配内容并忽略前后空白。

```elixir
parser = P.token(P.integer())
{:ok, -123, ""} = P.run(parser, "  -123   ")
```

## 使用示例

### 基础用法

```elixir
alias ParserCombinator, as: P

# 匹配带空白的整数
parser = P.token(P.integer())
{:ok, -123, ""} = P.run(parser, "  -123   ")

# 匹配括号内的内容
parser = P.between(P.char("("), P.char(")"), P.integer())
{:ok, 42, "!"} = P.run(parser, "(42)!")

# 匹配逗号分隔的列表
parser = P.sep_by(P.token(P.integer()), P.char(","))
{:ok, [1, 2, 3], ""} = P.run(parser, "1, 2, 3")
```

### JSON 解析器

项目内置了完整的 JSON 解析器实现：

```elixir
alias ParserCombinator.JSON

# 解析基本类型
{:ok, nil, ""} = JSON.parse("null")
{:ok, true, ""} = JSON.parse("true")
{:ok, false, ""} = JSON.parse("false")

# 解析数字
{:ok, 42, ""} = JSON.parse("42")
{:ok, -10, ""} = JSON.parse("-10")
{:ok, 3.14, ""} = JSON.parse("3.14")
{:ok, 1000.0, ""} = JSON.parse("1e3")

# 解析字符串（支持转义）
{:ok, "hello", ""} = JSON.parse("\"hello\"")
{:ok, "line\nfeed", ""} = JSON.parse("\"line\\nfeed\"")
{:ok, "unicode: ☺", ""} = JSON.parse("\"unicode: \\u263A\"")

# 解析数组
{:ok, [], ""} = JSON.parse("[]")
{:ok, [1, 2, 3], ""} = JSON.parse("[1,2,3]")

# 解析对象
{:ok, %{}, ""} = JSON.parse("{}")
{:ok, %{"a" => 1, "b" => true}, ""} = JSON.parse("{\"a\":1,\"b\":true}")

# 解析嵌套结构
input = "{\"arr\":[1, {\"x\":false}, [null]], \"n\":2}"
{:ok, %{"arr" => [1, %{"x" => false}, [nil]], "n" => 2}, ""} = JSON.parse(input)
```

## 项目结构

```
light-parser/
├── lib/
│   ├── parser_combinator.ex          # 主模块，统一对外接口
│   ├── parser_combinator/
│   │   ├── core.ex                   # 核心解析器原语
│   │   └── extras.ex                 # 实用组合器
│   └── json/
│       └── json.ex                   # JSON 解析器实现
├── test/
│   ├── parser_combinator_test.exs    # 核心功能测试
│   ├── json_parser_test.exs          # JSON 解析器测试
│   └── test_helper.exs
├── mix.exs                           # 项目配置
└── README.md
```

## 安装与运行

### 环境要求

- Elixir ~> 1.14

### 运行测试

```bash
mix test
```

### 在项目中使用

将项目添加到 `mix.exs` 的依赖中：

```elixir
def deps do
  [
    {:parser_combinator, path: "path/to/light-parser"}
  ]
end
```

## 扩展开发

### 创建自定义解析器

基于现有组合子可以轻松创建新的解析器：

```elixir
defmodule MyParser do
  alias ParserCombinator, as: P

  # 匹配标识符（字母开头，后跟字母或数字）
  def identifier do
    P.bind(P.satisfy(fn ch -> ch >= "a" and ch <= "z" end, "letter"), fn first ->
      P.map(P.many(P.choice(P.digit(), P.satisfy(fn ch -> ch >= "a" and ch <= "z" end, "letter"))), fn rest ->
        Enum.join([first | rest])
      end)
    end)
  end
end
```

### 设计原则

1. **组合优于继承**：通过组合小型解析器构建复杂解析器
2. **单一职责**：每个解析器只做一件事
3. **延迟求值**：使用 `lazy` 处理递归定义
4. **错误友好**：提供清晰的错误信息

## 许可证

查看 [LICENSE](LICENSE) 文件了解详情。
