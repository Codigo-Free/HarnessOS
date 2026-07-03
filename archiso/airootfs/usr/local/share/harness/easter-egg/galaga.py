#!/usr/bin/env python3
"""HarnessOS Easter Egg — Galaga"""

import sys
import math
import random
from pathlib import Path
import pygame

W, H = 800, 700
FPS  = 60

# Tokyo Night palette
BG     = (13,  17,  23)
WHITE  = (192, 202, 224)
DIM    = (70,  80,  100)
GREEN  = (158, 206, 106)
RED    = (247, 118, 142)
BLUE   = (122, 162, 247)
YELLOW = (224, 175, 104)
CYAN   = (125, 207, 255)
PURPLE = (187, 154, 247)
ORANGE = (255, 158, 100)


# ---------------------------------------------------------------------------
# Drawing helpers
# ---------------------------------------------------------------------------

def draw_ship(surf, x, y, size=None):
    pts = [
        (x,      y - 18),
        (x - 14, y + 12),
        (x,      y + 4),
        (x + 14, y + 12),
    ]
    pygame.draw.polygon(surf, GREEN, pts)
    pygame.draw.circle(surf, CYAN, (x, y - 3), 5)
    pygame.draw.rect(surf, (80, 200, 80), (x - 4, y + 12, 8, 5))


def draw_drone(surf, x, y, size=13):
    pts = [(x, y - size), (x + size, y), (x, y + size), (x - size, y)]
    pygame.draw.polygon(surf, BLUE, pts)
    pygame.draw.polygon(surf, CYAN, pts, 2)
    pygame.draw.circle(surf, WHITE, (x, y), 4)


def draw_bee(surf, x, y, size=15):
    pygame.draw.ellipse(surf, PURPLE, (x - 10, y - size, 20, size * 2))
    pygame.draw.ellipse(surf, YELLOW, (x - size, y - 7, size, 14))
    pygame.draw.ellipse(surf, YELLOW, (x,        y - 7, size, 14))
    pygame.draw.circle(surf, WHITE, (x, y), 5)


