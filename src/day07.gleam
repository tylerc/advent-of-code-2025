import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{Some}
import gleam/string
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

type Cell {
  Start
  Splitter
  Beam
  Empty
}

type Pos {
  Pos(row: Int, col: Int)
}

fn input_to_board(input: String) -> #(Dict(Pos, Cell), Pos) {
  string.split(input, "\n")
  |> list.index_fold(#(dict.new(), Pos(row: -1, col: -1)), fn(accum, line, row) {
    string.split(line, "")
    |> list.index_fold(accum, fn(accum, char, col) {
      let cell = case char {
        "S" -> Start
        "^" -> Splitter
        "." -> Empty
        unexpected -> panic as { "Unknown board char: " <> unexpected }
      }

      let pos = Pos(row:, col:)
      let board = dict.insert(accum.0, pos, cell)
      case cell {
        Start -> #(board, pos)
        _ -> #(board, accum.1)
      }
    })
  })
}

fn dict_insert_if_empty(
  board: Dict(Pos, Cell),
  pos: Pos,
  cell: Cell,
) -> Dict(Pos, Cell) {
  case dict.get(board, pos) == Ok(Empty) {
    True -> dict.insert(board, pos, cell)
    False -> board
  }
}

fn board_iter(board: Dict(Pos, Cell)) -> Dict(Pos, Cell) {
  let board_new =
    dict.fold(board, board, fn(board, pos, cell) {
      case cell {
        Start | Beam ->
          dict_insert_if_empty(board, Pos(row: pos.row + 1, col: pos.col), Beam)
        Splitter ->
          board
          |> dict_insert_if_empty(Pos(row: pos.row, col: pos.col - 1), Beam)
          |> dict_insert_if_empty(Pos(row: pos.row, col: pos.col + 1), Beam)
        Empty -> board
      }
    })
  case board_new == board {
    True -> board
    False -> board_iter(board_new)
  }
}

fn day07_part_1(input: String) {
  let board =
    input_to_board(input).0
    |> board_iter
  dict.fold(board, 0, fn(accum, pos, cell) {
    case
      cell == Splitter
      && dict.get(board, Pos(row: pos.row - 1, col: pos.col)) == Ok(Beam)
    {
      True -> accum + 1
      False -> accum
    }
  })
}

fn timelines_count_cached(
  board: Dict(Pos, Cell),
  pos: Pos,
  cache: Dict(Pos, Int),
) -> #(Int, Dict(Pos, Int)) {
  case dict.get(cache, pos) {
    Ok(count) -> #(count, cache)
    Error(_) -> {
      let pos_below = Pos(row: pos.row + 1, col: pos.col)
      let #(to_check_next, incr) = case dict.get(board, pos_below) {
        Error(_) -> #([], 1)
        Ok(Empty) -> #([pos_below], 0)
        Ok(Splitter) -> {
          let sides =
            [
              Pos(row: pos_below.row, col: pos_below.col - 1),
              Pos(row: pos_below.row, col: pos_below.col + 1),
            ]
            |> list.filter(fn(side) { dict.get(board, side) == Ok(Empty) })
          #(sides, 0)
        }
        Ok(Start) | Ok(Beam) -> panic as "Simulated into impossible situation."
      }

      let #(count_result, cache_result) =
        list.fold(to_check_next, #(incr, cache), fn(accum, pos_next) {
          let #(count_from_pos_next, cache_updated) =
            timelines_count_cached(board, pos_next, accum.1)
          #(accum.0 + count_from_pos_next, cache_updated)
        })

      #(count_result, dict.insert(cache_result, pos, count_result))
    }
  }
}

fn day07_part_2(input: String) {
  let #(board, start) = input_to_board(input)
  timelines_count_cached(board, start, dict.new()).0
}

pub fn solutions() -> List(Solution) {
  [
    Solution(7, 1, Example, Some(21), day07_part_1),
    Solution(7, 1, Real, Some(1646), day07_part_1),
    Solution(7, 2, Example, Some(40), day07_part_2),
    Solution(7, 2, Real, Some(32_451_134_474_991), day07_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
