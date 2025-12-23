import day01
import day02
import day03
import day04
import day05
import day06
import day07
import day08
import day09
import day10
import day11
import day12
import gleam/list
import helpers

pub fn main() -> Nil {
  helpers.measure_solutions(
    list.flatten([
      day01.solutions(),
      day02.solutions(),
      day03.solutions(),
      day04.solutions(),
      day05.solutions(),
      day06.solutions(),
      day07.solutions(),
      day08.solutions(),
      day09.solutions(),
      day10.solutions(),
      day11.solutions(),
      day12.solutions(),
    ]),
  )
}
