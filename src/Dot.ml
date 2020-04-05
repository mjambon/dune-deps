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

let node_attributes buf (node : Graph.Node.t) =
  let label = Graph.Name.label node.name in
  match node.kind with
  | Lib -> bprintf buf " [label=%a]" quote label
  | Exe -> bprintf buf " [label=%a,shape=diamond]" quote label
  | Ext -> bprintf buf " [label=%a,style=filled]" quote label

let print_node buf (node : Graph.Node.t) =
  bprintf buf "  %a%a\n"
    quote (Graph.Name.id node.name)
    node_attributes node

let print_edges buf (node : Graph.Node.t) =
  List.iter (fun dep_name ->
    bprintf buf "  %a -> %a\n"
      quote (Graph.Name.id node.name)
      quote (Graph.Name.id (Graph.Name.Lib dep_name))
  ) node.deps

let print_graph (nodes : Graph.Node.t list) =
  let buf = Buffer.create 1000 in
  bprintf buf "\
digraph {
";
  List.iter (print_node buf) nodes;
  List.iter (print_edges buf) nodes;
  bprintf buf "\
}
";
  print_string (Buffer.contents buf);
  flush stdout
