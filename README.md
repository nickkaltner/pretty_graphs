# PrettyGraphs
[![Hex.pm Version](https://img.shields.io/hexpm/v/pretty_graphs.svg)](https://hex.pm/packages/pretty_graphs)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/pretty_graphs.svg)](https://hex.pm/packages/pretty_graphs)
[![License](https://img.shields.io/hexpm/l/pretty_graphs.svg)](LICENSE)
[![Docs](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/pretty_graphs)


PrettyGraphs is a tiny Elixir library for generating good‑looking SVG/HTML charts suitable for Phoenix LiveView and other HTML renderers.

The initial release provides a horizontal bar chart with:
- Slightly rounded corners
- Titles shown by default
- Values rendered just past the end of each bar
- Simple inputs and a self-contained `<svg>` string output

## Installation

Add `pretty_graphs` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pretty_graphs, "~> 0.1.0"}
  ]
end
```

Then fetch your dependencies:

```bash
mix deps.get
```

## Quick start

```elixir
iex> svg = PrettyGraphs.bar_chart(
...>   [{"Apples", 10}, {"Bananas", 25}, {"Cherries", 18}],
...>   title: "Fruit Sales"
...> )
iex> String.starts_with?(svg, "<svg")
true
```

The returned value is a standalone `<svg>` element as a string. You can embed it anywhere HTML is accepted.

## Phoenix LiveView usage

Render the returned SVG string with `Phoenix.HTML.raw/1` so it isn’t escaped. Assign it in `mount/3` (or a handler) and render in your template:

```elixir
defmodule MyAppWeb.DemoLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    data = [{"Apples", 10}, {"Bananas", 25}, {"Cherries", 18}]
    svg =
      PrettyGraphs.bar_chart(data,
        title: "Fruit Sales",
        gradient: [from: "#4f46e5", to: "#a78bfa", direction: :right]
      )

    {:ok, assign(socket, bar_svg: svg)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-3xl">
      <%= Phoenix.HTML.raw(@bar_svg) %>
    </div>
    """
  end
end
```

### Adding LiveView events (phx-click, phx-value-*, hooks)

You can attach Phoenix attributes and classes to either:
- the entire SVG root (via `:svg_attrs` and `:svg_class`), and/or
- each bar `<rect>` (via `:bar_attrs` and `:bar_class`).

Per-bar attributes/classes can also be set at the data point level, so you can, for example, attach a global `phx-click` to every bar and a specific `phx-value-*` to each item.

Global SVG and bar attributes/classes:
```elixir
data = [{"Apples", 10}, {"Bananas", 25}, {"Cherries", 18}]

svg =
  PrettyGraphs.bar_chart(
    data,
    title: "Interactive Bars",
    # Attach a hook to the root SVG:
    svg_attrs: %{"phx-hook" => "Chart"},
    svg_class: ["w-full", "h-auto"],
    # Attach a click handler to each bar rect and add classes:
    bar_attrs: [data_role: "bar", %{"phx-click" => "bar_clicked"}],
    bar_class: ["cursor-pointer", "hover:opacity-80"]
  )
```

Per-data-point attributes and classes using a 3-tuple:
```elixir
data = [
  {"Apples", 10, [attrs: %{"phx-value-fruit" => "apples"}]},
  {"Bananas", 25, [attrs: %{"phx-value-fruit" => "bananas"}]},
  {"Cherries", 18, [attrs: %{"phx-value-fruit" => "cherries"}]}
]

svg =
  PrettyGraphs.bar_chart(
    data,
    title: "Per-bar values + global click",
    # Global click for all bars:
    bar_attrs: [%{"phx-click" => "bar_clicked"}],
    bar_class: "cursor-pointer hover:opacity-80"
  )
```

Per-data-point attributes using the map shape:
```elixir
data = %{
  "Apples" => {10, [attrs: %{"phx-value-fruit" => "apples"}, class: "fill-lime-600"]},
  "Bananas" => {25, [attrs: %{"phx-value-fruit" => "bananas"}]},
  "Cherries" => {18, [attrs: %{"phx-value-fruit" => "cherries"}]}
}

svg =
  PrettyGraphs.bar_chart(
    data,
    title: "Map shape with per-point attrs/classes",
    bar_attrs: [%{"phx-click" => "bar_clicked"}],
    bar_class: "cursor-pointer hover:opacity-80"
  )
```

In your LiveView, handle the event as usual:
```elixir
@impl true
def handle_event("bar_clicked", %{"fruit" => fruit}, socket) do
  # Do something with fruit e.g., "apples"
  {:noreply, socket}
end
```

Notes:
- `:svg_attrs`/`:bar_attrs` accept keyword lists or maps. Use string keys for hyphenated attributes (e.g., `%{"phx-click" => "...", "phx-value-id" => "123"}`).
- Per-point attrs/classes override global ones on conflicts.
- Always render with `Phoenix.HTML.raw/1` to avoid escaping the SVG.

## Data shapes

You can pass data in any of the following forms:

- List of `{label, value}` tuples:
  ```elixir
  [{"A", 10}, {"B", 20}]
  ```

- List of numbers (labels default to `"1"`, `"2"`, ...):
  ```elixir
  [10, 20, 30]
  ```

- Map of `label => value`:
  ```elixir
  %{"A" => 10, "B" => 20}
  ```

Values can be integers, floats, or numeric strings (e.g., `"42"`, `"3.14"`).

## Bar chart API

```elixir
PrettyGraphs.bar_chart(data, opts \\ [])
```

- `data`: one of the shapes described above
- `opts`: keyword list to customize the chart

### Options and defaults

- `:title` — Chart title string (default: `nil`)
- `:width` — Overall chart width in px (default: `640`)
- `:bar_height` — Height of each bar in px (default: `28`)
- `:bar_gap` — Gap between bars in px (default: `2`)
- `:padding` — Keyword list of `{left, right, top, bottom}` padding in px
  - default: `[left: 120, right: 48, top: 32, bottom: 24]`
- `:bar_radius` — Corner radius for bars (rx/ry) in px (default: `6`)
- `:bar_color` — Fill color for bars (default: `"#4f46e5"`)
- `:label_color` — Color for bar labels (default: `"#111827"`)
- `:value_color` — Color for value labels (default: `"#111827"`)
- `:title_color` — Color for title text (default: `"#111827"`)
- `:background` — Background color for the SVG (default: `nil`, no background rect)
- `:show_values` — Whether to render value labels (default: `true`)
- `:value_formatter` — `fun(value :: number) :: String.t()` for custom formatting
  - default: integers without decimals; floats up to 2 decimals (trimmed)
- `:font_family` — Font family used for text (default: system UI stack)
- `:font_size` — Base font size in px (default: `12`)
- `:gradient` — Enable a linear gradient fill for bars (default: `nil`, disabled). Example:
  - `[from: "#4f46e5", to: "#a78bfa", direction: :right]` for left-to-right
  - `[from: "#4f46e5", to: "#a78bfa", direction: :down]` for top-to-bottom

### Example: Theming and formatting

```elixir
data = %{"One" => 12, "Two" => 7.5, "Three" => 19.2}

svg =
  PrettyGraphs.bar_chart(data,
    title: "Custom Theme",
    width: 720,
    bar_height: 24,
    bar_gap: 10,
    bar_radius: 8,
    bar_color: "#0ea5e9",
    label_color: "#374151",
    value_color: "#111827",
    title_color: "#111827",
    background: "#ffffff",
    font_family: "Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif",
    value_formatter: fn v -> :erlang.float_to_binary(v * 1.0, [:compact, {:decimals, 1}]) <> "%" end
  )
```

### Example: Gradient fill

```elixir
data = [{"Apples", 10}, {"Bananas", 25}, {"Cherries", 18}]

svg =
  PrettyGraphs.bar_chart(data,
    title: "Gradient Bars",
    width: 640,
    gradient: [from: "#4f46e5", to: "#a78bfa", direction: :right]
  )
```

You can change the direction to `:down` for a vertical gradient:

```elixir
PrettyGraphs.bar_chart(data, gradient: [from: "#4f46e5", to: "#a78bfa", direction: :down])
```

Diagonal directions are also supported: `:down_right`, `:down_left`, `:up_right`, and `:up_left`.

```elixir
# Top-left -> bottom-right
PrettyGraphs.bar_chart(data, gradient: [from: "#0ea5e9", to: "#a78bfa", direction: :down_right])

# Top-right -> bottom-left
PrettyGraphs.bar_chart(data, gradient: [from: "#0ea5e9", to: "#a78bfa", direction: :down_left])

# Bottom-left -> top-right
PrettyGraphs.bar_chart(data, gradient: [from: "#0ea5e9", to: "#a78bfa", direction: :up_right])

# Bottom-right -> top-left
PrettyGraphs.bar_chart(data, gradient: [from: "#0ea5e9", to: "#a78bfa", direction: :up_left])
```

IEx-ready snippet you can paste:

```elixir
iex> data = [{"Apples", 10}, {"Bananas", 25}, {"Cherries", 18}]
iex> svg = PrettyGraphs.bar_chart(data, title: "Diagonal Gradient", gradient: [from: "#0ea5e9", to: "#a78bfa", direction: :down_right])
iex> String.starts_with?(svg, "<svg")
true
```

## Defaults tuned for LiveView

- Horizontal layout
- Slightly rounded bars
- Title shown (when provided via `:title`)
- Value labels near the end of the bar
- Sensible spacing for labels and values
- Standalone `<svg>` output (no external CSS required)

## Accessibility

- The root `<svg>` includes `role="img"` and an accessible label.
- Text labels are rendered as real text nodes for better screen reader support.
- Consider providing descriptive titles via `:title` for additional context.

## Testing

Run the test suite with:

```bash
mix test
```

example


## Roadmap

- Vertical bar charts
- Stacked/grouped bars
- Axes and gridlines
- Line/area charts
- Pie/donut charts
- Legend and color scales
- Animation and transitions (where appropriate)

Contributions and suggestions are welcome!

## License

MIT
