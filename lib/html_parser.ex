defmodule HTMLParser do
  @moduledoc """
  Parses an HTML string and returns an Elixir representation
  """

  alias HTMLParser.{HTMLNodeTree, ParseState, TreeBuilder}

  @type html :: String.t()

  @spec parse(html) :: {:ok, HTMLNodeTree.t() | [HTMLNodeTree.t()]} | {:error, any()}

  @doc """
  Parses an HTML string and returns an Elixir representation of HTML nodes with `HTMLNodeTree`
  """
  def parse(html) when is_binary(html) do
    parse_state = ParseState.new()
    html = html |> String.trim()

    parse_state
    |> do_parse(html, :init)
    |> ParseState.get_tags()
    |> TreeBuilder.build()
  end

  # Parse started
  defp do_parse(parse_state, <<"<">> <> rest, :init) do
    parse_state
    |> ParseState.set_char_count()
    |> do_parse(rest, :parse_open_tag)
  end

  # End of open tag
  defp do_parse(parse_state, <<">">> <> rest, :parse_open_tag) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.add_open_tag()
    |> ParseState.add_attrs()
    |> do_parse(rest, :continue)
  end

  # Parse attributes
  defp do_parse(parse_state, <<" ">> <> rest, :parse_open_tag) do
    parse_state
    |> ParseState.set_char_count()
    |> do_parse(rest, :parse_attrs)
  end

  # Build open tag
  defp do_parse(parse_state, <<open_tag>> <> rest, :parse_open_tag) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.build_open_tag(<<open_tag>>)
    |> do_parse(rest, :parse_open_tag)
  end

  defp do_parse(parse_state, <<">">> <> rest, :parse_attrs) do
    parse_state
    |> do_parse(<<">">> <> rest, :parse_open_tag)
  end

  defp do_parse(parse_state, " " <> rest, :parse_attrs) do
    parse_state
    |> ParseState.set_char_count()
    |> do_parse(rest, :parse_attrs)
  end

  defp do_parse(parse_state, rest, :parse_attrs) do
    parse_state
    |> do_parse(rest, :build_attr_key)
  end

  defp do_parse(parse_state, <<"\"">> <> rest, :build_attr_value) do
    if ParseState.get_attr_quote(parse_state) == :double do
      parse_state
      |> ParseState.set_char_count()
      |> ParseState.put_attr()
      |> do_parse(rest, :parse_attrs)
    else
      parse_state
      |> ParseState.set_char_count()
      |> ParseState.build_attr_value(<<"\"">>)
      |> do_parse(rest, :build_attr_value)
    end
  end

  defp do_parse(parse_state, <<"\'">> <> rest, :build_attr_value) do
    if ParseState.get_attr_quote(parse_state) == :single do
      parse_state
      |> ParseState.set_char_count()
      |> ParseState.put_attr()
      |> do_parse(rest, :parse_attrs)
    else
      parse_state
      |> ParseState.set_char_count()
      |> ParseState.build_attr_value(<<"\'">>)
      |> do_parse(rest, :build_attr_value)
    end
  end

  # Store attribute
  defp do_parse(parse_state, <<"=\"">> <> rest, :build_attr_key) do
    parse_state
    |> ParseState.set_char_count(2)
    |> ParseState.put_attr_quote(:double)
    |> do_parse(rest, :build_attr_value)
  end

  defp do_parse(parse_state, <<"=\'">> <> rest, :build_attr_key) do
    parse_state
    |> ParseState.set_char_count(2)
    |> ParseState.put_attr_quote(:single)
    |> do_parse(rest, :build_attr_value)
  end

  defp do_parse(parse_state, <<" ">> <> rest, :build_attr_key) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.put_attr()
    |> do_parse(rest, :parse_attrs)
  end

  # Build attribute
  defp do_parse(parse_state, <<attr_key>> <> rest, :build_attr_key) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.build_attr_key(<<attr_key>>)
    |> do_parse(rest, :build_attr_key)
  end

  defp do_parse(parse_state, <<attr_value>> <> rest, :build_attr_value) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.build_attr_value(<<attr_value>>)
    |> do_parse(rest, :build_attr_value)
  end

  # Text parsing finished
  defp do_parse(parse_state, <<"<", "/">> <> rest, :parse_text) do
    parse_state
    |> ParseState.set_char_count(2)
    |> ParseState.add_text()
    |> do_parse(rest, :parse_close_tag)
  end

  # Build text
  defp do_parse(parse_state, <<text>> <> rest, :parse_text) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.build_text(<<text>>)
    |> do_parse(rest, :parse_text)
  end

  # Start of closing tag
  defp do_parse(parse_state, <<"<", "/">> <> rest, :parse_open_tag) do
    parse_state
    |> ParseState.set_char_count(2)
    |> ParseState.add_meta()
    |> do_parse(rest, :parse_close_tag)
  end

  defp do_parse(parse_state, <<"<", "/">> <> rest, :continue) do
    parse_state
    |> ParseState.set_char_count(2)
    |> ParseState.add_meta()
    |> do_parse(rest, :parse_close_tag)
  end

  # End of closing tag
  defp do_parse(parse_state, <<">">> <> rest, :parse_close_tag) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.add_close_tag()
    |> do_parse(rest, :continue)
  end

  # Build closing tag
  defp do_parse(parse_state, <<close_tag>> <> rest, :parse_close_tag) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.build_close_tag(<<close_tag>>)
    |> do_parse(rest, :parse_close_tag)
  end

  # Start parsing open tag
  defp do_parse(parse_state, <<"<">> <> rest, :continue) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.add_meta()
    |> do_parse(rest, :parse_open_tag)
  end

  # Ignore whitespace characters before text
  defp do_parse(parse_state, <<" ">> <> rest, :continue) do
    parse_state
    |> ParseState.set_char_count()
    |> do_parse(rest, :continue)
  end

  defp do_parse(parse_state, <<"\n">> <> rest, :continue) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.set_newline_count()
    |> do_parse(rest, :continue)
  end

  # Parse text
  defp do_parse(parse_state, <<text>> <> rest, :continue) do
    parse_state
    |> ParseState.set_char_count()
    |> ParseState.build_text(<<text>>)
    |> do_parse(rest, :parse_text)
  end

  # End of parse
  defp do_parse(parse_state, "", _state) do
    parse_state
  end
end
