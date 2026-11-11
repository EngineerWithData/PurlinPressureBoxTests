// ─── PROJECT INFO ─────────────────────────────────────────────────
#let _project_title = "MBMA Purlin Pressure Box Test Database"
#let _project_sub   = "Assembly of full-scale vacuum and pressure chamber purlin tests from MBMA research reports"
#let _report_date   = "November 2026"
// ──────────────────────────────────────────────────────────────────

#show link: underline

#set page(
  paper: "us-letter",
  number-align: center,
  margin: (top: 1in, bottom: 1in),
)

#set par(justify: true, leading: 8pt)
#set heading(numbering: "1.")
#set text(style: "normal")
#show math.equation: math.upright

#show outline.entry.where(level: 1): it => {
  v(12pt, weak: true)
  strong(it)
}

#show heading: set block(above: 24pt, below: 12pt)
#show figure.where(kind: table): set figure.caption(position: top)
#show figure: set block(breakable: true)
#show table: set par(justify: false)
#show table: set text(size: 10pt)

// compact data table: header row shaded
#let dtable(cols, ..cells) = table(
  columns: cols,
  stroke: 0.5pt,
  inset: (x: 5pt, y: 4pt),
  align: left,
  fill: (x, y) => if y == 0 { luma(230) },
  ..cells,
)

#set page(numbering: none)

#place(
  right,
  text(26pt, weight: "bold", hyphenate: false)[#_project_title],
  dy: 8%,
)

#place(
  right,
  box(width: 75%, align(right, text(14pt, hyphenate: false)[#_project_sub])),
  dy: 22%,
)

#place(right, text(14pt)[Report by: EngineerWithData.org], dy: 40%)
#place(right, text(12pt)[#_report_date], dy: 50%)

#align(right + bottom)[
  #image("figures/turtles_logo.jpeg", width: 30%)
]

#pagebreak()
#set page(numbering: "1")
#outline(
  title: [Table of Contents],
  target: heading.where(outlined: true),
  indent: auto,
)

#pagebreak()

= Introduction

This report documents how a database of full-scale cold-formed steel purlin and girt strength tests was assembled from the Metal Building Manufacturers Association (MBMA) research report library. The database holds tests in which a roof or wall assembly was loaded by air pressure in a sealed chamber, either by evacuating the chamber (vacuum) or by pressurizing it, until the purlins or girts failed. Tests loaded by concrete blocks, hydraulic jacks, point loads or axial rams are left out.

The database contains 389 strength tests from 24 MBMA reports published between 1975 and 2011, in two sets:

- *Gravity set:* 190 tests from 8 reports, plus 132 rows of supporting coupon and cross-section data.
- *Uplift set:* 199 tests from 17 reports.

MBMA 8404 contributes to both sets: its gravity tests are in the gravity set and its uplift tests in the uplift set, so no test is counted twice.

Every value in the database can be traced to a page of the source report. Measured test results are carried as printed. Calculated predictions printed in the reports are carried as legacy values, also as printed, and are labelled as predictions. Values that a report does not state are left blank rather than inferred.

= Workflow

The database was built with a six-step pipeline. Each step is a script in the project `scripts/` folder, run as `julia --project=. scripts/<step>.jl`. Steps that read the reports call a large language model (Anthropic Claude) on page images; every step that changes a value is followed by engineering review.

#figure(
  dtable(
    (auto, 1fr, 1.4fr),
    [*Step*], [*What it does*], [*Output*],
    [1. Sort], [Sorts the 445 reports of the MBMA library by theme, topic and subtopic.], [`01_sorted/index.csv`],
    [1b. Select], [Selects the reports that contain full-scale pressure box purlin or girt strength tests and assigns each to the gravity set, the uplift set, or both.], [`02_selection/selection.csv`],
    [2. Extract], [Reads every page as an image and transcribes each data table to CSV, with column definitions, units, page numbers and notes in a comment header. Builds a standardized strength summary (Table S1) for each report.], [`02_extracted/*.csv`],
    [3. Context], [Writes a brief for each report and lists the questions the reports themselves cannot answer (tributary width, dead load, units, duplicates).], [`03_context/`],
    [4. Validate], [Draws random cells and claims and checks each one against the page image.], [`02_extracted/validation/`],
    [5. Harmonize], [Matches equivalent columns across reports (variable concordance).], [`05_sets/*_harmonized/`],
    [6. Aggregate], [Pools the reports into groups of comparable tests and audits the merge.], [`05_sets/*_aggregated/`],
  ),
  caption: [Pipeline steps],
) <tab_pipeline>

