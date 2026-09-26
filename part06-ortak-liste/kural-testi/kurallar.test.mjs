// Güvenlik kurallarının iddiaları — her test README'deki bir cümleyi kanıtlıyor.
// Çalıştırma (part06-ortak-liste klasöründen):
//   firebase emulators:exec --only firestore "npm --prefix kural-testi test"
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "node:fs";
import { after, before, beforeEach, describe, test } from "node:test";
import {
  arrayRemove,
  arrayUnion,
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  deleteDoc,
  where,
  writeBatch,
} from "firebase/firestore";

const KOD = "K7M4XP";
const LISTE = "liste1";
let env;

const db = (uid) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

// Kuralları atlayarak hazır veri kur: sahibi "ali", üyeleri verilen.
async function listeKur(uyeler = ["ali"], id = LISTE, kod = KOD) {
  await env.withSecurityRulesDisabled(async (c) => {
    const f = c.firestore();
    await setDoc(doc(f, "listeler", id), { uyeler, kod, olusturan: uyeler[0], olusturma: new Date() });
    await setDoc(doc(f, "kodlar", kod), { listeId: id });
    await setDoc(doc(f, "listeler", id, "urunler", "u1"), {
      ad: "Süt", alindi: false, ekleyen: uyeler[0], olusturma: new Date(),
    });
  });
}

// Uygulamanın katılma yazmasının aynısı.
function katil(uid, kod = KOD, eklenen = uid) {
  const f = db(uid);
  const b = writeBatch(f);
  b.update(doc(f, "listeler", LISTE), { uyeler: arrayUnion(eklenen) });
  b.set(doc(f, "listeler", LISTE, "katilimlar", uid), { kod });
  return b.commit();
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-ortak-liste",
    firestore: {
      rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await listeKur();
});
after(() => env.cleanup());

describe("okuma", () => {
  test("1 · üye listesini ve ürünlerini okur", async () => {
    await assertSucceeds(getDoc(doc(db("ali"), "listeler", LISTE)));
    await assertSucceeds(getDocs(collection(db("ali"), "listeler", LISTE, "urunler")));
  });

  test("2 · yabancı listeyi okuyamaz", async () => {
    await assertFails(getDoc(doc(db("veli"), "listeler", LISTE)));
  });

  test("3 · girişsiz kullanıcı hiçbir şeyi okuyamaz", async () => {
    await assertFails(getDoc(doc(db(null), "listeler", LISTE)));
    await assertFails(getDoc(doc(db(null), "kodlar", KOD)));
    await assertFails(getDocs(collection(db(null), "listeler", LISTE, "urunler")));
  });

  test("4 · kodlar taranamaz; tek kod giriş yapmış kullanıcıya sorulabilir", async () => {
    await assertFails(getDocs(collection(db("veli"), "kodlar")));
    await assertSucceeds(getDoc(doc(db("veli"), "kodlar", KOD)));
  });

  test("kendi listelerini sorgulayabilir (uygulamanın 'hangi listedeyim' sorusu)", async () => {
    const f = db("ali");
    await assertSucceeds(getDocs(query(collection(f, "listeler"), where("uyeler", "array-contains", "ali"))));
    await assertFails(getDocs(collection(f, "listeler"))); // filtresiz tarama yok
  });
});

describe("oluşturma", () => {
  test("liste + kod aynı toplu yazmada oluşturulur", async () => {
    const f = db("ayse");
    const b = writeBatch(f);
    b.set(doc(f, "listeler", "liste2"), {
      uyeler: ["ayse"], kod: "ABCDEF", olusturan: "ayse", olusturma: serverTimestamp(),
    });
    b.set(doc(f, "kodlar", "ABCDEF"), { listeId: "liste2" });
    await assertSucceeds(b.commit());
  });

  test("9 · var olan kodun üzerine yazılamaz (çakışma)", async () => {
    const f = db("ayse");
    const b = writeBatch(f);
    b.set(doc(f, "listeler", "liste2"), {
      uyeler: ["ayse"], kod: KOD, olusturan: "ayse", olusturma: serverTimestamp(),
    });
    b.set(doc(f, "kodlar", KOD), { listeId: "liste2" });
    await assertFails(b.commit());
  });

  test("başkası adına ya da geçersiz kodla liste açılamaz", async () => {
    const f = db("ayse");
    const b = writeBatch(f);
    b.set(doc(f, "listeler", "liste3"), {
      uyeler: ["ayse"], kod: "ABC0EF", olusturan: "ayse", olusturma: serverTimestamp(),
    });
    b.set(doc(f, "kodlar", "ABC0EF"), { listeId: "liste3" });
    await assertFails(b.commit());
  });
});

