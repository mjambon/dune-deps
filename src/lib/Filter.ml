(*
   Various operations that remove nodes from a graph.
*)

open Filterable

let no_exe graph = Filterable.filter graph (fun node -> node.kind <> Exe)

let no_ext graph = Filterable.filter graph (fun node -> node.kind <> Ext)

module Digraph = struct
  type t = (string, string) Hashtbl.t
  let create () : t = Hashtbl.create 100

  let add tbl from to_ =
    Hashtbl.add tbl from to_

  let of_list l =
    let tbl = create () in
    List.iter (fun (from, to_) -> add tbl from to_) l;
    tbl

  let to_list tbl =
    Hashtbl.fold (fun from to_ acc -> (from, to_) :: acc) tbl []

  let of_filterable graph =
    let nodes = Filterable.to_list graph in
    let edges =
      List.map (fun node ->
        let from = node.id in
        List.map (fun to_ -> (from, to_)) node.edges
      ) nodes
      |> List.flatten
    in
    of_list edges

  let reverse tbl =
    to_list tbl
    |> List.map (fun (a, b) -> (b, a))
    |> of_list

  (* Recursively visit all reachable nodes starting from the given start
     nodes. Return a function that tells whether a node is reachable. *)
  let is_reachable graph start_nodes =
    let visited = Hashtbl.create 100 in
    let rec visit start =
      if Hashtbl.mem visited start then
        ()
      else (
        Hashtbl.add visited start ();
        let neighbors = Hashtbl.find_all graph start in
        List.iter visit neighbors
      )
    in
    List.iter visit start_nodes;
    fun node -> Hashtbl.mem visited node.id
end

let is_dep graph start_ids =
  let digraph = Digraph.of_filterable graph in
  let is_reachable = Digraph.is_reachable digraph start_ids in
  is_reachable

let is_revdep graph start_ids =
  let digraph = Digraph.of_filterable graph |> Digraph.reverse in
  let is_reachable = Digraph.is_reachable digraph start_ids in
  is_reachable

let get_ids graph names =
  Filterable.resolve_names graph names
  |> List.map (fun node -> node.id)

let mark_start_nodes graph start_ids =
  let is_start_id = Filterable.is_member start_ids (fun x -> x) in
  Filterable.set_importance graph (fun node ->
    node.important || is_start_id node.id
  )

let deps graph names =
  let start_ids = get_ids graph names in
  let graph = mark_start_nodes graph start_ids in
  Filterable.filter graph (is_dep graph start_ids)

let revdeps graph names =
  let start_ids = get_ids graph names in
  let graph = mark_start_nodes graph start_ids in
  Filterable.filter graph (is_revdep graph start_ids)

let deps_or_revdeps graph ~deps:deps_names ~revdeps:revdeps_names =
  let deps_start_ids = get_ids graph deps_names in
  let revdeps_start_ids = get_ids graph revdeps_names in
  let is_reachable =
    let is_dep = is_dep graph deps_start_ids in
    let is_revdep = is_revdep graph revdeps_start_ids in
    fun node -> is_dep node || is_revdep node
  in
  let graph = mark_start_nodes graph (deps_start_ids @ revdeps_start_ids) in
  Filterable.filter graph is_reachable
