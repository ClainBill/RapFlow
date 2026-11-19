"""Synthesise the bundled practice beat (our own, royalty-free).

Writes assets/beats/practice_90.wav: 90 BPM, 4/4, 16 bars, mono 22.05 kHz.
The downbeat sits exactly at 0 ms so the beat grid is known without analysis.
Run: python3 tool/make_practice_beat.py
"""
import wave
import numpy as np

SR = 22050
BPM = 90
BARS = 16
BEATS_PER_BAR = 4
beat_s = 60.0 / BPM
n = int(round(BARS * BEATS_PER_BAR * beat_s * SR))
out = np.zeros(n)
rng = np.random.default_rng(7)


def add(sig, t):
    i = int(round(t * SR))
    end = min(n, i + len(sig))
    out[i:end] += sig[: end - i]


def kick():
    t = np.arange(int(0.35 * SR)) / SR
    freq = 50 + 90 * np.exp(-t * 30)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    return np.sin(phase) * np.exp(-t * 9) * 0.9


def snare():
    t = np.arange(int(0.22 * SR)) / SR
    noise = rng.uniform(-1, 1, len(t)) * np.exp(-t * 22)
    tone = np.sin(2 * np.pi * 185 * t) * np.exp(-t * 30)
    return (noise * 0.45 + tone * 0.3)


def hat(open_=False):
    t = np.arange(int((0.12 if open_ else 0.04) * SR)) / SR
    noise = rng.uniform(-1, 1, len(t))
    noise = np.diff(noise, prepend=0)  # crude high-pass
    return noise * np.exp(-t * (25 if open_ else 90)) * 0.12


def keys(freqs, dur):
    t = np.arange(int(dur * SR)) / SR
    sig = sum(np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t) for f in freqs)
    env = np.minimum(1, t * 40) * np.exp(-t * 1.2)
    return sig * env * 0.05


# Am7 - Fmaj7 - Dm7 - E7, one chord per bar.
chords = [
    [220.0, 261.63, 329.63, 392.0],
    [174.61, 220.0, 261.63, 329.63],
    [146.83, 174.61, 220.0, 261.63],
    [164.81, 207.65, 246.94, 293.66],
]

K, S, H = kick(), snare(), hat()
for bar in range(BARS):
    t0 = bar * BEATS_PER_BAR * beat_s
    add(keys(chords[bar % 4], BEATS_PER_BAR * beat_s), t0)
    # Kick on 1, the "and" of 2 and 3; snare on 2 and 4; 8th-note hats.
    for b in (0, 1.5, 2):
        add(K, t0 + b * beat_s)
    for b in (1, 3):
        add(S, t0 + b * beat_s)
    for e in range(8):
        add(hat(open_=(e == 7)), t0 + e * beat_s / 2)

out = out / np.max(np.abs(out)) * 0.89
pcm = (out * 32767).astype(np.int16)
with wave.open("assets/beats/practice_90.wav", "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print(f"wrote {n} samples, {n / SR:.2f} s")
