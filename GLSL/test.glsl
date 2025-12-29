// レイマーチング関連
float rayStep;
float density;
float heightBias;
float distanceFromOrigin;
float noiseScale;

// rayPos  : レイの現在位置
// noisePos: ノイズ計算用の一時座標
vec3 rayPos, noisePos;
// rayDir  : カメラから奥へ進むレイ方向
// ピクセルごとに「視線（レイ）の向き」を作る
// FC : Fragment Coordinate の略
//      → gl_FragCoord の省略名（Twigl が最初から定義している）
//      → 今処理しているピクセルの画面座標（px単位）
// r  : resolution の略
//      → 画面解像度（vec2：横px, 縦px）
//      → FC を割って「ピクセル座標 → 画面内の割合」に変換するための基準
//
// FC.xy / r
//   → (0〜画面サイズ) のピクセル座標を (0.0〜1.0) の正規化座標に変換
//   → 解像度が変わっても同じ見た目になるようにする
//
// - .6
//   → 原点を画面中央付近にずらし、視点に奥行きを持たせるためのオフセット
//
// z = 1
//   → レイを画面の奥（Z方向）へ飛ばす
vec3 rayDir = vec3(FC.xy / r - .6, 1);

// 初期位置を少し奥にずらす
// 約100ステップのレイマーチング
for (rayPos.zy--; rayStep++ < 99.;) {

  // ステップが進むほど密度を増加
  // → 雲・霧のボリューム積算
  density += rayStep / 8e5;

  // 密度と高さに応じて色を加算
  o.rgb += hsv(
    .6,
    distanceFromOrigin + heightBias * .3,
    density * rayStep / 40.
  );

  // フラクタルノイズの初期スケール
  noiseScale = 4.;

  // 密度と距離に応じてレイを前進
  // → 均一でない進み方がムラを生む
  noisePos = rayPos += rayDir * density * distanceFromOrigin * .2;

  // 高さ方向の影響を蓄積
  heightBias += noisePos.y / noiseScale;

  // ノイズ用座標を歪ませる
  // ・distanceFromOrigin を更新
  // ・時間でわずかに揺らす
  // ・Z方向に周期構造を作る
  noisePos = vec3(
    (distanceFromOrigin = length(noisePos)) - .5 + sin(t) * .02,
    exp2(mod(-noisePos.z, noiseScale) / distanceFromOrigin) - .2,
    noisePos
  );

  // --- 雲の形状を決めるフラクタルノイズ ---
  // スケールを倍々にして多層ノイズを合成
  for (density = --noisePos.y; noiseScale < 1e3; noiseScale += noiseScale)
    density += .03 - abs(
      dot(
        sin(noisePos.yzx * noiseScale),
        cos(noisePos.xzz * noiseScale)
      ) / noiseScale * .6
    );
}
