"""Damla sesi adaylarını sentezler (saf Python, dış dosya/lisans yok).

Uygulamadaki iki ses bununla üretildi (Ömer 6 çarpma + 4 bırakma adayı
arasından seçti). Çalıştır (proje kökünden):
    python tool/ses_uret.py
→ android/app/src/main/res/raw/damla_birak.wav ve damla_carp.wav
Damla "bloop"u: kısa sürede tizleşen sinüs + üstel sönüm. Gerçek damlada
ses, suya giren havanın titreşen kabarcığından gelir; frekansın yükselmesi
kabarcığın küçülmesinden.
"""
import math
import random
import struct
import wave
from pathlib import Path

HZ = 44100
KLASOR = Path(__file__).parent.parent / "android/app/src/main/res/raw"
random.seed(7)


def bos(saniye):
    return [0.0] * int(HZ * saniye)


def ekle(hedef, kaynak, basla=0.0, kazanc=1.0):
    b = int(HZ * basla)
    if len(hedef) < b + len(kaynak):
        hedef.extend([0.0] * (b + len(kaynak) - len(hedef)))
    for i, v in enumerate(kaynak):
        hedef[b + i] += v * kazanc
    return hedef


def bloop(f0, f1, sure, sonum, harmonik=0.0, egri=2.0):
    """f0→f1 Hz'e tizleşen ton. `egri` > 1: başta hızlı yükselir."""
    out, faz = [], 0.0
    n = int(HZ * sure)
    for i in range(n):
        t = i / HZ
        k = (t / sure) ** (1 / egri)
        f = f0 + (f1 - f0) * k
        faz += 2 * math.pi * f / HZ
        atak = min(1.0, t / 0.002)  # 2 ms yumuşak giriş: çıt sesi olmasın
        zarf = atak * math.exp(-t / sonum)
        out.append(zarf * (math.sin(faz) + harmonik * math.sin(2 * faz)))
    return out


def gurultu(sure, sonum, parlak=0.5):
    """Sıçrama/fısıltı: süzülmüş gürültü. `parlak` 0 = boğuk, 1 = tiz."""
    out, onceki = [], 0.0
    for i in range(int(HZ * sure)):
        t = i / HZ
        r = random.uniform(-1, 1)
        onceki = onceki + (1 - parlak) * (r - onceki) if parlak < 1 else r
        v = (r - onceki) if parlak >= .5 else onceki
        out.append(v * math.exp(-t / sonum) * min(1.0, t / 0.001))
    return out


def yaz(ad, ornek, tepe=0.8):
    m = max(abs(v) for v in ornek) or 1
    son = int(HZ * 0.004)  # son 4 ms'de sıfıra in
    for i in range(son):
        ornek[-1 - i] *= i / son
    with wave.open(str(KLASOR / f"{ad}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(HZ)
        w.writeframes(b"".join(struct.pack("<h", int(v / m * tepe * 32767)) for v in ornek))


# Seçilenler (2026-09-25): bırakma "b · Vınn", çarpma "1 · Klasik".
yaz("damla_birak", bloop(520, 860, 0.09, 0.04, egri=1), tepe=.3)
yaz("damla_carp", bloop(320, 1150, 0.16, 0.05))
print("tamam:", sorted(p.name for p in KLASOR.glob("damla_*.wav")))
