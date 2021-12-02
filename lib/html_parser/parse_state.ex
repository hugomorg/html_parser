defmodule HTMLParser.ParseState do
  @moduledoc """
  Manages changing parsing states for parser
  """

  defstruct open_tag: "",
            text: "",
            comment: "",
            attr_key: "",
            attr_value: "",
            attr_quote: :double,
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
          attr_key: String.t(),
          attr_value: String.t(),
          text: String.t(),
          comment: String.t(),
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

  @spec build_comment(t(), bitstring()) :: t()
  def build_comment(%__MODULE__{} = parse_state, comment) when is_bitstring(comment) do
    %__MODULE__{parse_state | comment: parse_state.comment <> comment}
  end

  @spec build_attr_key(t(), bitstring()) :: t()
  def build_attr_key(%__MODULE__{} = parse_state, attr_key) when is_bitstring(attr_key) do
    %__MODULE__{parse_state | attr_key: parse_state.attr_key <> attr_key}
  end

  @spec build_attr_value(t(), bitstring()) :: t()
  def build_attr_value(%__MODULE__{} = parse_state, attr_value) when is_bitstring(attr_value) do
    %__MODULE__{parse_state | attr_value: parse_state.attr_value <> attr_value}
  end

  @spec put_attr(t()) :: t()
  def put_attr(
        %__MODULE__{attr_key: attr_key, attr_value: attr_value, attrs: attrs} = parse_state
      ) do
    attrs =
      if attr_value == "" do
        Map.put(attrs, attr_key, true)
      else
        Map.put(attrs, attr_key, attr_value)
      end

    %__MODULE__{parse_state | attrs: attrs, attr_key: "", attr_value: ""}
  end

  @spec put_attr_quote(t(), :single | :double) :: t()
  def put_attr_quote(%__MODULE__{} = parse_state, attr_quote) do
    %__MODULE__{parse_state | attr_quote: attr_quote}
  end

  @spec get_attr_quote(t()) :: :single | :double
  def get_attr_quote(%__MODULE__{attr_quote: attr_quote}) do
    attr_quote
  end

  @spec add_text(t()) :: t()
  def add_text(%__MODULE__{tags: tags, text: text} = parse_state) do
    if String.trim(text) == "" do
      %__MODULE__{parse_state | text: ""}
    else
      %__MODULE__{parse_state | tags: [{:text, String.trim(text, "\n")} | tags], text: ""}
    end
  end

  @spec add_comment(t()) :: t()
  def add_comment(%__MODULE__{tags: tags, comment: comment} = parse_state) do
    if String.trim(comment) == "" do
      %__MODULE__{parse_state | comment: ""}
    else
      %__MODULE__{parse_state | tags: [{:comment, String.trim(comment)} | tags], comment: ""}
    end
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
  def add_open_tag(%__MODULE__{tags: tags, open_tag: open_tag_string, meta: meta} = parse_state) do
    open_tag = String.to_atom(open_tag_string)
    parse_state = parse_state |> increment_tag_count(open_tag)
    tag_count = get_tag_count!(parse_state, open_tag)

    meta = Map.merge(meta, %{depth_count: tag_count, type: :open, attrs: %{}})

    %__MODULE__{parse_state | tags: [{open_tag, meta} | tags], open_tag: "", meta: %{}}
  end

  @spec add_close_tag(t()) :: t()
  def add_close_tag(%__MODULE__{tags: tags, close_tag: close_tag, meta: meta} = parse_state) do
    close_tag = String.to_atom(close_tag)
    tag_count = get_tag_count!(parse_state, close_tag)
    parse_state = parse_state |> decrement_tag_count(close_tag)

    meta = Map.merge(meta, %{depth_count: tag_count, type: :close, attrs: %{}})

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

  @spec get_tags(t()) :: tags()
  def get_tags(%__MODULE__{tags: tags}) do
    Enum.reverse(tags)
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
