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


if __name__ == "__main__":
    main()