= Report selection

== Library sort

The MBMA library holds 445 reports. The sort placed 77 of them under purlin and girt (secondary framing) research, separating full-scale tests under gravity and uplift, base-test-method reports, scale-model tests, brace-force studies and analytical work. The candidate reports were taken from the full-scale test topics and from a later sweep of the library for reports with pressure box tests that the first pass had not selected.

== Selected and excluded reports

Thirty-five reports were reviewed. Twenty-four are in the database (Appendix A). Eleven were excluded for the reasons in @tab_excluded.

#figure(
  dtable(
    (auto, 1fr),
    [*Report*], [*Reason for exclusion*],
    [MBMA 8002], [Concrete-block loading.],
    [MBMA 8201], [Concrete-block loading (33 lb blocks).],
    [MBMA 8302], [Concrete-block loading.],
    [MBMA 8802], [Concrete-block loading; its 13 tests are the Rivard and Murray tests reported as data from a previous project.],
    [MBMA 8102], [Analytical study; its Table 5.1 re-lists the MBMA 7603 tests.],
    [MBMA 8203], [Observer report of the 12 tests published in MBMA 8702.],
    [MBMA 8401], [Re-publication of the nine MBMA 8310 Butler vacuum-chamber uplift tests (Appendix A, Table 2, p.29).],
    [MBMA 8309], [Edge-stiffener study on a narrow two-purlin specimen (purlins 18 in. apart under a 34 in. panel, Fig. 3); failure moments only, with no panel, fastening or bracing description.],
    [MBMA 1205], [Dissertation; Ch. 3 republishes the MBMA 1103 tests and Ch. 4 compiles other programs' tests.],
    [MBMA 1206], [Journal version of the MBMA 1103 tests.],
    [MBMA 1207], [Rotational restraint (stiffness) tests, not flexural strength tests.],
  ),
  caption: [Excluded reports],
) <tab_excluded>

== Tests left out of selected reports

Some selected reports also contain tests that do not belong in the database. These rows stay in the extracted CSV files as the record of the report but are removed before the sets are pooled. Each removal is written into the header of the pooled copy.

#figure(
  dtable(
    (auto, 1fr),
    [*Report*], [*Tests left out and reason*],
    [MBMA 7603], [In-plane deck shear (diaphragm) tests: load--deflection curves only, not purlin strength tests.],
    [MBMA 8001], [Beam tests B1--B7: four-point loads through channels joining the bottom flanges, no panel (p.36).],
    [MBMA 8404], [Test 13: the authors state its results are not valid because of an error in constructing the test setup (Sec. 3.3, p.34; Table 3.2 footnote). Its coupon and cross-section rows are also removed.],
    [MBMA 8803], [Test 3, the unbraced reference test first reported in MBMA 8703.],
    [MBMA 9003], [All tests except SP-10C-M: the axial-load-only tests, the combined uplift-plus-axial tests (the vacuum was held at a preset level and the specimen failed under the axial ram load, p.26), and tests whose data pages are missing from the scan.],
    [MBMA 9410], [Vacuum Box Test 1: set-up problems; no fastener failure (pp.50--51).],
    [MBMA 9501], [Proprietary manufacturer tests M1 and M2: R factor only, with no load, moment or assembly details.],
    [MBMA 9702], [Virginia Tech uplift base tests first reported in MBMA 9001 and MBMA 9102.],
    [MBMA 9902], [Axial tests A1--A4: hydraulic jack through load beams, no chamber (pp.56--57).],
  ),
  caption: [Tests removed from selected reports],
) <tab_droprows>

