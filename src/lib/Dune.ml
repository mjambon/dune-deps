(*
   Interpretation of 'dune' files into a dependency graph.

   This is not a strict interpretation.
   Pros: may work with older and newer versions of the dune format.
   Cons: may be incorrect with respect to the actual dune language.
*)

open Printf
open Sexplib.Sexp

let extract_node_kind entry : Dep_graph.Node.kind option =
  match entry with
  | Atom ("executable" | "executables") :: _ -> Some Dep_graph.Node.Exe
  | Atom ("library" | "libraries") :: _ -> Some Dep_graph.Node.Lib
  | _ -> None

let find_list names sexp_list =
  let found =
    Compat.List.filter_map (function
      | List [Atom s; List data]
      | List (Atom s :: data) when List.mem s names -> Some data
      | _ -> None
    ) sexp_list
  in
  match found with
  | [] -> None
  | ll -> Some (List.flatten ll)

let extract_strings sexp_list =
  Compat.List.filter_map (function
    | Atom s -> Some s
    | List _ -> None
  ) sexp_list

let extract_names public_private entry =
  let public_names =
    match find_list ["public_names"; "public_name"] entry with
    | None -> None
    | Some l -> Some (extract_strings l)
  in
  let names =
    match find_list ["names"; "name"] entry with
    | None -> None
    | Some l -> Some (extract_strings l)
  in
  match public_names, names with
  | None, None -> []
  | Some names, None | None, Some names -> names
  | Some ps, Some ns ->
      if List.compare_lengths ps ns <> 0 then
        (* https://dune.readthedocs.io/en/latest/reference/dune/executable.html#executables 
           > [(public_names <names>)] describes under what name to install each
           > executable. The list of names must be of the same length as the
           > list in the [(names ...)] field. *)
        invalid_arg "stanzas has a different number of names and public_names";
      (* https://dune.readthedocs.io/en/latest/reference/dune/executable.html#executables 
         > Moreover, you can use - for executables that shouldn’t be installed. *)
      List.iter2 (fun n p -> if p <> "-" then Hashtbl.add public_private n p) ns ps;
      ps

let extract_deps entry =
  match find_list ["libraries"] entry with
  | None -> []
  | Some l -> extract_strings l

(* 'get_index' is a function that returns a fresh numeric identifier for the
   source file 'path'. *)
let read_node public_private path get_index sexp_entry =
  match sexp_entry with
  | Atom _ -> []
  | List entry ->
      match extract_node_kind entry with
      | None -> []
      | Some kind ->
          let names = extract_names public_private entry in
          let deps = extract_deps entry in
          List.map (fun name_string ->
            let loc = { Dep_graph.Loc.path; index = get_index () } in
            let name =
              match kind with
              | Dep_graph.Node.Exe ->
                  let id = Dep_graph.Loc.id loc in
                  let basename = name_string in
                  let path = (* dune file folder + executable name *)
                    Filename.concat (Filename.dirname path) basename in
                  Dep_graph.Name.Exe { id; basename; path }
              | Dep_graph.Node.Lib -> Dep_graph.Name.Lib name_string
              | Dep_graph.Node.Ext -> assert false
            in
            { Dep_graph.Node.name; kind; deps; loc }
          ) names

(*
   'subdir' stanzas are inlined, and subdirectory names are discarded since
   we don't need them.

     (subdir
       foo
       (executable
         (name foo)
       )
     )

   becomes:

     (executable
       (name foo)
     )
*)
let inline_subdirs orig_sexp_entries =
  orig_sexp_entries
  |> List.map (function
    | List (Atom "subdir" :: Atom _dirname :: contents) -> contents
    | x -> [x]
  )
  |> List.flatten

let load_file public_private path =
  let sexp_entries =
    (try Sexplib.Sexp.load_sexps path
     with e ->
       failwith (
         sprintf "Cannot parse dune file %s: exception %s"
           path (Printexc.to_string e)
       )
    )
    |> inline_subdirs
  in
  let index = ref (-1) in
  let get_index () =
    incr index;
    !index
  in
  List.map (read_node public_private path get_index) sexp_entries
  |> List.flatten

let load_files paths =
  let public_private = Hashtbl.create 16 in
  List.map (load_file public_private) paths
  |> List.flatten
  |> Dep_graph.fixup public_private
  |> Filterable.of_dep_graph public_private
