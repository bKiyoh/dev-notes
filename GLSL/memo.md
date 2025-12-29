# 自分の表現したいことのメモ

## きっかけ

- YoheiNishitsuji(@YoheiNishitsuji)さんの[ポスト](https://x.com/YoheiNishitsuji/status/1880399305196073072?s=20)
- この GLSL を見て、大好きなターナーの「[ノラム城、日の出 ](https://en.wikipedia.org/wiki/Norham_Castle,_Sunrise)」のようなものを作れるんじゃないかと思った
- https://twigl.app?ol=true&ss=-OgQ6nH8Z7Ndt6w6PwoK

## コード分析から

### 原文

```glsl
float i,e,g,R,s;vec3 q,p,d=vec3(FC.xy/r-.6,1);for(q.zy--;i++<99.;){e+=i/8e5;o.rgb+=hsv(.6,R+g*.3,e*i/40.);s=4.;p=q+=d*e*R*.2;g+=p.y/s;p=vec3((R=length(p))-.5+sin(t)*.02,exp2(mod(-p.z,s)/R)-.2,p);for(e=--p.y;s<1e3;s+=s)e+=.03-abs(dot(sin(p.yzx*s),cos(p.xzz*s))/s*.6);}
```

元々 twigl 専用の省略記法使われてるから下記を参考にしながらみた方がいい
https://scrapbox.io/0b5vr/twigl

### 改行と解説コメント（ChatGPT）

```glsl
// レイマーチング用の各種変数
// i : ステップカウンタ
// e : 密度（積算値）
// g : 高さ方向の歪み量
// R : 距離（length）
// s : フラクタル用スケール
float i, e, g, R, s;

// q : レイの現在位置
// p : ノイズ計算用の一時ベクトル
// d : レイ方向（画面→奥方向）
vec3 q, p, d = vec3(FC.xy / r - .6, 1);

// q.zy-- : 初期位置を少し後方にずらす（奥行き感を出す）
// i++ < 99 : 約100ステップのレイマーチング
for (q.zy--; i++ < 99.;) {

  // ステップが進むほど少しずつ密度を増やす
  // → 霧・雲の「積算」表現
  e += i / 8e5;

  // HSVで色を加算
  // ・色相は固定
  // ・距離や歪みに応じて彩度を変化
  // ・密度が高いほど明るく
  o.rgb += hsv(.6, R + g * .3, e * i / 40.);

  // フラクタルノイズの初期スケール
  s = 4.;

  // 距離と密度に応じてレイを前進
  // → 一定で進まないためムラが生まれる
  p = q += d * e * R * .2;

  // 高さ方向（y）の影響を蓄積
  // → 雲が上下方向に偏る
  g += p.y / s;

  // p を歪ませる
  // ・R = 原点からの距離
  // ・sin(t) で時間変化
  // ・exp2 + mod で周期的な層構造
  p = vec3(
    (R = length(p)) - .5 + sin(t) * .02,
    exp2(mod(-p.z, s) / R) - .2,
    p
  );

  // --- 雲の形状を決める最重要ループ ---
  // s を倍々にしながらノイズを重ねる（フラクタル）
  for (e = --p.y; s < 1e3; s += s)
    e += .03 - abs(
      // sin と cos を直交方向で合成
      // → 角のない、自然な揺らぎ
      dot(
        sin(p.yzx * s),
        cos(p.xzz * s)
      ) / s * .6
    );
}
```

### 具体的な名前に変換

```glsl
// レイマーチング関連
float rayStep;
float density;
float heightBias;
float distanceFromOrigin;
float noiseScale;

// rayPos  : レイの現在位置
// noisePos: ノイズ計算用の一時座標
// rayDir  : カメラから奥へ進むレイ方向
vec3 rayPos, noisePos;
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
```

### 16 歳でもわかるように説明してって指示

```glsl
// ===============================
// レイマーチング用パラメータ
// ===============================

// 現在のレイマーチングのステップ数
float rayStep;

// 雲・霧の濃さ（積算されていく）
float density;

// 高さ方向の影響量（上に行くほど変化を与える）
float heightBias;

// 原点（カメラ付近）からの距離
float distanceFromOrigin;

// ノイズのスケール（フラクタル用）
float noiseScale;

// rayPos   : レイの現在位置
// noisePos : ノイズ計算用の一時座標
vec3 rayPos, noisePos;

// ===============================
// レイの向きを作成
// ===============================
//
// FC : Fragment Coordinate の略
//      → gl_FragCoord の省略名（Twigl が定義）
//      → 現在処理中のピクセル座標（px）
//
// r  : resolution（画面解像度）
//      → vec2(画面幅px, 画面高さpx)
//
// FC.xy / r
//   → ピクセル座標を 0.0〜1.0 に正規化
//   → 解像度が変わっても同じ見た目になる
//
// - .6
//   → 視点を画面中央付近にずらし、奥行きを演出
//
// z = 1
//   → レイを画面の奥方向へ飛ばす
//
vec3 rayDir = vec3(FC.xy / r - .6, 1.0);

// ===============================
// レイマーチング開始
// ===============================
//
// rayPos.zy--
//   → 初期位置を少し奥にずらす
//
// rayStep++ < 99.
//   → 約100ステップ分、レイを前進させる
//
for (rayPos.zy--; rayStep++ < 99.;) {

  // -------------------------------
  // ステップが進むほど密度を増加
  // → 奥に行くほど雲・霧が濃くなる
  // -------------------------------
  density += rayStep / 8e5;

  // -------------------------------
  // 雲の色を加算
  // ・色相は固定（青系）
  // ・距離と高さで彩度を変化
  // ・密度とステップ数で明るさを決定
  //
  // ※ 加算なので、重なるほど明るくなる
  // -------------------------------
  o.rgb += hsv(
    0.6,
    distanceFromOrigin + heightBias * 0.3,
    density * rayStep / 40.0
  );

  // -------------------------------
  // フラクタルノイズの初期スケール
  // -------------------------------
  noiseScale = 4.0;

  // -------------------------------
  // レイを前進させる
  //
  // density・距離に応じて進み方を変えることで
  // 均一でない「ムラ」を作る
  // -------------------------------
  noisePos = rayPos += rayDir * density * distanceFromOrigin * 0.2;

  // -------------------------------
  // 高さ方向の影響を蓄積
  // → 雲が上下方向で変化するようにする
  // -------------------------------
  heightBias += noisePos.y / noiseScale;

  // -------------------------------
  // ノイズ用座標の歪み処理
  //
  // x:
  //   ・原点からの距離を計算
  //   ・時間でわずかに揺らす
  //
  // y:
  //   ・Z方向に周期構造を作る
  //
  // z:
  //   ・元の位置情報を保持
  // -------------------------------
  noisePos = vec3(
    (distanceFromOrigin = length(noisePos)) - 0.5 + sin(t) * 0.02,
    exp2(mod(-noisePos.z, noiseScale) / distanceFromOrigin) - 0.2,
    noisePos
  );

  // ===============================
  // フラクタルノイズ生成
  // ===============================
  //
  // 小さいノイズ → 大きいノイズへ
  // スケールを倍々にして合成することで
  // 自然な雲の形状を作る
  //
  for (density = --noisePos.y; noiseScale < 1e3; noiseScale += noiseScale) {

    density += 0.03 - abs(
      dot(
        sin(noisePos.yzx * noiseScale),
        cos(noisePos.xzz * noiseScale)
      ) / noiseScale * 0.6
    );
  }
}
```

## コード分解

頭から調べて、どういう役割でどんな動きをするのか

### レイマーチング

```glsl
// レイマーチング関連
float rayStep;
float density;
float heightBias;
float distanceFromOrigin;
float noiseScale;
```

#### レイマーチングとは

> レイマーチングはレイトレーシングの一種です。
> レイトレーシングは視点に入ってくる光(レイ)の経路を追跡(トレース)する手法で、レイマーチングはトレースの際に光(レイ)を行進(マーチ)させるため、レイマーチングと呼ばれます。
> https://logicalbeat.jp/blog/6237/

a
