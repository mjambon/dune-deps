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

.PHONY: output
output:
	./dune-deps proj extra-proj > proj.dot
	./dune-deps proj extra-proj --no-exe > proj-no-exe.dot
	./dune-deps proj extra-proj --no-ext > proj-no-ext.dot

# Accept the test results
.PHONY: promote
promote:
	cp proj.dot proj.dot.expected
	cp proj-no-exe.dot proj-no-exe.dot.expected
	cp proj-no-ext.dot proj-no-ext.dot.expected

# This is for troubleshooting
.PHONY: render
render: output
	dot -Tpng proj.dot -o proj.png
	dot -Tpng proj-no-exe.dot -o proj-no-exe.png
	dot -Tpng proj-no-ext.dot -o proj-no-ext.png

# Same, but with transitive reduction for a more readable graph.
#
.PHONY: demo
demo: output
	tred < proj.dot > proj.tred.dot
	dot -Tpng proj.tred.dot -o proj.tred.png
