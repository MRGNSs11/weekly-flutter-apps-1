"""Uygulama ikonunu üretir: ikon-secenekleri.html → #1 Buğulu not.

Mavi gradyan zemin, beyaz not kartı; kartın alt yarısı buzlu cam, ortada kilit.
Bulanıklık vektörle çizilemediği için katmanlar PNG: zemin + ön plan +
tek renk (Android 13 temalı ikon). Eski sürümler için birleşik ic_launcher.png.

Çalıştırma (proje kökünden): python tool/ikon_uret.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

KOK = Path(__file__).resolve().parent.parent
RES = KOK / "android/app/src/main/res"

OLCEK = 8  # 108 birimlik tuval × 8 → sonra küçültülür (kenar yumuşar)
T = 108 * OLCEK

MAVI1, MAVI2 = (0x1F, 0x6F, 0xD1), (0x5A, 0xA9, 0xFF)
LACIVERT, ACIK_MAVI = (0x13, 0x20, 0x33, 255), (0x9C, 0xC8, 0xFF, 255)
SOLUK, CAM, KILIT = (0x6F, 0x7F, 0x93, 255), (0xDC, 0xEC, 0xFB, 178), (0x1F, 0x6F, 0xD1, 255)
BEYAZ = (255, 255, 255, 255)

YOGUNLUK = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def b(*d):
    return [v * OLCEK for v in d]


def zemin():
    """160° gradyan: sol üst koyu mavi → sağ alt açık mavi."""
    im = Image.new("RGBA", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(0, T):
            t = (x + y) / (2 * T)
            px[x, y] = tuple(round(a + (c - a) * t) for a, c in zip(MAVI1, MAVI2)) + (255,)
    return im


def on_plan(tek_renk=False):
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    renk = (lambda c: BEYAZ) if tek_renk else (lambda c: c)
    # Kart
    d.rounded_rectangle(b(31, 27, 77, 83), radius=9 * OLCEK, fill=renk(BEYAZ))
    if tek_renk:
        # Temalı ikon tek renk: kartın içindeki kilit boşluk olarak oyulur.
        d.rounded_rectangle(b(48, 64, 60, 74), radius=2 * OLCEK, fill=(0, 0, 0, 0))
        d.arc(b(50.5, 57.5, 57.5, 64.5), 180, 360, fill=(0, 0, 0, 0), width=round(2.2 * OLCEK))
        return im
    # Net satırlar
    d.rounded_rectangle(b(38, 36, 62, 41), radius=2.5 * OLCEK, fill=LACIVERT)
    d.rounded_rectangle(b(38, 46, 70, 50), radius=2 * OLCEK, fill=ACIK_MAVI)
    # Bulanık satırlar (camın arkası)
    bul = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bul)
    bd.rounded_rectangle(b(38, 58, 68, 62), radius=2 * OLCEK, fill=SOLUK)
    bd.rounded_rectangle(b(38, 67, 60, 71), radius=2 * OLCEK, fill=SOLUK)
    im.alpha_composite(bul.filter(ImageFilter.GaussianBlur(2.2 * OLCEK)))
    # Buzlu cam: kartın alt yarısı
    cam = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    ImageDraw.Draw(cam).rounded_rectangle(b(31, 54, 77, 83), radius=9 * OLCEK, fill=CAM)
    ImageDraw.Draw(cam).rectangle(b(31, 54, 77, 63), fill=CAM)  # üst köşeler düz
    im.alpha_composite(cam)
    # Kilit
    d = ImageDraw.Draw(im)
    d.rounded_rectangle(b(48, 64, 60, 74), radius=2 * OLCEK, fill=KILIT)
    d.arc(b(50.5, 57.5, 57.5, 64.5), 180, 360, fill=KILIT, width=round(2.2 * OLCEK))
    d.line(b(50.5 + 1.1, 61, 50.5 + 1.1, 64.5), fill=KILIT, width=round(2.2 * OLCEK))
    d.line(b(57.5 - 1.1, 61, 57.5 - 1.1, 64.5), fill=KILIT, width=round(2.2 * OLCEK))
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

    # Eski sürüm (Android 7): güvenli alanı (ortadaki 72) yuvarlak köşeli kare.
    birlesik = z.copy()
    birlesik.alpha_composite(o)
    kes = birlesik.crop(b(18, 18, 90, 90))
    maske = Image.new("L", kes.size, 0)
    ImageDraw.Draw(maske).rounded_rectangle((0, 0, *kes.size), radius=kes.size[0] // 5, fill=255)
    kes.putalpha(maske)
    kaydet(kes, "ic_launcher", 48)

    xml = RES / "mipmap-anydpi-v26" / "ic_launcher.xml"
    xml.parent.mkdir(parents=True, exist_ok=True)
    xml.write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<!-- Android 8+: katmanlar PNG (buzlu camın bulanıklığı vektörle çizilemiyor).
     Android 13+ temalı ikonda tek renk katman kullanılır. Üreten: tool/ikon_uret.py -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
""",
        encoding="utf-8",
    )
    # Önizleme (yerel)
    onz = birlesik.resize((432, 432), Image.LANCZOS)
    m = Image.new("L", onz.size, 0)
    ImageDraw.Draw(m).ellipse((0, 0, 432, 432), fill=255)
    onz.putalpha(m)
    onz.save(KOK / "build" / "ikon-onizleme.png")
    print("ikon üretildi")


if __name__ == "__main__":
    main()
