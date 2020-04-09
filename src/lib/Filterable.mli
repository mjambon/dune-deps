(**
   A labeled directed graph representation, suitable for this application.

   It is meant to be easy to filter on, using input from the user.
*)

(** Holds the graph information. *)
type t

type node_kind = Dep_graph.Node.kind = Exe | Lib | Ext

type node = private {
  id : string; (* unique identifier *)
  label : string; (* anything you want *)
  edges : string list; (* ID list of outgoing edges *)
  important : bool; (* rendering hint *)
  kind : node_kind; (* rendering hint *)
}

(** Ingest a dependency graph. Node IDs must be unique or [Invalid_argument]
    is raised. *)
val of_dep_graph : Dep_graph.t -> t

(** Return the graph as a list of nodes.
    Any edge pointing to an undeclared node is discarded. *)
val to_list : t -> node list

(** Keep only the nodes that match the given condition. *)
val filter : t -> (node -> bool) -> t

(** Change node labels however you wish. *)
val relabel : t -> (node -> string) -> t

(** Mark nodes as important or not. *)
val set_importance : t -> (node -> bool) -> t

(** Resolve the name of a node, by first checking if it matches a node ID.
    If no node ID matches, all the matching labels are returned. *)
val resolve_name : t -> string -> node list

(** Resolve multiple names. See [resolve_name]. *)
val resolve_names : t -> string list -> node list

(** [is_member list get_key] returns an efficient lookup function for
    an element in the list [list] using its key as returned by [get_key]. *)
val is_member : 'a list -> ('a -> 'key) -> ('a -> bool)

(** Prepare an efficient node lookup function. *)
val is_member_node : node list -> (node -> bool)

(** Prepare an efficient node ID lookup function. *)
val is_member_id : node list -> (string -> bool)
