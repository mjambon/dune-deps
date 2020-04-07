(*
   Unit tests for the Disambiguate module.
*)

open Printf
open Dune_deps

let map paths =
  printf "-- Input paths:\n";
  List.iter (fun path -> printf "  %s\n" path) paths;
  flush stdout;
  let names = Disambiguate.map paths in
  printf "-- Output names:\n";
  List.iter (fun name -> printf "  %s\n" name) names;
  flush stdout;
  names

let names_testable = Alcotest.list Alcotest.string

let check_names actual expected =
  Alcotest.check names_testable "equal names" expected actual

let test_base () =
  check_names [] (map []);
  check_names ["b"; "c"] (map ["a/b"; "a/c"])

let test_disambiguate () =
  check_names
    (map ["src/foo/x"; "src/bar/x"])
    ["x<foo>"; "x<bar>"];
  check_names
    (map ["src/foo/x"; "src/bar/x"; "y"])
    ["x<foo>"; "x<bar>"; "y"];
  check_names
    (map ["src/foo/x"; "src/bar/foo/x"])
    ["x<src/foo>"; "x<bar/foo>"]

let test_corner_cases () =
  check_names
    (map ["x"])
    ["x"];
  check_names
    (map ["x"; "x"])
    ["x"; "x"];
  check_names
    (map ["x"; "a/x"])
    ["x"; "x<a>"];
  check_names
    (map ["x"; "x/x"; "x/x/x"])
    ["x"; "x<x>"; "x<x/x>"];
  check_names
    (map ["/"; "/a"; "a/"; "a//b"; "\\a\\b"; "a\\b"])
    [""; "a"; "a"; "b"; "b"; "b"]

let test = "Disambiguate", [
  "base", `Quick, test_base;
  "disambiguate", `Quick, test_disambiguate;
  "corner cases", `Quick, test_corner_cases;
]
