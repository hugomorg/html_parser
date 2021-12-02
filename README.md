# HtmlParser

This module allows you to parse an HTML string to get an Elixir representation of the tree of nodes.

`Enum` functions can be used with `HTMLParser.HTMLNodeTree` as it is enumerable. `HTMLParser.Tags` can be used to check if tags are supposed to be empty, and if they are recognised.

See more in the docs.

## Example

```elixir
defmodule YourModule do
  alias HTMLParser.{HTMLNodeTree, HTMLTextNode, Tags}

  def parse(html) do
    {:ok, tree} = HTMLParser.parse(html)

    Enum.map(tree, fn
      %HTMLNodeTree{tag: tag} -> {tag, Tags.recognised?(tag)}
      %HTMLTextNode{value: value} -> {:text, value}
    end)
  end
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `html_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:html_parser, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/html_parser](https://hexdocs.pm/html_parser).

