(**
   Disambiguate path-like names, similarly to what emacs does for buffer
   names.

   This is meant for disambiguating private executables.
   If two executables are called 'main', we want to display just enough
   of their path so they appear unique. For example,
   'src/foo/bar/bin/main' and 'src/baz/bin/main' would be shown
   'main<bar/bin>' and 'main<baz/bin>'.

   It allows us to pick short and informative labels to put on graph nodes.
*)

(** [create paths] registers a list of file paths and creates a function
    [simplify] that takes an input path and returns the simplest unambiguous
    name for that path. [None] is returned if the input of [simplify]
    was not registered.
*)
val create : string list -> (string -> string option)

(** Map each path to a good name. This is intended for testing purposes. *)
val map : string list -> string list
