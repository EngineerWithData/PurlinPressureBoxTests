# Shared settings and .env loading for the purlin pipeline scripts.
# Run every script from the project folder: julia --project=. scripts/<step>.jl

const PROJ = normpath(joinpath(@__DIR__, ".."))
const MBMA_LIB = normpath(joinpath(PROJ, "..", "MBMA Library"))
# Local copies of the selected PDFs (step 1b). Google Drive streaming dropped pages mid-run,
# so every step after the sort reads PDFs from here instead of the Drive folder.
const PDF_CACHE = expanduser("~/.cache/steeldata/mbma_purlin")

# The key lives outside the shared drive so it does not sync to other Drive members.
# Setting ENV here covers PDFTopicSorter (ENV only) and every Data* module.
const ENV_FILES = [expanduser("~/.config/steeldata/.env"), joinpath(PROJ, ".env")]

function load_env!(paths=ENV_FILES)
    isempty(get(ENV, "ANTHROPIC_API_KEY", "")) || return
    for path in filter(isfile, paths), line in eachline(path)
        m = match(r"^\s*(?:export\s+)?ANTHROPIC_API_KEY\s*=\s*(.+?)\s*$", line)
        m === nothing || (ENV["ANTHROPIC_API_KEY"] = strip(m[1], ['"', '\'']); return)
    end
    error("No ANTHROPIC_API_KEY: add ANTHROPIC_API_KEY=sk-ant-... to $(ENV_FILES[1])")
end
load_env!()
cd(PROJ)

# Papers chosen in step 1b: code_tag => load_type ("gravity" | "uplift" | "both")
function read_selection(path=joinpath(PROJ, "02_selection", "selection.csv"))
    sel = Dict{String,String}()
    for (i, line) in enumerate(eachline(path))
        i == 1 && continue
        f = split(line, ',')
        length(f) >= 2 && (sel[strip(f[1])] = lowercase(strip(f[2])))
    end
    return sel
end
