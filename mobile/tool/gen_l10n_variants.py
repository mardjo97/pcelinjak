from pathlib import Path

base = Path(r"C:\Users\djord\projects\pcelinjak\mobile\lib\l10n")
sr = (base / "app_sr.arb").read_text(encoding="utf-8")

bs = sr.replace('"@@locale": "sr"', '"@@locale": "bs"')
bs = bs.replace("Nesinhronizovani", "Nesinhronizirani")
bs = bs.replace("Izmena pčelinjaka", "Izmjena pčelinjaka")
bs = bs.replace('"edit": "Izmeni"', '"edit": "Izmijeni"')
bs = bs.replace("editInGroup\": \"Izmeni u grupi", "editInGroup\": \"Izmijeni u grupi")
bs = bs.replace("Izmeni košnicu", "Izmijeni košnicu")
bs = bs.replace("Izmeni trenutnu", "Izmijeni trenutnu")
bs = bs.replace("Izmeni maticu", "Izmijeni maticu")
bs = bs.replace("Izmeni (nije dozvoljeno)", "Izmijeni (nije dozvoljeno)")
(base / "app_bs.arb").write_text(bs, encoding="utf-8")

cnr = sr.replace('"@@locale": "sr"', '"@@locale": "cnr"')
(base / "app_cnr.arb").write_text(cnr, encoding="utf-8")

print((base / "app_bs.arb").read_text(encoding="utf-8")[:120])
print("ok")
