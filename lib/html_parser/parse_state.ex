defmodule HTMLParser.ParseState do
  @moduledoc """
  Manages changing parsing states for parser
  """

  defstruct open_tag: "",
            text: "",
            attr: "",
            close_tag: "",
            attrs: %{},
            tags: [],
            tag_counter: %{}

  @type t :: %__MODULE__{}

  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @spec build_open_tag(t(), bitstring()) :: t()
  def build_open_tag(%__MODULE__{} = parse_state, open_tag) when is_bitstring(open_tag) do
    %__MODULE__{parse_state | open_tag: parse_state.open_tag <> open_tag}
  end

  @spec build_close_tag(t(), bitstring()) :: t()
  def build_close_tag(%__MODULE__{} = parse_state, close_tag) when is_bitstring(close_tag) do
    %__MODULE__{parse_state | close_tag: parse_state.close_tag <> close_tag}
  end

  @spec build_text(t(), bitstring()) :: t()
  def build_text(%__MODULE__{} = parse_state, text) when is_bitstring(text) do
    %__MODULE__{parse_state | text: parse_state.text <> text}
  end

  @spec build_attr(t(), bitstring()) :: t()
  def build_attr(%__MODULE__{} = parse_state, attr) when is_bitstring(attr) do
    %__MODULE__{parse_state | attr: parse_state.attr <> attr}
  end

  @spec put_attr(t()) :: t()
  def put_attr(%__MODULE__{attr: attr, attrs: attrs} = parse_state) do
    attrs =
      case String.split(attr, "=") do
        [key, value] ->
          value = value |> String.trim("\"") |> String.trim("'")
          Map.put(attrs, key, value)

        [key] ->
          Map.put(attrs, key, true)

        [key | values] ->
          value = values |> Enum.join("=") |> String.trim("\"") |> String.trim("'")
          Map.put(attrs, key, value)
      end

    %__MODULE__{parse_state | attrs: attrs, attr: ""}
  end

  @spec add_text(t()) :: t()
  def add_text(%__MODULE__{tags: tags, text: text} = parse_state) do
    %__MODULE__{parse_state | tags: [text | tags], text: ""}
  end

  @spec add_attrs(t()) :: t()
  def add_attrs(
        %__MODULE__{attrs: attrs, tags: [{tag, current_attrs, count} | rest]} = parse_state
      ) do
    %__MODULE__{
      parse_state
      | tags: [{tag, Map.merge(current_attrs, attrs), count} | rest],
        attrs: %{}
    }
  end

  @spec add_open_tag(t()) :: t()
  def add_open_tag(%__MODULE__{tags: tags, open_tag: open_tag} = parse_state) do
    open_tag = String.to_atom(open_tag)
    parse_state = parse_state |> increment_tag_count(open_tag)
    tag_count = get_tag_count!(parse_state, open_tag)

    %__MODULE__{parse_state | tags: [{open_tag, %{}, tag_count} | tags], open_tag: ""}
  end

  @spec add_close_tag(t()) :: t()
  def add_close_tag(%__MODULE__{tags: tags, close_tag: close_tag} = parse_state) do
    close_tag = String.to_atom(close_tag)
    tag_count = get_tag_count!(parse_state, close_tag)
    parse_state = parse_state |> decrement_tag_count(close_tag)

    %__MODULE__{parse_state | tags: [{close_tag, tag_count} | tags], close_tag: ""}
  end

  defp increment_tag_count(
         %__MODULE__{tag_counter: tag_counter} = parse_state,
         tag
       ) do
    %__MODULE__{parse_state | tag_counter: Map.update(tag_counter, tag, 0, &(&1 + 1))}
  end

  defp get_tag_count!(%__MODULE__{tag_counter: tag_counter}, tag) do
    Map.fetch!(tag_counter, tag)
  end

  defp decrement_tag_count(
         %__MODULE__{tag_counter: tag_counter} = parse_state,
         tag
       ) do
    tag_counter = Map.update!(tag_counter, tag, &(&1 - 1))

    %__MODULE__{parse_state | tag_counter: tag_counter}
  end
end
