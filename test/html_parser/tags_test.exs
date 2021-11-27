defmodule HTMLParser.TagsTest do
  use ExUnit.Case
  alias HTMLParser.Tags

  doctest Tags

  describe "all/0" do
    test "returns all tags" do
      assert Tags.all() == [
               :a,
               :abbr,
               :address,
               :area,
               :article,
               :aside,
               :audio,
               :b,
               :base,
               :bdi,
               :bdo,
               :blockquote,
               :body,
               :br,
               :button,
               :canvas,
               :caption,
               :cite,
               :code,
               :col,
               :colgroup,
               :data,
               :datalist,
               :dd,
               :del,
               :details,
               :dfn,
               :dialog,
               :div,
               :dl,
               :dt,
               :em,
               :embed,
               :fieldset,
               :figcaption,
               :figure,
               :footer,
               :form,
               :h1,
               :h2,
               :h3,
               :h4,
               :h5,
               :h6,
               :head,
               :header,
               :hr,
               :html,
               :i,
               :iframe,
               :img,
               :input,
               :ins,
               :kbd,
               :label,
               :legend,
               :li,
               :link,
               :main,
               :map,
               :mark,
               :match,
               :menu,
               :meta,
               :meter,
               :nav,
               :noscript,
               :object,
               :ol,
               :optgroup,
               :option,
               :output,
               :p,
               :param,
               :picture,
               :portal,
               :pre,
               :progress,
               :q,
               :rp,
               :rt,
               :ruby,
               :s,
               :samp,
               :script,
               :section,
               :select,
               :slot,
               :small,
               :source,
               :span,
               :strong,
               :style,
               :sub,
               :summary,
               :sup,
               :svg,
               :table,
               :tbody,
               :td,
               :template,
               :textarea,
               :tfoot,
               :th,
               :thead,
               :time,
               :title,
               :tr,
               :track,
               :u,
               :ul,
               :var,
               :video,
               :wbr
             ]
    end
  end

  describe "empty?/1" do
    test "returns whether a tag is empty (no children)" do
      assert Tags.empty?(:meta)
      refute Tags.empty?(:p)

      # Unknown tag
      refute Tags.empty?(:metal)
    end
  end

  describe "recognised?/1" do
    test "returns whether a tag is conventional and known" do
      assert Tags.recognised?(:pre)
      refute Tags.recognised?(:pizza)
    end
  end
end