= Data extraction

Each report was converted to page images and transcribed table by table. The transcription keeps every printed value as printed, including units, footnote markers and unreadable characters, which are marked `[?]`. Each CSV file opens with a comment header that gives the source, the page numbers, a definition and unit for every column, the extraction quality, and notes on anomalies.

For every report the extraction also built a standardized strength summary, Table S1. It has one row per test with the same leading columns in every report:

#align(center)[
  `test_id, load_direction, section_type, depth_in, thickness_in, span_ft, n_spans, n_purlin_lines, panel_type, bracing, failure_load_as_printed, failure_load_unit, failure_moment_as_printed, failure_moment_unit, failure_mode, value_source, pages`
]

Report-specific columns, such as yield stress, predicted loads, R factors and chamber pressures, follow these. Table S1 is the primary table that the pooled groups are built from; the other tables of a report are joined to it by test name.

= Engineering review

Every selected report was reviewed against the PDF. The review followed four rules:

+ *Measured values are used.* Where a report gives both nominal and measured dimensions or material properties, the measured values go in the main columns and the nominal values are kept in separate `_nominal` columns.
+ *Predictions are legacy values.* Predicted capacities, R factors computed by the authors and test-to-predicted ratios are carried exactly as printed.
+ *Nothing is inferred.* A value the report does not state is left blank. A value derived by hand is flagged as a hand calculation and its equation is given.
+ *Corrections are documented.* An apparent typographical error is corrected only after review, and the correction is recorded in a `# CORRECTED` note in the CSV header together with the page reference.

The context step raised 100 open questions that could not be settled from the extracted tables alone. All 100 were answered in review. The answers, with the date and the reviewer, are in `03_context/open_questions.csv`, and each answer that changed a value is also recorded as a `# REVIEW` note in the header of the affected CSV file. @tab_decisions lists the decisions that most affect how the data can be used; Appendix B gives the decision for every question.

#figure(
  dtable(
    (auto, 1fr),
    [*Report*], [*Decision*],
    [MBMA 1103], [Measured girt thickness (Table 7) replaces the nominal footnote value. The tributary width is $L_p slash 2 = 6.79$ ft from Eq. 14, not the 3 ft panel width stated in the extraction. A line load in plf is added as a hand calculation from Eq. 14, which includes panel and girt self-weight.],
    [MBMA 7501], [The three continuous-span assemblies are uplift tests and are in the uplift set. The First and Second Z assemblies are distinct tests: the second was built with straightened purlins.],
    [MBMA 8001], [Measured depth and thickness (Table 3.2) replace the nominal Table 3.3 values. V1 had fixed ends.],
    [MBMA 8404], [Test 13 is removed (see @tab_droprows).],
    [MBMA 9003], [Only SP-10C-M is kept; it includes about 9 plf of roof-system dead weight.],
    [MBMA 9610], [$W_"tot"$ is the line load on one purlin line ($M_t = W L^2 slash 8$ reproduces every printed $M_t$). No duplicates of these tests were found in any other report.],
    [MBMA 9704], [The printed failure loads include purlin self-weight (8 plf; 12 plf for FV20-3, doubled panel). FV20-4 is kept as printed although its pressure conversion uses 5.0 rather than 5.2 psf per inch of water. FV20-1 and FV20-2 had their top flanges pointing out; the other tests pointed in.],
    [MBMA 9902], [F1--F4 are kept. They were loaded by positive air pressure acting on a membrane under the panel rather than by vacuum, and the data may come from manufacturers' existing base tests (p.50).],
  ),
  caption: [Review decisions with the largest effect on the data],
) <tab_decisions>

= Validation

The validation step drew random cells from every table and random claims from every report schema, and checked each one against the page image. A second model pass compared each extracted value with the printed value; disagreements were proposed as corrections and reviewed before they were applied.

#figure(
  dtable(
    (1fr, auto, auto),
    [*Check type*], [*Checked*], [*Errors*],
    [Table cells], [4,369], [2],
    [Schema claims (report summary diagrams)], [208], [18],
    [*Total*], [*4,577*], [*20*],
  ),
  caption: [Validation results for the 24 reports in the database],
) <tab_validation>

