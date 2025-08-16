defmodule PrettyGraphs do
  @moduledoc """
  PrettyGraphs is a tiny Elixir library for generating good-looking SVG/HTML charts
  suitable for Phoenix LiveView and other HTML renderers.

  The initial release includes a horizontal bar chart with slightly rounded bars,
  labels shown by default, and each bar's value rendered just past the end of the bar.

  You can pass in very simple inputs and get back a self-contained `<svg>` string
  that you can embed into your LiveView templates.

  ## Quick start

      iex> svg = PrettyGraphs.bar_chart([{"Apples", 10}, {"Bananas", 25}, {"Cherries", 18}], title: "Fruit Sales")
      iex> String.starts_with?(svg, "<svg")
      true

  The `data` can be provided in several convenient shapes:

    - A list of `{label, value}` tuples:
      `[{"A", 10}, {"B", 20}]`

    - A simple list of numbers (labels will default to "1", "2", ...):
      `[10, 20, 30]`

    - A map of `label => value`:
      `%{"A" => 10, "B" => 20}`

  ## Phoenix LiveView usage

  In a LiveView, assign the SVG string and render it using Phoenix.HTML.raw/1.

  Example: set `assigns[:bar_svg] = PrettyGraphs.bar_chart([{"A", 10}, {"B", 25}, {"C", 17}], title: "Demo")`
  and place `<%= Phoenix.HTML.raw(@bar_svg) %>` where you want it to appear.

  ## Defaults

  - Horizontal bars
  - Slightly rounded corners (rx/ry)
  - Bar labels shown
  - Value labels shown at the end of each bar
  - Sensible padding and sizing

  See `PrettyGraphs.BarChart` for all configurable options.

  ## Notes

  The returned value is a standalone `<svg>` element as a string. If you need
  to manipulate it further, you can treat it as text or iodata.
  """

  @doc """
  Generate a horizontal, rounded-corner bar chart as a self-contained `<svg>` string.

  Accepts:
    - `data`: one of
        * list of `{label :: String.t(), value :: number}`
        * list of numbers (labels will default to `"1"`, `"2"`, ...)
        * map `%{label => value}`
    - `opts`: keyword list of options (see below)

  Options (all optional):
    - `:title` - Chart title string (default: `nil`)
    - `:width` - Overall chart width in px (default: 640)
    - `:bar_height` - Height of each bar in px (default: 28)
    - `:bar_gap` - Gap between bars in px (default: 2)
    - `:padding` - Keyword list of `{left, right, top, bottom}` padding in px
                   (default: `[left: 120, right: 48, top: 32, bottom: 24]`)
    - `:bar_radius` - Corner radius for bars (rx/ry) in px (default: 6)
    - `:bar_color` - Fill color for bars (default: "#4f46e5")
    - `:label_color` - Color for bar labels (default: "#111827")
    - `:value_color` - Color for value labels (default: "#111827")
    - `:title_color` - Color for title text (default: "#111827")
    - `:background` - Background color for the SVG (default: nil/no background)
    - `:show_values` - Whether to render value labels (default: true)
    - `:value_formatter` - `fun(value :: number) :: String.t()` to format values
                           (default: converts integer-like to integer string, otherwise trims trailing zeros)
    - `:font_family` - Font family to use for text (default: a system-ui stack)
    - `:font_size` - Base font size in px (default: 12)
    - `:gradient` - Keyword list to enable a linear gradient for bar fills (default: `nil`/disabled).
                    Direction options: `:right | :down | :down_right | :down_left | :up_right | :up_left`.
                    Example: `[from: "#4f46e5", to: "#a78bfa", direction: :down_right]`
    - `:svg_attrs` - Keyword list or map of extra attributes to add to the root `<svg>` element.
                     Use string keys for attributes with hyphens (e.g., `%{"phx-hook" => "Chart"}`).
    - `:svg_class` - String or list of classes to add to the root `<svg>` element.
    - `:bar_attrs` - Keyword list or map of extra attributes to add to each bar `<rect>`. Merged with per-point attrs.
    - `:bar_class` - String or list of classes to add to each bar `<rect>`. Combined with per-point classes.

  ## Examples

      iex> PrettyGraphs.bar_chart([{"A", 10}, {"B", 20}], title: "Example") |> String.contains?("<svg")
      true

      iex> PrettyGraphs.bar_chart([10, 5, 15]) |> String.contains?("rect")
      true

      iex> PrettyGraphs.bar_chart(%{"A" => 1, "B" => 2, "C" => 3}) |> String.contains?("text")
      true

      iex> PrettyGraphs.bar_chart([{"A", 10}, {"B", 20}], title: "Gradient", gradient: [from: "#4f46e5", to: "#a78bfa"]) |> String.contains?("<linearGradient")
      true
      iex> PrettyGraphs.bar_chart([{"NW", 5}, {"SE", 10}], gradient: [from: "#0ea5e9", to: "#a78bfa", direction: :down_right]) |> String.starts_with?("<svg")
      true
      iex> PrettyGraphs.bar_chart([{"Apples", 10, [attrs: %{"phx-click" => "bar", "phx-value-fruit" => "apples"}]}], bar_class: "hover:opacity-80", bar_attrs: [data_role: "bar"]) |> String.contains?("phx-click")
      true
  """
  @spec bar_chart(
          list({String.t(), number}) | list(number) | %{optional(String.t()) => number},
          keyword()
        ) :: String.t()
  def bar_chart(data, opts \\ []) do
    PrettyGraphs.BarChart.render(data, opts)
  end

  @doc """
  Retained for compatibility with the generated project test suite.

  Returns `:world`.
  """
  def hello, do: :world

  defmodule BarChart do
    @moduledoc """
    Renders a horizontal bar chart as an `<svg>` string.

    Defaults are tuned for LiveView with rounded bars and labels enabled.

    See `PrettyGraphs.bar_chart/2` for the full API.
    """

    @type bar :: {String.t(), number}

    @default_font_family "system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif"

    @spec render(list(bar) | list(number) | %{optional(String.t()) => number}, keyword()) ::
            String.t()
    def render(raw_data, opts \\ []) do
      data = normalize_data(raw_data)

      width = Keyword.get(opts, :width, 640)
      bar_height = Keyword.get(opts, :bar_height, 28)
      bar_gap = Keyword.get(opts, :bar_gap, 2)

      padding =
        Keyword.get(opts, :padding, left: 120, right: 48, top: 32, bottom: 24)
        |> normalize_padding()

      title = Keyword.get(opts, :title, nil)
      show_title? = title && String.trim(to_string(title)) != ""
      show_values? = Keyword.get(opts, :show_values, true)

      bar_radius = Keyword.get(opts, :bar_radius, 6)
      bar_color = Keyword.get(opts, :bar_color, "#4f46e5")
      label_color = Keyword.get(opts, :label_color, "#111827")
      value_color = Keyword.get(opts, :value_color, "#111827")
      title_color = Keyword.get(opts, :title_color, "#111827")
      background = Keyword.get(opts, :background, nil)
      gradient = normalize_gradient(Keyword.get(opts, :gradient, nil))
      uid = :erlang.unique_integer([:positive, :monotonic])
      grad_id = "pg-grad-#{uid}"
      clip_id = "pg-bars-clip-#{uid}"
      svg_attrs0 = Keyword.get(opts, :svg_attrs, [])
      svg_class = normalize_class(Keyword.get(opts, :svg_class, nil))
      bar_attrs = Keyword.get(opts, :bar_attrs, [])
      bar_class = normalize_class(Keyword.get(opts, :bar_class, nil))
      responsive? = Keyword.get(opts, :responsive, false)

      # If responsive, set width="100%" and disable aspect ratio preservation so bars expand to parent width.
      svg_attrs =
        if responsive? do
          merge_attrs(svg_attrs0, %{"preserveAspectRatio" => "none", "data-pg-width" => "100%"})
        else
          svg_attrs0
        end

      font_family = Keyword.get(opts, :font_family, @default_font_family)
      font_size = Keyword.get(opts, :font_size, 12)

      value_formatter = Keyword.get(opts, :value_formatter, &default_value_formatter/1)

      n = length(data)
      inner_width = max(width - padding.left - padding.right, 0)

      # Height: include top padding (space for title), bars/gaps, and bottom padding
      bars_total_height =
        if n > 0 do
          n * bar_height + max(n - 1, 0) * bar_gap
        else
          # A little space even for empty state
          bar_height
        end

      height = padding.top + bars_total_height + padding.bottom

      max_value =
        data
        |> Enum.map(fn item -> item.value end)
        |> case do
          [] -> 0
          vs -> Enum.max([0 | vs])
        end

      scale =
        if max_value == 0 or inner_width == 0 do
          fn _v -> 0.0 end
        else
          fn v -> v / max_value * inner_width end
        end

      {svg_open, svg_close} =
        svg_tag_open_close(
          width: width,
          height: height,
          background: background,
          class: svg_class,
          extra_attrs: svg_attrs
        )

      defs =
        case gradient do
          nil ->
            ""

          _ ->
            bar_geoms =
              Enum.with_index(data)
              |> Enum.map(fn {item, idx} ->
                y = padding.top + idx * (bar_height + bar_gap)
                bar_w = scale.(item.value)

                %{
                  x: padding.left,
                  y: y,
                  width: bar_w,
                  height: bar_height,
                  rx: bar_radius,
                  ry: bar_radius
                }
              end)

            [
              gradient_defs(
                grad_id,
                gradient,
                padding.left,
                padding.top,
                inner_width,
                bars_total_height
              ),
              bars_clip_defs(clip_id, bar_geoms)
            ]
        end

      title_text =
        if show_title? do
          y = max(0, div(padding.top, 2) + font_size)

          text_el(title |> to_string(),
            x: padding.left,
            y: y,
            opts: [
              font_family: font_family,
              font_size: font_size + 2,
              fill: title_color,
              font_weight: "600",
              anchor: "start"
            ]
          )
        else
          ""
        end

      fill_value =
        case gradient do
          nil -> bar_color
          _ -> "transparent"
        end

      bars =
        Enum.with_index(data)
        |> Enum.map(fn {item, idx} ->
          label = item.label
          value = item.value
          y = padding.top + idx * (bar_height + bar_gap)
          bar_w = scale.(value)
          rx = ry = bar_radius

          # Label to the left of the bar
          label_y = y + div(bar_height, 2)

          label_text =
            text_el(label,
              x: padding.left - 8,
              y: label_y,
              opts: [
                font_family: font_family,
                font_size: font_size,
                fill: label_color,
                anchor: "end",
                dominant_baseline: "middle"
              ]
            )

          # The bar rect with custom attrs/classes
          rect_el =
            rect_el(
              x: padding.left,
              y: y,
              width: bar_w,
              height: bar_height,
              rx: rx,
              ry: ry,
              fill: fill_value,
              class: join_classes([bar_class, item.class]),
              extra_attrs: merge_attrs(bar_attrs, item.attrs)
            )

          # Value label at end of bar
          value_text =
            if show_values? do
              value_str = value_formatter.(value)

              text_el(value_str,
                x: padding.left + bar_w + 6,
                y: label_y,
                opts: [
                  font_family: font_family,
                  font_size: font_size,
                  fill: value_color,
                  anchor: "start",
                  dominant_baseline: "middle"
                ]
              )
            else
              ""
            end

          [label_text, rect_el, value_text]
        end)

      # Insert a single gradient layer clipped by bar shapes, so bars act as windows over a global gradient
      bars =
        case gradient do
          nil ->
            bars

          _ ->
            [
              gradient_layer(
                grad_id: grad_id,
                clip_id: clip_id,
                x: padding.left,
                y: padding.top,
                width: inner_width,
                height: bars_total_height
              )
            ] ++ bars
        end

      empty_state =
        if n == 0 do
          y = padding.top + div(bar_height, 2)

          text_el("No data",
            x: padding.left,
            y: y,
            opts: [
              font_family: font_family,
              font_size: font_size,
              fill: label_color,
              anchor: "start",
              dominant_baseline: "middle"
            ]
          )
        else
          ""
        end

      IO.iodata_to_binary([svg_open, defs, title_text, bars, empty_state, svg_close])
    end

    @doc """
    Default value formatter.

    - Integer-like numbers are formatted without decimals.
    - Floats are formatted with up to 2 decimals, trimming trailing zeros.
    """
    @spec default_value_formatter(number) :: String.t()
    def default_value_formatter(v) when is_integer(v), do: Integer.to_string(v)

    def default_value_formatter(v) when is_float(v) do
      if v == trunc(v) * 1.0 do
        Integer.to_string(trunc(v))
      else
        :erlang.float_to_binary(v, [:compact, {:decimals, 2}])
      end
    end

    def default_value_formatter(v) when is_number(v) do
      # Fallback for other number types
      to_string(v)
    end

    # -- Internal helpers -----------------------------------------------------

    defp normalize_data(data) when is_list(data) do
      cond do
        data == [] ->
          []

        is_tuple(hd(data)) ->
          Enum.map(data, fn
            {label, v} ->
              %{
                label: to_string(label),
                value: to_number(v),
                attrs: [],
                class: nil
              }

            {label, v, item_opts} ->
              %{label: to_string(label), value: to_number(v)}
              |> Map.merge(normalize_item_opts(item_opts))
          end)

        is_number(hd(data)) ->
          data
          |> Enum.with_index(1)
          |> Enum.map(fn {v, idx} ->
            %{
              label: Integer.to_string(idx),
              value: to_number(v),
              attrs: [],
              class: nil
            }
          end)

        true ->
          raise ArgumentError,
                "bar_chart data list must contain numbers or {label, value} or {label, value, item_opts} tuples"
      end
    end

    defp normalize_data(%{} = map) do
      map
      |> Enum.map(fn
        {label, {v, item_opts}} ->
          %{label: to_string(label), value: to_number(v)}
          |> Map.merge(normalize_item_opts(item_opts))

        {label, v} ->
          %{
            label: to_string(label),
            value: to_number(v),
            attrs: [],
            class: nil
          }
      end)
      |> Enum.sort_by(& &1.label)
    end

    defp normalize_data(other) do
      raise ArgumentError,
            "unsupported data shape for bar_chart: #{inspect(other)}"
    end

    defp to_number(v) when is_integer(v), do: v
    defp to_number(v) when is_float(v), do: v

    defp to_number(v) do
      case v do
        _ when is_binary(v) ->
          case Float.parse(v) do
            {f, ""} -> f
            _ -> raise ArgumentError, "cannot parse number from string: #{inspect(v)}"
          end

        _ ->
          raise ArgumentError, "unsupported numeric value: #{inspect(v)}"
      end
    end

    defp normalize_padding(padding) when is_list(padding) do
      %{
        left: Keyword.get(padding, :left, 120),
        right: Keyword.get(padding, :right, 48),
        top: Keyword.get(padding, :top, 32),
        bottom: Keyword.get(padding, :bottom, 24)
      }
    end

    defp normalize_gradient(nil), do: nil
    defp normalize_gradient(false), do: nil

    defp normalize_gradient(opts) when is_list(opts) do
      %{
        from: Keyword.get(opts, :from, "#4f46e5"),
        to: Keyword.get(opts, :to, "#a78bfa"),
        direction: Keyword.get(opts, :direction, :right)
      }
    end

    defp gradient_defs(id, %{from: from, to: to, direction: dir}, x, y, w, h) do
      {x1, y1, x2, y2} =
        case dir do
          :down -> {x, y, x, y + h}
          :right -> {x, y, x + w, y}
          :down_right -> {x, y, x + w, y + h}
          :down_left -> {x + w, y, x, y + h}
          :up_right -> {x, y + h, x + w, y}
          :up_left -> {x + w, y + h, x, y}
          _ -> {x, y, x + w, y}
        end

      [
        "<defs>",
        "<linearGradient id=",
        attr(id),
        " gradientUnits=",
        attr("userSpaceOnUse"),
        " x1=",
        attr(x1),
        " y1=",
        attr(y1),
        " x2=",
        attr(x2),
        " y2=",
        attr(y2),
        ">",
        "<stop offset=\"0%\" stop-color=",
        attr(from),
        " />",
        "<stop offset=\"100%\" stop-color=",
        attr(to),
        " />",
        "</linearGradient>",
        "</defs>"
      ]
    end

    defp bars_clip_defs(id, geoms) do
      [
        "<defs>",
        "<clipPath id=",
        attr(id),
        " clipPathUnits=",
        attr("userSpaceOnUse"),
        ">",
        Enum.map(geoms, fn g ->
          rect_el(
            x: g.x,
            y: g.y,
            width: g.width,
            height: g.height,
            rx: g.rx,
            ry: g.ry,
            fill: "transparent"
          )
        end),
        "</clipPath>",
        "</defs>"
      ]
    end

    defp gradient_layer(grad_id: grad_id, clip_id: clip_id, x: x, y: y, width: w, height: h) do
      [
        "<g clip-path=",
        attr("url(#" <> clip_id <> ")"),
        ">",
        rect_el(x: x, y: y, width: w, height: h, rx: 0, ry: 0, fill: "url(#" <> grad_id <> ")"),
        "</g>"
      ]
    end

    defp svg_tag_open_close(
           width: width,
           height: height,
           background: nil,
           class: class,
           extra_attrs: extra_attrs
         ) do
      # Allow overriding the output width attribute via a special extra attr.
      # This enables responsive width (e.g., "100%") while keeping a numeric viewBox.
      attr_map = to_attr_map(extra_attrs)
      attr_width = Map.get(attr_map, "data-pg-width", width)
      cleaned_attrs = Map.delete(attr_map, "data-pg-width")

      open = [
        "<svg xmlns=\"http://www.w3.org/2000/svg\"",
        " width=",
        attr(attr_width),
        " height=",
        attr(height),
        " viewBox=",
        attr("0 0 #{width} #{height}"),
        " role=",
        attr("img"),
        " aria-label=",
        attr("Bar chart"),
        if(class && String.trim(to_string(class)) != "", do: [" class=", attr(class)], else: []),
        attrs_kv_to_iolist(cleaned_attrs),
        ">"
      ]

      {open, "</svg>"}
    end

    defp svg_tag_open_close(
           width: width,
           height: height,
           background: bg,
           class: class,
           extra_attrs: extra_attrs
         ) do
      rect_bg =
        rect_el(x: 0, y: 0, width: width, height: height, rx: 0, ry: 0, fill: bg)

      # Allow overriding the output width attribute via a special extra attr.
      # This enables responsive width (e.g., "100%") while keeping a numeric viewBox.
      attr_map = to_attr_map(extra_attrs)
      attr_width = Map.get(attr_map, "data-pg-width", width)
      cleaned_attrs = Map.delete(attr_map, "data-pg-width")

      open = [
        "<svg xmlns=\"http://www.w3.org/2000/svg\"",
        " width=",
        attr(attr_width),
        " height=",
        attr(height),
        " viewBox=",
        attr("0 0 #{width} #{height}"),
        " role=",
        attr("img"),
        " aria-label=",
        attr("Bar chart"),
        if(class && String.trim(to_string(class)) != "", do: [" class=", attr(class)], else: []),
        attrs_kv_to_iolist(cleaned_attrs),
        ">",
        rect_bg
      ]

      {open, "</svg>"}
    end

    defp rect_el(opts) when is_list(opts) do
      x = Keyword.fetch!(opts, :x)
      y = Keyword.fetch!(opts, :y)
      w = Keyword.fetch!(opts, :width)
      h = Keyword.fetch!(opts, :height)
      rx = Keyword.get(opts, :rx, 0)
      ry = Keyword.get(opts, :ry, 0)
      fill = Keyword.get(opts, :fill, "#000")
      class = Keyword.get(opts, :class, nil)
      extra_attrs = Keyword.get(opts, :extra_attrs, [])

      [
        "<rect",
        " x=",
        attr(x),
        " y=",
        attr(y),
        " width=",
        attr(max(0.0, w)),
        " height=",
        attr(h),
        " rx=",
        attr(rx),
        " ry=",
        attr(ry),
        " fill=",
        attr(fill),
        if(class && String.trim(to_string(class)) != "", do: [" class=", attr(class)], else: []),
        attrs_kv_to_iolist(extra_attrs),
        " />"
      ]
    end

    defp text_el(text, x: x, y: y, opts: opts) do
      anchor = Keyword.get(opts, :anchor, "start")
      font_size = Keyword.get(opts, :font_size, 12)
      font_family = Keyword.get(opts, :font_family, @default_font_family)
      fill = Keyword.get(opts, :fill, "#111827")
      dominant_baseline = Keyword.get(opts, :dominant_baseline, "alphabetic")
      font_weight = Keyword.get(opts, :font_weight, "400")

      [
        "<text",
        " x=",
        attr(x),
        " y=",
        attr(y),
        " text-anchor=",
        attr(anchor),
        " dominant-baseline=",
        attr(dominant_baseline),
        " fill=",
        attr(fill),
        " font-size=",
        attr(font_size),
        " font-family=",
        attr(font_family),
        " font-weight=",
        attr(font_weight),
        ">",
        escape_text(text),
        "</text>"
      ]
    end

    defp num(v) when is_integer(v), do: Integer.to_string(v)
    defp num(v) when is_float(v), do: :erlang.float_to_binary(v, [:compact, {:decimals, 2}])

    defp attr(v) when is_binary(v), do: ~s("#{escape_attr(v)}")
    defp attr(v) when is_integer(v), do: ~s("#{Integer.to_string(v)}")
    defp attr(v) when is_float(v), do: ~s("#{num(v)}")

    defp attrs_kv_to_iolist(attrs) when is_list(attrs) or is_map(attrs) do
      attrs
      |> to_attr_map()
      |> Enum.flat_map(fn {k, v} ->
        [" ", to_string(k), "=", attr(v)]
      end)
    end

    defp merge_attrs(global_attrs, item_attrs) do
      g = to_attr_map(global_attrs)
      i = to_attr_map(item_attrs)
      Map.merge(g, i, fn _k, _v1, v2 -> v2 end)
    end

    defp to_attr_map(attrs) when is_list(attrs) do
      Enum.reduce(attrs, %{}, fn
        {k, v}, acc ->
          Map.put(acc, to_attr_key(k), v)

        map, acc when is_map(map) ->
          Enum.reduce(map, acc, fn {k2, v2}, a -> Map.put(a, to_attr_key(k2), v2) end)

        other, acc ->
          Map.put(acc, to_attr_key(other), true)
      end)
    end

    defp to_attr_map(attrs) when is_map(attrs) do
      Enum.reduce(attrs, %{}, fn {k, v}, acc ->
        Map.put(acc, to_attr_key(k), v)
      end)
    end

    defp to_attr_map(nil), do: %{}

    defp to_attr_key(k) when is_atom(k), do: Atom.to_string(k)
    defp to_attr_key(k) when is_binary(k), do: k
    defp to_attr_key(k), do: to_string(k)

    defp normalize_item_opts(opts) when is_list(opts) do
      # Treat keyword lists specially; otherwise assume it's a plain list of {k, v} tuples for attrs.
      is_kw = Keyword.keyword?(opts)

      class =
        if is_kw do
          Keyword.get(opts, :class)
        else
          nil
        end

      attrs =
        cond do
          is_kw and Keyword.has_key?(opts, :attrs) ->
            Keyword.get(opts, :attrs, [])

          true ->
            # Treat the whole list as attrs, but drop :class and :attrs keys if present.
            if is_kw do
              Enum.reject(opts, fn
                {:class, _} -> true
                {:attrs, _} -> true
                _ -> false
              end)
            else
              opts
            end
        end

      %{
        attrs: attrs,
        class: normalize_class(class)
      }
    end

    defp normalize_item_opts(%{} = opts) do
      attrs = Map.get(opts, :attrs) || Map.get(opts, "attrs") || opts
      class = Map.get(opts, :class) || Map.get(opts, "class")

      %{
        attrs: attrs,
        class: normalize_class(class)
      }
    end

    defp normalize_item_opts(_), do: %{attrs: [], class: nil}

    defp normalize_class(nil), do: nil

    defp normalize_class(s) when is_binary(s) do
      case String.trim(s) do
        "" -> nil
        val -> val
      end
    end

    defp normalize_class(list) when is_list(list) do
      join_classes(list)
    end

    defp normalize_class(other), do: to_string(other)

    defp join_classes(list) when is_list(list) do
      list
      |> List.flatten()
      |> Enum.map(fn
        nil -> nil
        "" -> nil
        v when is_binary(v) -> String.trim(v)
        v when is_atom(v) -> Atom.to_string(v)
        v -> to_string(v)
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" ")
    end

    defp escape_attr(s) do
      s
      |> to_string()
      |> String.replace("&", "&amp;")
      |> String.replace("<", "&lt;")
      |> String.replace(">", "&gt;")
      |> String.replace("\"", "&quot;")
      |> String.replace("'", "&#39;")
    end

    defp escape_text(s) do
      s
      |> to_string()
      |> String.replace("&", "&amp;")
      |> String.replace("<", "&lt;")
      |> String.replace(">", "&gt;")
    end
  end
end
