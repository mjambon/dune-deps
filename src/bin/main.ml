(*
   Entry point of the dune-deps executable.
*)

open Printf
open Cmdliner
open Dune_deps

type config = {
  roots : string list;
  exclude : string list;
  no_exe : bool;
  no_ext : bool;
  deps : string list;
  revdeps : string list;
}

let optimistic_run {roots; exclude; no_exe; no_ext; deps; revdeps} =
  let graph =
    Find.find_dune_files roots ~exclude
    |> Dune.load_files
  in
  let graph =
    if no_exe then Filter.no_exe graph
    else graph
  in
  let graph =
    if no_ext then Filter.no_ext graph
    else graph
  in
  let graph =
    match deps, revdeps with
    | [], [] -> graph
    | _ -> Filter.deps_or_revdeps graph ~deps ~revdeps
  in
  Dot.print_graph graph

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

let exclude_term =
  let info =
    Arg.info ["exclude"; "x"]
      ~docv:"ROOT"
      ~doc:"Ignore folder or file $(docv) when scanning the file tree \
            for 'dune' files."
  in
  Arg.value (Arg.opt_all Arg.string [] info)

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

let hourglass_term =
  let info =
    Arg.info ["hourglass"; "h"]
      ~docv:"NAME"
      ~doc:"Select dependencies and reverse dependencies of that node. \
            The resulting graph may have an hourglass shape \
            if a node is selected in the middle of the graph. \
            $(docv) is used to select the node. It is either a node ID or a \
            label. \
            The node ID is unique and can be found by generating an \
            unfiltered graph with dune-deps. A label ID is what's displayed \
            on the graph rendered by 'dot'. Please note that the format of \
            either node ID or label is subject to change in future versions \
            of dune-deps. Node selection searches $(docv) first among \
            node IDs. If a node is found, then that node is selected. \
            Otherwise, all nodes whose label matches $(docv) are selected."
  in
  Arg.value (Arg.opt_all Arg.string [] info)

let deps_term =
  let info =
    Arg.info ["deps"; "d"]
      ~docv:"NAME"
      ~doc:"Same as --hourglass but select only the dependencies of the \
            specified node(s)."
  in
  Arg.value (Arg.opt_all Arg.string [] info)

let revdeps_term =
  let info =
    Arg.info ["revdeps"; "r"]
      ~docv:"NAME"
      ~doc:"Same as --hourglass but select only reverse dependencies of the \
            specified node(s)."
  in
  Arg.value (Arg.opt_all Arg.string [] info)

let cmdline_term =
  let combine roots exclude no_exe no_ext hourglass deps revdeps =
    let deps, revdeps =
      (deps @ hourglass), (revdeps @ hourglass)
    in
    { roots; exclude; no_exe; no_ext; deps; revdeps }
  in
  Term.(const combine
        $ roots_term
        $ exclude_term
        $ no_exe_term
        $ no_ext_term
        $ hourglass_term
        $ deps_term
        $ revdeps_term
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
