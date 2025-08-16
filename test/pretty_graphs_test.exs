defmodule PrettyGraphsTest do
  use ExUnit.Case, async: true
  doctest PrettyGraphs

  describe "bar_chart/2" do
    test "renders an SVG with role and basic elements" do
      svg = PrettyGraphs.bar_chart([{"A", 10}, {"B", 20}], title: "Example")

      assert String.starts_with?(svg, "<svg")
      assert svg =~ ~s(role="img" aria-label="Bar chart")
      assert svg =~ "<rect"
      assert svg =~ ">A</text>"
      assert svg =~ ">B</text>"
      assert svg =~ ">Example</text>"
      # values appear as text at the end of bars
      assert svg =~ ">10</text>"
      assert svg =~ ">20</text>"
    end

    test "supports list of numbers with default labels" do
      svg = PrettyGraphs.bar_chart([10, 5, 15])

      # three bars
      rect_count = Regex.scan(~r/<rect\b/, svg) |> length()
      assert rect_count == 3

      # default labels are 1, 2, 3 (as text nodes)
      assert svg =~ ">1</text>"
      assert svg =~ ">2</text>"
      assert svg =~ ">3</text>"

      # values present
      assert svg =~ ">10</text>"
      assert svg =~ ">5</text>"
      assert svg =~ ">15</text>"
    end

    test "supports map data shape" do
      svg = PrettyGraphs.bar_chart(%{"X" => 3, "Y" => 7})

      assert svg =~ ">X</text>"
      assert svg =~ ">Y</text>"
      assert svg =~ ">3</text>"
      assert svg =~ ">7</text>"
    end

    test "renders title when provided" do
      svg = PrettyGraphs.bar_chart([{"A", 1}], title: "Sales Results")
      assert svg =~ ">Sales Results</text>"
    end

    test "default value formatter handles floats compactly" do
      svg = PrettyGraphs.bar_chart([{"Pi", 3.14}, {"Half", 0.5}, {"Ten", 10.0}])

      assert svg =~ ">3.14</text>"
      assert svg =~ ">0.5</text>"
      # 10.0 should be compacted to "10"
      assert svg =~ ">10</text>"
      refute svg =~ ">10.0</text>"
    end

    test "empty data renders a 'No data' placeholder" do
      svg = PrettyGraphs.bar_chart([])
      assert svg =~ ">No data</text>"
    end

    test "respects width option in attributes" do
      svg = PrettyGraphs.bar_chart([{"A", 1}], width: 720)
      assert svg =~ ~s(width="720")
      assert svg =~ ~s(viewBox="0 0 720 )
    end

    test "gradient and clipPath IDs are unique per render" do
      svg1 = PrettyGraphs.bar_chart([{"A", 1}], gradient: [from: "#111111", to: "#222222"])
      svg2 = PrettyGraphs.bar_chart([{"A", 2}], gradient: [from: "#333333", to: "#444444"])

      # Extract gradient ids
      [id1] = Regex.run(~r/<linearGradient id="([^"]+)"/, svg1, capture: :all_but_first)
      [id2] = Regex.run(~r/<linearGradient id="([^"]+)"/, svg2, capture: :all_but_first)
      refute id1 == id2

      # Extract clipPath ids
      [clip1] = Regex.run(~r/<clipPath id="([^"]+)"/, svg1, capture: :all_but_first)
      [clip2] = Regex.run(~r/<clipPath id="([^"]+)"/, svg2, capture: :all_but_first)
      refute clip1 == clip2

      # Ensure references use the matching ids
      assert svg1 =~ "url(#" <> clip1 <> ")"
      assert svg2 =~ "url(#" <> clip2 <> ")"
      assert svg1 =~ "fill=\"url(#" <> id1 <> ")"
      assert svg2 =~ "fill=\"url(#" <> id2 <> ")"
    end
  end

  test "hello/0 smoke test for backward compat" do
    assert PrettyGraphs.hello() == :world
  end
end
