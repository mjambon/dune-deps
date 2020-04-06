(**
   Identify the shortest unique path for identifying a file.

   This is meant for disambiguating private executables.
   If two executables are called 'main', we want to display just enough
   of their path so they appear unique. For example,
   'src/foo/bar/bin/main' and 'src/baz/bin/main' would be shown
   'main<bar/bin>' and 'main<baz/bin>'.
*)

(** [create paths] registers a list of file paths and creates a function
    [simplify] that takes an input path and returns the simplest unambiguous
    name for that path. [None] is returned if the input of [simplify]
    was not registered.
*)
val create : string list -> (string -> string option)
