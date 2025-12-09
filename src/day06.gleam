import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

type Operator {
  Add
  Multiply
}

type Problem {
  Problem(terms: List(Int), operator: Operator)
}

fn problem_evaluate(problem: Problem) -> Int {
  case problem.operator {
    Add -> list.fold(problem.terms, 0, fn(accum, term) { accum + term })
    Multiply -> {
      let assert [head, ..tail] = problem.terms
      list.fold(tail, head, fn(accum, term) { accum * term })
    }
  }
}

fn split_on_whitespace_and_trim(str: String) -> List(String) {
  string.split(str, " ")
  |> list.map(string.trim)
  |> list.filter(fn(s) { s != "" })
}

fn input_to_problems_part_1(input: String) -> List(Problem) {
  let assert [operator_strs, ..number_lines] =
    list.reverse(string.split(input, "\n"))

  let operators =
    operator_strs
    |> split_on_whitespace_and_trim
    |> list.map(fn(str) {
      case str {
        "+" -> Add
        "*" -> Multiply
        unexpected -> panic as { "Unknown operator: " <> unexpected }
      }
    })

  let numbers_by_index =
    list.fold(number_lines, dict.new(), fn(numbers_by_index, line) {
      split_on_whitespace_and_trim(line)
      |> list.index_fold(numbers_by_index, fn(accum, str, index) {
        let assert Ok(num) = int.parse(str)
        case dict.get(accum, index) {
          Ok(list) -> dict.insert(accum, index, [num, ..list])
          Error(_) -> dict.insert(accum, index, [num])
        }
      })
    })

  list.index_map(operators, fn(operator, index) {
    let assert Ok(terms) = dict.get(numbers_by_index, index)
    Problem(terms:, operator:)
  })
}

fn day06_part_1(input: String) {
  input_to_problems_part_1(input)
  |> list.map(problem_evaluate)
  |> list.fold(0, fn(accum, item) { accum + item })
}

fn lines_to_number(lines: List(String)) -> #(Result(Int, Nil), List(String)) {
  let heads_and_tails = list.map(lines, string.pop_grapheme)
  let maybe_num =
    list.fold(heads_and_tails, Error(Nil), fn(accum, maybe_tuple) {
      let parsed = {
        use #(grapheme, _) <- result.try(maybe_tuple)
        use num <- result.try(int.parse(grapheme))
        Ok(num + result.unwrap(accum, 0) * 10)
      }
      result.or(parsed, accum)
    })
  let tails =
    result.all(heads_and_tails)
    |> result.unwrap([])
    |> list.map(fn(item) { item.1 })
  #(maybe_num, tails)
}

fn lines_while_numbers(
  lines: List(String),
  nums_building: List(Int),
) -> #(List(Int), List(String)) {
  let #(maybe_num, lines_remaining) = lines_to_number(lines)
  case maybe_num {
    Error(_) -> #(nums_building, lines_remaining)
    Ok(num) -> lines_while_numbers(lines_remaining, [num, ..nums_building])
  }
}

fn lines_to_problems(
  operators: List(Operator),
  lines: List(String),
) -> List(Problem) {
  case operators, lines {
    [], _ -> []
    _, [] -> []
    [operator, ..operators_next], lines -> {
      let #(terms, lines_next) = lines_while_numbers(lines, [])
      [
        Problem(operator:, terms:),
        ..lines_to_problems(operators_next, lines_next)
      ]
    }
  }
}

fn input_to_problems_part_2(input: String) -> List(Problem) {
  let lines = string.split(input, "\n")
  let assert #(number_lines, [operator_strs]) =
    list.split(lines, list.length(lines) - 1)

  let operators =
    operator_strs
    |> split_on_whitespace_and_trim
    |> list.map(fn(str) {
      case str {
        "+" -> Add
        "*" -> Multiply
        unexpected -> panic as { "Unknown operator: " <> unexpected }
      }
    })

  lines_to_problems(operators, number_lines)
}

fn day06_part_2(input: String) {
  input_to_problems_part_2(input)
  |> list.map(problem_evaluate)
  |> list.fold(0, fn(accum, item) { accum + item })
}

pub fn solutions() -> List(Solution) {
  [
    Solution(6, 1, Example, Some(4_277_556), day06_part_1),
    Solution(6, 1, Real, Some(5_667_835_681_547), day06_part_1),
    Solution(6, 2, Example, Some(3_263_827), day06_part_2),
    Solution(6, 2, Real, Some(9_434_900_032_651), day06_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
