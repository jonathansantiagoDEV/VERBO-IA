"""Monta os dados de Strong para o app.

Duas tarefas (rode na raiz do projeto, o primeiro comando precisa de internet):

1) Dicionário Strong completo (hebraico, aramaico e grego):
       python tools/montar_strong.py dicionario
       python tools/montar_strong.py dicionario --pt significados_pt.json

   Baixa o dicionário do projeto Open Scriptures (github.com/openscriptures/strongs,
   texto de Strong em domínio público / dados CC-BY-SA) e grava
   assets/strongs/hebrew.json e assets/strongs/greek.json.
   Vem com original, transliteração, pronúncia, origem e definição EM INGLÊS.
   Se o download falhar, baixe os dois arquivos .js e use:
       python tools/montar_strong.py dicionario --hebraico strongs-hebrew-dictionary.js --grego strongs-greek-dictionary.js

   --pt: JSON {"H1121": "filho, ...", "G3056": "palavra, ..."} com significados
   em português. Eles passam a aparecer no app no lugar do inglês.

2) Bíblia com números Strong:
       python tools/montar_strong.py biblia ORIGEM.json ID
   ORIGEM.json: uma Bíblia (66 livros) em que as palavras trazem o número Strong
   logo depois, como no MySword: "Filho<H1121> meu, atende<H7181>...".
   Também entende {H1121}, [H1121] e <WH1121>. ID vira o arquivo
   assets/bibles/ID.json. IDs que o app já conhece: kjvs, acfs, aras.
   Só use textos que você tem direito de usar (ARA e ACF com Strong têm
   direitos autorais).
"""
import json, os, re, sys, urllib.request

HEB_URL = "https://raw.githubusercontent.com/openscriptures/strongs/master/hebrew/strongs-hebrew-dictionary.js"
GRE_URL = "https://raw.githubusercontent.com/openscriptures/strongs/master/greek/strongs-greek-dictionary.js"
DEST_DIC = os.path.join("assets", "strongs")
DEST_BIB = os.path.join("assets", "bibles")


def ler_js(origem):
    """Lê um módulo .js (var x = {...};) e devolve o objeto como dict."""
    if origem.startswith("http"):
        with urllib.request.urlopen(origem, timeout=90) as r:
            texto = r.read().decode("utf-8-sig")
    else:
        with open(origem, encoding="utf-8-sig") as f:
            texto = f.read()
    i, j = texto.index("{"), texto.rindex("}")
    return json.loads(texto[i:j + 1])


def limpa(v):
    return re.sub(r"\s+", " ", v).strip() if isinstance(v, str) else ""


def converte(dic, prefixo, pt):
    saida = {}
    for chave, e in dic.items():
        num = re.sub(r"\D", "", chave)
        if not num:
            continue
        sid = f"{prefixo}{int(num)}"
        item = {
            "l": limpa(e.get("lemma")),
            "x": limpa(e.get("xlit") or e.get("translit")),
            "p": limpa(e.get("pron")),
            "d": limpa(e.get("derivation")),
            "s": limpa(e.get("strongs_def")),
            "k": limpa(e.get("kjv_def")),
            "t": limpa(pt.get(sid)),
        }
        saida[sid] = {k: v for k, v in item.items() if v}
    return saida


def cmd_dicionario(args):
    def opcao(nome, padrao):
        return args[args.index(nome) + 1] if nome in args else padrao

    pt = {}
    if "--pt" in args:
        with open(args[args.index("--pt") + 1], encoding="utf-8-sig") as f:
            pt = {k.strip().upper(): v for k, v in json.load(f).items()}
    os.makedirs(DEST_DIC, exist_ok=True)
    for nome, prefixo, origem in (
        ("hebrew", "H", opcao("--hebraico", HEB_URL)),
        ("greek", "G", opcao("--grego", GRE_URL)),
    ):
        print(f"[{nome}] lendo {origem}")
        dados = converte(ler_js(origem), prefixo, pt)
        caminho = os.path.join(DEST_DIC, f"{nome}.json")
        with open(caminho, "w", encoding="utf-8") as f:
            json.dump(dados, f, ensure_ascii=False, separators=(",", ":"))
        com_pt = sum(1 for v in dados.values() if "t" in v)
        print(f"[{nome}] {len(dados)} verbetes ({com_pt} com português) -> {caminho}")


TAGS = [
    (re.compile(r"\{([HG])0*(\d+)\}"), r"<\1\2>"),
    (re.compile(r"\[([HG])0*(\d+)\]"), r"<\1\2>"),
    (re.compile(r"<W?([HG])0*(\d+)>"), r"<\1\2>"),
]


def normaliza_verso(v):
    if isinstance(v, dict):
        v = v.get("text", "")
    v = str(v)
    for rx, sub in TAGS:
        v = rx.sub(sub, v)
    return re.sub(r"[ \t]{2,}", " ", v).strip()


def capitulos(livro):
    caps = livro["chapters"]
    for c in caps:
        if isinstance(c, dict):
            c = c.get("verses", [])
        yield [normaliza_verso(v) for v in c]


def cmd_biblia(args):
    if len(args) != 2:
        sys.exit("uso: python tools/montar_strong.py biblia ORIGEM.json ID")
    origem, bid = args
    with open(origem, encoding="utf-8-sig") as f:
        dados = json.load(f)
    livros = dados["books"] if isinstance(dados, dict) else dados
    if len(livros) != 66:
        sys.exit(f"a origem tem {len(livros)} livros (esperado 66, na ordem canônica)")
    saida = [{"abbrev": l.get("abbrev", ""), "chapters": list(capitulos(l))} for l in livros]
    total = com_tag = tags = 0
    for l in saida:
        for c in l["chapters"]:
            for v in c:
                total += 1
                n = len(re.findall(r"<[HG]\d+>", v))
                tags += n
                com_tag += 1 if n else 0
    if tags == 0:
        sys.exit("nenhum número Strong encontrado. Confira o formato "
                 "(esperado: palavra<H1121>).")
    os.makedirs(DEST_BIB, exist_ok=True)
    caminho = os.path.join(DEST_BIB, f"{bid}.json")
    with open(caminho, "w", encoding="utf-8") as f:
        json.dump(saida, f, ensure_ascii=False, separators=(",", ":"))
    print(f"{total} versículos, {com_tag} com Strong, {tags} marcações -> {caminho}")


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in ("dicionario", "biblia"):
        sys.exit(__doc__)
    (cmd_dicionario if sys.argv[1] == "dicionario" else cmd_biblia)(sys.argv[2:])
