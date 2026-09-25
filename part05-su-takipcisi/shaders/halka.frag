#version 460 core
// Dokunulan noktadan yayılan halkalar: su sahnesinin görüntüsünü mercek
// gibi büker. `ImageFiltered` + `ImageFilter.shader` ile çalışır; motor
// ilk vec2'ye doku boyutunu, ilk sampler2D'ye sahneyi kendisi koyar.
#include <flutter/runtime_effect.glsl>

uniform vec2 uBoyut;      // motor doldurur (doku boyutu, piksel)
uniform float uOran;      // yükseklik / genişlik (halkalar yuvarlak kalsın)
// Her halka: x, y (0–1, genişliğe/yüksekliğe göre), yarıçap (genişliğe
// göre), güç (0–1, zamanla söner). Güç 0 = boş yuva.
uniform vec4 uHalka0;
uniform vec4 uHalka1;
uniform vec4 uHalka2;
uniform vec4 uHalka3;
uniform sampler2D uSahne;  // motor doldurur

out vec4 renk;

// Halkanın bu noktaya verdiği kayma (uv) ve parlaklık.
vec3 halka(vec2 p, vec4 h) {
  if (h.w <= 0.0) return vec3(0.0);
  vec2 fark = vec2(p.x - h.x, (p.y - h.y) * uOran);
  float d = length(fark);
  if (d < 0.0001) return vec3(0.0);
  float kenar = d - h.z;
  // Halka kenarında ince bir dalga paketi: sinüs × çan eğrisi.
  float dalga = sin(kenar * 90.0) * exp(-kenar * kenar * 2500.0) * h.w;
  vec2 yon = fark / d;
  return vec3(yon * dalga * 0.012, dalga * 0.10);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uBoyut;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  vec3 toplam = halka(uv, uHalka0) + halka(uv, uHalka1)
              + halka(uv, uHalka2) + halka(uv, uHalka3);
  vec2 kay = vec2(toplam.x, toplam.y / uOran);
  vec4 c = texture(uSahne, clamp(uv + kay, 0.0, 1.0));
  // Dalga tepesinde hafif ışık.
  renk = vec4(c.rgb + max(toplam.z, 0.0) * c.a, c.a);
}
