# Run the tests for dune-deps
#
# This is just one run of dune-deps on a sample dune project.
# Add test cases to the proj/ folder as needed.
#

.PHONY: test
test: output
	diff -u proj.dot.expected proj.dot
	diff -u proj-no-exe.dot.expected proj-no-exe.dot
	diff -u proj-no-ext.dot.expected proj-no-ext.dot
	diff -u proj-hourglass.dot.expected proj-hourglass.dot
	diff -u proj-deps.dot.expected proj-deps.dot

.PHONY: output
output:
	./dune-deps proj extra-proj -x extra-proj/exclude-me > proj.dot
	./dune-deps proj --no-exe > proj-no-exe.dot
	./dune-deps proj --no-ext > proj-no-ext.dot
	./dune-deps proj --hourglass lib5 -h lib3 > proj-hourglass.dot
	./dune-deps proj --deps lib3 --revdeps lib5 > proj-deps.dot

# Accept the test results
.PHONY: promote
promote:
	cp proj.dot proj.dot.expected
	cp proj-no-exe.dot proj-no-exe.dot.expected
	cp proj-no-ext.dot proj-no-ext.dot.expected
	cp proj-hourglass.dot proj-hourglass.dot.expected
	cp proj-deps.dot proj-deps.dot.expected

# This is for troubleshooting
.PHONY: render
render: output
	dot -Tpng proj.dot -o proj.png
	dot -Tpng proj-no-exe.dot -o proj-no-exe.png
	dot -Tpng proj-no-ext.dot -o proj-no-ext.png
	dot -Tpng proj-hourglass.dot -o proj-hourglass.png
	dot -Tpng proj-deps.dot -o proj-deps.png

# Same, but with transitive reduction for a more readable graph.
#
.PHONY: demo
demo: output
	tred < proj.dot > proj.tred.dot
	dot -Tpng proj.tred.dot -o proj.tred.png
