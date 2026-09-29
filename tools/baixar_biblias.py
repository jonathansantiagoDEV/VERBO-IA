"""Baixa traduções da Bíblia e salva em assets/bibles/ no formato do app.

Rode na raiz do projeto, num computador com internet:
    python tools/baixar_biblias.py            # baixa todas
    python tools/baixar_biblias.py acf kjv    # baixa só as escolhidas

Fonte: repositório público github.com/thiagobodruk/bible (pasta json).
Os direitos das traduções continuam com seus detentores: use para
estudo pessoal e não publique o texto (ex.: Play Store) sem licença.
"""
import json, os, sys, urllib.request

BASE = "https://raw.githubusercontent.com/thiagobodruk/bible/master/json/{}.json"
# id no app -> nome do arquivo no repositório
FONTES = {"acf": "pt_acf", "aa": "pt_aa", "nvi": "pt_nvi", "kjv": "en_kjv"}
DESTINO = os.path.join("assets", "bibles")


def baixar(app_id):
    url = BASE.format(FONTES[app_id])
    print(f"[{app_id}] baixando {url}")
    with urllib.request.urlopen(url, timeout=60) as r:
        raw = r.read().decode("utf-8-sig")
    livros = json.loads(raw)
    if isinstance(livros, dict):
        livros = livros["books"]
    if len(livros) != 66:
        raise ValueError(f"veio com {len(livros)} livros (esperado 66)")
    limpo = [{"abbrev": b.get("abbrev", ""), "chapters": b["chapters"]} for b in livros]
    os.makedirs(DESTINO, exist_ok=True)
    caminho = os.path.join(DESTINO, f"{app_id}.json")
    with open(caminho, "w", encoding="utf-8") as f:
        json.dump(limpo, f, ensure_ascii=False)
    versos = sum(len(c) for b in limpo for c in b["chapters"])
    print(f"[{app_id}] ok: {versos} versículos -> {caminho}")


if __name__ == "__main__":
    ids = sys.argv[1:] or list(FONTES)
    for i in ids:
        if i not in FONTES:
            print(f"[{i}] desconhecida. Opções: {', '.join(FONTES)}")
            continue
        try:
            baixar(i)
        except Exception as e:
            print(f"[{i}] falhou: {e}")
            print("   Baixe o arquivo manualmente em github.com/thiagobodruk/bible (pasta json)")
            print(f"   e salve como assets/bibles/{i}.json")
