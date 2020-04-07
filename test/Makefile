# Run the tests for dune-deps
#
# This is just one run of dune-deps on a sample dune project.
# Add test cases to the proj/ folder as needed.
#

.PHONY: test
test: output
	diff -u proj.dot.expected proj.dot

.PHONY: output
output:
	./dune-deps proj extra-proj > proj.dot

# This is for troubleshooting
.PHONY: render
render: output
	dot -Tpng proj.dot -o proj.png

# Same, but with transitive reduction for a more readable graph.
#
.PHONY: demo
demo: output
	tred < proj.dot > proj.tred.dot
	dot -Tpng proj.tred.dot -o proj.tred.png
