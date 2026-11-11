# Step 2a: re-read pages that the extraction left empty (dense data sheets whose
# transcription ran past DataExtractor's 16k-token OCR limit). One page per call with a
# larger limit; each page is written straight into the OCR cache, so a re-run of
# 02_extract.jl for that paper picks it up for free.
#   julia --project=. scripts/02a_fill_pages.jl MBMA_7501:85-104 MBMA_8404:17-20
include("_env.jl")
using DataExtractor
const DE = DataExtractor

client = DE.Client(; timeout=1800)
pdfs = DE.find_pdfs(PDF_CACHE)
for arg in ARGS
    tag, rng = split(arg, ':')
    a, b = parse.(Int, split(rng, '-'))
    pdf = only(filter(f -> DE.code_tag_from_filename(f) == tag, pdfs))
    cache = joinpath("02_extracted", "_logs", "ocr", tag)
    for p in a:b
        f = joinpath(cache, "text", string("p", lpad(p, 4, '0'), ".txt"))
        isfile(f) && continue
        try
            got, _, u = DE.ocr_batch(client, pdf, [p], joinpath(cache, "images"); max_tokens=64_000)
            DE.record_usage!("02_extracted", tag, "ocr", u)
            haskey(got, p) ? write(f, got[p]) : @warn "page not returned" tag p
            @info "page read" tag p chars = length(get(got, p, "")) cost = round(DE.estimate_cost(u); digits=2)
        catch e
            @error "page failed" tag p exception = e
        end
    end
end
