# dune-deps ![CircleCI badge](https://circleci.com/gh/mjambon/dune-deps.svg?style=svg)

Show the internal dependencies in your OCaml/Reason/Dune project.

Input: the root folder of your project

Output: a graph in the dot format

Example:

```
$ dune-deps | tred | dot -Tpng > deps.png
```

Running dune-deps on itself gives us this dependency graph:

![graph for dune-deps itself](deps.png)

This is the graph we obtain for the
[source code of opam](https://github.com/ocaml/opam), an elaborate
project of over 50K lines of code:

![graph obtained for the opam project](opam-deps.png)

Installation
==

From opam:

```
$ opam update
$ opam install dune-deps
```

From the git repo:

```
$ make
$ make test
$ make install
```

Rendering the graph
==

For producing a 2D image of the graph, we rely on the `dot` command
from [Graphviz](https://www.graphviz.org/).

Additionally, it is often desirable to remove excessive edges to make
the graph more readable. We consider "excessive" an edge that can be
removed without changing the reachability from a node to another. This
transformation is called
[transitive reduction](https://en.wikipedia.org/wiki/Transitive_reduction)
and is performed by `tred`, normally installed as part of the Graphviz
suite.

Usage scenarios
==

How big is this project?
--

Produce a graph for the whole project without knowing anything about
it. This graph may be unreadable, but it gives a sense of the
project's complexity. Use the canonical command pipeline for this:

```
$ cd my-project
$ dune-deps | tred | dot -Tpng > deps.png
```

It can be useful to keep this graph embedded in your rich-text readme.
The markdown syntax, for including an image in a `README.md` file, is:

```
![project dependencies](deps.png)
```

How are these specific components related?
--

As a project grows, its graph becomes wider. Some basic dependencies
may be used directly by many components, resulting in many edges all
tangled up.
[Transitive reduction](https://en.wikipedia.org/wiki/Transitive_reduction)
as performed by `tred` helps with that but is not always sufficient.

For better results, you can build a graph only for selected
components. Specify `dune` files or selected
subfolders directly on the command line. Something like this:

```
$ dune-deps src/lib-foo src/lib-bar src/lib-baz | tred | dot -Tpng > deps.png
```

What uses or is used by a specific component?
--

This is work in progress (see https://github.com/mjambon/dune-deps/issues/5).
The idea is to show only the graph nodes
that are dependencies or reverse dependencies of a specific node.

Is this external dependency really necessary?
--

You can see this by showing all the direct dependencies, i.e. a plain
run without transitive reduction:

```
$ dune-deps | dot -Tpng > deps.png
```

The resulting graph can be messy, but the number of arrows pointing to
the node of interest should give you the answer you're looking for.

Note that this assumes `dune` files are properly written with all the
direct dependencies listed. If some code uses a module `Foo` directly, the
library `foolib` providing `Foo` must be declared as a dependency. In
such case, declare dependencies as `(libraries foolib barlib)` even if
`barlib` itself depends on `foolib`.

Project status
==

Dune-deps was initiated by Martin Jambon.
It is distributed free of charge under the terms of a
[BSD license](LICENSE).

Software maintenance takes time, skill, and effort. Please
contribute to open-source projects to the best of
your ability. Talk to your employer about it today.
