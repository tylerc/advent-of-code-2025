import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/set.{type Set}
import gleam/string
import helpers.{type Solution, Real, Solution, measure_solutions}

type Pos {
  Pos(row: Int, col: Int)
}

type Shape {
  Shape(index: Int, positions: Set(Pos))
}

type PackingRequirements {
  PackingRequirements(rows: Int, cols: Int, area: Int, reqs: Dict(Int, Int))
}

fn line_to_packing_requirements(line: String) -> PackingRequirements {
  let assert [dimensions, reqs_str] = string.split(line, ": ")
  let assert [cols_str, rows_str] = string.split(dimensions, "x")
  let assert Ok(cols) = int.parse(cols_str)
  let assert Ok(rows) = int.parse(rows_str)
  let reqs =
    string.split(reqs_str, " ")
    |> list.index_map(fn(count, index) {
      let assert Ok(count) = int.parse(count)
      #(index, count)
    })
    |> dict.from_list

  PackingRequirements(rows:, cols:, area: rows * cols, reqs:)
}

fn lines_to_shape(lines: String) -> Shape {
  let assert [label, ..shape_lines] = string.split(lines, "\n")
  let assert Ok(index) = string.replace(label, ":", "") |> int.parse
  let positions =
    list.index_map(shape_lines, fn(line, row) {
      string.split(line, "")
      |> list.index_map(fn(char, col) {
        case char {
          "#" -> [Pos(row:, col:)]
          "." -> []
          unexpected -> panic as { "Unexpected char in shape: " <> unexpected }
        }
      })
      |> list.flatten
    })
    |> list.flatten
    |> set.from_list

  Shape(index:, positions:)
}

fn input_to_shapes_and_requirements(
  input: String,
) -> #(Dict(Int, Shape), List(PackingRequirements)) {
  let assert [packing_str, ..shape_groups] =
    string.split(input, "\n\n") |> list.reverse

  let packing_requirements =
    string.split(packing_str, "\n") |> list.map(line_to_packing_requirements)
  let shapes =
    list.map(shape_groups, lines_to_shape)
    |> list.map(fn(shape) { #(shape.index, shape) })
    |> dict.from_list

  #(shapes, packing_requirements)
}

fn day12_part_1(input: String) {
  let #(shapes, packing_requirements) = input_to_shapes_and_requirements(input)
  list.fold(packing_requirements, 0, fn(possible_count, requirement) {
    let minimum_area =
      dict.fold(requirement.reqs, 0, fn(minimum_area, shape_index, shape_count) {
        let assert Ok(shape) = dict.get(shapes, shape_index)
        minimum_area + { set.size(shape.positions) * shape_count }
      })
    let maximum_area =
      dict.fold(requirement.reqs, 0, fn(maximum_area, _, shape_count) {
        maximum_area + { 9 * shape_count }
      })

    case minimum_area > requirement.area, maximum_area <= requirement.area {
      // The requirement is trivially impossible, the shapes take up more area than we have, even ignoring
      // their empty spots:
      True, _ -> possible_count
      // The requirement is trivially possible, the shapes can be packed right next to each other:
      _, True -> possible_count + 1
      // In theory we might need to somehow bin pack, but Eric was nice:
      False, False -> {
        panic as "This never happens on the real input."
      }
    }
  })
}

pub fn solutions() -> List(Solution) {
  [
    // Skip the example because it's harder than the real input.
    Solution(12, 1, Real, Some(544), day12_part_1),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
