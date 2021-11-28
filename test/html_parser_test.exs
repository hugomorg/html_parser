defmodule HTMLParserTest do
  use ExUnit.Case
  doctest HTMLParser

  alias HTMLParser.{HTMLNodeTree, HTMLTextNode}

  describe "parse/1" do
    test "parses empty tag" do
      {:ok, div} = HTMLParser.parse("<div></div>")

      assert div.tag == :div
      assert div.children == []
    end

    test "parses attributes" do
      {:ok, button} =
        HTMLParser.parse("<button class=\"bg-red\" disabled type='button'></button>")

      assert button.tag == :button
      assert button.attrs["class"] == "bg-red"
      assert button.attrs["disabled"] == true
      assert button.attrs["type"] == "button"
      assert button.children == []
    end

    test "parses tag with text" do
      {:ok, p} = HTMLParser.parse("<p>hello world</p>")
      assert p.tag == :p
      assert p.children == [%HTMLTextNode{value: "hello world"}]
    end

    test "parses tag with newline in text" do
      {:ok, p} = HTMLParser.parse("<p>hello\nworld</p>")
      assert p.tag == :p
      assert p.children == [%HTMLTextNode{value: "hello\nworld"}]
    end

    test "parses tag with unicode text" do
      {:ok, p} = HTMLParser.parse("<p>xinh chào quý khách</p>")
      assert p.tag == :p
      assert p.children == [%HTMLTextNode{value: "xinh chào quý khách"}]
    end

    test "parses children" do
      assert {:ok, div} = HTMLParser.parse("<div><p></p></div>")
      assert div.tag == :div

      assert [p] = div.children
      assert p.tag == :p
    end

    test "parses siblings" do
      assert {:ok, div} = HTMLParser.parse("<div><h1></h1><p></p></div>")
      assert [h1, p] = div.children

      assert h1.tag == :h1
      assert p.tag == :p
    end

    test "allows no root element" do
      assert {:ok, [h1, p]} = HTMLParser.parse("<h1></h1><p></p>")

      assert h1.tag == :h1
      assert p.tag == :p
      assert h1.children == []
      assert p.children == []
    end

    test "parses nested multiline children, with complex nesting" do
      html = """
        <div>
          <p>
            <h1></h1>
          </p>
          <div>
            <input>
          </div>
          <main>
            <h3>hi</h3>
          </main>
        </div>
      """

      assert {:ok, div} = HTMLParser.parse(html)
      assert div.tag == :div

      assert [p, div, main] = div.children

      assert p.tag == :p
      assert [h1] = p.children
      assert h1.tag == :h1

      assert div.tag == :div
      assert [input] = div.children
      assert input.tag == :input
      assert input.children == []

      assert main.tag == :main
      assert [h3] = main.children
      assert h3.tag == :h3
      assert h3.children == [%HTMLTextNode{value: "hi"}]
    end

    test "parses nested same tags" do
      html = """
        <div>
          <div>
            <div>
              <div></div>
            </div>
          </div>
          <div>
            <div></div>
          </div>
          <div>
          </div>
        </div>
      """

      assert {:ok, tree} = HTMLParser.parse(html)

      assert tree == %HTMLNodeTree{
               children: [
                 %HTMLNodeTree{
                   children: [
                     %HTMLNodeTree{
                       children: [%HTMLNodeTree{children: [], tag: :div}],
                       tag: :div
                     }
                   ],
                   tag: :div
                 },
                 %HTMLNodeTree{
                   children: [%HTMLNodeTree{children: [], tag: :div}],
                   tag: :div
                 },
                 %HTMLNodeTree{children: [], tag: :div}
               ],
               tag: :div
             }
    end
  end

  describe "edge cases" do
    test "space in attrs" do
      html = """
        <pre style=\"word-wrap: break-word; white-space: pre-wrap;\" double=\"sin'gle\" single='doub\"le'></pre>
      """

      assert {:ok, tree} = HTMLParser.parse(html)

      assert tree.attrs == %{
               "style" => "word-wrap: break-word; white-space: pre-wrap;",
               "double" => "sin'gle",
               "single" => "doub\"le"
             }
    end

    test "extra opening tag is treated as self-closing" do
      html = """
      <div>
      <div></div>
      """

      assert {:ok, tree} = HTMLParser.parse(html)

      assert tree == [
               %HTMLNodeTree{
                 attrs: %{},
                 children: [],
                 next: nil,
                 tag: :div,
                 empty: true
               },
               %HTMLNodeTree{attrs: %{}, children: [], next: nil, tag: :div}
             ]
    end

    test "extra closing tag causes error" do
      html = """
      <div>
      </div>
      </div>
      """

      assert {:error, [div: {:extra_closing_tag, 2, 15}]} = HTMLParser.parse(html)
    end
  end
end
