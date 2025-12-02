import gleam/int
import gleam/list
import gleam/string
import helpers.{read_file}

type Direction {
  Left
  Right
}

type Rotation {
  Rotation(direction: Direction, amount: Int)
}

fn input_to_rotations(str: String) -> List(Rotation) {
  string.split(str, on: "\n")
  |> list.map(fn(line) {
    let #(direction, amount_str) = case line {
      "L" <> num -> #(Left, num)
      "R" <> num -> #(Right, num)
      unknown ->
        panic as { "Invalid rotation instruction! '" <> unknown <> "'" }
    }

    let assert Ok(amount) = int.parse(amount_str)
    Rotation(direction:, amount:)
  })
}

fn position_wrap(position: Int) -> Int {
  case position {
    -1 -> 99
    100 -> 0
    _ -> position
  }
}

fn rotate_dial(
  position: Int,
  zero_count: Int,
  rotation: Rotation,
) -> #(Int, Int) {
  case rotation {
    Rotation(_, 0) -> #(position, zero_count)
    Rotation(direction, amount) -> {
      let position_next =
        position_wrap(case direction {
          Left -> position - 1
          Right -> position + 1
        })
      let zero_count_next = case position_next {
        0 -> zero_count + 1
        _ -> zero_count
      }
      rotate_dial(
        position_next,
        zero_count_next,
        Rotation(direction, amount - 1),
      )
    }
  }
}

fn rotate_dial_and_count_zeroes_part_1(rotations: List(Rotation)) -> Int {
  list.fold(rotations, #(50, 0), fn(accum, rotation) {
    let #(position, zeroes) = accum
    let position_new = rotate_dial(position, 0, rotation).0
    let zeroes_new =
      zeroes
      + case position_new {
        0 -> 1
        _ -> 0
      }
    #(position_new, zeroes_new)
  }).1
}

fn day01_part_1(filename: String) {
  read_file(filename)
  |> input_to_rotations
  |> rotate_dial_and_count_zeroes_part_1
}

fn rotate_dial_and_count_zeroes_part_2(rotations: List(Rotation)) -> Int {
  list.fold(rotations, #(50, 0), fn(accum, rotation) {
    let #(position, zeroes) = accum
    let #(position_new, zero_pass_counter) = rotate_dial(position, 0, rotation)
    let zeroes_new = zeroes + zero_pass_counter
    #(position_new, zeroes_new)
  }).1
}

fn day01_part_2(filename: String) {
  read_file(filename)
  |> input_to_rotations
  |> rotate_dial_and_count_zeroes_part_2
}

pub fn main() -> Nil {
  let assert 3 = day01_part_1("inputs/day01_example.txt")
  let assert 1168 = day01_part_1("inputs/day01.txt")

  let assert 6 = day01_part_2("inputs/day01_example.txt")
  let assert 10 =
    rotate_dial_and_count_zeroes_part_2([
      Rotation(Right, 1000),
    ])
  let assert 11 =
    rotate_dial_and_count_zeroes_part_2([
      Rotation(Right, 1000),
      Rotation(Left, 50),
    ])
  let assert 7199 = day01_part_2("inputs/day01.txt")
  Nil
}
