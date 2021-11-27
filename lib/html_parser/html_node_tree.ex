defmodule HTMLParser.HTMLNodeTree do
  @moduledoc """
  Represents a tree of HTML nodes
  """

  alias HTMLParser.HTMLTextNode

  @enforce_keys [:tag]
  defstruct [:tag, :next, children: [], attrs: %{}]

  @type t :: %__MODULE__{}
  @type tag :: atom()

  @doc """
  Builds a new `HTMLNodeTree`
  """
  @spec new(tag) :: t()
  def new(tag) do
    %__MODULE__{tag: tag}
  end

  @doc """
  Copies attrs map into node tree
  """
  @spec put_attrs(t(), map()) :: t()
  def put_attrs(%__MODULE__{} = html_node_tree, attrs) do
    %__MODULE__{html_node_tree | attrs: attrs}
  end

  @spec put_next(t(), (() -> any())) :: t()
  def put_next(%__MODULE__{} = html_text_node, next) do
    %__MODULE__{html_text_node | next: next}
  end

  @spec next(t() | HTMLTextNode.t()) :: any()
  def next(%__MODULE__{next: nil} = html_node_tree) do
    html_node_tree
    |> put_next(fn -> traverse_lazy(html_node_tree) end)
    |> next
  end

  def next(%__MODULE__{next: next_fun}) when is_function(next_fun, 0) do
    do_next(next_fun)
  end

  def next(%HTMLTextNode{next: next_fun}) when is_function(next_fun, 0) do
    do_next(next_fun)
  end

  defp do_next(next_fun) do
    case next_fun.() do
      {%__MODULE__{} = next_node, next_fun} ->
        put_next(next_node, next_fun)

      {%HTMLTextNode{} = next_node, next_fun} ->
        HTMLTextNode.put_next(next_node, next_fun)

      :done ->
        :done
    end
  end

  @doc """
  Adds another node tree to child list
  """
  @spec add_child(t(), t() | HTMLTextNode.t()) :: t()
  def add_child(%__MODULE__{children: children} = html_node_tree, child) do
    %__MODULE__{html_node_tree | children: [child | children]}
  end

  @spec add_children(t(), [t()] | HTMLTextNode.t()) :: t()
  def add_children(%__MODULE__{} = html_node_tree, children) do
    %__MODULE__{html_node_tree | children: html_node_tree.children ++ children}
  end

  @doc """
  Recursively traverses across a node tree and invokes a callback on each node
  """
  @spec traverse(t() | HTMLTextNode.t(), (t() -> any())) :: :ok
  def traverse(%HTMLTextNode{} = text_node, callback) do
    callback.(text_node)
  end

  def traverse(%__MODULE__{children: children} = html_node_tree, callback) do
    callback.(html_node_tree)
    Enum.each(children, &traverse(&1, callback))
  end

  @doc """
  Lazily traverses one node at a time
  """
  @spec traverse_lazy(t()) :: :done | {t() | HTMLTextNode.t(), (() -> any())}
  def traverse_lazy(%__MODULE__{} = html_node_tree) do
    do_traverse_lazy([html_node_tree], fn -> :done end)
  end

  defp do_traverse_lazy([], next), do: next.()

  defp do_traverse_lazy(
         [%__MODULE__{children: children} = html_node_tree | remaining_nodes],
         next
       ) do
    remaining_nodes = children ++ remaining_nodes
    {html_node_tree, fn -> do_traverse_lazy(remaining_nodes, next) end}
  end

  defp do_traverse_lazy([%HTMLTextNode{} = text_node | remaining_nodes], next) do
    {text_node, fn -> do_traverse_lazy(remaining_nodes, next) end}
  end

  defimpl Enumerable, for: __MODULE__ do
    alias HTMLParser.HTMLNodeTree

    def count(_html_node_tree), do: {:error, __MODULE__}

    def member?(_html_node_tree, _value), do: {:error, __MODULE__}

    def slice(_html_node_tree), do: {:error, __MODULE__}

    def reduce(_html_node_tree, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(%HTMLNodeTree{} = html_node, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(html_node, &1, fun)}
    end

    def reduce(%HTMLTextNode{} = text_node, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(text_node, &1, fun)}
    end

    def reduce(%HTMLNodeTree{} = html_node, {:cont, acc}, fun) do
      do_reduce(html_node, fun, acc)
    end

    def reduce(%HTMLTextNode{} = text_node, {:cont, acc}, fun) do
      do_reduce(text_node, fun, acc)
    end

    defp do_reduce(node, fun, acc) do
      case HTMLNodeTree.next(node) do
        :done ->
          {:done, acc}

        next_node ->
          reduce(next_node, fun.(next_node, acc), fun)
      end
    end
  end
end
