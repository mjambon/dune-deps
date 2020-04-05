(*
   Types involved in the representation of the dependency graph.
*)

open Printf

(* A node identifier. *)
module Name = struct
  (* An executable or a library. *)
  type t = Exe of string | Lib of string

  (* This is meant as node ID. *)
  let to_string = function
    | Exe name -> "exe:" ^ name
    | Lib name -> "lib:" ^ name

  let kind = function
    | Exe _ -> "an executable"
    | Lib _ -> "a library"

  let name_only = function
    | Exe name
    | Lib name -> name

  let num_kind = function
    | Exe _ -> 0
    | Lib _ -> 1

  let compare a b =
    let c = num_kind a - num_kind b in
    if c <> 0 then c
    else
      String.compare (name_only a) (name_only b)
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
    loc : string;
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
      (* not sure what to do here other than fail *)
      failwith (
        sprintf "Files %s and %s both define %s named %s."
          node.loc node2.loc (Name.kind name) (Name.name_only name)
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
