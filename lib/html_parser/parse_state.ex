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
            tag_counter: %{},
            char_count: 0,
            newline_count: 0,
            meta: %{}

  @type tag :: atom()
  @type char_count :: non_neg_integer()
  @type depth_count :: non_neg_integer()
  @type newline_count :: non_neg_integer()
  @type attrs :: %{String.t() => any()}
  @type meta ::
          %{
            depth_count: depth_count(),
            char_count: char_count(),
            newline_count: newline_count(),
            type: :open | :close,
            attrs: attrs()
          }
          | %{}
  @type tags :: list({tag(), meta()})

  @type t :: %__MODULE__{
          open_tag: String.t(),
          close_tag: String.t(),
          attr: String.t(),
          text: String.t(),
          attrs: attrs(),
          tags: tags(),
          tag_counter: map(),
          meta: meta(),
          char_count: char_count(),
          newline_count: newline_count()
        }

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
  def add_attrs(%__MODULE__{attrs: attrs, tags: tags} = parse_state) do
    [{tag, meta} | rest] = tags
    meta = Map.update!(meta, :attrs, &Map.merge(&1, attrs))

    %__MODULE__{parse_state | tags: [{tag, meta} | rest], attrs: %{}}
  end

  def add_meta(%__MODULE__{} = parse_state) do
    meta = Map.take(parse_state, [:char_count, :newline_count, :attrs])
    %__MODULE__{parse_state | meta: meta}
  end

  @spec add_open_tag(t()) :: t()
  def add_open_tag(%__MODULE__{tags: tags, open_tag: open_tag_string} = parse_state) do
    open_tag = String.to_atom(open_tag_string)
    parse_state = parse_state |> increment_tag_count(open_tag)
    tag_count = get_tag_count!(parse_state, open_tag)

    meta = %{depth_count: tag_count, type: :open, attrs: %{}}

    %__MODULE__{parse_state | tags: [{open_tag, meta} | tags], open_tag: "", meta: %{}}
  end

  @spec add_close_tag(t()) :: t()
  def add_close_tag(%__MODULE__{tags: tags, close_tag: close_tag} = parse_state) do
    close_tag = String.to_atom(close_tag)
    tag_count = get_tag_count!(parse_state, close_tag)
    parse_state = parse_state |> decrement_tag_count(close_tag)

    meta = %{depth_count: tag_count, type: :close, attrs: %{}}

    %__MODULE__{parse_state | tags: [{close_tag, meta} | tags], close_tag: "", meta: %{}}
  end

  @spec set_char_count(t(), non_neg_integer()) :: t()
  def set_char_count(parse_state, n \\ 1)

  def set_char_count(%__MODULE__{char_count: char_count} = parse_state, n)
      when is_integer(n) and n > 0 do
    %__MODULE__{parse_state | char_count: char_count + n}
  end

  @spec set_newline_count(t(), non_neg_integer()) :: t()
  def set_newline_count(parse_state, n \\ 1)

  def set_newline_count(%__MODULE__{newline_count: newline_count} = parse_state, n)
      when is_integer(n) and n > 0 do
    %__MODULE__{parse_state | newline_count: newline_count + n}
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
