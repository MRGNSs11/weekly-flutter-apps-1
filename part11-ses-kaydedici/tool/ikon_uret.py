"""Uygulama ikonunu üretir: ikon-secenekleri.html → #1 Çizgi ve nokta.

Mor bulut zemin (üç radyal gradyan, uygulamadaki gibi), ortada turuncu kayıt
noktası, iki yanında sönümlenen beyaz ses çizgisi. Katmanlar PNG: zemin +
ön plan + tek renk (Android 13 temalı ikon). Eski sürümler için birleşik
ic_launcher.png.

Çalıştırma (proje kökünden): python tool/ikon_uret.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

KOK = Path(__file__).resolve().parent.parent
RES = KOK / "android/app/src/main/res"

OLCEK = 8  # 108 birimlik tuval × 8 → sonra küçültülür (kenar yumuşar)
T = 108 * OLCEK

TABAN = (0x1A, 0x0F, 0x2E)
LEKELER = [  # (merkez x, merkez y, yarıçap, renk) — ikon-secenekleri.html ile aynı
    (0.20, 0.25, 0.70, (0x6A, 0x3D, 0xF0)),
    (0.85, 0.45, 0.60, (0xC0, 0x4C, 0xFD)),
    (0.40, 0.95, 0.75, (0x3A, 0x2B, 0xD8)),
]
LILA = (0xFB, 0xF8, 0xFF, 255)
TURUNCU = (0xFF, 0x7A, 0x59, 255)

YOGUNLUK = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def zemin():
    """Gradyan yumuşak: 216 px'te hesaplanıp büyütülür (ek paket gerekmez)."""
    k = 216
    im = Image.new("RGBA", (k, k))
    px = im.load()
    for j in range(k):
        for i in range(k):
            x, y = (i + 0.5) / k, (j + 0.5) / k
            renk = list(TABAN)
            for cx, cy, r, c in LEKELER:
                a = max(0.0, 1 - math.hypot(x - cx, y - cy) / r)
                renk = [p * (1 - a) + q * a for p, q in zip(renk, c)]
            px[i, j] = tuple(round(v) for v in renk) + (255,)
    return im.resize((T, T), Image.BICUBIC)


def dalga_noktalari(x0=24, x1=84, y=54, genlik=13):
    """Ortada sakin (nokta orada), iki yana doğru dalgalanıp sönen çizgi."""
    n = 1200
    for i in range(n + 1):
        t = i / n
        u = abs(t - 0.5) * 2
        zarf = math.sin(u * math.pi) if u > 0.12 else 0
        yield ((x0 + (x1 - x0) * t) * OLCEK, (y + genlik * zarf * math.sin(t * 19)) * OLCEK)


def _cizgi(d, noktalar, kalinlik, renk):
    """Sık yuvarlak damgalarla çizgi: köşeler yumuşak, uçlar yuvarlak."""
    r = kalinlik * OLCEK / 2
    for x, y in noktalar:
        d.ellipse((x - r, y - r, x + r, y + r), fill=renk)


def on_plan(tek_renk=False):
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    noktalar = list(dalga_noktalari())
    if not tek_renk:
        hale = Image.new("RGBA", (T, T), (0, 0, 0, 0))
        _cizgi(ImageDraw.Draw(hale), noktalar, 7, LILA[:3] + (89,))
        im.alpha_composite(hale)
    d = ImageDraw.Draw(im)
    _cizgi(d, noktalar, 3.2, LILA)
    r = 7.5 * OLCEK
    d.ellipse((54 * OLCEK - r, 54 * OLCEK - r, 54 * OLCEK + r, 54 * OLCEK + r),
              fill=LILA if tek_renk else TURUNCU)
    return im


def kaydet(im, ad, dp):
    for klasor, k in YOGUNLUK.items():
        hedef = RES / f"mipmap-{klasor}" / f"{ad}.png"
        hedef.parent.mkdir(parents=True, exist_ok=True)
        im.resize((round(dp * k), round(dp * k)), Image.LANCZOS).save(hedef)


def main():
    z, o = zemin(), on_plan()
    kaydet(z, "ic_launcher_background", 108)
    kaydet(o, "ic_launcher_foreground", 108)
    kaydet(on_plan(tek_renk=True), "ic_launcher_monochrome", 108)

    # Eski sürüm: güvenli alan (ortadaki 72) yuvarlak köşeli kare.
    birlesik = z.copy()
    birlesik.alpha_composite(o)
    kes = birlesik.crop([18 * OLCEK, 18 * OLCEK, 90 * OLCEK, 90 * OLCEK])
    maske = Image.new("L", kes.size, 0)
    ImageDraw.Draw(maske).rounded_rectangle((0, 0, *kes.size), radius=kes.size[0] // 5, fill=255)
    kes.putalpha(maske)
    kaydet(kes, "ic_launcher", 48)

    xml = RES / "mipmap-anydpi-v26" / "ic_launcher.xml"
    xml.parent.mkdir(parents=True, exist_ok=True)
    xml.write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<!-- Android 8+: katmanlar PNG (bulut gradyanı). Android 13+ temalı ikonda
     tek renk katman kullanılır. Üreten: tool/ikon_uret.py -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
""",
        encoding="utf-8",
    )
    # Önizleme (yerel, yayınlanmaz)
    onz = birlesik.crop([18 * OLCEK, 18 * OLCEK, 90 * OLCEK, 90 * OLCEK]).resize((432, 432), Image.LANCZOS)
    m = Image.new("L", onz.size, 0)
    ImageDraw.Draw(m).ellipse((0, 0, 432, 432), fill=255)
    onz.putalpha(m)
    (KOK / "build").mkdir(exist_ok=True)
    onz.save(KOK / "build" / "ikon-onizleme.png")
    print("ikon üretildi")


if __name__ == "__main__":
    main()