Twenty-nine corrections were proposed across all validated reports, including reports later excluded. Seventeen were applied after review, six were rejected, and six proposed on 2026-11-10 concern only the wording of the report schema diagrams and are not yet applied. None of the six pending corrections touches a value in the database. A per-table summary, with the probability that each table's accuracy exceeds 80, 90 and 95 percent, is in `02_extracted/validation/validation_report.csv`, and each CSV header carries its own validation line.

= Harmonization

Reports name the same quantity differently, for example `failure_load_as_printed`, `p_test_plf` or `W(tot)`. The harmonization step builds an inventory of the columns of every report in a set and clusters them into canonical variables, with the unit, the evidence and the availability in each report. The gravity concordance covers 8 reports and 65 canonical variables; the uplift concordance covers 17 reports and 68. Both are in `05_sets/*_harmonized/` together with an HTML view.

= Aggregation

The aggregation step pools the reports of each set into groups of physically comparable tests. A reviewed plan (`05_sets/*_aggregated/_plan/plan.json`) maps each report's columns to the group variables, joins supporting tables by test name, and records constants that a report states in its notes. The plan was reviewed and edited by hand; each hand edit is recorded in the plan's notes.

== Gravity set

#figure(
  dtable(
    (1fr, auto, 1.3fr),
    [*Group*], [*Tests*], [*Reports (tests)*],
    [Single-span standing seam base tests], [159], [9906 (118), 9002 (17), 9610 (15), 8903 (9)],
    [Multi-span continuous lapped assemblies], [24], [8903 (9), 9804 (7), 9704 (6), 7506 (2)],
    [Single-span through-fastened assemblies], [7], [8404 (7)],
    [*Strength tests*], [*190*], [],
    [Tensile coupons (supporting)], [72], [8404 (30), 8903 (18), 9002 (17), 9804 (7)],
    [Measured purlin cross-sections (supporting)], [30], [8404 (30)],
    [Computed AISI section properties (supporting)], [30], [8404 (30)],
  ),
  caption: [Gravity set groups],
) <tab_gravity>

== Uplift set

#figure(
  dtable(
    (1fr, auto, 1.3fr),
    [*Group*], [*Tests*], [*Reports (tests)*],
    [Simple-span through-fastened purlins and girts], [116], [1103 (50), 9501 (29), 8702 (12), 8310 (9), 8404 (8), 8001 (7), 9003 (1)],
    [Standing seam base and confirming tests], [40], [9001 (16), 9702 (12), 9102 (8), 9902 (4)],
    [Continuous-span through-fastened purlins], [31], [8703 (20), 7603 (4), 9105 (3), 7501 (3), 8803 (1)],
    [Vacuum-box panel fastener pullover tests], [12], [9410 (12)],
    [*Strength tests*], [*199*], [],
  ),
  caption: [Uplift set groups],
) <tab_uplift>

== Cell provenance

Every pooled CSV has a companion `_provenance.csv` with one code per cell:

- *R* (reported): copied from a table of the report.
- *C* (constant): stated once in the report's notes and applied to every test, for example a purlin spacing.
- *D* (derived): calculated by an exact definition, such as a unit conversion (kip-ft to kip-in), a ratio the report defines, or a label decoded from the report's own test-naming scheme.
- blank: not reported.

== Purlin orientation

The reports describe the relative orientation of the two purlin lines in inconsistent words. The same word can mean opposite things: in MBMA 8404 "Facing" means the flanges of a C-purlin pair point toward each other (Table 1.1 sketch, p.7), whereas in MBMA 9001 "Facing" marks the tests whose flanges point the same way. The pooled column `purlin_orientation` therefore holds only "same direction" or "opposed", converted report by report from each report's own definition. The printed wording is kept in `purlin_orientation_as_printed`, and `opposed_flange_direction` gives "in" or "out" where a report states which way the flanges of an opposed pair point.

== Merge audit

