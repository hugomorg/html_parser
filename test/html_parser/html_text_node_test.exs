defmodule HTMLParser.HTMLTextNodeTest do
  use ExUnit.Case
  alias HTMLParser.HTMLTextNode

  doctest HTMLTextNode

  describe "new/1" do
    test "returns text node with value" do
      assert HTMLTextNode.new("hi") == %HTMLTextNode{value: "hi"}
    end
  end

  describe "put_next/2" do
    test "returns text node with next fun" do
      text_node = HTMLTextNode.new("hi") |> HTMLTextNode.put_next(fn -> :done end)
      assert text_node.next.() == :done
    end
  end
end
