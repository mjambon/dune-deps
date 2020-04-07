(*
   Dune file finder.
*)

(* Find dune files starting from root folder or file *)
let find ~accept_file_name ~accept_dir_name root =
  let rec find acc path =
    let name = Filename.basename path in
    match Sys.is_directory path with
    | true ->
        if not (accept_dir_name name) then
          acc
        else
          let children =
            Sys.readdir path
            |> Array.to_list
            |> List.map (fun name -> Filename.concat path name)
          in
          List.fold_left find acc children
    | false ->
        if accept_file_name name then
          (path :: acc)
        else
          acc
  in
  find [] root

(*
   Recursively find dune files starting from a folder 'root'.
   Excludes '_build' folders but doesn't honor exclusion rules specified
   in dune files with (dirs ... \ exclude_me).
*)
let find_dune_files roots =
  List.fold_left (fun acc root ->
    find
      ~accept_file_name:(fun name -> name = "dune")
      ~accept_dir_name:(fun name -> name <> "_build" && name <> "_opam")
      root
    @ acc
  ) [] roots
