(lang dune 3.0)
(name dune-deps)

(generate_opam_files)
(license "BSD-3-Clause")
(homepage "https://github.com/mjambon/dune-deps")
(source (github mjambon/dune-deps))

; Specify one or more maintainers and authors
(maintainers "Martin Jambon <martin@mjambon.com>")
(authors "Martin Jambon" "OCaml community")

(package
  (name dune-deps)
  (synopsis "Show dependency graph of a multi-component dune project")
  (description "\
Dune-deps scans a dune project and produces a dependency graph
which can be rendered with 'dot'. It is useful for projects that define
multiple libraries or executables. It allows the developer to visualize
the dependencies between the various components of a project.")
  (depends
    (ocaml (>= 4.08.0))
    cmdliner
    sexplib
    (alcotest :with-test)
  )
  (depopts
    conf-graphviz
  )
)
