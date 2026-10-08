#!/usr/bin/env python3
"""Gera i18n/strings.gd a partir de i18n/strings.json ({"texto em português": ["english", "español"]}).
As chaves estão escritas como no código-fonte (com \\n, \\" ...)."""
import json, os
here = os.path.dirname(os.path.abspath(__file__))
m = json.load(open(os.path.join(here, "strings.json"), encoding="utf-8"))
def lit(s):
    # as chaves e traduções já vêm com as sequências de escape do GDScript; só falta proteger aspas soltas
    out, i = "", 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            out += s[i:i + 2]; i += 2; continue
        out += '\\"' if c == '"' else ("\\n" if c == "\n" else c)
        i += 1
    return '"' + out + '"'
lines = ['extends RefCounted', '## Gerado por i18n/build.py a partir de i18n/strings.json — não editar à mão.',
         '## Chave: texto original em português; valor: [inglês, espanhol].', '', 'const T := {']
for k in sorted(m):
    en, es = m[k]
    lines.append('\t%s: [%s, %s],' % (lit(k), lit(en), lit(es)))
lines.append('}')
open(os.path.join(here, "strings.gd"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
print(len(m), "textos")
