"""Uygulama ikonunu üretir: ikon-secenekleri.html → 6 · Karmin zemin.

Dalga, sayfadaki JS `dalga(22, 86, 56, 18, 54)` ile aynı formülden çıkar.
Çıktılar: iki vektör katman (Android 8+) + eski sürümler için mipmap PNG'leri.
Çalıştırma (proje kökünden): python tool/ikon_uret.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

KARMIN = "#B5121B"
RES = Path(__file__).resolve().parent.parent / "android/app/src/main/res"


def dalga(x0, x1, y, genlik, tepe, adim=2.2):
    noktalar, i, x = [(x0, y)], 0, x0 + adim
    while x <= x1:
        u = (x - tepe) / ((x1 - x0) * 0.13)
        a = 1.2 + genlik * math.exp(-u * u)
        isaret = 1 if i % 2 else -1
        noktalar.append((x, y + isaret * a * (0.55 + 0.45 * abs(math.sin(i * 2.3)))))
        x += adim
        i += 1
    noktalar.append((x1, y))
    return noktalar


NOKTALAR = dalga(22, 86, 56, 18, 54)
YOL = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in NOKTALAR)

ARKA = f"""<?xml version="1.0" encoding="utf-8"?>
<!-- İkon zemini: düz karmin (ikon-secenekleri.html → 6). -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FF{KARMIN[1:]}" android:pathData="M0,0 L108,0 L108,108 L0,108 Z" />
</vector>
"""

ON = f"""<?xml version="1.0" encoding="utf-8"?>
<!--
  İkon ön planı: beyaz sismogram dalgası (ikon-secenekleri.html → 6).
  tool/ikon_uret.py üretir. Başlatıcı 108dp'nin yalnız ortadaki 72dp'sini
  gösterdiği için dalga %68'e küçültüldü; sayfadaki önizlemeyle aynı oranda durur.
-->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <group android:pivotX="54" android:pivotY="56" android:scaleX="0.68" android:scaleY="0.68" android:translateY="-2">
        <path
            android:strokeColor="#FFFFFFFF"
            android:strokeWidth="2.6"
            android:strokeLineJoin="round"
            android:strokeLineCap="round"
            android:pathData="{YOL}" />
    </group>
</vector>
"""

UYARLANIR = """<?xml version="1.0" encoding="utf-8"?>
<!-- Android 8+: arka plan ve ön plan ayrı katman; başlatıcı kendi şeklini
     (daire, yumuşak kare…) uygular. Eski sürümler mipmap-*/ic_launcher.png'ye düşer. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
"""


def png(boy):
    k = 8  # büyük çiz, küçült: kenarlar yumuşak olsun
    b = boy * k
    s = b / 108
    resim = Image.new("RGBA", (b, b), (0, 0, 0, 0))
    ciz = ImageDraw.Draw(resim)
    ciz.rounded_rectangle([0, 0, b - 1, b - 1], radius=int(b * 0.18), fill=KARMIN)
    ciz.line(
        [(x * s, y * s) for x, y in NOKTALAR],
        fill="white",
        width=max(1, round(2.2 * s)),
        joint="curve",
    )
    return resim.resize((boy, boy), Image.LANCZOS)


(RES / "drawable/ic_launcher_background.xml").write_text(ARKA, encoding="utf-8")
(RES / "drawable/ic_launcher_foreground.xml").write_text(ON, encoding="utf-8")
(RES / "mipmap-anydpi-v26").mkdir(exist_ok=True)
(RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(UYARLANIR, encoding="utf-8")
for klasor, boy in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
    png(boy).save(RES / f"mipmap-{klasor}/ic_launcher.png")
print(f"{len(NOKTALAR)} nokta, 3 XML + 5 PNG yazıldı")
