# Purlin Pressure Box Test Database

Full-scale strength tests of cold-formed steel C- and Z-purlin (and girt) roof and wall assemblies loaded by air pressure in a sealed chamber. Each test loaded a full assembly of purlins, panel and supports to failure, either by evacuating the chamber (vacuum) or by pressurizing it. The tests were run for the Metal Building Manufacturers Association (MBMA) between 1975 and 2011; this repository collects them from 24 MBMA research reports into one open set of CSV files.

The data is meant for checking purlin design methods (AISI base test method, R factors, constrained bending, lap and brace rules) against tests. It also supports calibrating models and training machine-learning predictors on system-level purlin strength.

**389 strength tests from 24 MBMA research reports: 190 under gravity load and 199 under uplift.** Every value traces to a page of the source report. The full assembly record, including every review decision, is in [docs/](docs/).

## Datasets

The tests are split into a gravity set and an uplift set. Within each set they are pooled into groups of physically comparable tests.

### Gravity

| Group | Tests | MBMA reports (tests) |
|---|---|---|
| [Single-span standing seam base tests](data/gravity/aggregate_standing_seam_single_span_base_tests.csv) | 159 | 9906 (118), 9002 (17), 9610 (15), 8903 (9) |
| [Multi-span continuous lapped assemblies](data/gravity/aggregate_multi_span_continuous_gravity.csv) | 24 | 8903 (9), 9804 (7), 9704 (6), 7506 (2) |
| [Single-span through-fastened assemblies](data/gravity/aggregate_single_span_through_fastened_gravity.csv) | 7 | 8404 (7) |
| [Tensile coupons](data/gravity/aggregate_tensile_coupons.csv) (supporting) | 72 | 8404, 8903, 9002, 9804 |
| [Measured cross-sections](data/gravity/aggregate_measured_purlin_cross_sections.csv) (supporting) | 30 | 8404 |
| [Computed AISI section properties](data/gravity/aggregate_computed_aisi_section_properties.csv) (supporting) | 30 | 8404 |

### Uplift

| Group | Tests | MBMA reports (tests) |
|---|---|---|
| [Simple-span through-fastened purlins and girts](data/uplift/aggregate_simple_span_through_fastened_uplift.csv) | 116 | 1103 (50), 9501 (29), 8702 (12), 8310 (9), 8404 (8), 8001 (7), 9003 (1) |
| [Standing seam base and confirming tests](data/uplift/aggregate_standing_seam_uplift_base_and_confirming.csv) | 40 | 9001 (16), 9702 (12), 9102 (8), 9902 (4) |
| [Continuous-span through-fastened purlins](data/uplift/aggregate_continuous_span_through_fastened_uplift.csv) | 31 | 8703 (20), 7603 (4), 9105 (3), 7501 (3), 8803 (1) |
| [Vacuum-box panel fastener pullover tests](data/uplift/aggregate_panel_fastener_pullover_vacuum_box.csv) | 12 | 9410 (12) |

