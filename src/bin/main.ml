(*
   Entry point of the dune-deps executable.
*)

open Printf
open Cmdliner
open Dune_deps

type config = {
  roots : string list;
  no_exe : bool;
  no_ext : bool;
}

let optimistic_run {roots; no_exe; no_ext} =
  Find.find_dune_files roots
  |> Dune.load_files ~no_exe ~no_ext
  |> Dot.print_graph

let safe_run config =
  try optimistic_run config
  with
  | Failure msg ->
      eprintf "Error: %s\n%!" msg;
      exit 1
  | e ->
      let trace = Printexc.get_backtrace () in
      eprintf "Error: exception %s\n%s%!"
        (Printexc.to_string e)
        trace

let roots_term =
  let info =
    Arg.info []
      ~docv:"ROOT"
      ~doc:"$(docv) can be either a folder in which 'dune' files are to be \
            found recursively, or simply a 'dune' file. Multiple $(docv) \
            arguments are supported. If no $(docv) is specified, the current \
            folder is used."
  in
  Arg.value (Arg.pos_all Arg.file ["."] info)

let no_exe_term =
  let info =
    Arg.info ["no-exe"]
      ~doc:"Omit executables."
  in
  Arg.value (Arg.flag info)

let no_ext_term =
  let info =
    Arg.info ["no-ext"]
      ~doc:"Omit external libraries."
  in
  Arg.value (Arg.flag info)

let cmdline_term =
  let combine roots no_exe no_ext =
    { roots; no_exe; no_ext }
  in
  Term.(const combine
        $ roots_term
        $ no_exe_term
        $ no_ext_term
       )

let doc =
  "extract a dependency graph from a dune project"

let man = [
  `S Manpage.s_description;
  `P "dune-deps scans root folders for 'dune' files and extracts the \
      dependencies between the project's libraries, project's executables, \
      and their external dependencies. The result is a graph in the dot \
      format, printed on standard output.";
  `P "For usage suggestions and more, visit \
      https://github.com/mjambon/dune-deps.";
  `S Manpage.s_examples;
  `P "You should first install the Graphviz suite of tools. Check for
      the 'dot' and 'tred' commands. Then a good command to run from
      your project's root is:";
  `Pre "dune-deps | tred | dot -Tpng > deps.png";
  `S Manpage.s_authors;
  `P "Martin Jambon <martin@mjambon.com>";
  `S Manpage.s_bugs;
  `P "Check out bug reports at https://github.com/mjambon/dune-deps/issues.";
  `S Manpage.s_see_also;
  `P "dot(1), tred(1)"
]

let parse_command_line () =
  let info =
    Term.info
      ~doc
      ~man
      "dune-deps"
  in
  match Term.eval (cmdline_term, info) with
  | `Error _ -> exit 1
  | `Version | `Help -> exit 0
  | `Ok config -> config

let main () =
  Printexc.record_backtrace true;
  let config = parse_command_line () in
  safe_run config

let () = main ()
