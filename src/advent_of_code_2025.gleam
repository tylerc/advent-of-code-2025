import day01
import day02
import day03
import day04
import gleam/list
import helpers

pub fn main() -> Nil {
  helpers.measure_solutions(
    list.flatten([
      day01.solutions(),
      day02.solutions(),
      day03.solutions(),
      day04.solutions(),
    ]),
  )
}
