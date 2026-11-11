# How the database was assembled

This page is the text of the assembly report ([PDF](report/report.pdf), [Typst source](report/report.typ)) with the file paths changed to match this repository. The decision on every review question is in [decisions.md](decisions.md).

## Contents

1. [Scope](#1-scope)
2. [Workflow](#2-workflow)
3. [Report selection](#3-report-selection)
4. [Data extraction](#4-data-extraction)
5. [Engineering review](#5-engineering-review)
6. [Validation](#6-validation)
7. [Harmonization](#7-harmonization)
8. [Aggregation](#8-aggregation)
9. [Conventions and limitations](#9-conventions-and-limitations)
10. [Reports in the database](#10-reports-in-the-database)

## 1. Scope

The database holds full-scale cold-formed steel purlin and girt strength tests taken from the Metal Building Manufacturers Association (MBMA) research report library. Each test loaded a roof or wall assembly with air pressure in a sealed chamber until the purlins or girts failed. The pressure came either from evacuating the chamber (vacuum) or from pressurizing it. Tests loaded by concrete blocks, hydraulic jacks, point loads or axial rams are left out.

There are 389 strength tests from 24 MBMA reports published between 1975 and 2011, split into two sets:

- **Gravity set:** 190 tests from 8 reports, plus 132 rows of supporting coupon and cross-section data.
- **Uplift set:** 199 tests from 17 reports.

MBMA 8404 is in both sets. Its gravity tests are in the gravity set and its uplift tests in the uplift set, so no test is counted twice.

Every value can be traced to a page of the source report:

- **Measured results** are carried as printed.
- **Calculated predictions** printed in the reports are carried as legacy values, also as printed, and labelled as predictions.
- **Values a report does not state** are left blank, not inferred.

## 2. Workflow

The database was built with a six-step pipeline. Each step is a Julia script in [`pipeline/scripts/`](../pipeline/scripts/). The steps that read the reports call a large language model (Anthropic Claude) on page images, and every step that changes a value is followed by engineering review.

| Step | What it does | Output in this repository |
|---|---|---|
| 1. Sort | Sorts the 445 reports of the MBMA library by theme, topic and subtopic. | — |
| 1b. Select | Selects the reports with full-scale pressure box purlin or girt strength tests and assigns each to the gravity set, the uplift set, or both. | [`review/selection.csv`](../review/selection.csv) |
| 2. Extract | Reads every page as an image and transcribes each data table to CSV. Each CSV gets a comment header with column definitions, units, page numbers and notes. Also builds a standardized strength summary (Table S1) for each report. | [`source_tables/`](../source_tables/) |
| 3. Context | Writes a brief for each report and lists the questions the reports themselves cannot answer, such as tributary width, dead load, units and duplicates. | [`review/open_questions.csv`](../review/open_questions.csv), [`review/glossary.csv`](../review/glossary.csv), [`review/reuse_caveats.csv`](../review/reuse_caveats.csv) |
| 4. Validate | Draws random cells and claims and checks each one against the page image. | [`review/validation_report.csv`](../review/validation_report.csv), [`review/corrections.csv`](../review/corrections.csv) |
| 5. Harmonize | Matches equivalent columns across reports (variable concordance). | [`concordance/`](../concordance/) |
| 6. Aggregate | Pools the reports into groups of comparable tests and audits the merge. | [`data/`](../data/) |

## 3. Report selection

### 3.1 Library sort

The MBMA library holds 445 reports, and the sort placed 77 of them under purlin and girt (secondary framing) research. Within that theme it separated full-scale tests under gravity and under uplift, base-test-method reports, scale-model tests, brace-force studies and analytical work. Candidates came from the full-scale test topics. A later sweep of the library found more reports with pressure box tests that the first pass had missed.

### 3.2 Selected and excluded reports

Thirty-five reports were reviewed. Twenty-four are in the database (Section 10), and eleven were excluded:

| Report | Reason for exclusion |
|---|---|
| MBMA 8002 | Concrete-block loading. |
| MBMA 8201 | Concrete-block loading (33 lb blocks). |
| MBMA 8302 | Concrete-block loading. |
| MBMA 8802 | Concrete-block loading; its 13 tests are the Rivard and Murray tests reported as data from a previous project. |
| MBMA 8102 | Analytical study; its Table 5.1 re-lists the MBMA 7603 tests. |
| MBMA 8203 | Observer report of the 12 tests published in MBMA 8702. |
| MBMA 8401 | Re-publication of the nine MBMA 8310 Butler vacuum-chamber uplift tests (Appendix A, Table 2, p.29). |
| MBMA 8309 | Edge-stiffener study on a narrow two-purlin specimen (purlins 18 in. apart under a 34 in. panel, Fig. 3); failure moments only, with no panel, fastening or bracing description. |
| MBMA 1205 | Dissertation; Ch. 3 republishes the MBMA 1103 tests and Ch. 4 compiles other programs' tests. |
| MBMA 1206 | Journal version of the MBMA 1103 tests. |
| MBMA 1207 | Rotational restraint (stiffness) tests, not flexural strength tests. |

### 3.3 Tests left out of selected reports

Some selected reports also contain tests that do not belong in the database. These rows stay in the CSVs under [`source_tables/`](../source_tables/) as the record of the report, but they are removed before the sets are pooled. Each removal is noted in the header of the pooled copy. The rules are `DROP_ROWS` and `DROP_FILES` in [`pipeline/scripts/05_harmonize.jl`](../pipeline/scripts/05_harmonize.jl).

| Report | Tests left out and reason |
|---|---|
| MBMA 7603 | In-plane deck shear (diaphragm) tests. They give load-deflection curves only and are not purlin strength tests. |
| MBMA 8001 | Beam tests B1-B7: four-point loads through channels joining the bottom flanges, no panel (p.36). |
| MBMA 8404 | Test 13. The authors state its results are not valid because of an error in constructing the test setup (Sec. 3.3, p.34; Table 3.2 footnote). Its coupon and cross-section rows are removed too. |
| MBMA 8803 | Test 3, the unbraced reference test first reported in MBMA 8703. |
| MBMA 9003 | All tests except SP-10C-M, which removes three kinds of test. The axial-load-only tests go. So do the combined uplift-plus-axial tests: the vacuum was held at a preset level and the specimen failed under the axial ram load (p.26). Tests whose data pages are missing from the scan go too. |
| MBMA 9410 | Vacuum Box Test 1: set-up problems and no fastener failure (pp.50-51). |
| MBMA 9501 | Proprietary manufacturer tests M1 and M2: R factor only, with no load, moment or assembly details. |
| MBMA 9702 | Virginia Tech uplift base tests first reported in MBMA 9001 and MBMA 9102. |
| MBMA 9902 | Axial tests A1-A4: hydraulic jack through load beams, no chamber (pp.56-57). |

## 4. Data extraction

Each report was converted to page images and transcribed table by table. The transcription keeps every printed value as printed, including units, footnote markers and unreadable characters (marked `[?]`). Each CSV opens with a `#` comment header that gives:

- the source and the page numbers;
- a definition and unit for every column;
- the extraction quality;
- notes on anomalies;
- the review notes (`# REVIEW`) and corrections (`# CORRECTED`).

Each report also has a standardized strength summary, `TableS1_StrengthSummary.csv`, with one row per test. Its leading columns are the same in every report:

```
test_id, load_direction, section_type, depth_in, thickness_in, span_ft, n_spans,
n_purlin_lines, panel_type, bracing, failure_load_as_printed, failure_load_unit,
failure_moment_as_printed, failure_moment_unit, failure_mode, value_source, pages
```

Report-specific columns follow them, such as yield stress, predicted loads, R factors and chamber pressures. The pooled groups are built from Table S1. A report's other tables join to it by test name.

## 5. Engineering review

Every selected report was reviewed against the PDF under four rules:

1. **Measured values are used.** Where a report gives both nominal and measured dimensions or material properties, the measured values go in the main columns. The nominal values are kept in separate `_nominal` columns.
2. **Predictions are legacy values.** Predicted capacities, R factors computed by the authors and test-to-predicted ratios are carried exactly as printed.
3. **Nothing is inferred.** A value the report does not state is left blank. A value derived by hand is flagged as a hand calculation, and its equation is given.
4. **Corrections are documented.** An apparent typographical error is corrected only after review. The correction goes in a `# CORRECTED` note in the CSV header with the page reference.

The context step raised 100 open questions that the extracted tables could not settle, and all 100 were answered in review. The answers are in [`review/open_questions.csv`](../review/open_questions.csv) and [decisions.md](decisions.md). Every answer that changed a value is also recorded as a `# REVIEW` note in the header of the affected CSV. These are the decisions that most affect how the data can be used:

| Report | Decision |
|---|---|
| MBMA 1103 | The measured girt thickness (Table 7) replaces the nominal footnote value. The tributary width is L_p/2 = 6.79 ft from Eq. 14, not the 3 ft panel width. A plf line load is added as a hand calculation from Eq. 14, which includes panel and girt self-weight. |
| MBMA 7501 | The three continuous-span assemblies are uplift tests and are in the uplift set. The First and Second Z assemblies are distinct tests: the second was built with straightened purlins. |
| MBMA 8001 | The measured depth and thickness (Table 3.2) replace the nominal Table 3.3 values. V1 had fixed ends. |
| MBMA 8404 | Test 13 is removed (Section 3.3). |
| MBMA 9003 | Only SP-10C-M is kept. Its load includes about 9 plf of roof-system dead weight. |
| MBMA 9610 | W_tot is the line load on one purlin line: M_t = W L²/8 reproduces every printed M_t. No other report contains these tests. |
| MBMA 9704 | The printed failure loads include purlin self-weight: 8 plf, or 12 plf for FV20-3 with its doubled panel. FV20-4 is kept as printed although its pressure conversion uses 5.0 rather than 5.2 psf per inch of water. FV20-1 and FV20-2 had their top flanges pointing out; the other tests pointed in. |
| MBMA 9902 | F1-F4 are kept. They were loaded by positive air pressure on a membrane under the panel rather than by vacuum, and the data may come from manufacturers' existing base tests (p.50). |

## 6. Validation

The validation step drew random cells from every table and random claims from every report schema, and checked each one against the page image. A second model pass compared each extracted value with the printed value. Disagreements were proposed as corrections and reviewed before being applied.

| Check type (24 reports in the database) | Checked | Errors |
|---|---|---|
| Table cells | 4,369 | 2 |
| Schema claims (report summary diagrams) | 208 | 18 |
| **Total** | **4,577** | **20** |

Twenty-nine corrections were proposed across all validated reports, including reports later excluded:

- **Applied:** seventeen, after review.
- **Rejected:** six.
- **Pending:** six, proposed on 2026-11-10. They concern only the wording of the report schema diagrams and touch no value in the database.

The per-table results are in [`review/validation_report.csv`](../review/validation_report.csv), including the probability that each table's accuracy exceeds 80, 90 and 95 percent. Each CSV header also carries its own validation line.

## 7. Harmonization

Reports name the same quantity differently, for example `failure_load_as_printed`, `p_test_plf` or `W(tot)`. The harmonization step builds an inventory of every report's columns and clusters them into canonical variables. Each variable records its unit, the evidence for it and whether each report has it.

- **Gravity concordance:** 8 reports and 65 canonical variables.
- **Uplift concordance:** 17 reports and 68 canonical variables.

Both are in [`concordance/`](../concordance/). `concordance.html` gives a readable view of each.

## 8. Aggregation

The aggregation step pools the reports of each set into groups of physically comparable tests. A reviewed plan ([`data/gravity/plan.json`](../data/gravity/plan.json), [`data/uplift/plan.json`](../data/uplift/plan.json)) does three things:

- maps each report's columns to the group variables;
- joins supporting tables by test name;
- records constants that a report states in its notes.

The plans were reviewed and edited by hand, and each edit is recorded in the plan's `notes`.

### 8.1 Gravity set

| Group | Tests | Reports (tests) | File |
|---|---|---|---|
| Single-span standing seam base tests | 159 | 9906 (118), 9002 (17), 9610 (15), 8903 (9) | `aggregate_standing_seam_single_span_base_tests.csv` |
| Multi-span continuous lapped assemblies | 24 | 8903 (9), 9804 (7), 9704 (6), 7506 (2) | `aggregate_multi_span_continuous_gravity.csv` |
| Single-span through-fastened assemblies | 7 | 8404 (7) | `aggregate_single_span_through_fastened_gravity.csv` |
| **Strength tests** | **190** | | |
| Tensile coupons (supporting) | 72 | 8404 (30), 8903 (18), 9002 (17), 9804 (7) | `aggregate_tensile_coupons.csv` |
| Measured purlin cross-sections (supporting) | 30 | 8404 (30) | `aggregate_measured_purlin_cross_sections.csv` |
| Computed AISI section properties (supporting) | 30 | 8404 (30) | `aggregate_computed_aisi_section_properties.csv` |

### 8.2 Uplift set

| Group | Tests | Reports (tests) | File |
|---|---|---|---|
| Simple-span through-fastened purlins and girts | 116 | 1103 (50), 9501 (29), 8702 (12), 8310 (9), 8404 (8), 8001 (7), 9003 (1) | `aggregate_simple_span_through_fastened_uplift.csv` |
| Standing seam base and confirming tests | 40 | 9001 (16), 9702 (12), 9102 (8), 9902 (4) | `aggregate_standing_seam_uplift_base_and_confirming.csv` |
| Continuous-span through-fastened purlins | 31 | 8703 (20), 7603 (4), 9105 (3), 7501 (3), 8803 (1) | `aggregate_continuous_span_through_fastened_uplift.csv` |
| Vacuum-box panel fastener pullover tests | 12 | 9410 (12) | `aggregate_panel_fastener_pullover_vacuum_box.csv` |
| **Strength tests** | **199** | | |

### 8.3 Cell provenance

Every pooled CSV has a companion `_provenance.csv` with one code per cell:

- **R** (reported): copied from a table of the report.
- **C** (constant): stated once in the report's notes and applied to every test, for example a purlin spacing.
- **D** (derived): calculated by an exact definition. Examples are a unit conversion (kip-ft to kip-in), a ratio the report defines, or a label decoded from the report's own test-naming scheme.
- **-** (missing): not reported.

### 8.4 Purlin orientation

The reports describe the relative orientation of the two purlin lines in inconsistent words, and the same word can mean opposite things:

- In MBMA 8404, "Facing" means the flanges of a C-purlin pair point toward each other (Table 1.1 sketch, p.7).
- In MBMA 9001, "Facing" marks the tests whose flanges point the same way.

So each report's wording was converted using that report's own definition, and the pooled orientation data sits in three columns:

| Column | Holds |
|---|---|
| `purlin_orientation` | "same direction" or "opposed" |
| `purlin_orientation_as_printed` | the report's own wording |
| `opposed_flange_direction` | "in" or "out", where a report says which way the flanges of an opposed pair point |

### 8.5 Merge audit

Each set has a merge audit (`data/<set>/merge_audit.csv`). It re-derives reported values from the reports' own ratios and checks unit consistency, duplicates and join coverage.

**Gravity:**

- 125 identity checks, none failed.
- Join coverage is 92.5 percent. The gap is three MBMA 9002 test labels printed inconsistently between Table S1 and Table 3.1, a table that supplies no columns.

**Uplift:**

- Join coverage is 99.3 percent. The only unmatched test is MBMA 8703 Test 10, which has no row in Table D and no failure load.
- The audit status reads "FAILED" because of two flags, both reviewed and accepted:
  - The MBMA 1103 line loads do not equal pressure times tributary width, because Eq. 14 adds panel and girt self-weight.
  - The MBMA 9003 failure moment (141.8 kip-in) is flagged as a possible unit error against the much smaller MBMA 1103 girt moments. It is correct: 151.3 × 25² × 12 / 8 = 141.8 kip-in.

## 9. Conventions and limitations

Read these before pooling results across reports.

1. **Dead load.** The reports treat self-weight differently:

   | Treatment | Reports |
   |---|---|
   | Subtract the assembly dead weight | MBMA 8703, 8803 |
   | Include it | MBMA 8404 (gravity), 9906, 9704 |
   | Report the applied chamber load only | MBMA 7603, 8310, 8702, 9001, 9105 |
   | Give the applied load and the load including self-weight in separate columns | MBMA 9804 |

   For this reason, MBMA 9704 failure loads are in `total_load_incl_self_weight_plf`. The member notes in each `plan.json` record the convention for each report.
2. **Load units.**
   - MBMA 7501 and 7506 report failure loads in psf of roof area. MBMA 7501's are approximate text values ("about 40 psf"). These stay in psf columns and are not converted to plf.
   - MBMA 9501 and 9902 report moments only.
3. **Loading method.**
   - MBMA 9902 F1-F4 were loaded by positive pressure on a membrane, not by vacuum.
   - The MBMA 1103 tests are wall girts under suction, tested the same way as the roof purlin tests.
4. **Material properties.**
   - MBMA 9610 lists F_y = 55 ksi for every test in its first series, which appears to be a nominal value. The second series gives values that appear to be measured.
   - Where a report lists several coupon values for one test (MBMA 7501), the list is carried as text.
5. **Hand calculations.** The MBMA 1103 plf line loads are a reviewer's hand calculation from the report's Eq. 14 and are flagged in the CSV header. The printed pressures and moments are carried too.
6. **Predictions.** Predicted loads, moments and R factors follow the specification edition used in each report and are not recomputed.

## 10. Reports in the database

G = gravity set, U = uplift set.

| Report | Title | Authors (year) | Set | Tests |
|---|---|---|---|---|
| 7501 | Continuous Purlin Tests | Peköz (1975) | U | 3 |
| 7506 | Gravity Load Tests of C and Z Purlin Roof Systems | Linehan, Guedelhoefer (1975) | G | 2 |
| 7603 | Wind Uplift Tests of C and Z Purlin Roof Systems | Guedelhoefer, Boggs (1976) | U | 4 |
| 8001 | Ultimate Strength of Cold-Formed Steel Z-Purlins | Razak (1980) | U | 7 |
| 8310 | Laterally Unsupported Purlins Subjected to Uplift | LaBoube (1983) | U | 9 |
| 8404 | Experimental Investigation of C-Purlin Supported Roof Systems | Hendrick, Murray (1984) | G, U | 7 + 8 |
| 8702 | Braced Purlins Subjected to Uplift Load | LaBoube, Thompson (1987) | U | 12 |
| 8703 | MBMA Continuous Purlin Uplift Tests | Perry et al. (1987) | U | 20 |
| 8803 | Discrete Point Bracing Purlin Uplift Research | Golovin, Fisher (1988) | U | 1 |
| 8903 | Evaluation of the Base Test Method (gravity) | Brooks, Murray (1989) | G | 18 |
| 9001 | Base Test Method, Uplift Loading, Phase I | Anderson, Murray (1990) | U | 16 |
| 9002 | Base Test Method for Gravity Loaded Standing Seam Roof Systems | Rayburn, Murray (1990) | G | 17 |
| 9003 | Strength Evaluation of Strut Purlins | Hatch, Easterling, Murray (1990) | U | 1 |
| 9102 | Base Test Method, Uplift Loading, Phase II | Pugh, Murray (1991) | U | 8 |
| 9105 | Multispan C-Purlin Roof Systems Under Uplift Loading | Earls, Pugh, Murray (1991) | U | 3 |
| 9410 | Static Load Tests for Through-Fastened Metal Roof and Wall Systems | Ellifritt, Kreiner (1996) | U | 12 |
| 9501 | Uplift Capacity of Simple Span Cee and Zee Members with Through-Fastened Roof Panels | Fisher (1996) | U | 29 |
| 9610 | Stability of Standing Seam Roof-Purlin Systems | Fisher, Nunnery (1996) | G | 15 |
| 9702 | The Base Test Method for Uplift Loading | Murray (1997) | U | 12 |
| 9704 | Shear Plus Bending in Lapped Z-Purlins | Almoney, Murray (1998) | G | 6 |
| 9804 | Inflection Points as Brace Points in Multi-Span Purlin Roof Systems | Bryant, Murray (1999) | G | 7 |
| 9902 | Axial Strength of Purlins Attached to Standing Seam Roof Panels | Stolarczyk, Fisher (2001) | U | 4 |
| 9906 | Reduced Number of Gravity Loading Base Tests | Trout, Murray (2000) | G | 118 |
| 1103 | Flexural Strength of Exterior Metal Building Wall Assemblies with Rigid Insulation | Gao, Moen (2011) | U | 50 |
