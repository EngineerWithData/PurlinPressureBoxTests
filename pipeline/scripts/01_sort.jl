# Module 1: sort the whole MBMA Library into themes/topics/subtopics (one API call).
include("_env.jl")
using PDFTopicSorter

prompt = """Sort these MBMA research reports by themes, topics, and then sub topics, adding their code tags.
Give purlin and girt research its own theme. Within it, separate full-scale purlin system
strength tests under gravity loading, full-scale tests under uplift (wind suction) loading,
base-test-method reports, scale-model tests, brace/restraint-force studies, and analytical or
design-method work, so that physical strength-test reports are easy to pick out."""

r = sort_pdfs(MBMA_LIB; out="01_sorted", prompt, snippet_chars=300, max_tokens=32000)
println(r.usage)
println("rows in index: ", length(r.index))
