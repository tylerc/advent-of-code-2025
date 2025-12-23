import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{Some}
import gleam/string
import helpers.{
  type Solution, Example, ExamplePostfix, Real, Solution, measure_solutions,
}

type Device {
  Device(label: String, outputs: List(String))
}

fn line_to_device(line: String) -> Device {
  let assert [label, output_strs] = string.split(line, ": ")
  Device(label:, outputs: string.split(output_strs, " "))
}

fn input_to_devices(input: String) -> Dict(String, Device) {
  string.split(input, "\n")
  |> list.map(fn(line) {
    let device = line_to_device(line)
    #(device.label, device)
  })
  |> dict.from_list
  |> dict.insert("out", Device(label: "out", outputs: []))
}

fn devices_paths_count_part_1(
  devices: Dict(String, Device),
  current: Device,
) -> Int {
  case current.label == "out" {
    True -> 1
    False ->
      list.fold(current.outputs, 0, fn(accum, label) {
        let assert Ok(next) = dict.get(devices, label)
        accum + devices_paths_count_part_1(devices, next)
      })
  }
}

fn day11_part_1(input: String) {
  let devices = input_to_devices(input)
  let assert Ok(you) = dict.get(devices, "you")
  devices_paths_count_part_1(devices, you)
}

fn devices_paths_count_part_2(
  devices: Dict(String, Device),
  visit_cache: Dict(#(String, Bool, Bool), Int),
  current: Device,
  saw_dac: Bool,
  saw_fft: Bool,
) -> #(Int, Dict(#(String, Bool, Bool), Int)) {
  let saw_dac = saw_dac || current.label == "dac"
  let saw_fft = saw_fft || current.label == "fft"
  case current.label == "out" && saw_dac && saw_fft {
    True -> #(1, visit_cache)
    False ->
      list.fold(current.outputs, #(0, visit_cache), fn(accum, label) {
        let assert Ok(next) = dict.get(devices, label)
        let cache_key = #(label, saw_dac, saw_fft)
        case dict.get(visit_cache, cache_key) {
          Ok(count) -> #(accum.0 + count, visit_cache)
          Error(_) -> {
            let #(count, visit_cache_next) =
              devices_paths_count_part_2(
                devices,
                accum.1,
                next,
                saw_dac,
                saw_fft,
              )
            #(
              accum.0 + count,
              visit_cache_next |> dict.insert(cache_key, count),
            )
          }
        }
      })
  }
}

fn day11_part_2(input: String) {
  let devices = input_to_devices(input)
  let assert Ok(srv) = dict.get(devices, "svr")
  devices_paths_count_part_2(devices, dict.new(), srv, False, False).0
}

pub fn solutions() -> List(Solution) {
  [
    Solution(11, 1, Example, Some(5), day11_part_1),
    Solution(11, 1, Real, Some(749), day11_part_1),
    Solution(11, 2, ExamplePostfix("2"), Some(2), day11_part_2),
    Solution(11, 2, Real, Some(420_257_875_695_750), day11_part_2),
  ]
}

pub fn main() -> Nil {
  measure_solutions(solutions())
}
