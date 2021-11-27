defmodule HTMLParser.Tags do
  @external_resource csv_file = Path.join(__DIR__, "tags.csv")
  @raw_tags csv_file
            |> File.read!()
            |> String.split("\n", trim: true)
            |> Enum.map(&String.split(&1, ","))

  tags =
    for [tag, empty] <- @raw_tags do
      tag = String.to_atom(tag)

      def empty?(unquote(tag)) do
        unquote(empty) == "t"
      end

      def recognised?(unquote(tag)), do: true

      tag
    end

  def empty?(_), do: false
  def recognised?(_), do: false

  def all, do: unquote(tags)
end
