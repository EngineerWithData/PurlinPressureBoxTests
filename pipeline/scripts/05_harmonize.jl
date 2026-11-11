# Module 4: split the validated CSVs into gravity and uplift sets, then harmonize each.
# Papers marked "exclude" in selection.csv are left out (re-publications of tests reported
# elsewhere). Each test is counted once, from its original report.
include("_env.jl")
using DataHarmonizer

# Rows to leave out of the sets: tests first published in another selected paper, or tests
# that are not purlin strength tests. tag => (pattern on the file name, pattern on the first
# column, reason). The rows are dropped from the copy and the drop is noted in the header.
const DROP_ROWS = Dict(
    "MBMA_9702" => (r"", r"^\"?U-[ZC]-",
        "Virginia Tech uplift base tests first reported in MBMA_9001 and MBMA_9102; kept there, dropped here"),
    "MBMA_7603" => (r"", r"^\"?Deck shear Test",
        "in-plane deck shear (diaphragm) tests, curves only with no peak loads; not purlin strength tests (open question MBMA_7603-Q05)"),
    "MBMA_9410" => (r"_TableS1_StrengthSummary", r"^\"?1,",
        "Vacuum Box Test 1: problems with the test set-up; no fastener failure, stopped at 0.38 psi when the unbraced purlins rolled and the panels buckled (pp. 50-51, 99)"),
    "MBMA_8803" => (r"_Table[12]_", r"^\"?3,",
        "unbraced reference Test #3 first reported in MBMA_8703 (Test 3); kept there, dropped here (open question MBMA_8803-Q04)"),
    "MBMA_9501" => (r"_Table\d+_RValues", r"^\"?M[12],",
        "proprietary tests from two metal building manufacturers (M1, M2): R only, with no tested load or moment and no panel, fastener, insulation or failure-mode details; not this report's tests (open question MBMA_9501-Q04)"),
    "MBMA_8001" => (r"_Table(S1|3_3)_", r"^\"?B\d,",
        "beam tests B1-B7 (four-point loads through channels joining the bottom flanges, no panel, p.36); the database holds pressure (vacuum) box tests only (review 2026-11-06, Cris Moen)"),
    "MBMA_9902" => (r"_Table(S1|3|4|5|A5_2)_", r"^\"?A\d,",
        "axial tests A1-A4 (hydraulic jack through load beams, no chamber, pp.56-57); the database holds pressure (vacuum) box tests only (review 2026-11-06, Cris Moen)"),
    "MBMA_8404" => (r"", r"^\"?13[ ,*]",
        "Test 13: the authors state the results are not valid (failure caused by an error during construction of the test setup, Sec. 3.3 p.34, Table 3.2 footnote p.36); its coupon, cross-section and property rows go with it (review 2026-11-10, Cris Moen)"),
    "MBMA_9003" => (r"", r"^\"?SP-(?!10C-M\"?,)",
        "every test except SP-10C-M: axial-load-only tests (no vacuum; Table 3.2 and the -0 tests), tests whose data pages are missing from the scanned PDF (SP-8Z-75, SP-8Z-M, SP-10C-50, SP-10Z-M) (review 2026-11-06, Cris Moen), and the combined-load tests SP-8Z-25/50, SP-10Z-25/50/75, SP-10C-25/75 (vacuum held at a preset level, failure under the ram axial load, p.26) (review 2026-11-10, Cris Moen)"),
)

