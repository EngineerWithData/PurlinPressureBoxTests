# Step 2b: one strength-summary table per paper (Table S1), written in DataExtractor's own
# CSV format into 02_extracted/. Older reports state failure loads in the prose
# ("At 80 psf the eastern purlin ... failed"), which the table pass does not capture.
# Reads the cached page transcriptions from 02_extracted/_logs/ocr/<tag>/text/, so no
# page is read twice. Resumable: a paper with _logs/<tag>_strength.json is skipped.
#   julia --project=. scripts/02b_strength.jl            -> every selected paper
#   julia --project=. scripts/02b_strength.jl MBMA_7506  -> just these
include("_env.jl")
using DataExtractor
const DE = DataExtractor
const JSON = DE.JSON

const OUT = "02_extracted"

const STRENGTH_SYSTEM = """
You are a meticulous data curator building a database of full-scale cold-formed steel
purlin roof system tests. You will be given the complete transcribed text of one test
report (with `=== PAGE n ===` markers).

Return exactly ONE table: a strength summary with one row per full-scale test (or per
test specimen/purlin line where the report gives separate results), collecting the
measured ultimate strength of every test the report itself performed, wherever the
report states it: in a results table, in an appendix, OR in the narrative text. Do not
include other papers' results, design predictions on their own, or quarter-scale tests.

Use these columns first, in this order (leave a cell empty when the report does not state
it; never compute or guess a value that is not printed):
  test_id, load_direction, section_type, depth_in, thickness_in, span_ft, n_spans,
  n_purlin_lines, panel_type, bracing, failure_load_as_printed, failure_load_unit,
  failure_moment_as_printed, failure_moment_unit, failure_mode, value_source, pages
- load_direction: "gravity" or "uplift".
- section_type: "C" or "Z" (or as printed).
- panel_type: "through-fastened", "standing seam", or as printed.
- failure_load_as_printed / failure_moment_as_printed: the number exactly as printed;
  the unit goes in the matching _unit column exactly as printed (psf, plf, lb/ft, kips,
  ft-kips, in.-kips, ...). Keep the report's own units; do not convert.
- value_source: "table <label>", "text", or "figure <label>". If the only evidence is the
  last load increment before loading stopped (no explicit failure statement), write
  "inferred: last load step" so it can be filtered out.
- pages: page number(s) where the value is stated.
You may add further columns after these when the report gives other per-test results
(e.g. test-to-predicted ratio, yield stress). Apply the usual rules: table_label and
table_number are "S1", short_name is "StrengthSummary", data_basis starts with
"measured:", rows are verbatim, extraction_quality describes the transcription quality
of the values you copied. Use notes for the load sign convention, tributary width,
whether loads include dead load, and any footnote needed to read the numbers.

Every physical load test the report performed gets a row, even when there are only one or
two tests, when the result is stated only in a sentence of the narrative, or when the
test ended by deck, connection or panel failure rather than purlin buckling: record the
stated failure or maximum load and describe what limited the test in failure_mode.
Return an empty `tables` list ONLY if the report describes no physical load tests at all.
"""
const STRENGTH_ASK = "Build the strength summary table (S1) in the required JSON format."

# Long reports (e.g. MBMA_9906, 619 pages) do not fit in one request, so the page text is
# split into parts of at most CHUNK_CHARS characters, each asked separately.
const CHUNK_CHARS = 350_000

function paper_chunks(tag)
    dir = joinpath(OUT, "_logs", "ocr", tag, "text")
    isdir(dir) || return nothing
    pages = sort(filter(f -> occursin(r"^p\d+\.txt$", f), readdir(dir)))
    chunks = String[]
    io = IOBuffer()
    for f in pages
        n = parse(Int, match(r"\d+", f).match)
        t = string("=== PAGE ", n, " ===\n", read(joinpath(dir, f), String), "\n")
        if position(io) > 0 && position(io) + sizeof(t) > CHUNK_CHARS
            push!(chunks, String(take!(io)))
        end
        print(io, t)
    end
    position(io) > 0 && push!(chunks, String(take!(io)))
    return chunks
end

