(*
   Dump the graph into the dot format.

   The dot format is specified at
   https://www.graphviz.org/doc/info/lang.html
*)

open Printf

(* See spec *)
let quote buf s =
  Buffer.add_char buf '"';
  String.iter (function
    | '"' -> Buffer.add_string buf "\\\""
    | c -> Buffer.add_char buf c
  ) s;
  Buffer.add_char buf '"'

let node_attributes get_node_label buf (node : Graph.Node.t) =
  let label = get_node_label node in
  match node.kind with
  | Lib -> bprintf buf " [label=%a]" quote label
  | Exe -> bprintf buf " [label=%a,shape=diamond]" quote label
  | Ext -> bprintf buf " [label=%a,style=filled]" quote label

let print_node get_node_label buf (node : Graph.Node.t) =
  bprintf buf "  %a%a\n"
    quote (Graph.Name.id node.name)
    (node_attributes get_node_label) node

let print_edges buf (node : Graph.Node.t) =
  List.iter (fun dep_name ->
    bprintf buf "  %a -> %a\n"
      quote (Graph.Name.id node.name)
      quote (Graph.Name.id (Graph.Name.Lib dep_name))
  ) node.deps

let prepare_labels nodes =
  let exe_paths =
    Compat.List.filter_map (fun (node : Graph.Node.t) ->
      match node.name with
      | Lib _ -> None
      | Exe {path; _} -> Some path
    ) nodes
  in
  let get_exe_label = Disambiguate.create exe_paths in
  let get_node_label (node : Graph.Node.t) =
    match node.name with
      | Lib name -> name
      | Exe {path; _} ->
          match get_exe_label path with
          | None -> assert false
          | Some name -> name
  in
  get_node_label

let print_graph (nodes : Graph.Node.t list) =
  let get_node_label = prepare_labels nodes in
  let buf = Buffer.create 1000 in
  bprintf buf "\
digraph {
";
  List.iter (print_node get_node_label buf) nodes;
  List.iter (print_edges buf) nodes;
  bprintf buf "\
}
";
  print_string (Buffer.contents buf);
  flush stdout
