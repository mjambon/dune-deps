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
	$(MAKE) -C test

.PHONY: install
install:
	dune install

.PHONY: clean
clean:
	git clean -dfX