# Stack the S1 tables from several parts into one: columns are matched by name, and a
# column first seen in a later part is added at the end.
function merge_parts(parts)
    length(parts) == 1 && return parts[1]
    tables = [t for p in parts for t in get(p, "tables", Any[])]
    isempty(tables) && return parts[1]
    base = deepcopy(tables[1])
    cols = String.(base["columns"])
    defs = Dict(String(split(d, " = "; limit=2)[1]) => d for d in base["column_definitions"])
    rows = Any[]
    for t in tables
        tc = String.(t["columns"])
        for c in tc
            c in cols || push!(cols, c)
        end
        for d in t["column_definitions"]
            get!(defs, String(split(d, " = "; limit=2)[1]), d)
        end
        for r in t["rows"]
            push!(rows, Any[(i = findfirst(==(c), tc)) === nothing ? "" : r[i] for c in cols])
        end
    end
    # A test summarised in the main text and again on its data sheet comes back from two
    # parts; keep the first row for each test_id (the parts run in page order).
    seen = Set{String}()
    n_all = length(rows)
    rows = filter(r -> (id = string(r[1]); isempty(id) || !(id in seen) && (push!(seen, id); true)), rows)
    width = length(cols)
    base["columns"] = cols
    base["rows"] = [vcat(r, fill("", width - length(r))) for r in rows]
    base["column_definitions"] = [get(defs, c, c * " = (see notes)") for c in cols]
    base["pages"] = join(filter(!isempty, [string(get(t, "pages", "")) for t in tables]), ", ")
    base["notes"] = unique(vcat([get(t, "notes", Any[]) for t in tables]...))
    n_all > length(rows) && push!(base["notes"], "Assembled from $(length(parts)) requests over consecutive page ranges; " *
        "$(n_all - length(rows)) duplicate row(s) for tests reported in more than one place were dropped, keeping the first (earliest pages).")
    q = [string(get(t, "extraction_quality", "clean")) for t in tables]
    base["extraction_quality"] = "reconstructed" in q ? "reconstructed" : "ocr_repaired" in q ? "ocr_repaired" : "clean"
    out = deepcopy(parts[1])
    out["tables"] = Any[base]
    return out
end

function strength_summary(client, tag)
    rec = joinpath(OUT, "_logs", tag * "_strength.json")
    isfile(rec) && (@info "strength summary exists; skipping" tag; return)
    chunks = paper_chunks(tag)
    chunks === nothing && (@warn "no cached page text; run 02_extract.jl first" tag; return)
    parts = Any[]
    cost = 0.0
    for (i, text) in enumerate(chunks)
        ask = length(chunks) == 1 ? STRENGTH_ASK :
            "This is part $i of $(length(chunks)) of the report (the page markers give the pages). " *
            "Return the S1 rows for the tests whose results appear in this part only; another " *
            "request covers the other parts. Use exactly the required leading columns. " * STRENGTH_ASK
        body = DE.build_body(STRENGTH_SYSTEM, text, ask; max_tokens=32_000, schema=DE.TABLES_SCHEMA)
        p, resp = DE.ask_json(client, body; betas=DE.betas_for(true))
        u = DE.usage_tuple(resp)
        DE.record_usage!(OUT, tag, "strength", u)
        cost += DE.estimate_cost(u)
        push!(parts, p)
        @info "strength part" tag part = i of = length(chunks) ntables = length(get(p, "tables", Any[]))
    end
    parsed = merge_parts(parts)
    files, problems = DE.csv_outputs(tag, parsed; text_source="read from page images by the model (cached transcription)")
    for (f, csv) in files
        write(joinpath(OUT, f), csv)
    end
    open(rec, "w") do io
        JSON.print(io, Dict("answer" => parsed, "files" => first.(files), "problems" => problems), 2)
    end
    isempty(problems) || @warn "table failed validation" tag problems
    @info "strength summary" tag files = first.(files) cost = round(cost; digits=2)
end

client = DE.Client(; timeout=1800)
tags = isempty(ARGS) ? sort(collect(keys(read_selection()))) : ARGS
for tag in tags
    try
        strength_summary(client, tag)
    catch e
        @error "strength summary failed" tag exception = e
    end
end
