import gleam/bit_array
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, Some}
import gleam/string
import gleam/time/duration
import gleam/time/timestamp

pub type FileError

@external(erlang, "file", "read_file")
fn erlang_read_file(path: String) -> Result(BitArray, FileError)

/// We will assume that we never try to read files that don't exist.
fn read_file(path: String) -> String {
  let assert Ok(bits) = erlang_read_file(path)
  let assert Ok(str) = bit_array.to_string(bits)
  string.trim_end(str)
}

pub type SolultionKind {
  Example
  Real
}

pub type Solution {
  Solution(
    day: Int,
    part: Int,
    kind: SolultionKind,
    expected_result: Option(Int),
    computation: fn(String) -> Int,
  )
}

fn measure_solution(solution: Solution) {
  let path =
    "inputs/day"
    <> string.pad_start(int.to_string(solution.day), 2, "0")
    <> case solution.kind {
      Example -> "_example"
      _ -> ""
    }
    <> ".txt"
  let start = timestamp.system_time()
  let result = solution.computation(read_file(path))
  let end = timestamp.system_time()
  let diff = timestamp.difference(start, end)
  let #(seconds, nanos) = duration.to_seconds_and_nanoseconds(diff)
  let #(time, units) = case seconds > 0 {
    True -> #(seconds, "s")
    False ->
      case nanos < 1000 {
        True -> #(nanos, "ns")
        False ->
          case nanos < 1_000_000 {
            True -> #(nanos / 1000, "μs")
            False -> #(nanos / 1_000_000, "ms")
          }
      }
  }

  case solution.expected_result {
    Some(expected_result) ->
      case expected_result == result {
        True -> Nil
        False ->
          panic as {
            "For Day "
            <> int.to_string(solution.day)
            <> " Part "
            <> int.to_string(solution.part)
            <> " ("
            <> case solution.kind {
              Example -> "Example"
              _ -> "Real"
            }
            <> ") we expected "
            <> int.to_string(option.unwrap(solution.expected_result, 0))
            <> " but got "
            <> int.to_string(result)
            <> "."
          }
      }
    _ -> Nil
  }

  io.println(
    "| Day "
    <> string.pad_end(int.to_string(solution.day), 2, " ")
    <> " | Part "
    <> int.to_string(solution.part)
    <> " | "
    <> {
      case solution.kind {
        Example -> "Example | "
        Real -> "Real    | "
      }
    }
    <> string.pad_start(int.to_string(result), 18, " ")
    <> " |"
    <> string.pad_start(int.to_string(time) <> units, 7, " ")
    <> " | ",
  )
}

pub fn measure_solutions(solutions: List(Solution)) {
  io.println("+--------+--------+---------+--------------------+--------+")
  list.each(solutions, measure_solution)
  io.println("+--------+--------+---------+--------------------+--------+")
}
