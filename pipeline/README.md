# Pipeline

These Julia scripts built the database. They are kept as a record of exactly how each step was run, including the review decisions written into the code:

- `DROP_ROWS` and `DROP_FILES` in `05_harmonize.jl` list the tests left out and why.
- The plan handling in `06_aggregate.jl` explains why the token limits were raised.

Each script is one step, run from the project folder with `julia --project=. scripts/<step>.jl`:

| Script | Step |
|---|---|
| `01_sort.jl` | Sort the MBMA library PDFs by theme, topic and subtopic ([PDFTopicSorter.jl](https://github.com/runtosolve/PDFTopicSorter.jl)). |
| `01b_select.jl` | Write the selected reports to `02_selection/index.csv` and copy their PDFs to a local cache. |
| `02_extract.jl`, `02a_fill_pages.jl`, `02b_strength.jl` | Transcribe each report's tables from page images and build Table S1 ([DataExtractor.jl](https://github.com/runtosolve/DataExtractor.jl)). |
| `03_context.jl` | Report briefs, glossary, reuse caveats and open questions ([DataContext.jl](https://github.com/runtosolve/DataContext.jl)). |
| `04_validate.jl` | Spot checks against page images ([DataValidator.jl](https://github.com/runtosolve/DataValidator.jl)). |
| `05_harmonize.jl` | Variable concordance for each set ([DataHarmonizer.jl](https://github.com/runtosolve/DataHarmonizer.jl)). |
| `06_aggregate.jl` | Pooled groups and merge audit ([DataAggregator.jl](https://github.com/runtosolve/DataAggregator.jl)). |

`_env.jl` holds the shared settings. It reads `ANTHROPIC_API_KEY` from `~/.config/steeldata/.env`, and it reads the set assignments from `02_selection/selection.csv` (in this repository: [`review/selection.csv`](../review/selection.csv)).

The MBMA report PDFs are not included in this repository, so the steps that read pages (01–04) need your own copy of the MBMA library. Steps 05 and 06 can be rerun from the files here, with this folder layout:

| Copy from this repository | To |
|---|---|
| `source_tables/<report>/*.csv` | `02_extracted/` |
| `review/selection.csv` | `02_selection/` |
| `concordance/<set>/_inventories/` | `05_sets/<set>_harmonized/_inventories/` |
| `data/<set>/plan.json` | `05_sets/<set>_aggregated/_plan/` |

With the saved inventories, concordance and reviewed plans in place, these two steps reuse them and make no new model calls.
