# Step 1b: write 02_selection/index.csv = the rows of 01_sorted/index.csv for the papers in
# 02_selection/selection.csv (columns: code_tag,load_type,reason). DataExtractor reads it.
include("_env.jl")
using DataExtractor

sel = read_selection()
header, rows = DataExtractor.read_csv(joinpath("01_sorted", "index.csv"))
pcol = findfirst(==("path"), header)
q(s) = occursin(r"[,\"\n]", s) ? "\"" * replace(s, "\"" => "\"\"") * "\"" : s
kept = [r for r in rows if DataExtractor.code_tag_from_filename(r[pcol]) in keys(sel)]
mkpath(PDF_CACHE)
for r in kept
    local_pdf = joinpath(PDF_CACHE, basename(r[pcol]))
    isfile(local_pdf) || cp(r[pcol], local_pdf)
    r[pcol] = local_pdf
end
open(joinpath("02_selection", "index.csv"), "w") do io
    println(io, join(q.(header), ','))
    foreach(r -> println(io, join(q.(r), ',')), kept)
end
found = Set(DataExtractor.code_tag_from_filename(r[pcol]) for r in kept)
missing_tags = setdiff(keys(sel), found)
println("selected $(length(kept)) of $(length(sel)) papers")
isempty(missing_tags) || @warn "selection tags not in index" missing_tags
