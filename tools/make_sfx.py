"""Synthesizes the game's sound effects into assets/sounds/.

The sounds are generated here rather than taken from a pack, so the game owns
them outright. Run from the repo root: python3 tools/make_sfx.py
"""

import math
import random
import struct
import wave

RATE = 44100


def square(phase: float) -> float:
    return 1.0 if phase % 1.0 < 0.5 else -1.0


def tone(freqs, seconds: float, wave_fn=square, vibrato: float = 0.0):
    """One voice whose pitch slides linearly through `freqs`, with a decaying envelope."""
    count = int(seconds * RATE)
    phase = 0.0
    out = []
    for i in range(count):
        t = i / count
        segment = min(int(t * (len(freqs) - 1)), len(freqs) - 2)
        local = t * (len(freqs) - 1) - segment
        freq = freqs[segment] + (freqs[segment + 1] - freqs[segment]) * local
        freq *= 1.0 + vibrato * math.sin(2 * math.pi * 8 * i / RATE)
        phase += freq / RATE
        attack = min(1.0, i / (0.004 * RATE))
        out.append(wave_fn(phase) * attack * (1.0 - t) ** 1.5)
    return out


def notes(pitches, note_seconds: float):
    """Stepped pitches, each its own short blip."""
    out = []
    for pitch in pitches:
        out += tone([pitch, pitch], note_seconds)
    return out


def noise(seconds: float, rng: random.Random):
    count = int(seconds * RATE)
    return [rng.uniform(-1, 1) * (1.0 - i / count) ** 3 for i in range(count)]


def hiss(seconds: float, rng: random.Random):
    """A burning fuse: high-passed noise that crackles and swells as it burns down."""
    count = int(seconds * RATE)
    out = []
    previous = 0.0
    crackle = 0.0
    for i in range(count):
        t = i / count
        raw = rng.uniform(-1, 1)
        out.append((raw - previous) * (0.5 + 0.5 * t) * (0.6 + 0.4 * crackle))
        previous = raw
        if rng.random() < 0.0015:
            crackle = 1.0
        crackle *= 0.995
    return out


def rumble(seconds: float, rng: random.Random):
    """Low-passed noise that dies away, the body of an explosion."""
    count = int(seconds * RATE)
    out = []
    low = 0.0
    for i in range(count):
        low += (rng.uniform(-1, 1) - low) * 0.12
        out.append(low * (1.0 - i / count) ** 2)
    return out


def mix(*voices):
    length = max(len(v) for v in voices)
    return [sum(v[i] for v in voices if i < len(v)) for i in range(length)]


def write(path: str, samples, rms: float) -> None:
    current = math.sqrt(sum(s * s for s in samples) / len(samples))
    gain = rms / current
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767)) for s in samples
    )
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)


def main() -> None:
    rng = random.Random(8)
    # Target loudness matches the sounds these replace, so the mix doesn't change.
    write("assets/sounds/collect-1.wav", notes([988, 1319], 0.09) + tone([1319, 1319], 0.22), 0.028)
    write("assets/sounds/hit-3.wav", mix(tone([420, 110], 0.26), noise(0.12, rng)), 0.08)
    write(
        "assets/sounds/lose-10.wav",
        notes([523, 440, 349], 0.16) + tone([294, 147], 0.46, vibrato=0.02),
        0.03,
    )
    # The fuse is as long as a bomb's default fuse_time. The explosion is shorter
    # than the explosion animation, because the bomb frees itself when that ends.
    write("assets/sounds/fuse.wav", hiss(2.5, rng), 0.02)
    write(
        "assets/sounds/explosion.wav",
        mix(rumble(0.5, rng), tone([180, 40], 0.4), noise(0.08, rng)),
        0.08,
    )
    # Each death sound is shorter than its enemy's death animation, because the
    # enemy frees itself, and its sound, when that ends.
    write("assets/sounds/bat-death.wav", mix(tone([1800, 2600, 700], 0.22), noise(0.05, rng)), 0.04)
    write("assets/sounds/phantom-death.wav", tone([660, 880, 220], 0.45, vibrato=0.05), 0.03)
    write(
        "assets/sounds/spinner-death.wav",
        mix(tone([1400, 350], 0.3), tone([2100, 520], 0.3), noise(0.06, rng)),
        0.04,
    )
    write("assets/sounds/heal.wav", notes([523, 659, 784], 0.08) + tone([1047, 1047], 0.36), 0.035)
    # Shorter than the key's collected animation, because the key frees itself, and its sound, when that ends.
    write(
        "assets/sounds/key.wav",
        mix(notes([1568, 2093], 0.05) + tone([2637, 2637], 0.17), tone([3951, 3951], 0.27)),
        0.03,
    )


if __name__ == "__main__":
    main()