# Whole files to leave out of the sets: file name => reason.
const DROP_FILES = Dict(
    "MBMA_9410_Ellifritt1996_Table4_11_VacuumBoxTest1.csv" =>
        "Vacuum Box Test 1 time history; the test is left out (see DROP_ROWS)",
    "MBMA_8001_Razak1980_Table4_7_BeamTestLoadRatios.csv" =>
        "computed load ratios for the beam tests B1-B7, which are left out (see DROP_ROWS)",
    "MBMA_9003_Hatch1990_Table3_2_AxialLoadVerification.csv" =>
        "axial-load-only verification tests, left out (review 2026-11-06)",
    "MBMA_9003_Hatch1990_Table3_3_ScrewLocationEffect.csv" =>
        "computed axial capacities for the verification tests, left out (review 2026-11-06)",
    "MBMA_9003_Hatch1990_Table3_4_RotationalStiffnessTests.csv" =>
        "component rotational-stiffness (F) tests, not pressure box tests (review 2026-11-06)",
    "MBMA_9003_Hatch1990_TableD_1_FormFactorSummary.csv" =>
        "computed form factors for axial-only tests, left out (review 2026-11-06)",
    "MBMA_9902_Stolarczyk2001_Table1_AxialTestResults.csv" =>
        "axial test results A1-A4; the axial tests and FEM analyses are left out (review 2026-11-06)",
    "MBMA_9902_Stolarczyk2001_Table6_FemVsExpAxial.csv" =>
        "FEM vs. axial tests A1-A4; the axial tests and FEM analyses are left out (review 2026-11-06)",
    "MBMA_9902_Stolarczyk2001_Table8_PredictedAxialFromFlexural.csv" =>
        "predicted axial capacity (analysis); the axial tests and FEM analyses are left out (review 2026-11-06)",
    "MBMA_9902_Stolarczyk2001_Table9_PredictedVsTestedAxial.csv" =>
        "predicted vs. tested axial A1-A4; the axial tests and FEM analyses are left out (review 2026-11-06)",
    "MBMA_9902_Stolarczyk2001_TableA2_FemElasticBucklingResults.csv" =>
        "FEM elastic buckling analysis results, not tests; the axial tests and FEM analyses are left out (review 2026-11-06)",
    "MBMA_9902_Stolarczyk2001_TableA3_FemCorrectedResults.csv" =>
        "corrected FEM analysis results, not tests; the axial tests and FEM analyses are left out (review 2026-11-06)",
    "MBMA_9902_Stolarczyk2001_TableA5_1_AxialLoadEccentricity.csv" =>
        "axial test A1-A4 load eccentricity; the axial tests and FEM analyses are left out (review 2026-11-06)",
    "MBMA_9902_Stolarczyk2001_TableA5_3_AxialTestDialGages.csv" =>
        "axial test A1-A4 dial gage readings; the axial tests and FEM analyses are left out (review 2026-11-06)",
    "MBMA_9902_Stolarczyk2001_TableA5_4_AxialTestStrainGages.csv" =>
        "axial test A1-A4 strain gage readings; the axial tests and FEM analyses are left out (review 2026-11-06)",
)

function copy_csv(src, dest, tag)
    haskey(DROP_ROWS, tag) || return cp(src, dest; force=true)
    file, pat, why = DROP_ROWS[tag]
    occursin(file, basename(src)) || return cp(src, dest; force=true)
    lines = readlines(src)
    body = findfirst(l -> !startswith(l, "#"), lines)          # column header line
    keep = [l for (i, l) in enumerate(lines) if i <= something(body, 0) || !occursin(pat, l)]
    n = length(lines) - length(keep)
    n > 0 && body !== nothing && insert!(keep, body, "# ROWS REMOVED: $n row(s) — $why")
    write(dest, join(keep, "\n") * "\n")
end

sel = read_selection()
csvs = filter(f -> endswith(f, ".csv") && !haskey(DROP_FILES, f), readdir("02_extracted"))
for set in ("gravity", "uplift")
    for (tag, lt) in sel
        (lt == set || lt == "both") || continue
        dest = joinpath("05_sets", set, tag)
        mkpath(dest)
        for f in filter(f -> startswith(f, tag * "_"), csvs)
            copy_csv(joinpath("02_extracted", f), joinpath(dest, f), tag)
        end
    end
    # harmonize_papers does not pass max_tokens through, and the default 16k truncated the
    # MBMA_8201 inventory (13 tables). Build the inventories first with more room; the
    # harmonize_papers call below then reuses them (resume=true).
    input = abspath(joinpath("05_sets", set))
    client = DataHarmonizer.Client(; timeout=1800)
    logdir = joinpath(input * "_harmonized", "_inventories")
    invs = DataHarmonizer.build_inventories(DataHarmonizer.collect_papers(input), client,
        input * "_harmonized"; usage_log=logdir, max_tokens=64_000)
    # Same for the clustering call: its 32k default truncated the uplift set. Cluster here with
    # more room and write harmonization.json, which harmonize_papers then reuses. A clustering
    # that comes back as a "placeholder" stub is rejected rather than written.
    hfile = joinpath(logdir, "harmonization.json")
    if !isfile(hfile)
        # 64k at effort "high" still truncated the gravity set (reasoning counts against the
        # output budget), so the clustering runs at 128k and effort "medium".
        p, resp = DataHarmonizer.cluster_inventories(invs, client; max_tokens=128_000, effort="medium")
        DataHarmonizer.log_usage!(logdir, "ALL", "cluster", DataHarmonizer.usage_tuple(resp))
        names = [get(v, "name", "") for v in get(p, "canonical_variables", Any[])]
        (length(names) < 2 || "placeholder" in names) &&
            error("$set clustering returned a stub ($(length(names)) variables: $(join(names, ", "))); not written")
        open(io -> DataHarmonizer.JSON.print(io, p, 2), hfile, "w")
    end
    harmonize_papers(joinpath("05_sets", set))
end
