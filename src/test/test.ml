(*
   Entrypoint to run the unit tests from the command line.
*)

let test_suites : unit Alcotest.test list = [
  Disambiguate.test;
]

let main () = Alcotest.run "dune-deps" test_suites

let () = main ()