The 24 reports, with titles and authors, are listed in [docs/assembly.md](docs/assembly.md#10-reports-in-the-database).

## Using the data

### Repository layout

| Folder | Contents |
|---|---|
| [`data/gravity/`](data/gravity/), [`data/uplift/`](data/uplift/) | The pooled group CSVs and a `_provenance.csv` for each one. Also the merge audit, variable statistics, the reviewed aggregation plan (`plan.json`) and an HTML overview (`aggregation.html`). |
| [`source_tables/`](source_tables/) | Every table extracted from each of the 24 reports, one folder per report. `TableS1_StrengthSummary.csv` is the standardized one-row-per-test summary; the other files are the report's own tables as printed. |
| [`concordance/`](concordance/) | How each report's columns map to the shared variables. |
| [`review/`](review/) | Report selection with reasons, the 100 review questions with decisions, the validation results and corrections, a glossary and reuse caveats. |
| [`docs/`](docs/) | [How the database was assembled](docs/assembly.md), [every review decision](docs/decisions.md), and the [assembly report (PDF)](docs/report/report.pdf). |
| [`pipeline/`](pipeline/) | The Julia scripts that built the database. |

### File format

Every CSV starts with `#` comment lines. These hold the source, page numbers, column definitions and units, and the review notes (`# REVIEW`) and corrections (`# CORRECTED`). Read them: they say how each report defines its loads. Column names in the pooled files carry a short description in parentheses, and units are in the name suffix (`_plf`, `_psf`, `_in`, `_ksi`, `_kip_in`).

Some test names contain `#` (for example `Ceco #4`), so skip the comment lines by their first character instead of using pandas' `comment="#"`:

```python
import io
import pandas as pd

def read(path):
    with open(path, encoding="utf-8") as f:
        df = pd.read_csv(io.StringIO("".join(l for l in f if not l.startswith("#"))))
    df.columns = [c.split(" (")[0] for c in df.columns]   # drop the descriptions
    return df

tests = read("data/uplift/aggregate_simple_span_through_fastened_uplift.csv")
prov = read("data/uplift/aggregate_simple_span_through_fastened_uplift_provenance.csv")

# Z-purlin uplift tests with a failure line load, by report
z = tests.query("section_type == 'Z'").copy()
z["failure_load_plf"] = pd.to_numeric(z["failure_load_plf"], errors="coerce")
print(z.groupby("source_paper")["failure_load_plf"].describe())
```

### Provenance

Each `_provenance.csv` has one code per cell:

- **R:** reported in a table of the report.
- **C:** a constant stated once in the report's notes, such as a purlin spacing.
- **D:** derived by an exact definition, such as a unit conversion or a ratio the report defines.
- **-:** missing (not reported).

### Before pooling across reports

The reports do not share one convention, and these differences matter most:

- **Dead load.** Some reports subtract the assembly self-weight, some include it, and some give the applied chamber load only.
- **Load units.** A few reports give psf or moments only. These values are kept as printed and not converted.
- **Predictions.** Predicted capacities follow the specification edition used in each report.
- **Loading method.** MBMA 9902 used positive pressure on a membrane instead of vacuum.

All of these are listed report by report in [docs/assembly.md, Section 9](docs/assembly.md#9-conventions-and-limitations).

## How the database was built

The reports were sorted, selected, transcribed from page images, checked and pooled with a six-step pipeline. The pipeline uses the open-source RunToSolve packages [PDFTopicSorter.jl](https://github.com/runtosolve/PDFTopicSorter.jl), [DataExtractor.jl](https://github.com/runtosolve/DataExtractor.jl), [DataContext.jl](https://github.com/runtosolve/DataContext.jl), [DataValidator.jl](https://github.com/runtosolve/DataValidator.jl), [DataHarmonizer.jl](https://github.com/runtosolve/DataHarmonizer.jl) and [DataAggregator.jl](https://github.com/runtosolve/DataAggregator.jl). A large language model read the pages, and an engineer reviewed every report against the PDF:

- **Measured values are used.** Nominal values are kept alongside them.
- **Predictions are legacy values,** carried exactly as printed.
- **Nothing is inferred.** A value a report does not state is left blank.
- **Corrections are documented.** Every correction is noted in the CSV header with a page reference.

**Validation:** random spot checks of 4,369 table cells against the page images found 2 errors.

**Exclusions:** eleven reviewed reports were left out, for reasons such as concrete-block loading or re-publication of tests already in the set. Some tests inside selected reports were also left out, for example beam tests, axial-only tests, and a test the authors declared invalid.

The 100 questions the review had to settle, with each decision, are in [docs/decisions.md](docs/decisions.md). The full record is [docs/assembly.md](docs/assembly.md), also available as a [PDF report](docs/report/report.pdf).

## Contribute

If you have pressure box (vacuum or pressure chamber) purlin or girt tests, from MBMA programs not yet included or from other sources, we would like to add them. The same goes for corrections to the existing data.

- **Data in reports or spreadsheets:** [open an issue](https://github.com/EngineerWithData/PurlinPressureBoxTests/issues/new) describing what you have. We'll help convert it.
- **A problem in the data:** open an issue or a pull request that cites the report page.

## Citing

Cite the original MBMA report of each test you use. The citation is in the `# Source` line of each CSV and in the `citation` column of the pooled files. To cite the database itself, see [CITATION.cff](CITATION.cff).

## License

The test data is compiled from MBMA research reports; cite the original reports when you use it. The code in [`pipeline/`](pipeline/) and [`docs/report/`](docs/report/) is MIT-licensed (see [LICENSE](LICENSE)).