Each set has a merge audit (`merge_audit.csv`) that re-derives reported values from the reports' own ratios and checks unit consistency, duplicates and join coverage.

- *Gravity:* 125 identity checks, none failed. Join coverage is 92.5 percent; the remaining gap is three MBMA 9002 test labels printed inconsistently between Table S1 and Table 3.1, a table from which no columns are taken.
- *Uplift:* join coverage is 99.3 percent; the only test without a match is MBMA 8703 Test 10, which has no row in Table D and no failure load. The audit status reads "FAILED" because of two flags, both reviewed and accepted. First, the MBMA 1103 line loads do not equal pressure times tributary width, because Eq. 14 adds panel and girt self-weight. Second, the MBMA 9003 failure moment (141.8 kip-in) is flagged as a possible unit error against the much smaller MBMA 1103 girt moments; it is correct ($151.3 times 25^2 times 12 slash 8 = 141.8$ kip-in).

= Conventions and limitations

Users of the database should note the following before pooling results across reports.

+ *Dead load.* The reports treat self-weight differently. MBMA 8703 and 8803 subtract the assembly dead weight; MBMA 8404 (gravity), 9906 and 9704 include it; MBMA 7603, 8310, 8702, 9001 and 9105 report the applied chamber load only; MBMA 9804 reports the applied load and the load including self-weight in separate columns. MBMA 9704 failure loads are carried in `total_load_incl_self_weight_plf` for this reason. The group notes in each plan record the convention for each report.
+ *Load units.* MBMA 7501 and 7506 report failure loads in psf of roof area, and MBMA 7501's are approximate text values ("about 40 psf"). These are carried in psf columns and are not converted to plf. MBMA 9501 and 9902 report moments only.
+ *Loading method.* MBMA 9902 F1--F4 were loaded by positive pressure on a membrane, not by vacuum. MBMA 1103 tests are wall girts under suction, tested the same way as the roof purlin tests.
+ *Material properties.* MBMA 9610 lists $F_y = 55$ ksi for every test of its first series, which appears to be a nominal value; the second series gives values that appear to be measured. Where a report lists several coupon values for one test (MBMA 7501), the list is carried as text.
+ *Hand calculations.* The MBMA 1103 plf line loads are a reviewer's hand calculation from the report's Eq. 14, flagged in the CSV header; the printed pressures and moments are also carried.
+ *Predictions.* Predicted loads, moments and R factors follow the specification edition used in each report and are not recomputed.

= Data files

#figure(
  dtable(
    (auto, 1fr),
    [*Location*], [*Contents*],
    [`02_selection/selection.csv`], [Every reviewed report with its set assignment or exclusion reason.],
    [`02_extracted/`], [Extracted tables for every selected report, with comment headers, review notes and corrections.],
    [`02_extracted/validation/`], [Validation checks, scores and proposed corrections.],
    [`03_context/`], [Report briefs, glossary, reuse caveats and the 100 answered open questions.],
    [`05_sets/gravity_aggregated/`, `05_sets/uplift_aggregated/`], [Pooled group CSVs, provenance, merge audit, variable statistics, the reviewed plan and an HTML overview (`aggregation.html`).],
  ),
  caption: [Database files (project folder `Moen_purlin_testing_pull_October_2026`)],
) <tab_files>

#pagebreak()

#heading(numbering: none)[Appendix A: Reports in the database]

