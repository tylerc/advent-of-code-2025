import gleam/float
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/set.{type Set}
import gleam/string
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

type Pos {
  Pos(x: Int, y: Int, z: Int)
}

fn distance(a: Pos, b: Pos) -> Float {
  let x_diff = a.x - b.x
  let y_diff = a.y - b.y
  let z_diff = a.z - b.z
  let assert Ok(x_squared) = int.power(x_diff, 2.0)
  let assert Ok(y_squared) = int.power(y_diff, 2.0)
  let assert Ok(z_squared) = int.power(z_diff, 2.0)
  let assert Ok(result) = float.square_root(x_squared +. y_squared +. z_squared)
  result
}

fn input_to_positions(input: String) -> List(Pos) {
  string.split(input, "\n")
  |> list.map(fn(line) {
    let assert [x, y, z] =
      string.split(line, ",")
      |> list.map(fn(num_str) {
        let assert Ok(num) = int.parse(num_str)
        num
      })
    Pos(x:, y:, z:)
  })
}

fn positions_pair_and_sort(positions: List(Pos)) -> List(#(Pos, Pos)) {
  list.combination_pairs(positions)
  |> list.map(fn(pair) { #(pair, distance(pair.0, pair.1)) })
  |> list.sort(fn(a, b) { float.compare(a.1, b.1) })
  |> list.map(fn(item) { item.0 })
}

type Circuits {
  Circuits(connected: List(Set(Pos)), isolated: Set(Pos))
}

fn circuits_connect_some(
  circuits: Circuits,
  pairs: List(#(Pos, Pos)),
  connections_remaining: Int,
) -> Circuits {
  case pairs, connections_remaining {
    [], _ -> circuits
    _, 0 -> circuits
    [pair, ..rest], _ -> {
      let #(circuits_joining, circuits_other) =
        list.partition(circuits.connected, fn(circuit) {
          set.contains(circuit, pair.0) || set.contains(circuit, pair.1)
        })
      let connected = [
        list.fold(circuits_joining, set.from_list([pair.0, pair.1]), set.union),
        ..circuits_other
      ]
      let isolated =
        circuits.isolated |> set.delete(pair.0) |> set.delete(pair.1)
      circuits_connect_some(
        Circuits(connected:, isolated:),
        rest,
        connections_remaining - 1,
      )
    }
  }
}

fn multiply_three_largest(circuits: Circuits) -> Int {
  list.map(circuits.connected, set.size)
  |> list.sort(order.reverse(int.compare))
  |> list.take(3)
  |> list.fold(1, fn(accum, item) { accum * item })
}

fn day08_part_1(connection_count: Int, input: String) {
  let positions = input_to_positions(input)
  let pairs = positions_pair_and_sort(positions)
  circuits_connect_some(
    Circuits(connected: [], isolated: set.from_list(positions)),
    pairs,
    connection_count,
  )
  |> multiply_three_largest
}

fn circuits_connect_all_last_connection(
  circuits: Circuits,
  pairs: List(#(Pos, Pos)),
) -> #(Pos, Pos) {
  case pairs {
    [] -> panic as "Expected to connect all circuits before this"
    [pair, ..rest] -> {
      let #(circuits_joining, circuits_other) =
        list.partition(circuits.connected, fn(circuit) {
          set.contains(circuit, pair.0) || set.contains(circuit, pair.1)
        })
      let connected = [
        list.fold(circuits_joining, set.from_list([pair.0, pair.1]), set.union),
        ..circuits_other
      ]
      let isolated =
        circuits.isolated |> set.delete(pair.0) |> set.delete(pair.1)

      case set.is_empty(isolated) && list.length(connected) == 1 {
        True -> pair
        False ->
          circuits_connect_all_last_connection(
            Circuits(connected:, isolated:),
            rest,
          )
      }
    }
  }
}

fn day08_part_2(input: String) {
  let positions = input_to_positions(input)
  let pairs = positions_pair_and_sort(positions)
  let #(Pos(x: x1, ..), Pos(x: x2, ..)) =
    circuits_connect_all_last_connection(
      Circuits(connected: [], isolated: set.from_list(positions)),
      pairs,
    )
  x1 * x2
}

pub fn solutions() -> List(Solution) {
  [
    Solution(8, 1, Example, Some(40), day08_part_1(10, _)),
    Solution(8, 1, Real, Some(32_103), day08_part_1(1000, _)),
    Solution(8, 2, Example, Some(25_272), day08_part_2),
    Solution(8, 2, Real, Some(8_133_642_976), day08_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
