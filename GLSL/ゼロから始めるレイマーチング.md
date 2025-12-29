# ゼロから始めるレイマーチング

## 元ネタ

https://qiita.com/jpnykw/items/7096fe59d1edf3ef3aa3

## 使用する数学知識

1. ベクトル（位置・方向・単位ベクトル）
2. ベクトルの正規化（長さを 1 にする）
3. 内積（ドット積 / dot product）
4. ベクトルの長さ（ユークリッド距離）
5. 数値微分（有限差分）
6. 勾配（グラディエント / ∇）
7. 三角関数（sin, cos）
8. 線形変換（座標の正規化・スケーリング）
9. 反復計算（レイマーチング / 反復法）
10. max 関数（値の切り捨て・クランプ）
11. 球の方程式（x² + y² + z² = r²）

## コード

### 1. [円を描く](https://qiita.com/jpnykw/items/7096fe59d1edf3ef3aa3#%E5%86%86%E3%82%92%E6%8F%8F%E3%81%8F)

https://twigl.app/?ol=true&ss=-OhbsYEpnu831TDP8sHd

```glsl
precision mediump float;

// 画面サイズ（ピクセル単位）
// JS 側から渡される： (canvas.width, canvas.height)
uniform vec2 resolution;

// 点 p が原点から距離 r 未満なら 1.0（円の中）、そうでなければ 0.0（円の外）を返す関数
float circle(vec2 p, float r) {
    // length(p) = sqrt(p.x * p.x + p.y * p.y)
    // → 原点 (0,0) から点 p までの距離
    return length(p) < r ? 1.0 : 0.0;
}

void main() {
    // gl_FragCoord.xy は「今処理しているピクセルの画面座標（左下原点・px単位）」
    // それを以下の式で「画面中央が (0,0) になる正規化座標」に変換している
    //
    // 1. * 2.0 → 座標の範囲を [0 .. resolution] から [0 .. 2*resolution] に広げる
    // 2. - resolution → 範囲を [-resolution .. +resolution] にして中央を 0 にする
    // 3. / min(...) → 縦横比を補正しつつスケールを正規化する
    vec2 position = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    // position が原点から半径 0.5 以内なら白 (1.0)、外なら黒 (0.0)
    vec3 color = vec3(circle(position, 0.5));

    // このピクセルの最終色を出力（RGBA、アルファは 1.0 = 完全不透明）
    gl_FragColor = vec4(color, 1.0);
}
```

### 2.[レイを定義する](https://qiita.com/jpnykw/items/7096fe59d1edf3ef3aa3#%E3%83%AC%E3%82%A4%E3%82%92%E5%AE%9A%E7%BE%A9%E3%81%99%E3%82%8B)

https://twigl.app/?ol=true&ss=-Ohc2a8aId1t6PDErSX6

