/// Pomodoro döngüsünün üç fazı (PLAN K1).
enum Faz { calisma, kisaMola, uzunMola }

/// Sayacın üç durumu (PLAN K2). "Bitti" ayrı bir durum değildir.
enum Durum { bosta, calisiyor, duraklatildi }

/// Bir faz bitince sıradaki faz.
/// [donguSayaci] o ana kadar tamamlanan çalışma sayısıdır (tamamlanan dahil).
Faz siradakiFaz(Faz faz, int donguSayaci) => switch (faz) {
  Faz.calisma => donguSayaci >= 4 ? Faz.uzunMola : Faz.kisaMola,
  Faz.kisaMola || Faz.uzunMola => Faz.calisma,
};
