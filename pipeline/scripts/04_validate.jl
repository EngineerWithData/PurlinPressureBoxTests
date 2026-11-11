# Module 3: AI spot-check against page images.
#   julia --project=. scripts/04_validate.jl         -> validate and score
#   julia --project=. scripts/04_validate.jl apply   -> apply corrections.csv (after review)
include("_env.jl")
using DataValidator
if !isempty(ARGS) && ARGS[1] == "apply"
    apply_corrections("02_extracted")
else
    validate_papers("02_extracted"; pdfs=PDF_CACHE)
end
