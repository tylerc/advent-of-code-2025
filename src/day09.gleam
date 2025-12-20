import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

type Pos {
  Pos(x: Int, y: Int)
}

fn input_to_positions(input: String) -> List(Pos) {
  string.split(input, "\n")
  |> list.map(fn(line) {
    let assert [x, y] =
      string.split(line, ",")
      |> list.map(fn(num_str) {
        let assert Ok(num) = int.parse(num_str)
        num
      })
    Pos(x:, y:)
  })
}

fn area(a: Pos, b: Pos) -> Int {
  { int.absolute_value(a.x - b.x) + 1 } * { int.absolute_value(a.y - b.y) + 1 }
}

fn day09_part_1(input: String) {
  let assert 50 = area(Pos(x: 2, y: 5), Pos(x: 11, y: 1))

  input_to_positions(input)
  |> list.combination_pairs
  |> list.map(fn(pair) { area(pair.0, pair.1) })
  |> list.max(int.compare)
  |> result.unwrap(0)
}

type ScanLine {
  ScanLine(start: Int, end: Int)
}

fn flood_fill_horizontal_scan_lines(
  polygon: List(#(Pos, Pos)),
  y: Int,
) -> List(ScanLine) {
  let horizontal_segments =
    list.filter(polygon, fn(segment) {
      { segment.0 }.y == y && { segment.0 }.y == { segment.1 }.y
    })
  let vertical_segments =
    list.filter(polygon, fn(segment) {
      let y_min = int.min({ segment.0 }.y, { segment.1 }.y)
      let y_max = int.max({ segment.0 }.y, { segment.1 }.y)
      { segment.0 }.x == { segment.1 }.x && y_min <= y && y_max >= y
    })

  list.append(horizontal_segments, vertical_segments)
  |> list.map(fn(segment) {
    let x_min = int.min({ segment.0 }.x, { segment.1 }.x)
    let x_max = int.max({ segment.0 }.x, { segment.1 }.x)
    ScanLine(start: x_min, end: x_max)
  })
  |> scan_lines_combine_all
  |> list.sort(fn(a, b) { int.compare(a.start, b.start) })
  |> scan_line_combine_for_flood_fill
  |> scan_lines_combine_all
}

fn flood_fill_vertical_scan_lines(
  polygon: List(#(Pos, Pos)),
  x: Int,
) -> List(ScanLine) {
  let vertical_segments =
    list.filter(polygon, fn(segment) {
      { segment.0 }.x == x && { segment.0 }.x == { segment.1 }.x
    })
  let horizontal_segments =
    list.filter(polygon, fn(segment) {
      let x_min = int.min({ segment.0 }.x, { segment.1 }.x)
      let x_max = int.max({ segment.0 }.x, { segment.1 }.x)
      { segment.0 }.y == { segment.1 }.y && x_min <= x && x_max >= x
    })

  list.append(horizontal_segments, vertical_segments)
  |> list.map(fn(segment) {
    let y_min = int.min({ segment.0 }.y, { segment.1 }.y)
    let y_max = int.max({ segment.0 }.y, { segment.1 }.y)
    ScanLine(start: y_min, end: y_max)
  })
  |> scan_lines_combine_all
  |> list.sort(fn(a, b) { int.compare(a.start, b.start) })
  |> scan_line_combine_for_flood_fill
  |> scan_lines_combine_all
}

fn segment_overlaps_flood_fill(
  polygon: List(#(Pos, Pos)),
  segment: #(Pos, Pos),
) -> Bool {
  case { segment.0 }.y == { segment.1 }.y {
    True if segment.0.x == segment.1.x -> False
    True -> {
      assert { segment.0 }.x != { segment.1 }.x
      let y = { segment.0 }.y
      let x_min = int.min({ segment.0 }.x, { segment.1 }.x)
      let x_max = int.max({ segment.0 }.x, { segment.1 }.x)
      let scan_lines = flood_fill_horizontal_scan_lines(polygon, y)
      list.any(scan_lines, fn(line) { line.start <= x_min && line.end >= x_max })
    }
    False -> {
      assert { segment.0 }.x == { segment.1 }.x
      assert { segment.0 }.y != { segment.1 }.y
      let x = { segment.0 }.x
      let y_min = int.min({ segment.0 }.y, { segment.1 }.y)
      let y_max = int.max({ segment.0 }.y, { segment.1 }.y)
      let scan_lines = flood_fill_vertical_scan_lines(polygon, x)
      list.any(scan_lines, fn(line) { line.start <= y_min && line.end >= y_max })
    }
  }
}

fn scan_lines_overlap(a: ScanLine, b: ScanLine) -> Bool {
  a.end >= b.start && a.start <= b.end
}

fn scan_lines_combine(a: ScanLine, b: ScanLine) -> ScanLine {
  ScanLine(start: int.min(a.start, b.start), end: int.max(a.end, b.end))
}

fn scan_lines_combine_all(ranges: List(ScanLine)) -> List(ScanLine) {
  case ranges {
    [] -> []
    [last] -> [last]
    [head, ..tail] -> {
      let #(head_new, ranges_new) =
        list.fold(tail, #(head, []), fn(combining, item) {
          case scan_lines_overlap(combining.0, item) {
            True -> #(scan_lines_combine(combining.0, item), combining.1)
            False -> #(combining.0, [item, ..combining.1])
          }
        })
      case head == head_new {
        True -> [head_new, ..scan_lines_combine_all(ranges_new)]
        False -> scan_lines_combine_all([head_new, ..ranges_new])
      }
    }
  }
}

fn scan_line_combine_for_flood_fill(lines: List(ScanLine)) -> List(ScanLine) {
  case lines {
    [] -> []
    [a] -> [a]
    [a, b, ..rest] -> [
      ScanLine(start: a.start, end: b.end),
      ..case b.start == b.end {
        True -> scan_line_combine_for_flood_fill(rest)
        False -> scan_line_combine_for_flood_fill([b, ..rest])
      }
    ]
  }
}

fn corners(control_points: #(Pos, Pos)) -> #(Pos, Pos) {
  #(
    Pos(x: { control_points.1 }.x, y: { control_points.0 }.y),
    Pos(x: { control_points.0 }.x, y: { control_points.1 }.y),
  )
}

fn positions_to_svg(
  positions: List(Pos),
  areas: List(#(#(Pos, Pos), Int)),
) -> String {
  let max_x =
    list.map(positions, fn(pos) { pos.x })
    |> list.max(int.compare)
    |> result.unwrap(0)
  let max_y =
    list.map(positions, fn(pos) { pos.y })
    |> list.max(int.compare)
    |> result.unwrap(0)
  let header =
    "<svg viewBox=\"0 0 "
    <> int.to_string(max_x)
    <> " "
    <> int.to_string(max_y)
    <> "\" xmlns=\"http://www.w3.org/2000/svg\">\n"
  let footer = "</svg>\n"
  let positions_str =
    list.map(positions, fn(pos) {
      int.to_string(pos.x) <> "," <> int.to_string(pos.y)
    })
    |> string.join(" ")
  let polygon =
    "<polygon points=\""
    <> positions_str
    <> "\" fill=\"black\" stroke=\"none\" />\n"

  let squares =
    list.index_map(areas, fn(item, index) {
      let #(anchor_a, anchor_b) = item.0
      let #(corner_a, corner_b) = corners(item.0)
      "<polygon points=\""
      <> int.to_string(anchor_a.x)
      <> ","
      <> int.to_string(anchor_a.y)
      <> " "
      <> int.to_string(corner_a.x)
      <> ","
      <> int.to_string(corner_a.y)
      <> " "
      <> int.to_string(anchor_b.x)
      <> ","
      <> int.to_string(anchor_b.y)
      <> " "
      <> int.to_string(corner_b.x)
      <> ","
      <> int.to_string(corner_b.y)
      <> "\" fill=\"hsl("
      <> int.to_string(index % 255)
      <> " 50% 50% / 50%)\" stroke=\"none\" />\n"
    })

  header <> polygon <> string.join(squares, "") <> footer
}

fn largest_contained_areas(positions: List(Pos)) -> List(#(#(Pos, Pos), Int)) {
  let polygon_segments = list.window_by_2(positions)
  let assert Ok(first) = list.first(positions)
  let assert Ok(last) = list.last(positions)
  let polygon_segments = [#(first, last), ..polygon_segments]

  list.combination_pairs(positions)
  |> list.filter(fn(pair) {
    let #(corner_a, corner_b) = corners(pair)
    segment_overlaps_flood_fill(polygon_segments, #(pair.0, corner_a))
    && segment_overlaps_flood_fill(polygon_segments, #(pair.0, corner_b))
    && segment_overlaps_flood_fill(polygon_segments, #(pair.1, corner_a))
    && segment_overlaps_flood_fill(polygon_segments, #(pair.1, corner_b))
  })
  |> list.map(fn(pair) { #(pair, area(pair.0, pair.1)) })
  |> list.sort(fn(a, b) { int.compare(b.1, a.1) })
}

fn day09_part_2(input: String) {
  let positions = input_to_positions(input)
  let areas = largest_contained_areas(positions)
  let assert Ok(#(_, result)) = list.first(areas)
  let _ =
    helpers.write_file(
      "./viz" <> int.to_string(string.length(input)) <> ".svg",
      positions_to_svg(positions, areas),
    )
  result
}

pub fn solutions() -> List(Solution) {
  [
    Solution(9, 1, Example, Some(50), day09_part_1),
    Solution(9, 1, Real, Some(4_759_531_084), day09_part_1),
    Solution(9, 2, Example, Some(24), day09_part_2),
    Solution(9, 2, Real, Some(1_539_238_860), day09_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
