defmodule HTMLParser.TreeBuilderTest do
  use ExUnit.Case
  alias HTMLParser.{HTMLNodeTree, HTMLTextNode, TreeBuilder}

  doctest TreeBuilder

  defp open_tag(opts \\ []) do
    tag(:open, opts)
  end

  defp close_tag(opts \\ []) do
    tag(:close, opts)
  end

  defp tag(type, opts) do
    depth_count = Keyword.get(opts, :depth_count, 0)
    char_count = Keyword.get(opts, :char_count, 0)
    newline_count = Keyword.get(opts, :newline_count, 0)
    attrs = Keyword.get(opts, :attrs, %{})

    %{
      depth_count: depth_count,
      char_count: char_count,
      newline_count: newline_count,
      attrs: attrs,
      type: type
    }
  end

  describe "build/1 builds tree from parsed open and close tags" do
    test "single tag" do
      assert TreeBuilder.build(div: open_tag(), div: close_tag()) == HTMLNodeTree.new(:div)
    end

    test "single tag with text" do
      assert TreeBuilder.build([{:div, open_tag()}, "hi", div: close_tag()]) == %HTMLNodeTree{
               tag: :div,
               children: [
                 HTMLTextNode.new("hi")
               ]
             }
    end

    test "single empty tag" do
      assert TreeBuilder.build(meta: open_tag()) == HTMLNodeTree.new(:meta)
    end

    test "single tag with different child" do
      assert TreeBuilder.build(div: open_tag(), p: open_tag(), p: close_tag(), div: close_tag()) ==
               %HTMLNodeTree{tag: :div, children: [HTMLNodeTree.new(:p)]}
    end

    test "single tag with same child" do
      assert TreeBuilder.build(
               div: open_tag(),
               div: open_tag(depth_count: 1),
               div: close_tag(depth_count: 1),
               div: close_tag()
             ) == %HTMLNodeTree{tag: :div, children: [HTMLNodeTree.new(:div)]}
    end

    test "sibling tags - different" do
      assert TreeBuilder.build(div: open_tag(), div: close_tag(), p: open_tag(), p: close_tag()) ==
               [
                 HTMLNodeTree.new(:div),
                 HTMLNodeTree.new(:p)
               ]
    end

    test "single tag with empty child" do
      assert TreeBuilder.build(div: open_tag(), input: open_tag(), div: close_tag()) ==
               %HTMLNodeTree{tag: :div, children: [HTMLNodeTree.new(:input)]}
    end

    test "sibling tags - same" do
      assert TreeBuilder.build(p: open_tag(), p: close_tag(), p: open_tag(), p: close_tag()) == [
               HTMLNodeTree.new(:p),
               HTMLNodeTree.new(:p)
             ]
    end

    test "sibling empty" do
      assert TreeBuilder.build(p: open_tag(), p: close_tag(), input: open_tag()) == [
               HTMLNodeTree.new(:p),
               HTMLNodeTree.new(:input)
             ]
    end

    test "with attrs" do
      assert TreeBuilder.build(
               p: open_tag(attrs: %{"class" => "red"}),
               p: close_tag(),
               input: open_tag(attrs: %{"type" => "number"})
             ) == [
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
        div: open_tag(),
        div: open_tag(depth_count: 1, attrs: %{"class" => "green", "id" => "1"}),
        input: open_tag(),
        div: close_tag(depth_count: 1),
        input: open_tag(depth_count: 1),
        p: open_tag(),
        h1: open_tag()
      ]

      second = [h1: close_tag(), p: close_tag(), div: close_tag()]

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
