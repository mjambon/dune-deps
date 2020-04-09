(**
   Library of filters over the nodes of directed graphs of type Filterable.t.
*)

(** Remove all external dependencies from the graph. *)
val no_ext : Filterable.t -> Filterable.t

(** Remove all executables from the graph. *)
val no_exe : Filterable.t -> Filterable.t

(** Return the subgraph made of all the nodes reachable from the specified
    start nodes. Nodes are referenced by name, see details in [Filterable].
    Start nodes are marked as important.
*)
val deps : Filterable.t -> string list -> Filterable.t

(** Same as [deps] but visits edges in the opposite direction. *)
val revdeps : Filterable.t -> string list -> Filterable.t

(** Compute the subgraph representing the union of dependencies
    and reverse dependencies, as determined by [deps] and [revdeps]. *)
val deps_or_revdeps :
  Filterable.t ->
  deps: string list ->
  revdeps: string list ->
  Filterable.t
