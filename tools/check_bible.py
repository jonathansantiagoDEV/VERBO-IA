"""Confere se um JSON de tradução tem os 66 livros e os capítulos certos.
Uso: python tools/check_bible.py assets/bibles/arc.json
"""
import json, sys, re

CHAPTERS = [50,40,27,36,34,24,21,4,31,24,22,25,29,36,10,13,10,42,150,31,12,8,66,52,5,48,12,14,3,9,1,4,7,3,3,3,2,14,4,
            28,16,24,21,28,16,16,13,6,6,4,4,5,3,6,4,3,1,13,5,5,3,5,1,1,1,22]

raw = open(sys.argv[1], encoding="utf-8-sig").read()
data = json.loads(raw)
books = data["books"] if isinstance(data, dict) else data
ok = True
if len(books) != 66:
    print(f"ERRO: {len(books)} livros (esperado 66)"); sys.exit(1)
verses = 0
for i, b in enumerate(books):
    ch = b["chapters"]
    verses += sum(len(c) for c in ch)
    if len(ch) != CHAPTERS[i]:
        ok = False
        print(f"Livro #{i+1}: {len(ch)} capítulos (esperado {CHAPTERS[i]})")
    for n, c in enumerate(ch, 1):
        if not c:
            ok = False; print(f"Livro #{i+1} cap. {n}: vazio")
print(f"{verses} versículos.", "Tudo certo!" if ok else "Há problemas acima.")
