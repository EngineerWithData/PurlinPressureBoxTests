# Module 0: falsifiable claims + open questions. Re-run after answering open_questions.csv
# (resume=true reuses every brief, so a re-run is nearly free).
#
# Two local adjustments to DataContext 0.x:
#  - It reads each paper from the PDF text layer, which in these 1970s-90s scans drops
#    decimals and C/Z letters. We hand it the page transcriptions DataExtractor already made
#    (02_extracted/_logs/ocr/<tag>/text), in the same "=== PAGE n ===" format.
#  - Its brief is capped at 24k output tokens, which MBMA_8404 overran. Raised to 64k.
include("_env.jl")
using DataContext

const OCR_DIR = joinpath(PROJ, "02_extracted", "_logs", "ocr")
# Longest text sent for one paper (~150k tokens). Only MBMA_9906 (619 pages, mostly test data
# sheets in Vols. I-II) exceeds it; its main report comes first, so the cut keeps that.
const MAX_CHARS = 600_000

# Narrower String methods take precedence over the package's AbstractString ones and fall
# back to them with `invoke`, so nothing in the package is overwritten.
@eval DataContext begin
    function extract_text(pdf::String; timeout::Real=120)
        m = match(r"([A-Za-z]{2,}[_\-]\d{2,}[A-Za-z]?)", basename(pdf))
        dir = m === nothing ? "" : joinpath($OCR_DIR, uppercase(replace(String(m[1]), "-" => "_")), "text")
        isdir(dir) || return invoke(extract_text, Tuple{AbstractString}, pdf; timeout)
        io = IOBuffer()
        for f in sort(filter(f -> occursin(r"^p\d+\.txt$", f), readdir(dir)))
            t = string("\n=== PAGE ", parse(Int, match(r"\d+", f).match), " ===\n", rstrip(read(joinpath(dir, f), String)), "\n")
            if position(io) + sizeof(t) > $MAX_CHARS
                print(io, "\n=== REMAINING PAGES OMITTED (length limit; they hold per-test data sheets) ===\n")
                break
            end
            print(io, t)
        end
        return String(take!(io))
    end
    ask_brief(client::Client, p::Paper, text::String; max_tokens::Int=64_000, kwargs...) =
        invoke(ask_brief, Tuple{Client,Paper,AbstractString}, client, p, text; max_tokens, kwargs...)
end

build_context("02_extracted"; pdfs=PDF_CACHE, out="03_context", recursive=false)
