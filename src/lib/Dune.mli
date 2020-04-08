(**
   Interpretation of 'dune' files into a dependency graph.
*)

(**
   Load the specified dune files into a graph that's ready
   to export.

   @param no_exe omit executables from the graph.
   @param no_ext omit external dependencies from the graph.
*)
val load_files :
  no_exe:bool ->
  no_ext:bool ->
  string list -> Graph.t
