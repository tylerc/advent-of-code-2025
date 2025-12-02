import day01
import gleam/list
import helpers

pub fn main() -> Nil {
  helpers.measure_solutions(list.flatten([day01.solutions()]))
}
