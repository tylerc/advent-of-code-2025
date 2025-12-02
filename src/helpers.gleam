import gleam/bit_array
import gleam/string

pub type FileError

@external(erlang, "file", "read_file")
fn erlang_read_file(path: String) -> Result(BitArray, FileError)

/// We will assume that we never try to read files that don't exist.
pub fn read_file(path: String) -> String {
  let assert Ok(bits) = erlang_read_file(path)
  let assert Ok(str) = bit_array.to_string(bits)
  string.trim_end(str)
}
