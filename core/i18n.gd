class_name I18n
extends RefCounted
## Traduções: o texto original (português) é a chave; i18n/strings.gd tem o inglês e o espanhol.
## I18n.t("Jogar") devolve o texto no idioma escolhido (ou o original, se não houver tradução).
## Os Label/Button também se traduzem sozinhos quando o texto é exatamente uma chave.

const LANGS := ["pt", "en", "es"]
const LANG_NAMES := ["Português", "English", "Español"]
const STRINGS := preload("res://i18n/strings.gd")

static var lang := "pt"
static var _ready := false


## Idioma do sistema, se for um dos suportados (senão inglês).
static func system_lang() -> String:
	var l := OS.get_locale_language()
	return l if l in LANGS else "en"


static func setup(p_lang: String) -> void:
	lang = p_lang if p_lang in LANGS else "en"
	if not _ready:
		_ready = true
		for i in range(1, LANGS.size()):
			var tr := Translation.new()
			tr.locale = LANGS[i]
			for k: String in STRINGS.T:
				var v: Array = STRINGS.T[k]
				if v.size() >= i and String(v[i - 1]) != "":
					tr.add_message(k, v[i - 1])
			TranslationServer.add_translation(tr)
	TranslationServer.set_locale(lang)


static func t(s: String) -> String:
	if lang == "pt":
		return s
	return String(TranslationServer.translate(s))
