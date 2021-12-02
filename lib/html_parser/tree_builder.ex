defmodule HTMLParser.TreeBuilder do
  @moduledoc """
  Builds an HTML node tree from a parsed list of tags with depth counts.
  """

  alias HTMLParser.{HTMLCommentNode, HTMLNodeTree, HTMLTextNode, ParseState}

  @spec build(ParseState.tags()) :: {:ok, [HTMLNodeTree.t()] | HTMLNodeTree.t()} | {:error, any()}
  def build(tags) do
    tags
    |> validate_node_list()
    |> case do
      :ok ->
        case do_build(tags) do
          [node] -> {:ok, node}
          nodes -> {:ok, nodes}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_node_list(nodes) do
    nodes
    |> Enum.reject(&match?({:comment, _comment}, &1))
    |> Enum.reject(&match?({:text, _comment}, &1))
    |> Enum.filter(&is_tuple/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.reduce([], fn {tag, nodes}, acc ->
      too_many_closing = Enum.filter(nodes, fn %{depth_count: depth_count} -> depth_count < 0 end)

      case too_many_closing do
        [] -> acc
        [error_nodes] -> [{tag, {:extra_closing_tag, error_nodes}} | acc]
      end
    end)
    |> case do
      [] ->
        :ok

      error_nodes ->
        errors =
          error_nodes
          |> Enum.map(fn {tag, {error, meta}} ->
            {tag, {error, meta.newline_count, meta.char_count}}
          end)

        {:error, errors}
    end
  end

  defp do_build([]), do: []

  defp do_build([{:"!DOCTYPE", _} | elements]) do
    do_build(elements)
  end

  defp do_build([{:"!doctype", _} | elements]) do
    do_build(elements)
  end

  defp do_build([{:comment, element} | elements]) do
    [HTMLCommentNode.new(element) | do_build(elements)]
  end

  defp do_build([{:text, element} | elements]) do
    [HTMLTextNode.new(element) | do_build(elements)]
  end

  defp do_build([{tag, %{attrs: attrs, depth_count: depth_count}} | elements]) do
    node = tag |> HTMLNodeTree.new() |> HTMLNodeTree.put_attrs(attrs)

    case Enum.split_while(elements, &not_matching_tag?(tag, depth_count, &1)) do
      {remaining, [_close_tag | siblings]} ->
        tree = HTMLNodeTree.add_children(node, do_build(remaining))
        [tree] ++ do_build(siblings)

      # Self-closing / empty tag
      {remaining, []} ->
        node = HTMLNodeTree.put_empty(node)
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
