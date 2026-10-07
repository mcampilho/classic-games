# Arcade Clássico

Jogos clássicos modernizados, feitos em **Godot 4.4** (GDScript), com builds para **Windows, Linux e Android**.

Primeiro jogo: **Pong (1972)**, em três estilos que partilham exatamente a mesma jogabilidade:

| Estilo | O que é |
|---|---|
| **Clássico 1972** | Fiel ao original: preto e branco, bola quadrada, rede tracejada, marcador em blocos e os três "bips" de onda quadrada. |
| **Neon** | Brilho aditivo, rasto da bola, faíscas, ondas de choque, ecrã a tremer e sons sintetizados que sobem de tom com a velocidade da jogada. |
| **Papel & Tinta** | Um Pong jogado na margem de um caderno: traço a tinta "a ferver", salpicos que ficam no papel, marcador a caneta com círculo vermelho e sons acústicos (madeira, lápis, sino). |

O estilo troca-se em tempo real no menu — a demonstração ao fundo muda logo.

## Abrir o projeto

1. Instala o [Godot 4.4](https://godotengine.org/download) (versão normal, não .NET).
2. No Project Manager: **Import** → escolhe `project.godot`.
3. **F5** para jogar.

## Controlos

| | Jogador 1 (esquerda) | Jogador 2 (direita) |
|---|---|---|
| Teclado | W / S | Setas ↑ / ↓ |
| Comando | Analógico/D-pad do comando 1 | Comando 2 |
| Ecrã tátil | Arrastar na metade esquerda | Arrastar na metade direita |

Contra a CPU qualquer conjunto de teclas controla a tua raquete. **Esc / P / Start** pausa; **F11** ecrã inteiro; no Android o botão "voltar" pausa/volta ao menu.

No ecrã tátil (e com o rato, a arrastar) a raquete segue o dedo em posição absoluta — tal como o botão rotativo da máquina original.

## Regras (iguais ao original)

- Ganha quem chegar primeiro a **11 pontos**.
- A raquete divide-se em **8 segmentos**; cada um devolve a bola com um ângulo fixo (as pontas dão os ângulos mais fechados).
- A bola **acelera após 4 e 12 toques** na mesma jogada.
- O serviço vai para quem sofreu o ponto.

## Estrutura

```
core/                  partilhado por todos os jogos
  main.gd / main.tscn  ecrã inicial (lista de jogos)
  synth.gd             sintetizador: os sons são gerados em código, sem ficheiros de áudio
  ui.gd                tema dos menus gerado a partir da palete de cada estilo
  cycle_button.gd      botão de opções  <  valor  >
  settings.gd          preferências guardadas (user://settings.cfg)
games/pong/
  pong_game.gd         lógica pura do jogo (física, regras, CPU, toque) — emite sinais
  pong_main.gd         menus, pausa, fim de jogo, troca de estilo
  skins/pong_skin.gd   classe base de um estilo (desenho + sons + reação a eventos)
  skins/classic_skin.gd, neon_skin.gd, paper_skin.gd
```

**Criar um novo estilo**: estende `PongSkin`, desenha em `_draw()` a partir de `game` (raquetes, bola, marcador), cria os sons em `_build_sfx()` e acrescenta-o a `SKINS` em `pong_main.gd`.

**Acrescentar um novo jogo**: cria `games/<jogo>/<jogo>_main.gd` (um `Node` com o sinal `exit_requested` e o método `go_back()`) e regista-o em `GAMES` no `core/main.gd`.

Renderizador: *Compatibility* (OpenGL), para correr em PCs antigos e na maioria dos telemóveis Android.

## Builds

Os presets de exportação já estão em `export_presets.cfg` (Windows, Linux, Android).

### No editor
**Project → Export** → escolhe a plataforma → **Export Project**. Da primeira vez o Godot pede para descarregar os *export templates* (Editor → Manage Export Templates).

### Linha de comandos
```bash
./build.sh            # todas
./build.sh windows    # ou linux / android
```
(usa `GODOT=/caminho/para/godot` se o executável não estiver no PATH)

### Android
Precisa de, uma vez: **JDK 17**, **Android SDK** (com *platform-tools* e *build-tools*) e uma keystore de debug — tudo configurado em **Editor → Editor Settings → Export → Android**. Guia oficial: <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html>.
O APK sai assinado com a chave de debug, pronto a instalar (`adb install builds/android/ArcadeClassico.apk`). Para a Play Store será preciso uma keystore de release e o formato AAB (Gradle build).

### Automático (GitHub Actions)
Se puseres o projeto num repositório GitHub, `.github/workflows/builds.yml` gera as três builds a cada push para `main` e deixa-as em **Actions → Artifacts**.

## Próximos jogos (ideias)
Breakout (1976) · Space Invaders (1978) · Asteroids (1979)