```glsl
precision mediump float;

// 画面サイズ（ピクセル単位）
// JS 側から (canvas.width, canvas.height) が渡される
uniform vec2 resolution;

// 球の半径（仮想3D空間上のスケール）
float sphereSize = 0.6;

// 球の Signed Distance Function（距離関数）
// 引数 position : 3D 空間上の点
// 戻り値：
//   正 → 球の外側（まだ当たっていない）
//   0  → 球の表面
//   負 → 球の内側（めり込んでいる）
float sphereDistanceFunction(vec3 position, float size) {
    // 原点中心の球なので、原点からの距離 length(position) と
    // 半径 size の差が「表面までの距離」になる
    return length(position) - size;
}

void main(void) {

    // gl_FragCoord.xy は「今処理しているピクセルの画面座標（px）」
    // これを「画面中央が (0,0) になる正規化座標」に変換している
    vec2 position = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    // 仮想3D空間内のカメラ位置（視点）
    // 今回は z = 10 の位置から原点方向を見ている
    vec3 cameraPosition = vec3(0.0, 0.0, 10.0);

    // カメラの前に置いた仮想スクリーンの z 座標
    // 各ピクセルはこの平面上の1点に対応する
    float screenZ = 4.0;

    // レイの進行方向を計算
    // 「カメラ位置 → スクリーン上のこのピクセルの位置」へのベクトルを作り、
    // normalize で長さ1の「方向ベクトル」にしている
    vec3 rayDirection = normalize(vec3(position, screenZ) - cameraPosition);

    // 最終的に出力する色（初期値は黒 = 何も当たっていない）
    vec3 color = vec3(0.0);

    // レイマーチングループ
    // レイを前に進めながら、球に当たるかどうかを調べる
    for (int i = 0; i < 99; i++) {

        // 今のカメラ位置から、レイ方向に少し進んだ位置を計算
        // ここでは cameraPosition を「レイの現在位置」として使っている
        vec3 rayPosition = cameraPosition + rayDirection;

        // その位置から球の表面までの距離を取得
        float dist = sphereDistanceFunction(rayPosition, sphereSize);

        // 球の表面に十分近づいたら「ヒット」と判定
        if (dist < 0.0001) {
            color = vec3(1.0); // 当たったので白くする
            break;
        }

        // 球の表面までの距離 dist 分だけ、レイを前に進める
        // SDF の性質により、この距離だけ進んでも球を飛び越えない
        cameraPosition += rayDirection * dist;
    }

    // このピクセルの最終色を出力（RGBA、アルファは 1.0 = 完全不透明）
    gl_FragColor = vec4(color, 1.0);
}
```

### 3.[法線を用いてライティング](https://qiita.com/jpnykw/items/7096fe59d1edf3ef3aa3#%E6%B3%95%E7%B7%9A%E3%82%92%E7%94%A8%E3%81%84%E3%81%A6%E3%83%A9%E3%82%A4%E3%83%86%E3%82%A3%E3%83%B3%E3%82%B0)

https://twigl.app?ol=true&ss=-Ohc6-S4Gj-XSa6zVArp

```glsl
precision mediump float;

// 画面の解像度（px単位）
uniform vec2 resolution;

// 球の半径
float sphereSize = 0.6;

// 球の Signed Distance Function
// position の位置が、球の表面からどれくらい離れているかを返す
// 0: 表面 / 正: 外側 / 負: 内側
float sphereDistanceFunction(vec3 position, float size) {
    return length(position) - size;
}

// 球の表面の向き（法線）を求める関数
// 距離関数の微小な変化量から、どちらを向いているかを計算している
vec3 getNormal(vec3 pos, float size) {
    float v = 0.001; // 微小なズレ量（差分計算用）
    return normalize(vec3(
        // x方向に少しズラした時の距離との差
        sphereDistanceFunction(pos, size) - sphereDistanceFunction(vec3(pos.x - v, pos.y, pos.z), size),
        // y方向に少しズラした時の距離との差
        sphereDistanceFunction(pos, size) - sphereDistanceFunction(vec3(pos.x, pos.y - v, pos.z), size),
        // z方向に少しズラした時の距離との差
        sphereDistanceFunction(pos, size) - sphereDistanceFunction(vec3(pos.x, pos.y, pos.z - v), size)
    ));
}

void main(void) {

    // 現在のピクセル座標を、中央原点・縦横比補正した座標に変換
    vec2 position = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    // カメラの位置（z方向に手前）
    vec3 cameraPosition = vec3(0.0, 0.0, 10.0);

    // スクリーン（投影面）の z 座標
    float screenZ = 4.0;

    // 光が飛んでくる方向（正面から）
    vec3 lightDirection = normalize(vec3(0.0, 0.0, 1.0));

    // カメラから現在ピクセル方向へ向かうレイの向き
    vec3 rayDirection = normalize(vec3(position, screenZ) - cameraPosition);

    // 最終的に表示する色（最初は黒）
    vec3 color = vec3(0.0);

    // レイが進んだ距離の合計
    float depth = 0.0;

    // レイマーチングループ（最大99回まで進める）
    for (int i = 0; i < 99; i++) {

        // 現在のレイの位置を計算
        vec3 rayPosition = cameraPosition + rayDirection * depth;

        // 現在位置から球までの距離を取得
        float dist = sphereDistanceFunction(rayPosition, sphereSize);

        // 球に十分近づいたらヒットとみなす
        if (dist < 0.0001) {

            // 球表面の向きを取得
            vec3 n = getNormal(rayPosition, sphereSize);

            // 光の向きとどれくらい一致しているかを計算（明るさ）
            float diff = max(dot(n, lightDirection), 0.0);

            // 明るさをそのままグレースケールの色として使用
            color = vec3(diff);

            // ヒットしたのでループ終了
            break;
        }

        // 球までの距離分だけレイを前に進める
        depth += dist;
    }

    // 最終的な色を出力
    gl_FragColor = vec4(color, 1.0);
}
```

