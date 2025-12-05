import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/string
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

type Range {
  Range(start: Int, end: Int)
}

fn input_to_ranges_and_ids(input: String) -> #(List(Range), List(Int)) {
  let assert [range_lines, id_lines] = string.split(input, "\n\n")

  let ranges =
    list.map(string.split(range_lines, "\n"), fn(line) {
      let assert [start_str, end_str] = string.split(line, "-")
      let assert #(Ok(start), Ok(end)) = #(
        int.parse(start_str),
        int.parse(end_str),
      )
      Range(start:, end:)
    })

  let ids =
    list.map(string.split(id_lines, "\n"), fn(line) {
      let assert Ok(id) = int.parse(line)
      id
    })

  #(ranges, ids)
}

fn is_fresh(ranges: List(Range), id: Int) -> Bool {
  list.any(ranges, fn(range) { id >= range.start && id <= range.end })
}

fn day05_part_1(input: String) -> Int {
  let #(ranges, ids) = input_to_ranges_and_ids(input)
  list.fold(ids, 0, fn(accum, id) {
    case is_fresh(ranges, id) {
      True -> accum + 1
      False -> accum
    }
  })
}

fn ranges_overlap(a: Range, b: Range) -> Bool {
  a.end >= b.start && a.start <= b.end
}

fn ranges_combine(a: Range, b: Range) -> Range {
  Range(start: int.min(a.start, b.start), end: int.max(a.end, b.end))
}

fn ranges_combine_all(ranges: List(Range)) -> List(Range) {
  case ranges {
    [] -> []
    [last] -> [last]
    [head, ..tail] -> {
      let #(head_new, ranges_new) =
        list.fold(tail, #(head, []), fn(combining, item) {
          case ranges_overlap(combining.0, item) {
            True -> #(ranges_combine(combining.0, item), combining.1)
            False -> #(combining.0, [item, ..combining.1])
          }
        })
      case head == head_new {
        True -> [head_new, ..ranges_combine_all(ranges_new)]
        False -> ranges_combine_all([head_new, ..ranges_new])
      }
    }
  }
}

fn ranges_sum(ranges: List(Range)) -> Int {
  list.fold(ranges, 0, fn(sum, range) { sum + { range.end - range.start + 1 } })
}

fn day05_part_2(input: String) -> Int {
  let #(ranges, _ids) = input_to_ranges_and_ids(input)
  ranges_combine_all(ranges)
  |> ranges_sum
}

pub fn solutions() -> List(Solution) {
  [
    Solution(5, 1, Example, Some(3), day05_part_1),
    Solution(5, 1, Real, Some(529), day05_part_1),
    Solution(5, 2, Example, Some(14), day05_part_2),
    Solution(5, 2, Real, Some(344_260_049_617_193), day05_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