#figure(
  dtable(
    (auto, 1.6fr, 1fr, auto, auto),
    [*Report*], [*Title*], [*Authors (year)*], [*Set*], [*Tests*],
    [7501], [Continuous Purlin Tests], [Peköz (1975)], [U], [3],
    [7506], [Gravity Load Tests of C and Z Purlin Roof Systems], [Linehan, Guedelhoefer (1975)], [G], [2],
    [7603], [Wind Uplift Tests of C and Z Purlin Roof Systems], [Guedelhoefer, Boggs (1976)], [U], [4],
    [8001], [Ultimate Strength of Cold-Formed Steel Z-Purlins], [Razak (1980)], [U], [7],
    [8310], [Laterally Unsupported Purlins Subjected to Uplift], [LaBoube (1983)], [U], [9],
    [8404], [Experimental Investigation of C-Purlin Supported Roof Systems], [Hendrick, Murray (1984)], [G, U], [7 + 8],
    [8702], [Braced Purlins Subjected to Uplift Load], [LaBoube, Thompson (1987)], [U], [12],
    [8703], [MBMA Continuous Purlin Uplift Tests], [Perry et al. (1987)], [U], [20],
    [8803], [Discrete Point Bracing Purlin Uplift Research], [Golovin, Fisher (1988)], [U], [1],
    [8903], [Evaluation of the Base Test Method (gravity)], [Brooks, Murray (1989)], [G], [18],
    [9001], [Base Test Method, Uplift Loading, Phase I], [Anderson, Murray (1990)], [U], [16],
    [9002], [Base Test Method for Gravity Loaded Standing Seam Roof Systems], [Rayburn, Murray (1990)], [G], [17],
    [9003], [Strength Evaluation of Strut Purlins], [Hatch, Easterling, Murray (1990)], [U], [1],
    [9102], [Base Test Method, Uplift Loading, Phase II], [Pugh, Murray (1991)], [U], [8],
    [9105], [Multispan C-Purlin Roof Systems Under Uplift Loading], [Earls, Pugh, Murray (1991)], [U], [3],
    [9410], [Static Load Tests for Through-Fastened Metal Roof and Wall Systems], [Ellifritt, Kreiner (1996)], [U], [12],
    [9501], [Uplift Capacity of Simple Span Cee and Zee Members with Through-Fastened Roof Panels], [Fisher (1996)], [U], [29],
    [9610], [Stability of Standing Seam Roof--Purlin Systems], [Fisher, Nunnery (1996)], [G], [15],
    [9702], [The Base Test Method for Uplift Loading], [Murray (1997)], [U], [12],
    [9704], [Shear Plus Bending in Lapped Z-Purlins], [Almoney, Murray (1998)], [G], [6],
    [9804], [Inflection Points as Brace Points in Multi-Span Purlin Roof Systems], [Bryant, Murray (1999)], [G], [7],
    [9902], [Axial Strength of Purlins Attached to Standing Seam Roof Panels], [Stolarczyk, Fisher (2001)], [U], [4],
    [9906], [Reduced Number of Gravity Loading Base Tests], [Trout, Murray (2000)], [G], [118],
    [1103], [Flexural Strength of Exterior Metal Building Wall Assemblies with Rigid Insulation], [Gao, Moen (2011)], [U], [50],
  ),
  caption: [Reports in the database (G = gravity set, U = uplift set)],
) <tab_reports>

#pagebreak()

#heading(numbering: none)[Appendix B: Decisions on the open questions]

The context step raised 100 questions that the extracted tables could not answer on their own. Each was answered by Cris Moen after checking the report; the answer below is the decision as recorded in `03_context/open_questions.csv`, with the date it was made. Questions on reports that were later excluded from the database (see @tab_excluded) are listed too, because their answers led to the exclusions. Page numbers are PDF pages unless stated otherwise.

// Table built from appendix_questions.csv (written by make_appendix_questions.py)
#let _qs = csv("appendix_questions.csv", row-type: dictionary)
#let _papers = _qs.map(r => r.paper).dedup()

// let long file names and identifiers break after underscores
#let _brk(s) = s.replace("_", "_\u{200B}").replace("/", "/\u{200B}")

#for p in _papers {
  let rows = _qs.filter(r => r.paper == p)
  let status = if rows.first().status == "excluded" [ (report excluded)] else []
  block(above: 16pt, below: 6pt, sticky: true, text(11pt, weight: "bold")[#p#status])
  table(
    columns: (auto, 1fr, 1fr),
    stroke: 0.5pt,
    inset: (x: 5pt, y: 4pt),
    align: left,
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*No.*], [*Question*], [*Decision*]),
    ..rows.map(r => ([#r.id \ #text(8pt, fill: luma(90))[#r.date]], [#_brk(r.question)], [#_brk(r.decision)])).flatten(),
  )
}
