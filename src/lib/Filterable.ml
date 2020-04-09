(*
   A directed graph representation suitable for filtering and other
   simple user-driven transformations.
*)

open Printf

type node_kind = Dep_graph.Node.kind = Exe | Lib | Ext

type node = {
  id : string; (* unique identifier *)
  label : string; (* anything you want *)
  edges : string list; (* ID list of outgoing edges *)
  important : bool; (* rendering hint *)
  kind : node_kind; (* rendering hint *)
}

type t = node list

let prepare_labels (nodes : Dep_graph.Node.t list) =
  let open Dep_graph.Node in
  let exe_paths =
    Compat.List.filter_map (fun node ->
      match node.name with
      | Lib _ -> None
      | Exe {path; _} -> Some path
    ) nodes
  in
  let get_exe_label = Disambiguate.create exe_paths in
  let get_node_label node =
    match node.name with
      | Lib name -> name
      | Exe {path; _} ->
          match get_exe_label path with
          | None -> assert false
          | Some name -> name
  in
  get_node_label

let check_ids nodes =
  let tbl = Hashtbl.create 100 in
  List.iter (fun node ->
    let id = node.id in
    if Hashtbl.mem tbl id then
      invalid_arg (sprintf "Filterable.check_ids: duplicate node ID %S" id)
    else
      Hashtbl.add tbl id ()
  ) nodes;
  nodes

let is_member list get_key =
  let tbl = Hashtbl.create (2 * List.length list) in
  List.iter (fun v -> Hashtbl.replace tbl (get_key v) ()) list;
  fun v ->
    Hashtbl.mem tbl (get_key v)

let is_member_node nodes =
  is_member nodes (fun node -> node.id)

let is_member_id nodes =
  is_member (List.map (fun node -> node.id) nodes) (fun id -> id)

(*
   Each node of the graph must be in the list of nodes.
   Remove references to unknown node IDs.
*)
let remove_dead_edges nodes =
  let is_node_id = is_member_id nodes in
  List.map (fun node ->
    let edges = List.filter is_node_id node.edges in
    { node with edges }
  ) nodes

let of_dep_graph nodes : t =
  let open Dep_graph in
  let get_node_label = prepare_labels nodes in
  List.map (fun node ->
    {
      id = Node.(node.name) |> Name.id;
      label = get_node_label node;
      edges = List.map (fun name -> Name.id (Name.Lib name)) Node.(node.deps);
      important = false;
      kind = Node.(node.kind);
    }
  ) nodes
  |> check_ids
  |> remove_dead_edges

(* assumes dead edges were removed *)
let to_list nodes = nodes

let filter nodes f =
  List.filter f nodes
  |> remove_dead_edges

let relabel nodes get_label =
  List.map (fun node -> { node with label = get_label node }) nodes

let set_importance nodes get_importance =
  List.map (fun node -> { node with important = get_importance node }) nodes

let resolve_name nodes name =
  match Compat.List.find_opt (fun node -> node.id = name) nodes with
  | Some node -> [node]
  | None ->
      List.find_all (fun node -> node.label = name) nodes

let deduplicate nodes =
  let tbl = Hashtbl.create 100 in
  List.filter (fun node ->
    if Hashtbl.mem tbl node.id then
      false
    else (
      Hashtbl.add tbl node.id ();
      true
    )
  ) nodes

let resolve_names nodes names =
  List.map (fun name -> resolve_name nodes name) names
  |> List.flatten
  |> deduplicate
