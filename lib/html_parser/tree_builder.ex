defmodule HTMLParser.TreeBuilder do
  @moduledoc """
  Builds an HTML node tree from a parsed list of tags with depth counts.
  """

  alias HTMLParser.{HTMLNodeTree, HTMLTextNode}

  @spec build([atom() | String.t()]) :: [HTMLNodeTree.t()] | HTMLNodeTree.t()
  def build(tags) do
    case do_build(tags) do
      [node] -> node
      nodes -> nodes
    end
  end

  defp do_build([]), do: []

  defp do_build([element | elements]) when is_binary(element) do
    [HTMLTextNode.new(element) | do_build(elements)]
  end

  defp do_build([{tag, attrs, count} | elements])
       when is_atom(tag) and is_map(attrs) and is_integer(count) do
    node = tag |> HTMLNodeTree.new() |> HTMLNodeTree.put_attrs(attrs)

    case Enum.split_while(elements, &(&1 != {tag, count})) do
      {remaining, [_close_tag | siblings]} ->
        tree = HTMLNodeTree.add_children(node, do_build(remaining))
        [tree] ++ do_build(siblings)

      {remaining, []} ->
        [node] ++ do_build(remaining)
    end
  end

  defp do_build([_element | elements]) do
    do_build(elements)
  end
end
