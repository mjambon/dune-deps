# dune-deps ![CircleCI badge](https://circleci.com/gh/mjambon/dune-deps.svg?style=svg)

Show the internal dependencies in your OCaml/Reason/Dune project.

Input: the root folder of your project

Output: a graph in the dot format

Example:

```
$ dune-deps | tred > deps.dot
$ dot -Tpng deps.dot -o deps.png
```

![sample graph visualization](demo.png)

Installation
==

From opam (TODO):

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
