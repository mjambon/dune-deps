(*
   Dune file finder.
*)

let find ~accept_file_name ~accept_dir_name root_dir =
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
  find [] root_dir

(*
   Recursively find dune files starting from a folder 'proj_dir'.
   Excludes '_build' folders but doesn't honor exclusion rules specified
   in dune files with (dirs ... \ exclude_me).
*)
let find_dune_files proj_dir =
  find
    ~accept_file_name:(fun name -> name = "dune")
    ~accept_dir_name:(fun name -> name <> "_build")
    proj_dir