describe("katılma", () => {
  test("5 · doğru kodla katılım başarılı", async () => {
    await assertSucceeds(katil("veli"));
    await assertSucceeds(getDoc(doc(db("veli"), "listeler", LISTE)));
  });

  test("6 · listeId'yi bilen ama kodu yanlış olan katılamaz", async () => {
    await assertFails(katil("veli", "ZZZZZZ"));
    // katılım belgesi olmadan da olmaz
    await assertFails(updateDoc(doc(db("veli"), "listeler", LISTE), { uyeler: arrayUnion("veli") }));
  });

  test("7 · başkasını üye olarak ekleyemez", async () => {
    await assertFails(katil("veli", KOD, "hasan"));
  });

  test("8 · katılırken başka alanı değiştiremez", async () => {
    const f = db("veli");
    const b = writeBatch(f);
    b.update(doc(f, "listeler", LISTE), { uyeler: arrayUnion("veli"), kod: "ABCDEF" });
    b.set(doc(f, "listeler", LISTE, "katilimlar", "veli"), { kod: KOD });
    await assertFails(b.commit());
  });

  test("14 · 11. üye katılamaz", async () => {
    await env.clearFirestore();
    await listeKur(Array.from({ length: 10 }, (_, i) => `u${i}`));
    await assertFails(katil("onbirinci"));
  });

  test("ayrılıp yeniden katılabilir", async () => {
    await katil("veli");
    await updateDoc(doc(db("veli"), "listeler", LISTE), { uyeler: arrayRemove("veli") });
    await assertSucceeds(katil("veli"));
  });
});

describe("ürünler", () => {
  const yeniUrun = (uid, ad = "Ekmek", ekleyen = uid) =>
    setDoc(doc(db(uid), "listeler", LISTE, "urunler", `y-${uid}`), {
      ad, alindi: false, ekleyen, olusturma: serverTimestamp(),
    });

  test("üye ürün ekler, işaretler, siler", async () => {
    await assertSucceeds(yeniUrun("ali"));
    const u = doc(db("ali"), "listeler", LISTE, "urunler", "u1");
    await assertSucceeds(updateDoc(u, { alindi: true }));
    await assertSucceeds(deleteDoc(u));
  });

  test("10 · üye olmayan ürün okuyamaz ve yazamaz", async () => {
    await assertFails(getDoc(doc(db("veli"), "listeler", LISTE, "urunler", "u1")));
    await assertFails(yeniUrun("veli"));
    await assertFails(deleteDoc(doc(db("veli"), "listeler", LISTE, "urunler", "u1")));
  });

  test("11 · başkası adına ürün eklenemez", async () => {
    await assertFails(yeniUrun("ali", "Ekmek", "veli"));
  });

  test("12 · ürün adı 60 karakteri aşamaz, boş olamaz", async () => {
    await assertSucceeds(yeniUrun("ali", "a".repeat(60)));
    await assertFails(yeniUrun("ali", "a".repeat(61)));
    await assertFails(yeniUrun("ali", ""));
  });

  test("13 · ürün adı sonradan değiştirilemez", async () => {
    const u = doc(db("ali"), "listeler", LISTE, "urunler", "u1");
    await assertFails(updateDoc(u, { ad: "Zehir" }));
    await assertFails(updateDoc(u, { ekleyen: "veli" }));
  });
});

describe("ayrılma", () => {
  test("15 · üye yalnız kendini çıkarabilir", async () => {
    await katil("veli");
    await assertFails(updateDoc(doc(db("veli"), "listeler", LISTE), { uyeler: arrayRemove("ali") }));
    await assertSucceeds(updateDoc(doc(db("veli"), "listeler", LISTE), { uyeler: arrayRemove("veli") }));
  });

  test("liste silinemez", async () => {
    await assertFails(deleteDoc(doc(db("ali"), "listeler", LISTE)));
  });
});
