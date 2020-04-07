(*
   Disambiguate path-like names.
*)

open Printf

(* This splits the string wherever there's a slash or a backslash.
   It ignores leading and trailing slashes, which should be fine for our
   application.
 *)
let parse_path =
  let re = Str.regexp "[/\\]+" in
  fun s ->
    Str.split re s

(*
   Ensure each path has at least one component.
   Reverse it so that the file name comes first.
*)
let normalize_path s =
  match parse_path s |> List.rev with
  | [] -> [""]
  | l -> l

let deduplicate l =
  let tbl = Hashtbl.create 100 in
  Compat.List.filter_map (fun x ->
    if Hashtbl.mem tbl x then
      None
    else (
      Hashtbl.add tbl x ();
      Some x
    )
  ) l

(*
   Algorithm:

   Store all the paths in a table, each path keyed by the file name.
   Any cluster of more than 1 is removed and its elements are re-added
   using a longer key.
   This is repeated until there are no more clusters of more than 1.
*)

(*
   This table stores clusters of paths, where the key is the name
   that we want to be unique in the end.
*)
type clus = (string list, (string list * string list      ) list) Hashtbl.t
(*           name          full path     rest of the path *)

let add (clus : clus) k v =
  let values =
    try Hashtbl.find clus k
    with Not_found -> []
  in
  Hashtbl.replace clus k (v :: values)

let make_clusters kv_list =
  let clus = Hashtbl.create (2 * List.length kv_list) in
  List.iter (fun (k, v) -> add clus k v) kv_list;
  clus

let extend_name name (full_path, rest) =
  match rest with
  | [] ->
      (* don't extend because we can't, for this particular path *)
      (name, (full_path, rest))
  | dir :: parents ->
      (name @ [dir], (full_path, parents))

(* Separate unique names (singletons) from other clusters (others). *)
let remove_singletons (clus : clus) =
  Hashtbl.fold (fun k vl (singletons, clusters) ->
    match vl with
    | [v] ->
        ((k, v) :: singletons), clusters
    | vl ->
        let additional_clusters = List.map (fun v -> extend_name k v) vl in
        singletons, (additional_clusters @ clusters)
  ) clus ([], [])

let extend_paths full_paths =
  let rec loop acc clusters =
    match clusters with
    | [] -> acc
    | clusters ->
        let clus = make_clusters clusters in
        let singletons, clusters = remove_singletons clus in
        loop (singletons @ acc) clusters
  in
  let init full_path =
    match full_path with
    | name :: parents -> ([name], (full_path, parents))
    | [] -> ([], (full_path, []))
  in
  let clusters =
    List.map init full_paths
  in
  loop [] clusters

let format_name = function
  | [] -> ""
  | [name] -> name
  | name :: rev_path ->
      sprintf "%s<%s>" name (String.concat "/" (List.rev rev_path))

let create paths =
  let unique_paths =
    List.map normalize_path paths
    |> deduplicate
  in
  let res = extend_paths unique_paths in
  let lookup_tbl = Hashtbl.create 100 in
  List.iter (fun (name, (full_path, _discarded_path)) ->
    Hashtbl.add lookup_tbl full_path name
  ) res;
  let simplify s =
    let path = normalize_path s in
    match Compat.Hashtbl.find_opt lookup_tbl path with
    | None -> None
    | Some name -> Some (format_name name)
  in
  simplify

let map paths =
  let simplify = create paths in
  List.map (fun path ->
    match simplify path with
    | Some name -> name
    | None -> assert false
  ) paths
