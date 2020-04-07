# Build everything from here:
#
# make
# make test
# make install
#
# If 'make test' fails, visit test/ and work from there.
#

.PHONY: build
build:
	dune build @install

.PHONY: test
test: build
	ln -sf ../_build/install/default/bin/dune-deps test/
	dune exec src/test/test.exe
	$(MAKE) -C test

.PHONY: install
install:
	dune install

.PHONY: clean
clean:
	git clean -dfX

# You can stick this section in your own project if you wish.
# 'make graph' produces a image that can be included in 'README.md'.
#
.PHONY: graph deps.png
graph: deps.png
deps.png:
	dune-deps src | tred | dot -Tpng > deps.png
