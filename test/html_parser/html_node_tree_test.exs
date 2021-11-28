defmodule HTMLParser.HTMLNodeTreeTest do
  use ExUnit.Case
  alias HTMLParser.{HTMLNodeTree, HTMLTextNode}

  doctest HTMLNodeTree

  describe "new/1" do
    test "returns node tree with tag" do
      assert HTMLNodeTree.new(:p) == %HTMLNodeTree{tag: :p}
    end
  end

  describe "put_next/2" do
    test "returns node tree with next fun" do
      div = HTMLNodeTree.new(:div) |> HTMLNodeTree.put_next(fn -> :done end)
      assert div.next.() == :done
    end
  end

  describe "next/1" do
    test "returns result of next fun" do
      div = HTMLNodeTree.new(:div) |> HTMLNodeTree.put_next(fn -> :done end)
      assert HTMLNodeTree.next(div) == :done
    end
  end

  describe "put_attrs/2" do
    test "copies attrs map" do
      html_node_tree = HTMLNodeTree.new(:p)
      attrs = %{"class" => "red"}
      refute html_node_tree.attrs == attrs

      updated = HTMLNodeTree.put_attrs(html_node_tree, %{"class" => "red"})

      assert updated.attrs == attrs
    end
  end

  describe "add_child/2" do
    test "adds child to children list" do
      parent = HTMLNodeTree.new(:p)
      child = HTMLNodeTree.new(:h1)
      another_child = HTMLNodeTree.new(:h2)
      assert parent.children == []

      updated = HTMLNodeTree.add_child(parent, child)
      assert updated.children == [child]

      updated = HTMLNodeTree.add_child(updated, another_child)
      assert updated.children == [another_child, child]
    end
  end

  describe "add_children/2" do
    test "adds children to children list" do
      parent = HTMLNodeTree.new(:p)
      child = HTMLNodeTree.new(:h1)
      another_child = HTMLNodeTree.new(:h2)
      assert parent.children == []

      updated = HTMLNodeTree.add_children(parent, [child, another_child])
      assert updated.children == [child, another_child]
    end
  end

  describe "traverse/2" do
    test "traverses across all nodes" do
      html = """
        <div>
          <p>
            <h1>hi</h1>
          </p>
          <main>
            <h3>title</h3>
          </main>
        </div>
      """

      {:ok, agent} = Agent.start(fn -> [] end)

      {:ok, parsed} = HTMLParser.parse(html)

      HTMLNodeTree.traverse(parsed, fn html_node_tree ->
        Agent.update(agent, &[html_node_tree | &1])
      end)

      nodes = Agent.get(agent, &Enum.reverse(&1))

      assert [div, p, h1, text_1, main, h3, text_2] = nodes
      assert div.tag == :div
      assert p.tag == :p
      assert h1.tag == :h1
      assert text_1 == %HTMLTextNode{value: "hi"}
      assert main.tag == :main
      assert h3.tag == :h3
      assert text_2 == %HTMLTextNode{value: "title"}
    end
  end

  describe "traverse_lazy/2" do
    test "lazily traverses across all nodes" do
      html = """
        <div>
          <p>
            <h1>hi</h1>
          </p>
          <main>
            <h3>title</h3>
          </main>
        </div>
      """

      {:ok, parsed} = HTMLParser.parse(html)

      {div, next} = HTMLNodeTree.traverse_lazy(parsed)
      assert div.tag == :div

      {p, next} = next.()
      assert p.tag == :p

      {h1, next} = next.()
      assert h1.tag == :h1

      {%HTMLTextNode{value: "hi"}, next} = next.()

      {main, next} = next.()
      assert main.tag == :main

      {h3, next} = next.()
      assert h3.tag == :h3

      {%HTMLTextNode{value: "title"}, next} = next.()

      assert :done == next.()
    end
  end

  describe "enumerable" do
    test "implements enumerable" do
      assert Enumerable.impl_for(HTMLNodeTree.new(:div)) == Enumerable.HTMLParser.HTMLNodeTree
    end

    test "can use enum functions properly" do
      html = """
        <div>
          <p>
            <h1>hi</h1>
          </p>
          <main>
            <h3>title</h3>
          </main>
        </div>
      """

      {:ok, tree} = HTMLParser.parse(html)

      tags_or_text =
        Enum.map(tree, fn
          %HTMLNodeTree{tag: tag} -> tag
          %HTMLTextNode{value: value} -> value
        end)

      assert tags_or_text == [:div, :p, :h1, "hi", :main, :h3, "title"]
    end
  end
end
