(*
   Types involved in the representation of the dependency graph.
*)

open Printf

(* The location of a node declaration. *)
module Loc = struct
  type t = {
    path : string; (* path to the dune file *)
    index : int;   (* sequential ID within the dune file *)
  }

  let id {path; index} = sprintf "%s:%i" path index
  let path loc = loc.path
end

(* A node identifier. *)
module Name = struct
  type exe = {
    id : string;
      (* unique identifier *)

    basename : string;
      (* the short name of the library or executable, as typically referenced
         in dune files. It may be ambiguous. *)

    path : string;
      (* a path-like name that will be used to generate a good node label,
         such as "src/foo/lib/bar". It may end up being shown as
         "bar" or "bar<lib>" or "bar<lib/foo>" etc. depending on ambiguities
         found with other labels.
      *)
  }

  (* An executable or a library. *)
  type t =
    | Exe of exe
    | Lib of string (* both the unique ID among libraries
                       and the library name. *)

  let id = function
    | Exe x -> "exe:" ^ x.id
    | Lib name -> "lib:" ^ name

  let kind = function
    | Exe _ -> "an executable"
    | Lib _ -> "a library"

  let basename = function
    | Exe {basename; _}
    | Lib basename -> basename

  let full_name = function
    | Exe {path; _} -> path
    | Lib name -> name

  let num_kind = function
    | Exe _ -> 0
    | Lib _ -> 1

  let compare a b =
    let c = num_kind a - num_kind b in
    if c <> 0 then c
    else
      String.compare (full_name a) (full_name b)
end

(* A node with its outgoing edges (dependencies). *)
module Node = struct
  (* A node is either an executable, an internal library, or an external
     library. *)
  type kind = Exe | Lib | Ext

  type t = {
    name : Name.t;
    kind : kind;

    (* List of libraries. Nothing can depend on an executable. *)
    deps : string list;

    (* Path to the original 'dune' file. For error reporting. *)
    loc : Loc.t;
  }
end

(* The representation of the graph as we're building it. *)
type tbl = (Name.t, Node.t) Hashtbl.t

(* The graph is a list of nodes that has been constructed properly. *)
type t = Node.t list

let add_node tbl node =
  let open Node in
  let name = node.name in
  match Compat.Hashtbl.find_opt tbl name with
  | Some node2 ->
      (* should happen only when defining two libraries of the same name *)
      failwith (
        sprintf "Files %s and %s both define %s named %s."
          (Loc.path node.loc)
          (Loc.path node2.loc)
          (Name.kind name)
          (Name.full_name name)
      )
  | None ->
      Hashtbl.add tbl name node

(*
   Identify all dependencies that are not already nodes in the graph,
   and add them as nodes representing external libraries.
*)
let add_missing_nodes tbl =
  let all_deps =
    let dep_names = Hashtbl.create 100 in
    Hashtbl.iter (fun _name (node : Node.t) ->
      List.iter (fun dep_name ->
        Hashtbl.replace dep_names dep_name node.loc
      ) node.deps
    ) tbl;
    Hashtbl.fold (fun dep_name loc acc -> (dep_name, loc) :: acc) dep_names []
  in
  List.iter (fun (dep_name, loc) ->
    let name = Name.Lib dep_name in
    if not (Hashtbl.mem tbl name) then
      let node : Node.t = {
        name;
        kind = Ext;

         (* we don't know and don't care what the external dependencies
            themselves depend on *)
        deps = [];

        loc;
      } in
      add_node tbl node
    else
      ()
  ) all_deps

(*
   Complete the graph so as to have explicit nodes for the external
   dependencies.

   This also checks that there are no duplicate nodes.
*)
let fixup nodes =
  let tbl = Hashtbl.create 100 in
  List.iter (add_node tbl) nodes;
  add_missing_nodes tbl;
  let nodes = Hashtbl.fold (fun _name node acc -> node :: acc) tbl [] in
  List.sort (fun (a : Node.t) b -> Name.compare a.name b.name) nodes
