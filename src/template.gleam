import gleam/option.{None, Some}
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

fn day01_part_1(_input: String) {
  0
}

fn day01_part_2(_input: String) {
  0
}

pub fn solutions() -> List(Solution) {
  [
    Solution(1, 1, Example, Some(42), day01_part_1),
    Solution(1, 1, Real, None, day01_part_1),
    Solution(1, 2, Example, None, day01_part_2),
    Solution(1, 2, Real, None, day01_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
