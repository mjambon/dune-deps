# Build everything from here:
#
# make
# make test
# make install
#
# If 'make test' fails, visit test/ and work from there.
#

# Choices are 'default' or 'static'. See root 'dune' file.
ifndef DUNE_PROFILE
  DUNE_PROFILE = default
endif
export DUNE_PROFILE

.PHONY: build
build:
	dune build @install --profile $(DUNE_PROFILE)

.PHONY: test
test:
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
	mkdir -p img
	dune-deps src | tred | dot -Tpng > img/deps.png
