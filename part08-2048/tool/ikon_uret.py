"""Uygulama ikonunu üretir: ikon-secenekleri.html → 1 · Tek kare, turuncu 2048.

Kabarık gölge Android'in vektör ikon biçiminde yapılamadığı için ön plan PNG:
108 birimlik tuvalde 58×58 kare (köşe 14), iki gölge (sağ-alt koyu, sol-üst
açık, 3,5 birim kayık, bulanıklık yarıçapı 7) ve Nunito 900 ile turuncu "2048".
Zemin düz beton rengi (vektör).

Çıktılar: arka plan XML · ön plan PNG (5 yoğunluk) · tek renk PNG (Android 13
temalı ikon, 5 yoğunluk) · eski sürümler için mipmap PNG (5 yoğunluk).
Çalıştırma (proje kökünden): python tool/ikon_uret.py
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

KOK = Path(__file__).resolve().parent.parent
RES = KOK / "android/app/src/main/res"
FONT = KOK / "assets/fonts/Nunito.ttf"

ZEMIN = (0xD8, 0xD8, 0xD5, 255)
GOLGE = (0xB5, 0xB5, 0xB1, 255)
ISIK = (0xFA, 0xFA, 0xF8, 255)
VURGU = (0xFF, 0x4D, 0x00, 255)

# 108 birimlik tuvalde ölçüler (ikon-secenekleri.html → 1 ile aynı).
KARE = (25, 25, 83, 83)
KOSE = 14
G = 3.5  # kabarıklık: gölge kayması; bulanıklık yarıçapı 2G
YAZI_BOY = 19

YOGUNLUK = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def yazi(ciz, s, renk):
    font = ImageFont.truetype(str(FONT), round(YAZI_BOY * s))
    font.set_variation_by_axes([900])
    ciz.text((54 * s, 54.5 * s), "2048", font=font, fill=renk, anchor="mm")


def kare_maskesi(boy, s, kayma=0.0):
    m = Image.new("L", (boy, boy), 0)
    x0, y0, x1, y1 = (v * s + kayma * s for v in KARE)
    ImageDraw.Draw(m).rounded_rectangle([x0, y0, x1, y1], radius=KOSE * s, fill=255)
    return m


def on_plan(boy):
    """Saydam zemin üstünde gölgeli kare + yazı (108 birim = boy piksel)."""
    s = boy / 108
    resim = Image.new("RGBA", (boy, boy), (0, 0, 0, 0))
    # CSS bulanıklık yarıçapı 2G, Gauss sigması G.
    for renk, kayma in ((GOLGE, G), (ISIK, -G)):
        golge = Image.new("RGBA", (boy, boy), renk)
        maske = kare_maskesi(boy, s, kayma).filter(ImageFilter.GaussianBlur(G * s))
        golge.putalpha(maske)
        resim = Image.alpha_composite(resim, golge)
    yuz = Image.new("RGBA", (boy, boy), ZEMIN)
    yuz.putalpha(kare_maskesi(boy, s))
    resim = Image.alpha_composite(resim, yuz)
    yazi(ImageDraw.Draw(resim), s, VURGU)
    return resim


def tek_renk(boy):
    """Temalı ikon: kare dolu, yazı oyuk (sistem tek renge boyar)."""
    s = boy / 108
    maske = kare_maskesi(boy, s)
    oyuk = Image.new("L", (boy, boy), 0)
    yazi(ImageDraw.Draw(oyuk), s, 255)
    maske = ImageChops.subtract(maske, oyuk)
    resim = Image.new("RGBA", (boy, boy), (255, 255, 255, 0))
    resim.putalpha(maske)
    return resim


def eski_ikon(boy):
    """Android 7 ve öncesi: yumuşak kare zemin + ortadaki 72 birim."""
    k = 4
    tam = 108 / 72 * boy * k
    on = on_plan(round(tam))
    kes = round(tam * 18 / 108)
    on = on.crop((kes, kes, kes + boy * k, kes + boy * k))
    zemin = Image.new("RGBA", (boy * k, boy * k), (0, 0, 0, 0))
    ImageDraw.Draw(zemin).rounded_rectangle(
        [0, 0, boy * k - 1, boy * k - 1], radius=int(boy * k * 0.22), fill=ZEMIN
    )
    maske = zemin.getchannel("A")
    birlesik = Image.alpha_composite(zemin, on)
    birlesik.putalpha(ImageChops.multiply(birlesik.getchannel("A"), maske))
    return birlesik.resize((boy, boy), Image.LANCZOS)


ARKA = """<?xml version="1.0" encoding="utf-8"?>
<!-- İkon zemini: düz beton (#D8D8D5). tool/ikon_uret.py üretir. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FFD8D8D5" android:pathData="M0,0 L108,0 L108,108 L0,108 Z" />
</vector>
"""

UYARLANIR = """<?xml version="1.0" encoding="utf-8"?>
<!-- Android 8+: zemin vektör, ön plan PNG (kabarık gölge vektörde yapılamıyor).
     Başlatıcı kendi şeklini (daire, yumuşak kare…) uygular; Android 13+ temalı
     ikonda tek renk katman kullanılır. Eski sürümler mipmap-*/ic_launcher.png'ye düşer. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
"""

(RES / "drawable/ic_launcher_background.xml").write_text(ARKA, encoding="utf-8")
(RES / "mipmap-anydpi-v26").mkdir(exist_ok=True)
(RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(UYARLANIR, encoding="utf-8")
for ad, kat in YOGUNLUK.items():
    klasor = RES / f"drawable-{ad}"
    klasor.mkdir(exist_ok=True)
    on_plan(round(108 * kat)).save(klasor / "ic_launcher_foreground.png")
    tek_renk(round(108 * kat)).save(klasor / "ic_launcher_monochrome.png")
    eski_ikon(round(48 * kat)).save(RES / f"mipmap-{ad}/ic_launcher.png")
print("2 XML + 15 PNG yazıldı")
