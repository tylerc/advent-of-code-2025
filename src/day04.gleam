import gleam/list
import gleam/option.{None, Some}
import gleam/set.{type Set}
import gleam/string
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

type Point {
  Point(row: Int, col: Int)
}

fn input_to_points(input: String) -> Set(Point) {
  string.split(input, "\n")
  |> list.index_map(fn(line, row) {
    string.split(line, "")
    |> list.index_map(fn(char, col) {
      case char {
        "@" -> Some(Point(row:, col:))
        _ -> None
      }
    })
  })
  |> list.flatten
  |> list.filter_map(fn(item) -> Result(Point, Nil) {
    case item {
      Some(point) -> Ok(point)
      None -> Error(Nil)
    }
  })
  |> set.from_list
}

fn points_adjacent(point: Point) -> List(Point) {
  [
    Point(row: point.row - 1, col: point.col - 1),
    Point(row: point.row - 1, col: point.col),
    Point(row: point.row - 1, col: point.col + 1),
    Point(row: point.row, col: point.col - 1),
    Point(row: point.row, col: point.col + 1),
    Point(row: point.row + 1, col: point.col - 1),
    Point(row: point.row + 1, col: point.col),
    Point(row: point.row + 1, col: point.col + 1),
  ]
}

fn rolls_adjacent_count(rolls: Set(Point), point: Point) -> Int {
  points_adjacent(point)
  |> list.fold(0, fn(accum, neighbor) {
    accum
    + case set.contains(rolls, neighbor) {
      True -> 1
      False -> 0
    }
  })
}

fn rolls_accessible(rolls: Set(Point)) -> Int {
  set.fold(rolls, 0, fn(accum, point) {
    accum
    + case rolls_adjacent_count(rolls, point) < 4 {
      True -> 1
      False -> 0
    }
  })
}

fn day04_part_1(input: String) -> Int {
  input_to_points(input)
  |> rolls_accessible
}

fn rolls_clear(rolls: Set(Point)) -> Set(Point) {
  let rolls_new =
    set.filter(rolls, fn(point) { rolls_adjacent_count(rolls, point) >= 4 })
  case rolls == rolls_new {
    True -> rolls
    False -> rolls_clear(rolls_new)
  }
}

fn day04_part_2(input: String) -> Int {
  let points_orig = input_to_points(input)
  let points_end = rolls_clear(points_orig)
  set.size(points_orig) - set.size(points_end)
}

pub fn solutions() -> List(Solution) {
  [
    Solution(4, 1, Example, Some(13), day04_part_1),
    Solution(4, 1, Real, Some(1424), day04_part_1),
    Solution(4, 2, Example, Some(43), day04_part_2),
    Solution(4, 2, Real, Some(8727), day04_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
