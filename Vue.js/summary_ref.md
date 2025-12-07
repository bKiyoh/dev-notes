# `ref()`, `reactive()`,`shallowRef()`

## 概要

Vue では、データの値が変わったときに自動で画面を更新してくれる「リアクティブシステム」があります。
`ref` は、そのリアクティブシステムに「この値の変化をちゃんと追いかけてね」と Vue に教えるための機能です。

この記事では、

- なぜ `ref` が必要なのか
- `ref` を使うと何が解決するのか
- 実際の使い方

を、段階的に整理して説明します。

---

## この記事で伝えたいこと　

- Vue の `ref` は「値の変化を Vue に正しく伝えるための入れ物」であること
- `ref` を使うと「値が変わったのに画面が更新されない」といった問題を防げること
- `ref` を使う場所・使わない場所を意識すると、コードの見通しが良くなること

---

## 解決したい課題

Vue で開発していると、次のような困りごとが起きます。

- 値を書き換えたのに、画面が更新されない
- ローカル変数に代入しただけでは、Vue が変化に気づいてくれない
- `setup()` 内の値をテンプレートに表示したいのに、うまく反映されない

例：

```ts
<script setup>
let count = 0;

const increment = () => {
  count++;
};
</script>

<template>
  <button @click="increment">
    {{ count }}
  </button>
</template>
```

このコードでは `count` はただのローカル変数なので、クリックしても画面は更新されません。

---

## 課題の原因

原因は、

> 「Vue が監視している“リアクティブな値”になっていない」

からです。

### 主なポイント

- Vue は「どの値を監視するか」を決めている
- 監視対象になっていない値を変えても、Vue は変更に気づかない
- Composition API (`<script setup>` など) では、
  `ref()` や `reactive()` を使って「これは監視してほしい値です」と宣言する必要がある

---

## 課題を解決する技術、手法

この課題を解決するための手法が **`ref` を使ったリアクティブな状態管理** です。

---

## 技術、手法の概要

### 1. `ref()` は「値を包むリアクティブな箱」

```ts
import { ref } from "vue";

const count = ref(0);
```

`count` に入るのは **0 そのものではなく、値を持つラッパーオブジェクト**
Vue はこのオブジェクトを監視し、変化があれば画面を更新します。

---

### 2. JavaScript 側で値を扱うときは `.value`

```ts
count.value++; // ← 箱の中身を変更
console.log(count); // → [object Object]
console.log(count.value); // → 1
```

---

### 3. テンプレート側では自動で `.value` が展開される

```ts
<template>
  <button @click="count++">{{ count }}</button>
</template>
```

テンプレート内では `{{ count }}` と書くだけで中身が表示されます。
Vue が内部で `count.value` を参照しているためです。

---

## 技術、手法の効果

`ref` を使うことで次のような効果があります。

1. **画面と状態がズレない**

   - `count.value` を変えるだけで自動的に再描画される

2. **状態の場所が明確になる**

   - 「ここがコンポーネントの状態」というのが `ref()` / `reactive()` の宣言で分かりやすい

3. **ロジックの再利用がしやすい**

   - `ref` を使ったロジックを composable 関数に切り出せる（例：`useCounter()` など）

---

## 課題がどう解決されるか

### Before: 画面が更新されないコード

```ts
<script setup>
let count = 0;

const increment = () => {
  count++;
};
</script>

<template>
  <button @click="increment">
    {{ count }}
  </button>
</template>
```

- `count` は Vue から見れば「ただのローカル変数」
- 変更しても Vue は気づかず、テンプレートは再評価されない

### After: `ref` で画面と同期するコード

```ts
<script setup>
import { ref } from "vue";

const count = ref(0);

const increment = () => {
  count.value++;
};
</script>

<template>
  <button @click="increment">
    {{ count }}
  </button>
</template>
```

- `count` は `ref` になり、Vue が変更を監視する
- `count.value++` すると、自動で再描画される

→ 「値は変わっているのに画面が変わらない」という課題が解消されます。

---

## 留意点、デメリット

### 1. `.value` を忘れやすい（Composition API 側）

JavaScript 側では必ず `.value` が必要です。

```ts
count.value++; // 正しい
count++; // 間違い（意図通り動かない）
```

- 対策：Lint ルールや TypeScript を使うとミスに気づきやすくなります。

### 2. `ref` と `reactive` の使い分け

- 単純な値（数値、文字列、真偽値など） → `ref`
- 複数のプロパティを持つオブジェクト → `reactive` か、`ref`

混在させると「どこに `.value` が必要か」分かりづらくなることがあります。

#### ▼ `reactive` の例（オブジェクトをまるごとリアクティブ化）

```ts
import { reactive } from "vue";

const user = reactive({
  name: "Alice",
  age: 18,
});

user.age++; // 直接更新（.valueは不要）
console.log(user); // { name: 'Alice', age: 19 }
```

#### reactive と ref どちらを使用すればよいか

reactive は便利だが、構造を分割するとリアクティブでなくなるため
扱いに注意が必要です。

その点、`ref` は computed とも統一して `.value` で扱えるため  
状態管理ルールがブレにくいというメリットがあります。

```ts
<script setup>
import { reactive } from 'vue'

const state = reactive({
  count: 0,
  msg: 'Hello Vue'
})

/** ここで分割代入 → リアクティブでなくなる */
const { count, msg } = state
// この時点で count と msg は普通の値（ref ではない）
// state.count を更新しても count は変わらない

const add = () => {
  state.count++   // state.count は更新される
}
</script>

<template>
  <h2>reactive を分割代入するとリアクティブを失う</h2>
  <p>state.count: {{ state.count }}</p>
  <p>count(分割代入済み): {{ count }}</p> <!-- ← 更新されない -->
  <button @click="add">count +1</button>
</template>

```

---

## 中身を追跡せず、値が丸ごと変わったときだけ更新したいときは`shallowRef`

`ref` は中の値が **オブジェクトでも配列でも深くリアクティブに**なります。

一方で `shallowRef` は **中身を追跡せず、値が丸ごと変わったときだけ更新**します。

### いつ使う？

- 大量のオブジェクトをリアクティブに持ちたくないとき
- 値の更新は「差分ではなく丸ごと更新」で十分なとき
- 大きなデータを深いリアクティブにしないことで処理を軽くしたいとき

---

#### ▼ `ref`（深い追跡）

```ts
import { ref } from "vue";

const user = ref({ name: "Alice" });

user.value.name = "Bob"; // ← プロパティ更新でもリアクティブ
console.log(user.value); // { name: 'Bob' }
```

---

#### ▼ `shallowRef`（中身は追跡しない）

```ts
import { shallowRef } from "vue";

const user = shallowRef({ name: "Alice" });

user.value.name = "Bob"; // ← 更新されない
user.value = { name: "Charlie" }; // ← 更新される
```

---

### 使い分けまとめ

| 種類       | 内部変更を追跡           | `.value` | 向いている用途                                             |
| ---------- | ------------------------ | -------- | ---------------------------------------------------------- |
| ref        | ◎ 追う                   | あり     | ほとんどのケースでこれ                                     |
| reactive   | ◎ （構造がそのままなら） | 不要     | 複数プロパティのまとまり                                   |
| shallowRef | ✕ 追わない               | あり     | 内部の値変化は不要で、更新はオブジェクト単位で行えば良い時 |

---

---
