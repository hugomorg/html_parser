defmodule HTMLParser.TreeBuilder do
  @moduledoc """
  Builds an HTML node tree from a parsed list of tags with depth counts.
  """

  alias HTMLParser.{HTMLNodeTree, HTMLTextNode, ParseState}

  @spec build(ParseState.tags()) :: [HTMLNodeTree.t()] | HTMLNodeTree.t()
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

  defp do_build([{tag, %{attrs: attrs, depth_count: depth_count}} | elements]) do
    node = tag |> HTMLNodeTree.new() |> HTMLNodeTree.put_attrs(attrs)

    case Enum.split_while(elements, &not_matching_tag?(tag, depth_count, &1)) do
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

  defp not_matching_tag?(tag, depth_count, {other_tag, other_meta}) do
    other_tag != tag or other_meta.depth_count != depth_count
  end

  defp not_matching_tag?(_tag, _depth_count, _text), do: true
end
