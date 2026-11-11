"""Write docs/decisions.md from docs/report/appendix_questions.csv.
Run from the repository root: python3 docs/report/make_decisions_md.py"""
import csv
rows = list(csv.DictReader(open("docs/report/appendix_questions.csv", encoding="utf-8")))
esc = lambda s: s.replace("|", "\\|").replace("\n", " ")
out = ["# Decisions on the open questions", "",
       "The review raised 100 questions that the extracted tables could not answer on their own. "
       "Each was answered by Cris Moen after checking the report PDF. This page lists every question with the decision "
       "and the date it was made; it is Appendix B of the [assembly report](report/report.pdf). "
       "The same records are in [`review/open_questions.csv`](../review/open_questions.csv). "
       "Questions on reports later excluded from the database are included, because their answers led to the exclusions. "
       "Page numbers are PDF pages unless stated otherwise.", ""]
papers = list(dict.fromkeys(r["paper"] for r in rows))
head = {p: p + (" (report excluded)" if next(r for r in rows if r["paper"] == p)["status"] == "excluded" else "") for p in papers}
slug = lambda h: "".join(c for c in h.lower().replace(" ", "-") if c.isalnum() or c == "-")
out += ["**Reports:** " + ", ".join(f"[{p}](#{slug(head[p])})" for p in papers), ""]
for p in papers:
    rs = [r for r in rows if r["paper"] == p]
    out += [f"## {head[p]}", "",
            "| No. | Question | Decision | Date |", "|---|---|---|---|"]
    out += [f"| {r['id']} | {esc(r['question'])} | {esc(r['decision'])} | {r['date']} |" for r in rs]
    out.append("")
open("docs/decisions.md", "w", encoding="utf-8").write("\n".join(out))
print(len(rows), "questions,", len(papers), "reports")
