import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/result
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

fn button_max_presses(button: List(Int), joltage_reqs: Joltage) -> Int {
  list.map(button, fn(joltage_index) {
    let assert Ok(val) = dict.get(joltage_reqs, joltage_index)
    val
  })
  |> list.max(order.reverse(int.compare))
  |> result.unwrap(0)
  |> int.max(0)
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

type JoltageInfo {
  JoltageInfo(joltage_value: Int, buttons: Buttons, button_count: Int)
}

fn result_pick_lowest(
  accum: Result(Int, Nil),
  next: Result(Int, Nil),
) -> Result(Int, Nil) {
  case accum, next {
    Ok(last), Ok(newest) if newest < last -> Ok(newest)
    Error(Nil), Ok(newest) -> Ok(newest)
    _, _ -> accum
  }
}

fn distribute_presses(
  to_allocate: Int,
  max_presses: List(Int),
) -> List(List(Int)) {
  case max_presses {
    [] -> []
    [last] if last < to_allocate -> []
    [last] -> [[int.min(to_allocate, last)]]
    [head, ..tail] -> {
      list.range(int.min(to_allocate, head), 0)
      |> list.map(fn(this_allocation) {
        distribute_presses(to_allocate - this_allocation, tail)
        |> list.map(fn(new_tail) { [this_allocation, ..new_tail] })
        |> list.filter(fn(allocation) {
          let sum = list.fold(allocation, 0, fn(accum, num) { accum + num })
          sum == to_allocate
        })
      })
      |> list.flatten
    }
  }
}

// This is based on the insights from: https://github.com/michel-kraemer/adventofcode-rust/blob/main/2025/day10/src/main.rs#L114
// In particular:
// 1. Only consider the most-constrained Joltage value at the current point in time. That is, the value affected by the fewest buttons.
// 2. Compute every possible combination of button presses that could be applied to that Joltage value. Subsequent recursive steps can
//    stop checking those buttons, which prunes the search space substantially.
fn press_most_constrained(
  buttons: Buttons,
  joltage_reqs: Joltage,
  presses_total: Int,
) -> Result(Int, Nil) {
  case joltage_is_zero(joltage_reqs) {
    True -> Ok(presses_total)
    False -> {
      let joltage_infos =
        dict.to_list(joltage_reqs)
        |> list.filter(fn(item) { item.1 > 0 })
        |> list.map(fn(item) {
          let #(joltage_index, joltage_value) = item
          let buttons_for_joltage_index =
            list.filter(buttons, fn(button) {
              list.contains(button, joltage_index)
              && button_max_presses(button, joltage_reqs) > 0
            })

          JoltageInfo(
            joltage_value:,
            buttons: buttons_for_joltage_index,
            button_count: list.length(buttons_for_joltage_index),
          )
        })

      let impossible_constraint =
        list.any(joltage_infos, fn(j) {
          j.joltage_value < 0 || { j.button_count == 0 && j.joltage_value > 0 }
        })

      case impossible_constraint {
        True -> Error(Nil)
        False -> {
          use joltage_most_constrained <- result.try(
            joltage_infos
            |> list.filter(fn(item) { item.button_count > 0 })
            |> list.sort(fn(a, b) {
              case int.compare(a.button_count, b.button_count) {
                order.Eq -> int.compare(b.joltage_value, a.joltage_value)
                other -> other
              }
            })
            |> list.first,
          )

          let buttons_next =
            list.filter(buttons, fn(button) {
              !list.contains(joltage_most_constrained.buttons, button)
            })
          let joltage_button_maxes =
            list.map(joltage_most_constrained.buttons, fn(button) {
              button_max_presses(button, joltage_reqs)
            })
          let button_allocation_combinations =
            distribute_presses(
              joltage_most_constrained.joltage_value,
              joltage_button_maxes,
            )

          list.fold(
            button_allocation_combinations,
            Error(Nil),
            fn(accum, allocation) {
              let joltage_reqs_next =
                list.zip(allocation, joltage_most_constrained.buttons)
                |> list.fold(joltage_reqs, fn(accum, item) {
                  let #(press_count, button) = item
                  case press_count {
                    0 -> accum
                    _ -> button_reduce_joltage_reqs(button, press_count, accum)
                  }
                })

              let result =
                press_most_constrained(
                  buttons_next,
                  joltage_reqs_next,
                  presses_total + joltage_most_constrained.joltage_value,
                )
              result_pick_lowest(accum, result)
            },
          )
        }
      }
    }
  }
}

fn day10_part_2(input: String) {
  let subject = process.new_subject()
  let machines = input_to_machines(input)
  let machine_count = list.length(machines)

  list.map(machines, fn(machine) {
    process.spawn(fn() {
      let assert Ok(cost) =
        press_most_constrained(machine.buttons, machine.joltage_reqs, 0)

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
