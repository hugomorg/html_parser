defmodule HTMLParser.HTMLTextNode do
  @type t :: %__MODULE__{}

  @enforce_keys :value
  defstruct [:value, :next]

  def new(value), do: %__MODULE__{value: value}

  def put_next(%__MODULE__{} = html_text_node, next) do
    %__MODULE__{html_text_node | next: next}
  end
end
