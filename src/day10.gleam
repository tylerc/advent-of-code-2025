import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

type Lights =
  Dict(Int, Bool)

type Buttons =
  List(List(Int))

type Joltage =
  Dict(Int, Int)

type Machine {
  Machine(lights: Lights, buttons: Buttons, joltage_reqs: Joltage)
}

fn line_to_machine(line: String) -> Machine {
  let assert [lights_str, ..rest] = string.split(line, " ")
  let lights =
    string.split(lights_str, "")
    |> list.flat_map(fn(char) {
      case char {
        "#" -> [True]
        "." -> [False]
        _ -> []
      }
    })
    |> list.index_fold(dict.new(), fn(accum, item, index) {
      dict.insert(accum, index, item)
    })

  let #(buttons, joltage_reqs) =
    list.fold(rest, #([], dict.new()), fn(accum, item) {
      case string.starts_with(item, "(") {
        True -> {
          let without_parens =
            string.replace(item, "(", "") |> string.replace(")", "")
          let numbers =
            string.split(without_parens, ",")
            |> list.map(fn(digits) {
              let assert Ok(num) = int.parse(digits)
              num
            })
          #([numbers, ..accum.0], accum.1)
        }
        False -> {
          let without_brackets =
            string.replace(item, "{", "") |> string.replace("}", "")
          let numbers =
            string.split(without_brackets, ",")
            |> list.map(fn(digits) {
              let assert Ok(num) = int.parse(digits)
              num
            })
            |> list.index_fold(dict.new(), fn(accum, item, index) {
              dict.insert(accum, index, item)
            })
          #(accum.0, numbers)
        }
      }
    })

  Machine(lights:, buttons: list.reverse(buttons), joltage_reqs:)
}

fn input_to_machines(input: String) -> List(Machine) {
  string.split(input, "\n")
  |> list.map(line_to_machine)
}

fn lights_possible(machine: Machine) -> List(Lights) {
  list.map(machine.buttons, fn(affects) {
    list.fold(affects, machine.lights, fn(accum, light) {
      let assert Ok(state) = dict.get(accum, light)
      dict.insert(accum, light, !state)
    })
  })
}

fn lights_fewest_presses(
  machine: Machine,
  to_check: List(#(Lights, Int)),
  costs: Dict(Lights, Int),
) -> Dict(Lights, Int) {
  case to_check {
    [] -> costs
    [#(lights, cost), ..rest] -> {
      let cost_next = cost + 1
      let #(costs_next, destinations) =
        lights_possible(Machine(..machine, lights:))
        |> list.filter(fn(lights) {
          case dict.get(costs, lights) {
            Error(_) -> True
            Ok(cost) if cost_next < cost -> True
            _ -> False
          }
        })
        |> list.map_fold(costs, fn(accum, lights) {
          #(dict.insert(accum, lights, cost_next), #(lights, cost_next))
        })

      lights_fewest_presses(
        machine,
        list.append(destinations, rest),
        costs_next,
      )
    }
  }
}

fn day10_part_1(input: String) {
  input_to_machines(input)
  |> list.fold(0, fn(accum, machine) {
    let all_off = dict.map_values(machine.lights, fn(_, _) { False })
    let fewest =
      lights_fewest_presses(
        machine,
        [#(all_off, 0)],
        dict.from_list([#(all_off, 0)]),
      )
    let assert Ok(cost) = dict.get(fewest, machine.lights)
    accum + cost
  })
}

// TODO: 1. Implement:
fn day10_part_2(_input: String) {
  0
}

pub fn solutions() -> List(Solution) {
  [
    Solution(10, 1, Example, Some(7), day10_part_1),
    Solution(10, 1, Real, Some(469), day10_part_1),
    Solution(10, 2, Example, None, day10_part_2),
    Solution(10, 2, Real, None, day10_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