## 4.[着色とアニメーション](https://qiita.com/jpnykw/items/7096fe59d1edf3ef3aa3#%E7%9D%80%E8%89%B2%E3%81%A8%E3%82%A2%E3%83%8B%E3%83%A1%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3)

https://twigl.app/?ol=true&ss=-Ohc7-kuWmL3t9SP7JeN

```glsl
precision mediump float;

// 画面の解像度（px単位）
uniform vec2 resolution;

uniform float time;

// 球の半径
float sphereSize = 0.6;

// 球の Signed Distance Function
// position の位置が、球の表面からどれくらい離れているかを返す
// 0: 表面 / 正: 外側 / 負: 内側
float sphereDistanceFunction(vec3 position, float size) {
    return length(position) - size;
}

// 球の表面の向き（法線）を求める関数
// 距離関数の微小な変化量から、どちらを向いているかを計算している
vec3 getNormal(vec3 pos, float size) {
    float v = 0.001; // 微小なズレ量（差分計算用）
    return normalize(vec3(
        // x方向に少しズラした時の距離との差
        sphereDistanceFunction(pos, size) - sphereDistanceFunction(vec3(pos.x - v, pos.y, pos.z), size),
        // y方向に少しズラした時の距離との差
        sphereDistanceFunction(pos, size) - sphereDistanceFunction(vec3(pos.x, pos.y - v, pos.z), size),
        // z方向に少しズラした時の距離との差
        sphereDistanceFunction(pos, size) - sphereDistanceFunction(vec3(pos.x, pos.y, pos.z - v), size)
    ));
}

void main(void) {

    // 現在のピクセル座標を、中央原点・縦横比補正した座標に変換
    vec2 position = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    // カメラの位置（z方向に手前）
    vec3 cameraPosition = vec3(0.0, 0.0, 10.0);

    // スクリーン（投影面）の z 座標
    float screenZ = 4.0;

    // 光が飛んでくる方向（正面から）
    vec3 lightDirection = normalize(vec3(sin(time * 3.0), cos(time * 2.0) * 2.0, 1.0));


    // カメラから現在ピクセル方向へ向かうレイの向き
    vec3 rayDirection = normalize(vec3(position, screenZ) - cameraPosition);

    // 最終的に表示する色（最初は黒）
    vec3 color = vec3(0.0);

    // レイが進んだ距離の合計
    float depth = 0.0;

    // レイマーチングループ（最大99回まで進める）
    for (int i = 0; i < 99; i++) {

        // 現在のレイの位置を計算
        vec3 rayPosition = cameraPosition + rayDirection * depth;

        // 現在位置から球までの距離を取得
        float dist = sphereDistanceFunction(rayPosition, sphereSize);

        // 球に十分近づいたらヒットとみなす
        if (dist < 0.0001) {

            // 球表面の向きを取得
            vec3 n = getNormal(rayPosition, sphereSize);

            // 光の向きとどれくらい一致しているかを計算（明るさ）
            float diff = max(dot(n, lightDirection), 0.0);

            // 明るさをそのままグレースケールの色として使用
            color = vec3(diff) + vec3(1.0, 0.7, 0.2);

            // ヒットしたのでループ終了
            break;
        }

        // 球までの距離分だけレイを前に進める
        depth += dist;
    }

    // 最終的な色を出力
    gl_FragColor = vec4(color, 1.0);
}
```
