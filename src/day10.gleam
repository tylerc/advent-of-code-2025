import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{Some}
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

fn joltage_is_zero(joltage: Joltage) -> Bool {
  dict.values(joltage) |> list.all(fn(value) { value == 0 })
}

fn button_reduce_joltage_reqs(
  button: List(Int),
  presses: Int,
  joltage_reqs: Joltage,
) -> Joltage {
  list.fold(button, joltage_reqs, fn(accum, joltage_index) {
    let assert Ok(value) = dict.get(accum, joltage_index)
    dict.insert(accum, joltage_index, value - presses)
  })
}

fn possible_presses(buttons: Buttons) -> List(Buttons) {
  case buttons {
    [] -> []
    [button] -> [[button], []]
    [button, ..rest] -> {
      let remainder = possible_presses(rest)
      list.map(remainder, fn(sub_list) { [[button, ..sub_list], sub_list] })
      |> list.flatten
    }
  }
}

// Based on the insights from this post: https://www.reddit.com/r/adventofcode/comments/1pk87hl/2025_day_10_part_2_bifurcate_your_way_to_victory/
// In particular:
// 1. Find all combinations of single-or-zero button presses that make the joltages even.
// 2. Then, divide the joltages in half and recurse, counting 2 times the minimum presses in the next recursive step.
fn press_until_even(
  possible_presses_list: List(Buttons),
  joltage_reqs: Joltage,
) -> Int {
  case joltage_is_zero(joltage_reqs) {
    True -> 0
    False -> {
      possible_presses_list
      |> list.map(fn(buttons_considering) {
        let joltage_new =
          list.fold(buttons_considering, joltage_reqs, fn(joltage_new, button) {
            button_reduce_joltage_reqs(button, 1, joltage_new)
          })
        let is_valid =
          dict.values(joltage_new)
          |> list.all(fn(jotlage_value) {
            jotlage_value >= 0 && jotlage_value % 2 == 0
          })

        case is_valid {
          True ->
            Ok(#(
              joltage_new |> dict.map_values(fn(_key, value) { value / 2 }),
              list.length(buttons_considering),
            ))
          False -> Error(Nil)
        }
      })
      |> list.fold(1_000_000, fn(lowest_answer, item) {
        case item {
          Error(_) -> lowest_answer
          Ok(#(joltage_new, presses)) -> {
            int.min(
              lowest_answer,
              presses + 2 * press_until_even(possible_presses_list, joltage_new),
            )
          }
        }
      })
    }
  }
}

fn day10_part_2(input: String) {
  let subject = process.new_subject()
  let machines = input_to_machines(input)
  let machine_count = list.length(machines)

  list.map(machines, fn(machine) {
    process.spawn(fn() {
      let cost =
        press_until_even(
          possible_presses(machine.buttons),
          machine.joltage_reqs,
        )
      process.send(subject, cost)
    })
  })
  |> list.index_fold(0, fn(accum, _, index) {
    let cost = process.receive_forever(subject)
    echo {
      "Day 10 ("
      <> int.to_string(index + 1)
      <> "/"
      <> int.to_string(machine_count)
      <> ") "
      <> int.to_string(cost)
    }
    accum + cost
  })
}

pub fn solutions() -> List(Solution) {
  [
    Solution(10, 1, Example, Some(7), day10_part_1),
    Solution(10, 1, Real, Some(469), day10_part_1),
    Solution(10, 2, Example, Some(33), day10_part_2),
    Solution(10, 2, Real, Some(19_293), day10_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
