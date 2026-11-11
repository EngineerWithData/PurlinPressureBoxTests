# Module 2: extract schema SVGs and data-table CSVs.
#   julia --project=. scripts/02_extract.jl pilot TAG1 TAG2 TAG3   -> 02_extracted/ (pilot papers only)
#   julia --project=. scripts/02_extract.jl                        -> 02_extracted/ (resumable)
include("_env.jl")
using DataExtractor

if !isempty(ARGS) && ARGS[1] == "pilot"
    pdfs = DataExtractor.find_pdfs(PDF_CACHE)
    for tag in ARGS[2:end]
        p = only(filter(f -> DataExtractor.code_tag_from_filename(f) == tag, pdfs))
        extract_paper(p; out="02_extracted", ocr=:always, max_tokens_tables=128000)  # same folder: the full run resumes past these
    end
else
    extract_papers("02_selection"; out="02_extracted", ocr=:always, max_tokens_tables=128000)
end