def draw_boss(surf, x, y, size=20):
    pygame.draw.ellipse(surf, RED, (x - size, y - size, size * 2, size * 2))
    pygame.draw.ellipse(surf, YELLOW, (x - 12, y - size // 2, 24, size))
    pygame.draw.circle(surf, WHITE, (x, y), 7)
    pygame.draw.line(surf, ORANGE, (x - 8,  y - size), (x - 14, y - size - 10), 2)
    pygame.draw.line(surf, ORANGE, (x + 8,  y - size), (x + 14, y - size - 10), 2)


# ---------------------------------------------------------------------------
# Game objects
# ---------------------------------------------------------------------------

class Bullet:
    def __init__(self, x, y, vy, color):
        self.x = x
        self.y = float(y)
        self.vy = vy
        self.color = color

    def update(self):
        self.y += self.vy

    def draw(self, surf):
        h = 14 if self.vy < 0 else 10
        pygame.draw.rect(surf, self.color, (self.x - 2, int(self.y) - h // 2, 4, h))


class Enemy:
    DEFS = {
        'drone': (BLUE,   10, 13, draw_drone),
        'bee':   (PURPLE, 20, 15, draw_bee),
        'boss':  (RED,    50, 20, draw_boss),
    }

    def __init__(self, col, row, etype):
        self.etype = etype
        self.color, self.pts, self.size, self._draw_fn = self.DEFS[etype]
        self.home_x = 90 + col * 66
        self.home_y = 100 + row * 52
        self.x = float(self.home_x)
        self.y = float(self.home_y)
        self.alive    = True
        self.bullets: list[Bullet] = []
        self.swooping = False
        self._phase   = 0.0
        self._ox = self._oy = 0.0
        self.shoot_cd = random.randint(120, 500)

    def start_swoop(self):
        if not self.swooping:
            self.swooping = True
            self._phase = 0.0
            self._ox = self.x
            self._oy = self.y

    def update(self, fm_dx, fm_dy, bullet_speed=7):
        if self.swooping:
            self._phase += 0.025
            self.x = self._ox + math.sin(self._phase * 2.5) * 160
            self.y = self._oy + self._phase * 220
            if self.y > H + 60:
                self.swooping = False
                self.x = self.home_x + fm_dx
                self.y = self.home_y + fm_dy
        else:
            self.x = self.home_x + fm_dx
            self.y = self.home_y + fm_dy

        self.shoot_cd -= 1
        if self.shoot_cd <= 0:
            self.shoot_cd = random.randint(200, 600)
            self.bullets.append(Bullet(int(self.x), int(self.y) + 12, bullet_speed, RED))

        for b in self.bullets[:]:
            b.update()
            if b.y > H + 20:
                self.bullets.remove(b)

    def draw(self, surf):
        if self.alive:
            self._draw_fn(surf, int(self.x), int(self.y), self.size)
        for b in self.bullets:
            b.draw(surf)


class Player:
    def __init__(self, score=0, lives=3):
        self.x        = float(W // 2)
        self.y        = float(H - 75)
        self.speed    = 5.5
        self.bullets: list[Bullet] = []
        self.shoot_cd = 0
        self.score    = score
        self.lives    = lives
        self.inv      = 0

    def shoot(self):
        if self.shoot_cd <= 0:
            self.bullets.append(Bullet(int(self.x), int(self.y) - 22, -13, GREEN))
            self.shoot_cd = 14

    def hit(self) -> bool:
        if self.inv == 0:
            self.lives -= 1
            self.inv = 140
            return True
        return False

    def update(self, dx):
        self.x = max(24.0, min(float(W - 24), self.x + dx * self.speed))
        if self.shoot_cd > 0:
            self.shoot_cd -= 1
        if self.inv > 0:
            self.inv -= 1
        for b in self.bullets[:]:
            b.update()
            if b.y < -10:
                self.bullets.remove(b)

    def draw(self, surf):
        if self.inv % 8 < 4:
            draw_ship(surf, int(self.x), int(self.y))
        for b in self.bullets:
            b.draw(surf)


# ---------------------------------------------------------------------------
# Stars
# ---------------------------------------------------------------------------

def make_stars(n=130):
    return [
        [random.uniform(0, W), random.uniform(0, H),
         random.randint(100, 220), random.uniform(0.4, 2.0),
         random.randint(1, 2)]
        for _ in range(n)
    ]


def draw_stars(surf, stars):
    for s in stars:
        s[1] += s[3]
        if s[1] > H:
            s[1] = 0.0
            s[0] = random.uniform(0, W)
        c = s[2]
        pygame.draw.circle(surf, (c, c, min(255, c + 30)),
                           (int(s[0]), int(s[1])), s[4])


def make_enemies():
    layout = [('boss', 10), ('bee', 10), ('drone', 10), ('drone', 10)]
    return [Enemy(col, row, etype) for row, (etype, cols) in enumerate(layout) for col in range(cols)]


# ---------------------------------------------------------------------------
# Intro screen: 3 flashes → portrait → fade to black
# ---------------------------------------------------------------------------

def _find_portrait() -> str | None:
    candidates = [
        Path("/usr/local/share/harness/easter-egg/portrait.png"),
        Path("/usr/local/share/harness/easter-egg/portrait.jpg"),
    ]
    home = Path.home() / ".local/share/harness/easter-egg"
    for ext in ("png", "jpg", "jpeg", "webp"):
        candidates.append(home / f"portrait.{ext}")
    for p in candidates:
        if p.exists():
            return str(p)
    return None


def screen_intro(surface, clock) -> bool:
    """Flash 3×, show portrait fullscreen, fade to black. Returns False on quit."""

    def pump() -> bool:
        """Drain event queue; return False if quit requested."""
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                return False
            if ev.type == pygame.KEYDOWN and ev.key in (pygame.K_q, pygame.K_ESCAPE):
                return False
        return True

    # --- 3 white flashes ---
    for _ in range(3):
        surface.fill((255, 255, 255))
        pygame.display.flip()
        pygame.time.wait(90)
        if not pump():
            return False
        surface.fill((0, 0, 0))
        pygame.display.flip()
        pygame.time.wait(90)
        if not pump():
            return False

    # --- Load portrait ---
    path = _find_portrait()
    if not path:
        return True  # no portrait, skip to game

    try:
        img = pygame.image.load(path).convert()
    except Exception:
        return True

    # Scale to fit window, keep aspect ratio
    iw, ih = img.get_size()
    scale   = min(W / iw, H / ih)
    nw, nh  = int(iw * scale), int(ih * scale)
    portrait = pygame.transform.smoothscale(img, (nw, nh))
    px = (W - nw) // 2
    py = (H - nh) // 2

    # --- Fade in portrait ---
    fade = pygame.Surface((W, H))
    fade.fill((0, 0, 0))
    for alpha in range(255, -1, -10):
        if not pump():
            return False
        fade.set_alpha(alpha)
        surface.fill((0, 0, 0))
        surface.blit(portrait, (px, py))
        surface.blit(fade, (0, 0))
        pygame.display.flip()
        clock.tick(FPS)

    # --- Hold (3 s or any key to skip) ---
    surface.fill((0, 0, 0))
    surface.blit(portrait, (px, py))
    pygame.display.flip()

    start = pygame.time.get_ticks()
    skip = False
    while pygame.time.get_ticks() - start < 3000 and not skip:
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                return False
            if ev.type == pygame.KEYDOWN:
                if ev.key in (pygame.K_q, pygame.K_ESCAPE):
                    return False
                skip = True
        clock.tick(FPS)

    # --- Fade out portrait ---
    for alpha in range(0, 256, 10):
        if not pump():
            return False
        fade.set_alpha(alpha)
        surface.fill((0, 0, 0))
        surface.blit(portrait, (px, py))
        surface.blit(fade, (0, 0))
        pygame.display.flip()
        clock.tick(FPS)

    return True


# ---------------------------------------------------------------------------
# Game screens
# ---------------------------------------------------------------------------

def screen_title(surface, clock, stars, fonts) -> bool:
    f_big, f_med, f_sm = fonts
    t = 0
    while True:
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                return False
            if ev.type == pygame.KEYDOWN:
                if ev.key in (pygame.K_ESCAPE, pygame.K_q):
                    return False
                if ev.key in (pygame.K_RETURN, pygame.K_SPACE):
                    return True

        surface.fill(BG)
        draw_stars(surface, stars)

        pulse = 0.6 + 0.4 * abs(math.sin(t * 0.04))
        title = f_big.render("HARNESS  OS", True, CYAN)
        sub   = f_med.render("G  A  L  A  G  A", True,
                              tuple(int(c * pulse) for c in YELLOW))
        blink = WHITE if t % 60 < 40 else DIM
        hint  = f_sm.render("PRESS  ENTER  TO  PLAY  /  Q  QUIT", True, blink)
        ctrl  = f_sm.render("ARROWS / WASD  move      SPACE  shoot", True, DIM)

        surface.blit(title, (W // 2 - title.get_width() // 2, 180))
        surface.blit(sub,   (W // 2 - sub.get_width()   // 2, 268))

        cx = W // 2
        draw_ship(surface,  cx - 140, 370)
        draw_boss(surface,  cx,       355, 22)
        draw_ship(surface,  cx + 140, 370)
        draw_drone(surface, cx - 70,  380, 12)
        draw_bee(surface,   cx - 70,  420, 13)
        draw_drone(surface, cx + 70,  380, 12)
        draw_bee(surface,   cx + 70,  420, 13)

        surface.blit(hint, (W // 2 - hint.get_width() // 2, 470))
        surface.blit(ctrl, (W // 2 - ctrl.get_width() // 2, 508))

        pygame.display.flip()
        clock.tick(FPS)
        t += 1


def screen_gameover(surface, clock, stars, fonts, score) -> bool:
    f_big, _, f_sm = fonts
    t = 0
    while True:
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                return False
            if ev.type == pygame.KEYDOWN:
                if ev.key in (pygame.K_ESCAPE, pygame.K_q):
                    return False
                if ev.key == pygame.K_RETURN:
                    return True

        surface.fill(BG)
        draw_stars(surface, stars)
        blink = WHITE if t % 60 < 40 else DIM
        go   = f_big.render("GAME  OVER", True, RED)
        sc   = f_sm.render(f"Score: {score:06d}", True, WHITE)
        hint = f_sm.render("ENTER restart   Q quit", True, blink)
        surface.blit(go,   (W // 2 - go.get_width()   // 2, H // 2 - 80))
        surface.blit(sc,   (W // 2 - sc.get_width()   // 2, H // 2))
        surface.blit(hint, (W // 2 - hint.get_width() // 2, H // 2 + 60))
        pygame.display.flip()
        clock.tick(FPS)
        t += 1


def screen_wave(surface, clock, stars, fonts, wave) -> bool:
    f_big = fonts[0]
    for _ in range(120):
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                return False
            if ev.type == pygame.KEYDOWN and ev.key in (pygame.K_q, pygame.K_ESCAPE):
                return False
        surface.fill(BG)
        draw_stars(surface, stars)
        txt = f_big.render(f"WAVE  {wave}", True, CYAN)
        surface.blit(txt, (W // 2 - txt.get_width() // 2, H // 2 - 40))
        pygame.display.flip()
        clock.tick(FPS)
    return True


def run_game(surface, clock, stars, fonts, wave=1, score=0, lives=3):
    """Returns (score, lives, signal) — signal: 'quit' | 'dead' | 'next_wave'"""
    _, _, f_hud = fonts
    player  = Player(score=score, lives=lives)
    enemies = make_enemies()

    fm_dx  = 0.0
    fm_dy  = 0.0
    fm_dir = 1
    fm_spd = min(2.0, 0.5 + (wave - 1) * 0.22)
    fm_drop = 22.0
    bullet_speed = min(11, 7 + (wave - 1))
    swoop_cd = random.randint(160, 340)
    explosions: list[dict] = []

    while True:
        clock.tick(FPS)
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                return player.score, player.lives, 'quit'
            if ev.type == pygame.KEYDOWN and ev.key in (pygame.K_ESCAPE, pygame.K_q):
                return player.score, player.lives, 'quit'

        keys = pygame.key.get_pressed()
        dx = 0
        if keys[pygame.K_LEFT]  or keys[pygame.K_a]: dx = -1
        if keys[pygame.K_RIGHT] or keys[pygame.K_d]: dx = 1
        if keys[pygame.K_SPACE] or keys[pygame.K_UP] or keys[pygame.K_w]:
            player.shoot()
        player.update(dx)

        alive_form = [e for e in enemies if e.alive and not e.swooping]
        if alive_form:
            xs = [e.home_x + fm_dx for e in alive_form]
            # Drop only on the frame the direction flips — otherwise the
            # formation drops 22px on every frame it hugs the edge
            if max(xs) >= W - 55 and fm_dir == 1:
                fm_dir  = -1
                fm_dy  += fm_drop
            elif min(xs) <= 55 and fm_dir == -1:
                fm_dir  = 1
                fm_dy  += fm_drop
        fm_dx += fm_spd * fm_dir

        swoop_cd -= 1
        if swoop_cd <= 0:
            swoop_cd = max(70, random.randint(100, 280) - wave * 8)
            cands = [e for e in enemies if e.alive and not e.swooping]
            if cands:
                random.choice(cands).start_swoop()

        for e in enemies:
            e.update(fm_dx, fm_dy, bullet_speed=bullet_speed)

        for pb in player.bullets[:]:
            for e in enemies:
                if e.alive and abs(pb.x - e.x) < e.size + 6 and abs(pb.y - e.y) < e.size + 6:
                    e.alive = False
                    player.score += e.pts
                    if pb in player.bullets:
                        player.bullets.remove(pb)
                    explosions.append({'x': int(e.x), 'y': int(e.y),
                                       'r': 4.0, 'max': 32.0, 'color': e.color})
                    break

        for e in enemies:
            for b in e.bullets[:]:
                if abs(b.x - player.x) < 14 and abs(b.y - player.y) < 14:
                    if player.hit():
                        e.bullets.remove(b)
                        explosions.append({'x': int(player.x), 'y': int(player.y),
                                           'r': 4.0, 'max': 50.0, 'color': GREEN})

        # Formation reaching the bottom ends the game — but swooping enemies
        # dive past the player and rejoin the formation, like in real Galaga
        for e in enemies:
            if e.alive and not e.swooping and e.y > H - 50:
                player.lives = 0

        if player.lives <= 0:
            return player.score, 0, 'dead'
        if all(not e.alive for e in enemies):
            return player.score, player.lives, 'next_wave'

        surface.fill(BG)
        draw_stars(surface, stars)
        for e in enemies:
            e.draw(surface)
        player.draw(surface)
        for ex in explosions[:]:
            ex['r'] += 2.5
            pygame.draw.circle(surface, ex['color'], (ex['x'], ex['y']), int(ex['r']), 2)
            if ex['r'] >= ex['max']:
                explosions.remove(ex)

        sc_t = f_hud.render(f"SCORE  {player.score:06d}", True, WHITE)
        wv_t = f_hud.render(f"WAVE  {wave}", True, CYAN)
        lv_t = f_hud.render("SHIP  " + "■ " * max(0, player.lives), True, GREEN)
        surface.blit(sc_t, (20, 12))
        surface.blit(wv_t, (W // 2 - wv_t.get_width() // 2, 12))
        surface.blit(lv_t, (W - lv_t.get_width() - 20, 12))
        pygame.display.flip()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    pygame.init()
    surface = pygame.display.set_mode((W, H))
    pygame.display.set_caption("HarnessOS — Galaga")
    clock = pygame.time.Clock()

    fonts = (
        pygame.font.SysFont("monospace", 52, bold=True),
        pygame.font.SysFont("monospace", 34, bold=True),
        pygame.font.SysFont("monospace", 20, bold=True),
    )
    stars = make_stars()

    # --- Easter egg intro (flashes + portrait) ---
    if not screen_intro(surface, clock):
        pygame.quit()
        sys.exit()

    # --- Game loop ---
    while True:
        if not screen_title(surface, clock, stars, fonts):
            break

        wave, score, lives = 1, 0, 3
        while True:
            result_score, result_lives, signal = run_game(
                surface, clock, stars, fonts,
                wave=wave, score=score, lives=lives,
            )
            score = result_score
            lives = result_lives

            if signal == 'quit':
                pygame.quit()
                sys.exit()
            elif signal == 'next_wave':
                wave += 1
                if not screen_wave(surface, clock, stars, fonts, wave):
                    pygame.quit()
                    sys.exit()
            else:  # dead
                if not screen_gameover(surface, clock, stars, fonts, score):
                    break
                wave, score, lives = 1, 0, 3

    pygame.quit()
    sys.exit()


if __name__ == "__main__":
    main()
