import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/string
import helpers.{type Solution, Example, Real, Solution, measure_solutions}

type Range {
  Range(start: Int, end: Int)
}

fn input_to_ranges(input: String) -> List(Range) {
  list.map(string.split(input, on: ","), fn(range_str) {
    let assert [start_str, end_str] = string.split(range_str, "-")
    let assert Ok(start) = int.parse(start_str)
    let assert Ok(end) = int.parse(end_str)
    Range(start:, end:)
  })
}

fn string_to_chunks(str: String, chunk_size: Int) -> List(String) {
  let length = string.length(str)
  case length > 1 && length % chunk_size == 0 {
    True ->
      list.map(list.range(0, length / chunk_size - 1), fn(i) {
        string.slice(str, i * chunk_size, chunk_size)
      })
    False -> []
  }
}

fn chunks_all_match(chunks: List(String)) -> Bool {
  case chunks {
    [] -> False
    [first, ..rest] -> list.all(rest, fn(item) { first == item })
  }
}

fn number_is_invalid_part_1(number: Int) -> Bool {
  let str = int.to_string(number)
  let length = string.length(str)
  case length % 2 == 0 {
    True -> {
      let half_length = length / 2
      string.slice(str, 0, half_length)
      == string.slice(str, half_length, half_length)
    }
    False -> False
  }
}

fn number_is_invalid_part_2(number: Int) -> Bool {
  let str = int.to_string(number)
  let length = string.length(str)
  let max_chunk_size = length / 2
  list.any(list.range(1, max_chunk_size), fn(chunk_size) {
    chunks_all_match(string_to_chunks(str, chunk_size))
  })
}

fn range_valid_sum(is_invalid: fn(Int) -> Bool, sum: Int, range: Range) -> Int {
  let sum_next = case is_invalid(range.start) {
    True -> sum + range.start

    False -> sum
  }
  case range.start >= range.end {
    True -> sum_next
    False ->
      range_valid_sum(
        is_invalid,
        sum_next,
        Range(start: range.start + 1, end: range.end),
      )
  }
}

fn day02_part_1(input: String) {
  input_to_ranges(input)
  |> list.fold(0, fn(accum, range) {
    range_valid_sum(number_is_invalid_part_1, accum, range)
  })
}

fn day02_part_2(input: String) {
  input_to_ranges(input)
  |> list.fold(0, fn(accum, range) {
    range_valid_sum(number_is_invalid_part_2, accum, range)
  })
}

pub fn solutions() -> List(Solution) {
  let assert False = number_is_invalid_part_1(42)
  let assert True = number_is_invalid_part_1(55)
  let assert True = number_is_invalid_part_1(6464)
  let assert True = number_is_invalid_part_1(123_123)

  let assert 33 = range_valid_sum(number_is_invalid_part_1, 0, Range(11, 22))
  let assert 99 = range_valid_sum(number_is_invalid_part_1, 0, Range(95, 115))
  let assert 33 = range_valid_sum(number_is_invalid_part_2, 0, Range(11, 22))
  let assert 210 = range_valid_sum(number_is_invalid_part_2, 0, Range(95, 115))

  let assert ["123", "456"] = string_to_chunks("123456", 3)
  let assert [] = string_to_chunks("1234567", 3)

  [
    Solution(2, 1, Example, Some(1_227_775_554), day02_part_1),
    Solution(2, 1, Real, Some(29_818_212_493), day02_part_1),
    Solution(2, 2, Example, Some(4_174_379_265), day02_part_2),
    Solution(2, 2, Real, Some(37_432_260_594), day02_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
