# Classic Arcade

*[Versão em português](README.pt.md)*

### ▶ [Play in your browser](https://mcampilho.github.io/classic-games/)

**18 original games inspired by the classics of the 70s, 80s and 90s**, made with **Godot 4.7** (GDScript), with builds for **Windows, Linux and Android**.

Every game has three visual styles — one faithful to the look of its era, one modern and popular (neon, cartoon...) and one created from scratch for this project — that share exactly the same gameplay and can be switched live from the menu. All graphics, sound effects and music are generated in code: there are no image or audio files.

On the launcher, a footer shows the classic that inspired the focused (or hovered) game, a short history and a link to Wikipedia. On touch screens, where tapping a game opens it straight away, an **i** button next to each game does the same.

The game is available in **English, Portuguese and Spanish** — it follows the system language and can be changed on the launcher ("Idioma / Language").

![Classic Arcade launcher](docs/screenshots/launcher.jpg)

## The games

| Game | Inspired by | Styles |
|---|---|---|
| [**Paddles**](#paddles-1972) (1972) | [Pong](https://en.wikipedia.org/wiki/Pong) (Atari, 1972) | Classic 1972 · Neon · Paper & Ink |
| [**Brick Breaker**](#brick-breaker-1976) (1976) | [Breakout](https://en.wikipedia.org/wiki/Breakout_(video_game)) (Atari, 1976) | Classic 1976 · Neon · Stained Glass |
| [**Alien Attack**](#alien-attack-1978) (1978) | [Space Invaders](https://en.wikipedia.org/wiki/Space_Invaders) (Taito, 1978) | Classic 1978 · Neon · Azulejo (Portuguese tiles) |
| [**Meteors**](#meteors-1979) (1979) | [Asteroids](https://en.wikipedia.org/wiki/Asteroids_(video_game)) (Atari, 1979) | Classic 1979 · Neon · Origami |
| [**Swarm**](#swarm-1979) (1979) | [Galaxian](https://en.wikipedia.org/wiki/Galaxian) (Namco, 1979) | Classic 1979 · Neon · Ocean |
| [**Firefly**](#firefly-1980) (1980) | [Pac-Man](https://en.wikipedia.org/wiki/Pac-Man) (Namco, 1980) | Arcade 1980 · Neon · Shadow Theatre |
| [**The Crossing**](#the-crossing-1981) (1981) | [Frogger](https://en.wikipedia.org/wiki/Frogger) (Konami, 1981) | Classic 1981 · Neon · Felt |
| [**Mushrooms**](#mushrooms-1981) (1981) | [Centipede](https://en.wikipedia.org/wiki/Centipede_(video_game)) (Atari, 1981) | Classic 1981 · Neon · Naturalist Engraving |
| [**Incursion**](#incursion-1982) (1982) | [Penetrator](https://en.wikipedia.org/wiki/Penetrator_(video_game)) (Melbourne House, 1982) | Classic 1982 · Neon · Topographic Map |
| [**Hen House**](#hen-house-1983) (1983) | [Chuckie Egg](https://en.wikipedia.org/wiki/Chuckie_Egg) (A&F Software, 1983) | Classic 1983 · Neon · Cross-stitch |
| [**Jet Astronaut**](#jet-astronaut-1983) (1983) | [Jetpac](https://en.wikipedia.org/wiki/Jetpac) (Ultimate Play the Game, 1983) | Classic 1983 · Neon · Comic Book |
| [**Tower of Relics**](#tower-of-relics-1984) (1984) | [Knight Lore](https://en.wikipedia.org/wiki/Knight_Lore) (Ultimate Play the Game, 1984) | Classic 1984 · Neon · Geometric Pastel |
| [**Stack**](#stack-1984) (1984) | [Tetris](https://en.wikipedia.org/wiki/Tetris) (Alexey Pajitnov, 1984) | Classic 1984 · Neon · Wooden Toy |
| [**School Trouble**](#school-trouble-1985) (1985) | [Skool Daze](https://en.wikipedia.org/wiki/Skool_Daze) (Microsphere, 1985) | Classic 1985 · Chalkboard · Cartoon |
| [**Sun Road**](#sun-road-1986) (1986) | [Out Run](https://en.wikipedia.org/wiki/Out_Run) (Sega, 1986) | Classic 1986 · Synthwave · Travel Poster |
| [**Sword of the Valley**](#sword-of-the-valley-1986) (1986) | [The Legend of Zelda](https://en.wikipedia.org/wiki/The_Legend_of_Zelda_(video_game)) (Nintendo, 1986) | Classic 1986 · Handheld Console · Watercolour |
| [**Palace Escape**](#palace-escape-1989) (1989) | [Prince of Persia](https://en.wikipedia.org/wiki/Prince_of_Persia_(1989_video_game)) (Jordan Mechner, 1989) | Classic 1989 · Silhouette · Persian Miniature |
| [**Flock**](#flock-1991) (1991) | [Lemmings](https://en.wikipedia.org/wiki/Lemmings_(video_game)) (DMA Design / Psygnosis, 1991) | Classic 1991 · Clay · Notebook Doodles |

Each game has a demo running behind its menu, a saved high score and, where it makes sense, two-player modes, keyboard, mouse, gamepad and touch controls. Every style, the controls and the rules of each game are described below.

> **Disclaimer:** this is a non-commercial fan project. The names of the games that served as inspiration are trademarks of their respective owners and are mentioned only to credit that inspiration; this project is not affiliated with or endorsed by those companies. All code, graphics, sounds and music are original.

## Paddles (1972)

*Inspired by [Pong](https://en.wikipedia.org/wiki/Pong) (Atari, 1972).*

![Paddles](docs/screenshots/pong.jpg)

| Style | What it is |
|---|---|
| **Classic 1972** | True to the original: black and white, square ball, dashed net, blocky score digits and the three square-wave "beeps". |
| **Neon** | Additive glow, ball trail, sparks, shockwaves, screen shake and synthesised sounds that rise in pitch with the speed of the rally. |
| **Paper & Ink** | A paddle game in the margin of a notebook: "boiling" ink lines, splatters that stay on the paper, a pen-drawn score with a red circle and acoustic sounds (wood, pencil, bell). |

### Controls

| | Player 1 (left) | Player 2 (right) |
|---|---|---|
| Keyboard | W / S | Arrow keys ↑ / ↓ |
| Gamepad | Stick/D-pad on gamepad 1 | Gamepad 2 |
| Touch screen | Drag on the left half | Drag on the right half |

Against the CPU, either set of keys controls your paddle.

On a touch screen (and when dragging with the mouse) the paddle follows your finger in absolute position — just like the rotary knob on the original machine.

### Rules (same as the original)

- First to **11 points** wins.
- The paddle is split into **8 segments**; each one returns the ball at a fixed angle (the ends give the sharpest angles).
- The ball **speeds up after 4 and 12 hits** in the same rally.
- The serve goes to whoever conceded the point.

## Brick Breaker (1976)

*Inspired by [Breakout](https://en.wikipedia.org/wiki/Breakout_(video_game)) (Atari, 1976).*

![Brick Breaker](docs/screenshots/breakout.jpg)

| Style | What it is |
|---|---|
| **Classic 1976** | Like the Atari cabinet: a black-and-white monitor with strips of coloured cellophane stuck on the glass — so the ball and walls change colour as they cross each band, and the paddle is blue. Square-wave beeps with one pitch per brick colour. |
| **Neon** | Bricks of light in an electric rainbow, sparks, shockwaves, floating points and **combos**: each brick hit in a row without touching the paddle sounds a semitone higher. |
| **Stained Glass** | The wall is a cathedral window. The ball is an orb of light that lights up the panes it passes; each broken pane falls in shards, leaving only the lead frame. Sounds of glass, bronze, stone and bells. |

### Controls

| | |
|---|---|
| Keyboard | ← → or A / D · launch: Space / Enter |
| Mouse | the paddle follows the cursor · click to launch |
| Gamepad | stick / D-pad · launch: A |
| Touch screen | drag anywhere on the screen (relative movement, so your finger doesn't hide the paddle) · tap to launch |

### Rules (same as the original)

- 8 rows of 14 bricks: red **7** points, orange **5**, green **3**, yellow **1**.
- The ball speeds up at **4** and **12** paddle hits, and the first time it touches the **orange** and **red** rows.
- When the ball breaks through the wall and hits the top, the paddle **shrinks to half size** (until the next wall).
- The paddle is split into 8 segments; the ends return the ball at wider angles.
- **3 balls** (or 5, in the options). **2-player alternating** mode, each with their own wall, as on the cabinet.
- Clearing a wall brings up another (the original had only two; here it goes on without limit). The high score is saved.

## Alien Attack (1978)

*Inspired by [Space Invaders](https://en.wikipedia.org/wiki/Space_Invaders) (Taito, 1978).*

![Alien Attack](docs/screenshots/invaders.jpg)

| Style | What it is |
|---|---|
| **Classic 1978** | Black-and-white monitor with cellophane strips: red at the top (the flying saucer zone) and green at the bottom (shields and cannon). Pixel font, the 4-note bass march and square-wave sounds. |
| **Neon** | Invaders of light that pulse to the beat of the march, sparks, shockwaves, floating points and a synthesised bass line. |
| **Azulejo (Portuguese tiles)** | The invasion painted on a panel of Portuguese tiles: cobalt-blue invaders with uneven brushstrokes, saucer and cannon in ochre, tiles that crack and ceramic chips falling. Marimba, ceramic and bell sounds. |

The invader, flying saucer and cannon designs are original (in the same spirit, but not Taito's sprites).

### Controls

| | |
|---|---|
| Keyboard | ← → or A / D · fire: Space / W / ↑ |
| Mouse | the cannon follows the cursor · click (or hold) to fire |
| Gamepad | stick / D-pad · fire: A or X |
| Touch screen | drag anywhere (relative movement) · fires automatically while your finger is on the screen |

### Rules (same as the original)

- 5 rows of 11 invaders: top row **30** points, the two middle rows **20**, the two bottom rows **10**.
- The fleet marches as a block and drops down when it touches the edge. It moves one invader per frame, so it **speeds up as they fall** (and so does the march beat).
- If the fleet reaches the cannon, the game is over.
- 1 shot at a time; up to 3 enemy bombs (one in three is aimed at the cannon).
- 4 shields that crumble under shots, bombs and the invaders themselves.
- Flying saucer every ~25 s, with "mystery" points (50–300) that depend on the number of shots fired.
- Extra life at **1500** points. Each new wave starts lower down. 2-player alternating mode.

## Meteors (1979)

*Inspired by [Asteroids](https://en.wikipedia.org/wiki/Asteroids_(video_game)) (Atari, 1979).*

![Meteors](docs/screenshots/asteroids.jpg)

| Style | What it is |
|---|---|
| **Classic 1979** | Vector monitor: thin white lines with phosphor glow, vector-drawn digits, dotted explosions and the ship breaking into segments. The 2-note "heartbeat", the engine and the saucer sirens. |
| **Neon** | Asteroids of light in electric colours, engine trail, shots with tails, sparks, shockwaves and floating points. |
| **Origami** | Crumpled, faceted paper asteroids (the shading changes as they spin), the ship is a paper plane and the flying saucer a little paper boat. Card-stock sky with cut-out stars, confetti and paper sounds. |

### Controls

| | |
|---|---|
| Keyboard | rotate ← → (A / D) · thrust ↑ (W) · fire Space · hyperspace ↓ (S) or Shift |
| Mouse | the ship points at the cursor · click fires · right button thrusts · middle button: hyperspace |
| Gamepad | stick to rotate (up thrusts) · A/X fires · RB/RT thrusts · Y/LB hyperspace |
| Touch screen | left half: joystick (the ship turns where you point and thrusts if you push further) · right half: fire · "HYPER" button |

### Rules (same as the original)

- Large asteroids (**20** pts) split into 2 medium ones (**50**), which split into 2 small ones (**100**).
- Everything wraps around the screen. The ship has inertia; at most 4 shots on screen.
- Hyperspace: the ship reappears at a random spot — and sometimes explodes on re-entry.
- Large flying saucer (**200** pts, fires at random) and small one (**1000** pts, aims at the ship, getting better over time).
- The 2-note heartbeat speeds up during the wave. Extra life every **10 000** points.
- Each wave starts with more asteroids (4, 6, 8… up to 11). After losing a life, the ship only returns once the centre is clear.

## Swarm (1979)

*Inspired by [Galaxian](https://en.wikipedia.org/wiki/Galaxian) (Namco, 1979).*

![Swarm](docs/screenshots/galaxian.jpg)

| Style | What it is |
|---|---|
| **Classic 1979** | Black background with coloured stars falling and twinkling, multicoloured pixel ships, the missile resting on the tip of the ship, wave flags and the formation's constant hum. |
| **Neon** | Ships of light with trails on their dives, stars streaking at speed, sparks and shockwaves. |
| **Ocean** | The battle at the bottom of the sea: a shoal of fish, jellyfish, crabs and anglerfish (with their lanterns lit) against a small submarine. Bubbles, light rays, ink and sonar sounds. |

The ship designs are original (in the same spirit, but not Namco's sprites).

### Controls

Same as Alien Attack: ← → (A / D), mouse or gamepad; fire with Space / click / A. On a touch screen, dragging moves and a resting finger fires automatically.

### Rules (same as the original)

- Formation of 46: 2 flagships, 6 escorts, 8 emissaries and 30 drones, swaying from side to side.
- Ships peel off in an arc and dive at the player, firing; if they get past, they exit at the bottom and return to their place.
- Points: drone 30/60, emissary 40/80, escort 50/100 (in formation / diving).
- Flagship: 60 in formation; diving it is worth 150 alone, 200 with 1 escort, 300 with 2 — and **800** if you shoot down the escorts first.
- Only 1 missile at a time. Extra life at 7000 points. When only a few ships remain, they attack non-stop.

## Firefly (1980)

*Inspired by [Pac-Man](https://en.wikipedia.org/wiki/Pac-Man) (Namco, 1980).*

![Firefly](docs/screenshots/firefly.jpg)

An **original** maze-chase game in the spirit of 1980 arcades (with its own characters, maze and name). A firefly collects dots of light in a garden maze, chased by 4 bats. Light flowers make it glow: the bats are dazzled, flee, and can be caught.

| Style | What it is |
|---|---|
| **Arcade 1980** | Black screen, hedges outlined in green, pixel dots, flashing flowers, pixel art and chip sounds — with crickets chirping in the background. |
| **Neon** | A maze of light tubes, the firefly with a golden halo, neon bats and waves of light. |
| **Shadow Theatre** | A garden cut out in silhouette against a backlit paper screen, between velvet curtains. Everything is shadow except the firefly's light; the bats can only be made out by their eyes and, when dazzled, turn into pale paper cut-outs. Music box, wood and gong. |

### Controls

| | |
|---|---|
| Keyboard | arrow keys or WASD (the direction is remembered until there's an opening) |
| Gamepad | D-pad or stick |
| Mouse | clicking on the screen picks the direction relative to the firefly |
| Touch screen | swipe in the desired direction, anywhere |

### Rules

- Dots of light **10**, flowers **50**; dazzled bats **200, 400, 800, 1600** in sequence.
- Each bat hunts in its own way: the **Hunter** heads straight for you, the **Ambusher** tries to get in front of you, the **Flanker** closes in from the side opposite the Hunter, and the **Wanderer** approaches but runs off when it gets close.
- The bats alternate between "scatter" (each to its own corner) and "hunt"; when they switch, they turn around.
- Tunnels at the sides (the bats slow down inside them). Garden bonus twice per level (dewdrop, acorn, mushroom, clover, sunflower, pine cone, moon, star).
- The dazzle lasts less each level. Extra life at 10 000 points. 2-player alternating mode.

## The Crossing (1981)

*Inspired by [Frogger](https://en.wikipedia.org/wiki/Frogger) (Konami, 1981).*

![The Crossing](docs/screenshots/frogger.jpg)

| Style | What it is |
|---|---|
| **Classic 1981** | Midnight-blue river, black road, purple pavements, a hedge with 5 burrows, pixel vehicles and frog, a timer bar and a chip tune (original). |
| **Neon** | A motorway of light with trails, a rippling neon river, vehicles in glowing outlines and an acid-green frog. |
| **Felt** | A felt activity book: cut-out pieces with visible stitching, buttons for eyes and wheels, a river with sewn waves and patchwork panels. Toy whistles, xylophone and music box. |

Original designs (frog, vehicles, turtles, crocodile and fly).

### Controls

| | |
|---|---|
| Keyboard / gamepad | arrow keys, WASD or D-pad: one hop per press (hold = repeated hops) |
| Mouse | clicking on the screen hops in that direction, relative to the frog |
| Touch screen | swipe in the desired direction; a simple tap hops forward |

### Rules (same as the original)

- Cross 5 lanes of road and 5 of river (logs and turtles) to one of the 5 burrows.
- 10 points for each new row, 50 per frog home + 10 for every half second left on the clock; 1000 for filling all 5 burrows (and the level goes up, everything faster).
- Fly in a burrow: +200. From level 2 a crocodile appears in the burrows; from level 3 more turtles dive.
- You lose a life if you get run over, fall in the water, get carried off screen, jump into an occupied burrow or run out of time. Extra life at 10 000 points.

## Mushrooms (1981)

*Inspired by [Centipede](https://en.wikipedia.org/wiki/Centipede_(video_game)) (Atari, 1981).*

![Mushrooms](docs/screenshots/centipede.jpg)

| Style | What it is |
|---|---|
| **Classic 1981** | Black background and pixel art with colours that change every wave, as on the cabinet; poisoned mushrooms with swapped colours and the beat of the centipede's footsteps. |
| **Neon** | Glowing mushrooms, a centipede of light, an electric spider, sparks and shockwaves. |
| **Naturalist Engraving** | A plate from a 19th-century field notebook: watercolour mushrooms with sepia hatching, an engraved centipede with moving legs, spider, flea and scorpion in pen, and a nib that fires drops of ink. Specimen cards at the sides; quill, paper and harpsichord sounds. |

Original designs (mushrooms, centipede, shooter, spider, flea and scorpion).

### Controls

| | |
|---|---|
| Keyboard / gamepad | arrow keys, WASD or stick to move (in the bottom zone); Space / A to fire (hold = rapid fire) |
| Mouse | the shooter follows the cursor; holding the button fires |
| Touch screen | dragging anywhere moves the shooter; with your finger on the screen it fires automatically |

### Rules (same as the original)

- The centipede (12 segments) zigzags down: when it hits a mushroom or the edge it drops one row and reverses. Each segment shot becomes a mushroom and the next one becomes a head.
- Head **100**, body **10**; mushrooms take 4 shots (**+1** when destroyed).
- The flea (**200**, 2 shots) drops down seeding mushrooms when there are few at the bottom; the spider (**300/600/900**, depending on distance) bounces around the player zone and eats mushrooms; the scorpion (**1000**) poisons mushrooms — a centipede that touches one plunges straight down.
- When the centipede reaches the bottom, new heads enter from the sides. When you lose a life, damaged mushrooms are repaired (**+5** each).
- Each wave has more loose heads and the colours change. Extra life every **12 000** points. 2-player alternating mode.

## Incursion (1982)

*Inspired by [Penetrator](https://en.wikipedia.org/wiki/Penetrator_(video_game)) (Melbourne House, 1982).*

![Incursion](docs/screenshots/penetrator.jpg)

| Style | What it is |
|---|---|
| **Classic 1982** | Black background and terrain drawn only as an outline, one colour per zone, as on 8-bit micros; beeper sounds. |
| **Neon** | Parallax starry sky, dark terrain with glowing outlines (a pair of colours per zone), ship and enemies with halos. |
| **Topographic Map** | The mission on a military cross-section map: grid paper, terrain in hypsometric tints with contour lines, enemies as map symbols, a cartouche and a scale bar. |

Ship, missiles, radars, saucers and depot are original designs.

### Controls

| | |
|---|---|
| Keyboard / gamepad | arrow keys / WASD / stick to move; Space, Z or A fires; X, B, Ctrl or the B button drops bombs |
| Touch screen | dragging on the left half moves the ship; right half: top fires (hold), bottom drops a bomb |

### Rules (as in the original)

- Five zones per mission: Mountains, Caverns, Radar Base, Tunnels and Arsenal. Hitting the terrain costs a life and you restart at the beginning of the zone.
- Missiles launch from the ground as you approach (**50** on the ground, **80** in the air); radars **100**, flying saucers **150**.
- At the end of the Arsenal is the bomb depot: it takes **6** bombs. Destroying it completes the mission (**1000** + bonus) and the next one is faster, with more missiles.
- Extra life every **10 000** points.

## Hen House (1983)

*Inspired by [Chuckie Egg](https://en.wikipedia.org/wiki/Chuckie_Egg) (A&F Software, 1983).*

![Hen House](docs/screenshots/chuckie.jpg)

| Style | What it is |
|---|---|
| **Classic 1983** | The 8-colour palette of 8-bit micros: black background, green bricks, magenta ladders, yellow hens and the "beeps" of the built-in speaker. |
| **Neon** | The farm at night in light tubes: cyan platforms, magenta ladders, pink hens and haloed eggs. |
| **Cross-stitch** | The level embroidered on linen, like a farmyard sampler: each pixel is a cross-stitch, embroidered lettering, a backstitch border and music-box sounds. |

The 8 levels, the farmer, the hens and the duck are original designs.

### Controls

| | |
|---|---|
| Keyboard / gamepad | arrow keys / WASD / D-pad to walk and climb up/down ladders; Space, Z, J or A to jump |
| Touch screen | drag on the left half of the screen (walking and ladders); tap the right half to jump |

### Rules (as in the original)

- Collect the **12 eggs** in each level (**100** each) without touching the hens. Grain is worth **50** and stops the clock for 3 s — but the hens eat it too.
- Jump between platforms, grab ladders mid-jump and ride the lifts (mind the ceiling!). Falling through a hole in the floor costs a life.
- Leftover time is added to your score. After level 8 the levels repeat with the **giant duck** set loose, chasing you; further on the hens get faster and there are more of them.
- Extra life every **10 000** points. 2-player alternating mode (each player keeps their own level and remaining eggs).

## Jet Astronaut (1983)

*Inspired by [Jetpac](https://en.wikipedia.org/wiki/Jetpac) (Ultimate Play the Game, 1983).*

![Jet Astronaut](docs/screenshots/jetpac.jpg)

| Style | What it is |
|---|---|
| **Classic 1983** | Black background, green platforms, yellow ground and the pure colours of 8-bit micros; the rocket changes colour with each model. |
| **Neon** | Starry deep space, light-tube platforms and everything haloed; multicoloured laser. |
| **Comic Book** | A 1950s science-fiction magazine: gradient sky with halftone dots, a ringed planet, thick black linework, sound effects ("ZAP!", "BOOM!") and captions in yellow boxes. |

Astronaut, rockets, fuel pods, gems and the eight alien types are original designs.

### Controls

| | |
|---|---|
| Keyboard / gamepad | ← → to walk/fly, ↑ / W (or B on the gamepad) fires the jetpack; Space, Z, Ctrl or A fires the laser |
| Touch screen | joystick on the left half (push up to fire the jetpack); tap the right half to fire |

### Rules (as in the original)

- The screen wraps at the sides. On the first planet (and every 4th) you have to assemble the rocket: carry the two parts to the base (**100** each).
- Then fuel pods fall, one at a time: carry **6** to the rocket and climb in to take off (**1000**).
- Each planet has a different type of alien (meteors, fuzzballs, bubbles, fighters, crosses, saucers, hoppers and jelly blobs). Falling gems are worth **250**.
- Extra life every **10 000** points.

## Tower of Relics (1984)

*Inspired by [Knight Lore](https://en.wikipedia.org/wiki/Knight_Lore) (Ultimate Play the Game, 1984).*

![Tower of Relics](docs/screenshots/relics.jpg)

An original game inspired by the "Filmation" games on 8-bit micros, such as Knight Lore: a 16-room castle in isometric perspective.

| Style | What it is |
|---|---|
| **Classic 1984** | Black background and each room drawn in a single colour, with line-drawn outlines and bricks, like 8-bit isometric games. |
| **Neon** | The tower as a model made of light: grid floor, glass walls, glowing wireframe cubes and a golden altar. |
| **Geometric Pastel** | Soft geometric illustration: cubes in three shades of light, a pastel chequered floor, soft shadows and a sky that follows the day (dawn, noon, dusk, night). |

Explorer, guards, ghosts, relics, rooms and map are original.

### Controls

| | |
|---|---|
| Keyboard / gamepad | arrow keys / WASD / stick to walk (the screen diagonals are the corridors); Space / A jumps; E, X, Enter or B picks up/drops crates |
| Touch screen | joystick on the left half; right half: top jumps, bottom picks up/drops |

### Rules

- Collect the **8 relics** scattered around the castle and take them to the Chapel altar (each relic **500**, each delivery **1000**, plus a bonus for the days left over). You have **30 days** (40 s each).
- Crates can be pushed, carried and dropped in front of you — even on top of a block. **Trick:** drop the crate mid-jump and you'll land on top of it.
- Some doors are halfway up the wall: stack whatever you need to reach them.
- Spikes, guards, balls and ghosts cost a life; you restart at the room's entrance, and the room resets. Hearts give an extra life.

## Stack (1984)

*Inspired by [Tetris](https://en.wikipedia.org/wiki/Tetris) (Alexey Pajitnov, 1984).*

![Stack](docs/screenshots/blocks.jpg)

An original game inspired by the falling-blocks classic (Tetris): four-square pieces fall into a 10 x 20 well; rotate and fit them to complete lines, which disappear. It follows the modern rules: 7-piece bag, rotation with wall "kicks", hold piece, ghost piece showing where it will land, lock delay, soft drop and hard drop. The music is the Russian folk song "Korobeiniki" (public domain), in an original arrangement with a different timbre for each style.

| Style | What it is |
|---|---|
| **Classic 1984** | The green text screen of 1980s terminals: a well drawn with "<!" and "!>", pieces made of "[ ]", scanlines and phosphor glow. Beeper sounds. |
| **Neon** | Light tubes on a dark background with a perspective grid; glowing pieces, sparks on completed lines and synth with drums. |
| **Wooden Toy** | Painted wooden pieces with grain and rounded edges, in a beech box on a playroom table; wood and marimba sounds and music-box music. |

### Controls

| | |
|---|---|
| Keyboard | ← → move; ↓ soft drop; Space hard drop; ↑ or X rotate; Z or Ctrl rotate counter-clockwise; C or Shift hold piece |
| Gamepad | D-pad to move and soft drop, ↑ hard drops; A rotates, B rotates counter-clockwise; LB/RB hold |
| Touch screen | drag sideways to move and down to soft drop; tap to rotate (left half: counter-clockwise); flick down to hard drop, flick up to hold |

### Rules

- 1, 2, 3 or 4 lines at once are worth 100, 300, 500 or 800 points, times the level; 4 lines followed by another 4 are worth 50% more, and consecutive line-clearing moves give a bonus.
- Every 10 lines the level goes up and pieces fall faster. The game ends when a piece no longer fits in the well.

## School Trouble (1985)

*Inspired by [Skool Daze](https://en.wikipedia.org/wiki/Skool_Daze) (Microsphere, 1985).*

![School Trouble](docs/screenshots/school.jpg)

An original game inspired by Skool Daze: Zé has to get his report card out of the safe in the headmaster's office. The school has three floors, classrooms, stairs, a canteen and a playground; there's a timetable to follow, classmates (the Bully who hits, the Swot who tells tales, the Tearaway who carries a catapult) and four teachers in gowns and mortarboards who hand out lines to anyone caught misbehaving.

| Style | What it is |
|---|---|
| **Classic 1985** | The bold colours of 8-bit computers: each room in an "attribute" colour, thick floors and walls, stepped staircases and characters in black ink only, with pixel lettering. |
| **Chalkboard** | The whole school drawn in chalk on a slate board: shaky lines, chalk in several colours, stick figures and a wooden ledge holding the panel. |
| **Cartoon** | A modern cartoon school: pastel walls, wooden floors, windows, lockers, thick outlines and big-headed characters with expressive eyes. |

### Controls

| | |
|---|---|
| Keyboard / gamepad | ← → walk; ↑ ↓ go up and down stairs (and ↑ by the safe to open it); Space / A jump; X or J / X catapult; Z or K / B punch |
| Touch screen | joystick on the left half; right half: top jumps, middle catapult, bottom punch |

### Rules

- Follow the timetable (on the panel): go to the right classroom for each lesson and to the canteen at lunch. If you skip class, get caught with the catapult or fighting, or are found in the headmaster's office, you get lines. At 10000 lines you're expelled.
- Teachers can't see what happens behind their backs — for example, while they're writing on the board.
- First, hit all 12 shields on the walls by jumping; the highest ones can only be reached by standing on a knocked-down classmate.
- Then knock each teacher down with the catapult: as they get up, they say their letter of the safe's code (if they see you firing, they'll give you lines too). With all 4 letters, open the safe in the headmaster's office and you move up a level.

## Sun Road (1986)

*Inspired by [Out Run](https://en.wikipedia.org/wiki/Out_Run) (Sega, 1986).*

![Sun Road](docs/screenshots/outrun.jpg)

| Style | What it is |
|---|---|
| **Classic 1986** | Blue summer sky with clouds, saturated colours, striped kerbs and scenery sprites that grow towards the screen; yellow HUD with a rev counter. |
| **Synthwave** | Eternal night: a striped sun on the horizon, wireframe mountains, a neon grid floor, silhouettes with glowing outlines and shining tail lights. Each region has its own pair of neon colours. |
| **Travel Poster** | The road as a 1930s Art Deco tourism poster: sky in flat bands, a sun with rays, ink-cut mountains, grainy paper, signs in the HUD and a dial speedometer. |

The generic convertible, traffic, scenery and the three radio tracks are original (composed and synthesised in code).

### Controls

| | |
|---|---|
| Keyboard / gamepad | arrow keys / WASD / stick to steer, ↑ W / A / right trigger to accelerate, ↓ S / B / left trigger to brake; Space / Shift / X changes gear (manual gearbox) |
| Mouse | holding the left button accelerates (right brakes) and the car follows the cursor |
| Touch screen | drag your finger sideways to steer (virtual wheel); 1 finger accelerates, 2 fingers brake |

### Rules (as in the original)

- Time trial over 5 stages. At the end of each one the road **forks**: the side you choose decides the next region (Coast, Desert, Forest, Alps, City, Vineyards) — 5 possible finishes, like the original's pyramid (the map in the corner shows your route).
- Each checkpoint gives extra time; time left at the finish counts as a bonus.
- Off the road the car slows down; hitting scenery or a car at high speed makes the car flip. At low speed, it's just a bump.
- On bends the car is pulled outwards: on the tightest ones, ease off the throttle.
- Automatic or manual gearbox (low gear pulls away well but won't go past 174 km/h). Radio: Atlantic Wave, Magic Road, Sunset or off.

## Sword of the Valley (1986)

*Inspired by [The Legend of Zelda](https://en.wikipedia.org/wiki/The_Legend_of_Zelda_(video_game)) (Nintendo, 1986).*

![Sword of the Valley](docs/screenshots/vale.jpg)

An original top-down adventure inspired by the sword-and-dungeon classics: a 12-screen valley and a 6-room dungeon.

| Style | What it is |
|---|---|
| **Classic 1986** | 16 x 16 pixel tiles as on 8-bit consoles — grass, round trees, rocks, rippling water, a brick dungeon — and a black HUD. |
| **Handheld Console** | The same designs in just 4 shades of green, with the pixel grid of an LCD screen and the grey bezel of 1989 handhelds. |
| **Watercolour** | Each screen painted like a storybook illustration: watercolour washes on paper, ink-lined trees and rocks, layered water and a HUD written in the margin. |

The hero, enemies, maps and the Stone Guardian are original.

### Controls

| | |
|---|---|
| Keyboard / gamepad | arrow keys / WASD / D-pad to walk (4 directions); Space, Z, X or A swings the sword |
| Touch screen | joystick on the left half; tap the right half to swing |

### Rules

- Find the cave in the north-east mountains and enter the dungeon. To recover the **Crystal of the Valley**, defeat the **Stone Guardian**.
- In the dungeon, clearing certain rooms makes a key appear; keys open locked doors.
- The sword cuts bushes (sometimes there are coins or hearts hidden). There's an extra heart in the valley and another in the dungeon.
- Enemies: hopping slimes, bats, goblin archers and knights. You have 3 lives: when you lose all your hearts, you restart at the start of the valley or at the dungeon entrance.

## Palace Escape (1989)

*Inspired by [Prince of Persia](https://en.wikipedia.org/wiki/Prince_of_Persia_(1989_video_game)) (Jordan Mechner, 1989).*

![Palace Escape](docs/screenshots/palace.jpg)

An original game inspired by the "cinematic" platformers of the era, such as Prince of Persia. The characters are skeletons animated by interpolated poses, for smooth animation without sprite sheets.

| Style | What it is |
|---|---|
| **Classic 1989** | Bluish stone dungeons with bricks, light-edged flagstones and flickering torches; a hero in white and guards in colourful turbans. |
| **Silhouette** | Shadow theatre at sunset: the palace and characters in black against a gradient sky, arches in the distance and a scarf fluttering behind the hero. |
| **Persian Miniature** | The palace painted as a Persian miniature: a lapis-lazuli background with gold stars, turquoise tiled walls, marble flagstones, colourful costumes, scimitars and a gilded frame. |

### Controls

| | |
|---|---|
| Keyboard / gamepad | ← → run; Shift + ← → careful step; Space jumps (while running = long jump); ↑ jumps up, grabs and climbs ledges, enters doors; ↓ crouches, climbs down from a ledge or lets go; X / J sword (↑ blocks) |
| Touch screen | joystick on the left half (↑/↓ to climb up and down); right half: top jumps, middle careful step, bottom sword |

### Rules

- You have **20 minutes** to get through the palace's two levels. When you die you restart the level, but the clock keeps running.
- Falling one storey is harmless, two cost a triangle of health and three are fatal. While falling, ↑ grabs the nearest ledge.
- Spikes only get you if you run or land on them; cross them with a careful step. Loose floor tiles fall shortly after you step on them.
- Pressure plates open gates for 12 seconds. The exit plate opens the door at the end of the level.
- When you have the sword, guards force you to fight: attack, block (↑) and advance or retreat. Red potions heal and green ones increase your health.

## Flock (1991)

*Inspired by [Lemmings](https://en.wikipedia.org/wiki/Lemmings_(video_game)) (DMA Design / Psygnosis, 1991).*

![Flock](docs/screenshots/flock.jpg)

An original game inspired by puzzle games like Lemmings: the sheep leave the pen and walk on their own, afraid of nothing; you have to give them skills so they reach the barn. The terrain is a pixel map that gets dug and built as you play. Six levels, from a gentle stroll to "everything at once".

| Style | What it is |
|---|---|
| **Classic 1991** | The look of 16-bit puzzle games: black background, grainy earth with grass, riveted steel plates, sheep made of a few pixels, a wooden trapdoor and a red barn with torches. Blue panel with green numbers. |
| **Clay** | Everything moulded by hand: terracotta clay with plasticine grass, dough clouds and sun, fluffy sheep made of little balls and plasticine buttons. |
| **Notebook Doodles** | A pencil scribble on a lined page: hatched graphite terrain, steel in blue ballpoint, bricks in red pen and sheep with a wobbly, "boiling" outline, like hand-drawn cartoons. |

### Controls

| | |
|---|---|
| Mouse / touch screen | tap a panel button to pick a skill and then a sheep to assign it; − / + change the release rate; pause, fast-forward and restart on the panel |
| Keyboard / gamepad | 1–7 or Q / E (LB / RB) pick the skill; arrow keys / WASD / stick move the cursor; Space / Enter / A assigns; F (Y) fast-forward; R (Back) restarts the level; Esc pauses |

### Rules

- Each level tells you how many sheep you must save and how much time you have. If you don't make it, you replay the level.
- Skills: **Climber** (climbs walls), **Umbrella** (falls slowly, unharmed), **Blocker** (makes the others turn around), **Builder** (12 bridge steps), **Basher** (tunnel straight ahead), **Miner** (diagonal tunnel) and **Digger** (hole straight down).
- A long fall is fatal, unless using an umbrella. Steel can't be dug through.

## Running the project

1. Install [Godot 4.7](https://godotengine.org/download) (standard version, not .NET).
2. In the Project Manager: **Import** → choose `project.godot`.
3. Press **F5** to play.

In every game: **Esc / P / Start** pauses; **F11** toggles fullscreen; on Android the "back" button pauses and returns to the menu.

## Project structure

```
core/                  shared by all games
  main.gd / main.tscn  launcher (game list and the "inspired by" panel)
  inspirations.gd      the classics that inspired each game, with a short history and Wikipedia link
  synth.gd             tiny synthesizer: every sound is generated in code
  ui.gd                menu theme generated from each style's palette
  pixel_font.gd        5x7 pixel font; pixel_art.gd: multicolour pixel drawings
  settings.gd          saved preferences (user://settings.cfg)
  i18n.gd              translations (I18n.t); the texts are in i18n/strings.json
games/<game>/
  <game>_game.gd       pure game logic (rules, physics, demo AI, input) — emits signals
  <game>_main.gd       menus, pause, game over, high score, style switching
  skins/<game>_skin.gd base class of a visual style (drawing + sounds + reactions to events)
  skins/*.gd           the three styles
```

The folders and class names keep the short internal names used during development (`pong`, `breakout`...).

**New style:** extend the game's skin base class, draw in `_draw()` from `game`, create the sounds in `_build_sfx()` and add it to `SKINS` in the game's `*_main.gd`.

**New game:** create `games/<game>/<game>_main.gd` (a `Node` with an `exit_requested` signal and a `go_back()` method), register it in `GAMES` in `core/main.gd` and add its inspiration to `core/inspirations.gd`.

**Translations:** the original text (Portuguese) is the key; the code wraps every visible string with `I18n.t("...")`. The English and Spanish texts live in `i18n/strings.json` (`{"Portuguese text": ["English", "Spanish"]}`); after editing it, run `python3 i18n/build.py` to regenerate `i18n/strings.gd`. A missing translation simply shows the Portuguese text. Adding a language means adding a column to the JSON and to `I18n.LANGS`/`LANG_NAMES` in `core/i18n.gd`.

Renderer: *Compatibility* (OpenGL), to run on older PCs and most Android phones.

## Builds

Export presets are in `export_presets.cfg` (Windows, Linux, Android and Web).

- **Editor:** **Project → Export** → choose the platform → **Export Project** (the first time, Godot asks to download the export templates).
- **Command line:** `./build.sh` (all) or `./build.sh windows|linux|android|web` (set `GODOT=/path/to/godot` if it is not in the PATH).
- **Android:** needs JDK 17, the Android SDK and a debug keystore, configured in **Editor → Editor Settings → Export → Android** ([official guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)). The APK is signed with the debug key; publishing on the Play Store needs your own release keystore (never commit it).
- **Web:** exported without threads (*Thread Support* off), so it runs on any static file server, GitHub Pages included, with no special headers. To try it locally, export to a folder and run `python3 -m http.server` there.
- **GitHub Actions:** `.github/workflows/builds.yml` runs on every push to `main`: it builds Windows, Linux, Android and Web (under **Actions → Artifacts**) and publishes the web version to **GitHub Pages** (enable it once in **Settings → Pages → Source: GitHub Actions**; for this repository it is [https://mcampilho.github.io/classic-games/](https://mcampilho.github.io/classic-games/)). Pushing a `v*` tag (`git tag v1.0.0 && git push --tags`) also creates a **Release** with the downloadable files.

## License

The code is released under the [MIT License](LICENSE). The [Godot](https://godotengine.org) engine is also MIT-licensed.
