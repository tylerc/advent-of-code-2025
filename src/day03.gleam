import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/string
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

fn input_to_digits(input: String) -> List(List(Int)) {
  list.map(string.split(input, "\n"), fn(line) {
    list.map(string.split(line, ""), fn(char) {
      let assert Ok(num) = int.parse(char)
      num
    })
  })
}

fn find_higest_two(bank: List(Int)) {
  let pairs =
    list.flatten(
      list.index_map(bank, fn(battery, index) {
        list.map(list.drop(bank, index + 1), fn(other_battery) {
          #(battery, other_battery)
        })
      }),
    )

  let assert [highest, ..] =
    list.sort(
      pairs,
      order.reverse(fn(a: #(Int, Int), b: #(Int, Int)) {
        let first_comparison = int.compare(a.0, b.0)
        case first_comparison {
          order.Eq -> int.compare(a.1, b.1)
          other -> other
        }
      }),
    )
  highest
}

fn sum_highest_part_1(batteries: List(List(Int))) -> Int {
  list.fold(batteries, 0, fn(accum, bank) {
    let #(first, second) = find_higest_two(bank)
    accum + { first * 10 } + second
  })
}

fn day03_part_1(input: String) {
  input |> input_to_digits |> sum_highest_part_1
}

fn numbers_with_longest_runs(bank: List(Int)) -> Dict(Int, List(Int)) {
  list.index_fold(bank, dict.new(), fn(numbers, number, index) {
    case dict.has_key(numbers, number) {
      True -> numbers
      False -> {
        dict.insert(numbers, number, list.drop(bank, index + 1))
      }
    }
  })
}

fn highest_with_sufficient_length(
  bank: List(Int),
  length_needed: Int,
) -> #(Int, List(Int)) {
  let assert [first, ..] =
    numbers_with_longest_runs(bank)
    |> dict.to_list
    |> list.filter(fn(item) { list.length(item.1) >= length_needed })
    |> list.sort(fn(a, b) { int.compare(b.0, a.0) })
  first
}

fn recurse_and_combine_highest(
  bank: List(Int),
  accum: Int,
  length_needed: Int,
) -> Int {
  case length_needed {
    0 -> accum
    _ -> {
      let #(highest, remaining) =
        highest_with_sufficient_length(bank, length_needed - 1)
      recurse_and_combine_highest(
        remaining,
        accum * 10 + highest,
        length_needed - 1,
      )
    }
  }
}

fn sum_highest_part_2(batteries: List(List(Int))) -> Int {
  list.fold(batteries, 0, fn(accum, bank) {
    accum + recurse_and_combine_highest(bank, 0, 12)
  })
}

fn day03_part_2(input: String) {
  input |> input_to_digits |> sum_highest_part_2
}

pub fn solutions() -> List(Solution) {
  [
    Solution(3, 1, Example, Some(357), day03_part_1),
    Solution(3, 1, Real, Some(16_858), day03_part_1),
    Solution(3, 2, Example, Some(3_121_910_778_619), day03_part_2),
    Solution(3, 2, Real, Some(167_549_941_654_721), day03_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
