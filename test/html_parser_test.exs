defmodule HTMLParserTest do
  use ExUnit.Case
  doctest HTMLParser

  alias HTMLParser.HTMLTextNode

  describe "parse/1" do
    test "parses empty tag" do
      div = HTMLParser.parse("<div></div>")

      assert div.tag == :div
      assert div.children == []
    end

    test "parses attributes" do
      button = HTMLParser.parse("<button class=\"bg-red\" disabled type='button'></button>")

      assert button.tag == :button
      assert button.attrs["class"] == "bg-red"
      assert button.attrs["disabled"] == true
      assert button.attrs["type"] == "button"
      assert button.children == []
    end

    test "parses tag with text" do
      p = HTMLParser.parse("<p>hello world</p>")
      assert p.tag == :p
      assert p.children == [%HTMLTextNode{value: "hello world"}]
    end

    test "parses tag with unicode text" do
      p = HTMLParser.parse("<p>xinh chào quý khách</p>")
      assert p.tag == :p
      assert p.children == [%HTMLTextNode{value: "xinh chào quý khách"}]
    end

    test "parses children" do
      assert div = HTMLParser.parse("<div><p></p></div>")
      assert div.tag == :div

      assert [p] = div.children
      assert p.tag == :p
    end

    test "parses siblings" do
      assert div = HTMLParser.parse("<div><h1></h1><p></p></div>")
      assert [h1, p] = div.children

      assert h1.tag == :h1
      assert p.tag == :p
    end

    test "allows no root element" do
      assert [h1, p] = HTMLParser.parse("<h1></h1><p></p>")

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

      assert div = HTMLParser.parse(html)
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

      assert HTMLParser.parse(html) == %HTMLParser.HTMLNodeTree{
               children: [
                 %HTMLParser.HTMLNodeTree{
                   children: [
                     %HTMLParser.HTMLNodeTree{
                       children: [%HTMLParser.HTMLNodeTree{children: [], tag: :div}],
                       tag: :div
                     }
                   ],
                   tag: :div
                 },
                 %HTMLParser.HTMLNodeTree{
                   children: [%HTMLParser.HTMLNodeTree{children: [], tag: :div}],
                   tag: :div
                 },
                 %HTMLParser.HTMLNodeTree{children: [], tag: :div}
               ],
               tag: :div
             }
    end
  end
end
