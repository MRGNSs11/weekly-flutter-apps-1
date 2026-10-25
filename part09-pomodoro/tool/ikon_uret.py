"""Uygulama ikonunu üretir: ikon-secenekleri.html → 3 · Halka + dalga.

Lacivert zemin (#1F3A93), beyaz halka, halkanın içinde alt yarıda kıvrımlı
beyaz dolgu. Bildirim ikonunun (ic_stat_pomodoro) renkli, büyük hâli.
Her şey düz şekil olduğu için ön plan vektör; dolgu halkanın içine clip-path
ile kesilir.

Çıktılar: arka plan + ön plan XML · uyarlanır ikon XML (ön plan Android 13
temalı ikonda tek renk katman olarak da kullanılır) · eski sürümler için
mipmap PNG (5 yoğunluk).
Çalıştırma (proje kökünden): python tool/ikon_uret.py
"""

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

KOK = Path(__file__).resolve().parent.parent
RES = KOK / "android/app/src/main/res"

ZEMIN = (0x1F, 0x3A, 0x93, 255)
BEYAZ = (255, 255, 255, 255)

# 108 birimlik tuvalde ölçüler (ikon-secenekleri.html → 3 ile aynı).
MERKEZ = 54
HALKA_R = 27  # çizgi ortası
HALKA_KALINLIK = 6
DOLGU_R = 22  # dolgunun kesildiği daire
DALGA_Y, DALGA_GENLIK, DALGA_BOY = 58, 2.4, 12

YOGUNLUK = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def dalga_noktalari():
    """Kıvrımlı kenarın noktaları, alttan kapanır (HTML'deki dalga() ile aynı eğri)."""
    nok = [(0, 108), (0, DALGA_Y)]
    for i in range(0, 217):  # 0,5 birim aralık: HTML'deki 2'lik adım dalgayı tırtıklı yapıyordu
        x = i / 2
        y = DALGA_Y + DALGA_GENLIK * math.sin(x * 2 * math.pi / DALGA_BOY)
        nok.append((round(x, 1) if x % 1 else int(x), round(y, 2)))
    return nok + [(108, 108)]


def daire_yolu(r):
    c = MERKEZ
    return f"M{c - r},{c} a{r},{r} 0 1,0 {2 * r},0 a{r},{r} 0 1,0 {-2 * r},0 Z"


def on_plan_xml():
    dis = HALKA_R + HALKA_KALINLIK / 2
    ic = HALKA_R - HALKA_KALINLIK / 2
    halka = f"{daire_yolu(dis)} {daire_yolu(ic)}"
    dalga = "M" + " L".join(f"{x},{y}" for x, y in dalga_noktalari()) + " Z"
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!-- İkon ön planı: beyaz halka + içinde kıvrımlı dolgu. tool/ikon_uret.py üretir. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FFFFFFFF" android:fillType="evenOdd"
        android:pathData="{halka}" />
    <group>
        <clip-path android:pathData="{daire_yolu(DOLGU_R)}" />
        <path android:fillColor="#FFFFFFFF"
            android:pathData="{dalga}" />
    </group>
</vector>
"""


ARKA = """<?xml version="1.0" encoding="utf-8"?>
<!-- İkon zemini: R1 vurgu laciverdi (#1F3A93). tool/ikon_uret.py üretir. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FF1F3A93" android:pathData="M0,0 L108,0 L108,108 L0,108 Z" />
</vector>
"""

UYARLANIR = """<?xml version="1.0" encoding="utf-8"?>
<!-- Android 8+: zemin ve ön plan vektör. Başlatıcı kendi şeklini uygular;
     Android 13+ temalı ikonda ön plan tek renk katman olarak kullanılır.
     Eski sürümler mipmap-*/ic_launcher.png'ye düşer. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
"""


def eski_ikon(boy):
    """Android 7 ve öncesi: yumuşak kare zemin + ortadaki 72 birim."""
    k = 4
    tam = boy * k
    s = tam / 72  # 72 birim görünür alan
    kay = 18  # 108'den 72'ye kırpma payı

    def p(x, y):
        return ((x - kay) * s, (y - kay) * s)

    def daire(ciz, r, renk):
        x0, y0 = p(MERKEZ - r, MERKEZ - r)
        x1, y1 = p(MERKEZ + r, MERKEZ + r)
        ciz.ellipse([x0, y0, x1, y1], fill=renk)

    resim = Image.new("RGBA", (tam, tam), (0, 0, 0, 0))
    ciz = ImageDraw.Draw(resim)
    ciz.rounded_rectangle([0, 0, tam - 1, tam - 1], radius=int(tam * 0.22), fill=ZEMIN)
    daire(ciz, HALKA_R + HALKA_KALINLIK / 2, BEYAZ)
    daire(ciz, HALKA_R - HALKA_KALINLIK / 2, ZEMIN)

    dolgu = Image.new("L", (tam, tam), 0)
    ImageDraw.Draw(dolgu).polygon([p(x, y) for x, y in dalga_noktalari()], fill=255)
    kesim = Image.new("L", (tam, tam), 0)
    daire(ImageDraw.Draw(kesim), DOLGU_R, 255)
    resim.paste(BEYAZ, (0, 0), ImageChops.multiply(dolgu, kesim))
    return resim.resize((boy, boy), Image.LANCZOS)


(RES / "drawable/ic_launcher_background.xml").write_text(ARKA, encoding="utf-8")
(RES / "drawable/ic_launcher_foreground.xml").write_text(on_plan_xml(), encoding="utf-8")
(RES / "mipmap-anydpi-v26").mkdir(exist_ok=True)
(RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(UYARLANIR, encoding="utf-8")
for ad, kat in YOGUNLUK.items():
    eski_ikon(round(48 * kat)).save(RES / f"mipmap-{ad}/ic_launcher.png")
eski_ikon(512).save(KOK / "build/ikon-512.png")
print("3 XML + 5 PNG yazıldı (+ build/ikon-512.png önizleme)")
