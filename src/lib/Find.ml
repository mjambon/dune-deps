(*
   Dune file finder.
*)

type visit_tracker = {
  was_visited : string -> bool;
  mark_visited : string -> unit;
}

let memoize f =
  let tbl = Hashtbl.create 100 in
  fun x ->
    let run =
      match Compat.Hashtbl.find_opt tbl x with
      | Some run -> run
      | None ->
          let run = lazy (f x) in
          Hashtbl.add tbl x run;
          run
    in
    Lazy.force run

(* Cache the results of the 'stat' syscall to speed things up.
   (due to calling it multiple times on the same path, and having
   possibly a lot of paths, and not so great caching at the OS level). *)
let stat = memoize Unix.stat

(* This is to avoid visiting the same file or directory multiple times.

   It can happen if the same folder or overlapping folders are specified
   on the command line. It can also happen due to cycles introduced
   by symbolic links.
*)
let create_visit_tracker () =
  let tbl = Hashtbl.create 100 in
  let get_id path =
    try Some (stat path).st_ino
    with _ -> None
  in
  let was_visited path =
    match get_id path with
    | None -> true
    | Some id -> Hashtbl.mem tbl id
  in
  let mark_visited path =
    match get_id path with
    | None -> ()
    | Some id -> Hashtbl.replace tbl id ()
  in
  { was_visited; mark_visited }

let get_file_kind path =
  try Some (stat path).st_kind
  with _ -> None

(* Find dune files starting from root folder or file *)
let find ~accept_file_name ~accept_dir_name visit_tracker root =
  let rec find acc path =
    if visit_tracker.was_visited path then
      acc
    else (
      visit_tracker.mark_visited path;
      let name = Filename.basename path in
      match get_file_kind path with
      | Some Unix.S_DIR ->
          if not (accept_dir_name name) then
            acc
          else
            let children =
              let a = Sys.readdir path in
              (* sort elements so as to obtain reproducible test results *)
              Array.sort String.compare a;
              Array.to_list a
              |> List.map (fun name -> Filename.concat path name)
            in
            List.fold_left find acc children
      | Some Unix.S_REG ->
          if accept_file_name name then
            (path :: acc)
          else
            acc
      | None | Some _ ->
          (* leave broken symlinks and special files alone *)
          acc
    )
  in
  find [] root

(*
   Recursively find dune files starting from a folder 'root'.
   Excludes '_build' folders but doesn't honor exclusion rules specified
   in dune files with (dirs ... \ exclude_me).
*)
let find_dune_files ~exclude roots =
  let visit_tracker = create_visit_tracker () in
  List.iter visit_tracker.mark_visited exclude;
  List.fold_left (fun acc root ->
    find
      ~accept_file_name:(fun name -> name = "dune")
      ~accept_dir_name:(fun name -> name <> "_build" && name <> "_opam")
      visit_tracker
      root
    @ acc
  ) [] roots
