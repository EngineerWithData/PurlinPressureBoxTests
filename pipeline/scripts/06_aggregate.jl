# Module 5: pool each set into comparable groups with a merge audit.
include("_env.jl")
using DataAggregator
for set in ("gravity", "uplift")
    # aggregate_papers does not pass max_tokens through. At its defaults (32k, effort "high")
    # the gravity plan came back empty (no groups), the same stub failure the harmonizer's
    # clustering showed. Build the plan here with more room; aggregate_papers then reuses it
    # (resume=true). An empty plan is rejected rather than written.
    input = abspath(joinpath("05_sets", set))
    out = input * "_aggregated"
    plan = joinpath(out, "_plan", "plan.json")
    if !isfile(plan)
        p = DataAggregator.build_plan(DataAggregator.collect_papers(input),
            DataAggregator.read_concordance(input * "_harmonized"), DataAggregator.Client(; timeout=1800), out;
            resume=false, max_tokens=128_000, effort="medium", usage_log=joinpath(out, "_plan"))
        if isempty(get(p, "groups", Any[]))
            mv(plan, plan * ".empty"; force=true)
            error("$set plan came back with no groups; moved to plan.json.empty")
        end
    end
    aggregate_papers(input)
end
