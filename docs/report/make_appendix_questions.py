"""Write report/appendix_questions.csv from 03_context/open_questions.csv for Appendix B.
Run from the project folder: python3 report/make_appendix_questions.py"""
import csv
L = [l for l in open("03_context/open_questions.csv", encoding="utf-8").read().splitlines() if not l.startswith("#")]
rows = list(csv.DictReader(L))
sel = {l.split(",")[0]: l.split(",")[1] for l in open("02_selection/selection.csv", encoding="utf-8").read().splitlines()[1:]}
rows.sort(key=lambda r: (r["paper"][5:7] < "70", r["paper"], r["question_id"]))  # 1103 after 9906, as in Appendix A
with open("report/appendix_questions.csv", "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f)
    w.writerow(["paper", "status", "id", "question", "decision", "date"])
    for r in rows:
        w.writerow([r["paper"].replace("MBMA_", "MBMA "), "excluded" if sel.get(r["paper"]) == "exclude" else "in database",
                    r["question_id"].split("-")[-1], r["question"].strip(), r["answer"].strip(), r["answered_on"]])
print(len(rows), "questions written")
