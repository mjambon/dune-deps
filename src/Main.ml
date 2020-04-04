(*
   Entry point of the dune-deps executable.
*)

open Printf

let usage_msg =
  "\
Usage: dune-deps [PROJECT_DIR]

dune-deps scans a folder for 'dune' files, extracts the dependencies between
the libraries and executables that they define, as well as external
dependencies. The result is a graph in the dot format, printed on standard
output.

Options:
  --help  print this help message and exit.
"

let optimistic_run root_dir =
  Find.find_dune_files root_dir
  |> Dune.load_files
  |> Dot.print_graph

let safe_run root_dir =
  try optimistic_run root_dir
  with
  | Failure msg ->
      eprintf "Error: %s\n%!" msg;
      exit 1
  | e ->
      let trace = Printexc.get_backtrace () in
      eprintf "Error: exception %s\n%s%!"
        (Printexc.to_string e)
        trace

let main () =
  Printexc.record_backtrace true;
  match Sys.argv with
  | [| _ |] -> safe_run "."
  | [| _; "--help" |] ->
      printf "%s%!" usage_msg;
      exit 0
  | [| _; root_dir |] -> safe_run root_dir
  | _ ->
      eprintf "%s%!" usage_msg;
      exit 1

let () = main ()
