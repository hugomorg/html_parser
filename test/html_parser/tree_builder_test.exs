defmodule HTMLParser.TreeBuilderTest do
  use ExUnit.Case
  alias HTMLParser.{HTMLNodeTree, HTMLTextNode, TreeBuilder}

  doctest TreeBuilder

  defp open_tag(tag, count \\ 0, attrs \\ %{}) do
    {tag, attrs, count}
  end

  defp close_tag(tag, count \\ 0) do
    {tag, count}
  end

  describe "build/1 builds tree from parsed open and close tags" do
    test "single tag" do
      assert TreeBuilder.build([open_tag(:div), close_tag(:div)]) == HTMLNodeTree.new(:div)
    end

    test "single tag with text" do
      assert TreeBuilder.build([open_tag(:div), "hi", close_tag(:div)]) == %HTMLNodeTree{
               tag: :div,
               children: [
                 HTMLTextNode.new("hi")
               ]
             }
    end

    test "single empty tag" do
      assert TreeBuilder.build([open_tag(:meta)]) == HTMLNodeTree.new(:meta)
    end

    test "single tag with different child" do
      assert TreeBuilder.build([open_tag(:div), open_tag(:p), close_tag(:p), close_tag(:div)]) ==
               %HTMLNodeTree{tag: :div, children: [HTMLNodeTree.new(:p)]}
    end

    test "single tag with same child" do
      assert TreeBuilder.build([
               open_tag(:div),
               open_tag(:div, 1),
               close_tag(:div, 1),
               close_tag(:div)
             ]) == %HTMLNodeTree{tag: :div, children: [HTMLNodeTree.new(:div)]}
    end

    test "sibling tags - different" do
      assert TreeBuilder.build([open_tag(:div), close_tag(:div), open_tag(:p), close_tag(:p)]) ==
               [
                 HTMLNodeTree.new(:div),
                 HTMLNodeTree.new(:p)
               ]
    end

    test "single tag with empty child" do
      assert TreeBuilder.build([open_tag(:div), open_tag(:input), close_tag(:div)]) ==
               %HTMLNodeTree{tag: :div, children: [HTMLNodeTree.new(:input)]}
    end

    test "sibling tags - same" do
      assert TreeBuilder.build([open_tag(:p), close_tag(:p), open_tag(:p), close_tag(:p)]) == [
               HTMLNodeTree.new(:p),
               HTMLNodeTree.new(:p)
             ]
    end

    test "sibling empty" do
      assert TreeBuilder.build([open_tag(:p), close_tag(:p), open_tag(:input)]) == [
               HTMLNodeTree.new(:p),
               HTMLNodeTree.new(:input)
             ]
    end

    test "with attrs" do
      assert TreeBuilder.build([
               open_tag(:p, 0, %{"class" => "red"}),
               close_tag(:p),
               open_tag(:input, 0, %{"type" => "number"})
             ]) == [
               %HTMLParser.HTMLNodeTree{
                 attrs: %{"class" => "red"},
                 children: [],
                 next: nil,
                 tag: :p
               },
               %HTMLParser.HTMLNodeTree{
                 attrs: %{"type" => "number"},
                 children: [],
                 next: nil,
                 tag: :input
               }
             ]
    end

    test "complex example" do
      first = [
        open_tag(:div),
        open_tag(:div, 1, %{"class" => "green", "id" => "1"}),
        open_tag(:input),
        close_tag(:div, 1),
        open_tag(:input, 1),
        open_tag(:p),
        open_tag(:h1)
      ]

      second = [close_tag(:h1), close_tag(:p), close_tag(:div)]

      tags = first ++ ["yo"] ++ second

      tree = TreeBuilder.build(tags)

      assert tree == %HTMLParser.HTMLNodeTree{
               children: [
                 %HTMLParser.HTMLNodeTree{
                   attrs: %{"class" => "green", "id" => "1"},
                   children: [
                     HTMLNodeTree.new(:input)
                   ],
                   tag: :div
                 },
                 HTMLNodeTree.new(:input),
                 %HTMLParser.HTMLNodeTree{
                   children: [%HTMLNodeTree{tag: :h1, children: [HTMLTextNode.new("yo")]}],
                   tag: :p
                 }
               ],
               tag: :div
             }
    end
  end
end
