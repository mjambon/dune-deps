(*
   Dump the graph into the dot format.

   The dot format is specified at
   https://www.graphviz.org/doc/info/lang.html
*)

open Printf
open Filterable

(* See spec *)
let quote buf s =
  Buffer.add_char buf '"';
  String.iter (function
    | '"' -> Buffer.add_string buf "\\\""
    | c -> Buffer.add_char buf c
  ) s;
  Buffer.add_char buf '"'

let node_attributes buf node =
  let label = node.label in
  let style =
    match node.important with
    | true -> ",style=bold"
    | false -> ""
  in
  match node.kind with
  | Lib -> bprintf buf " [label=%a%s]" quote label style
  | Exe -> bprintf buf " [label=%a,shape=diamond%s]" quote label style
  | Ext -> bprintf buf " [label=%a,style=filled%s]" quote label style

let print_node buf node =
  bprintf buf "  %a%a\n"
    quote node.id
    node_attributes node

let print_edges buf node =
  List.iter (fun dep_name ->
    bprintf buf "  %a -> %a\n"
      quote node.id
      quote dep_name
  ) node.edges

let print_graph graph =
  let nodes = Filterable.to_list graph in
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
