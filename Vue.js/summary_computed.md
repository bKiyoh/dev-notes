# `computed`

## 概要

`computed` は、Vue.js が提供する **リアクティブな値の派生ロジック** を記述する仕組みです。
特定のデータが変化したときのみ再計算され、不要な処理を避けつつ、明確で保守しやすいコードを実現します。

---

## この記事で伝えたいこと

- `computed` の役割と特性を整理する
- `computed` を用いたロジック整理の具体的な形を示す
- `computed` の提供する機能と、利用上の注意点をまとめる

---

## 解決したい課題

Vue で開発していると、次のような困りごとが起きます。

1. テンプレート内で同じ計算ロジックを何度も書いてしまう
2. 大量に表示される UI の描画負荷が大きくなる
3. 派生値が増えるほど状態管理が複雑になる
4. methods を使うと「何度呼ばれても毎回再計算される」ため最適化しづらい

---

## 課題の原因

これらの課題は、以下の要因によって発生します。

- 依存関係を持つ値が増えるほど、派生ロジックが分散しやすい
- methods がキャッシュを持たないため、呼ばれるたびに処理が実行される
- テンプレートにロジックを書くと可読性が低下し、デバッグも困難になる
- 数値計算やフィルタリングなどの負荷が高い処理をテンプレート内で直接行うとパフォーマンスが落ちる

---

## 課題を解決する技術・手法

### 1. 技術・手法の概要

`computed` は、依存している値が変わらない限り **再計算されないキャッシュ付きの派生値** を定義できる仕組みです。

```ts
const fullName = computed(() => `${firstName.value} ${lastName.value}`);
```

特徴:

- getter（必要時に読み取る関数）が基本形
- setter を追加することで「書き込み可能な computed」も作れる
- 依存する ref / reactive の変化を自動で追跡
- 不要な再計算を抑制してくれる

---

### 2. 技術・手法の効果

`computed` の導入により以下が実現します。

- テンプレートが明瞭になり、ロジックと UI の責務が分離される
- パフォーマンスが向上する（キャッシュ機能）
- 依存関係を Vue が自動管理するため、値の一貫性が向上する
- コードのテスト性が上がる（純粋関数的な計算の切り出し）

---

### 3. 課題がどう解決されるか

#### 課題 1：テンプレートにロジックが散らばり読みにくい

#### Before（テンプレートに直接ロジック）

```html
<div>{{ firstName }} {{ lastName.toUpperCase() }}</div>
```

#### After（computed にロジックを集約）

```ts
const displayName = computed(
  () => `${firstName.value} ${lastName.value.toUpperCase()}`
);
```

---

```html
<div>{{ displayName }}</div>
```

**→ テンプレートがシンプルになり、ロジックの再利用性も向上。**

---

#### 課題 2：methods では毎回再計算され、パフォーマンスが悪化する

#### Before（methods：呼ぶたびに再実行）

```ts
const filtered = () => items.value.filter((item) => item.active);
```

```html
<li v-for="item in filtered()" :key="item.id">{{ item.name }}</li>
```

#### After（computed：依存値が変わった時だけ再計算）

```ts
const filtered = computed(() => items.value.filter((item) => item.active));
```

```html
<li v-for="item in filtered" :key="item.id">{{ item.name }}</li>
```

**→ 大量データのフィルタリングでも無駄な再計算が発生しない。**

---

#### 課題 3：状態を増やすほど管理が複雑になる

#### Before（派生値まで state として保持してしまう）

```ts
const width = ref(120);
const height = ref(80);
const area = ref(width.value * height.value); // 変更のたび手動更新が必要

watch([width, height], () => {
  area.value = width.value * height.value;
});
```

#### After（computed で動的に算出）

```ts
const width = ref(120);
const height = ref(80);
const area = computed(() => width.value * height.value);
```

**→ 拡張性を損なわず、派生状態を自動維持できる。**

---

#### 課題 4：同じロジックが複数箇所に重複する

#### Before（複数箇所で同じロジックをコピペ）

```ts
const displayPrice = `${price.value}円（税込 ${price.value * 1.1}円）`;
```

```ts
const displayPriceInCart = `${price.value}円（税込 ${price.value * 1.1}円）`;
```

#### After（computed に一元化）

```ts
const displayPrice = computed(
  () => `${price.value}円（税込 ${price.value * 1.1}円）`
);
```

**→ ロジックを 1 箇所に集約し、変更に強い構造になる。**

---

### 4. 活用事例

#### ■ methods との明確な使い分け

- **computed**: 「値」を返す（キャッシュされる）
- **methods**: 毎回実行される「処理」

```ts
// methods は毎回計算される
const doubleByMethod = () => count.value * 2;

// computed は count が変わらない限り再計算されない
const doubleByComputed = computed(() => count.value * 2);
```

---

#### ■ 書き込み可能な computed（getter + setter）

フォームなどで、双方向バインディングを整理したい場合に便利。

```ts
const fullName = computed({
  get: () => `${firstName.value} ${lastName.value}`,
  set: (value) => {
    const [first, last] = value.split(" ");
    firstName.value = first;
    lastName.value = last;
  },
});
```

---

#### ■ 前回の値を使った計算

computed は「依存値が変わった時にだけ」再計算されるため、
map / filter などの処理を安全に行える。

```ts
const sortedList = computed(() =>
  [...items.value].sort((a, b) => a.order - b.order)
);
```

---

#### ■ reactive と組み合わせた複雑な派生状態の整理

```ts
const state = reactive({
  width: 120,
  height: 80,
});

const area = computed(() => state.width * state.height);
```

---

#### ■ 非同期データ + フラグの組み合わせ

```ts
const isLoading = ref(false);
const hasData = ref(false);

const canDisplay = computed(() => !isLoading.value && hasData.value);
```

---

#### ■ 前回の値を取得する （Vue 3.4+ の新機能）

Vue 3.4 以上では、`computed` の getter の **第 1 引数に “前回の返り値（previous value）” が渡される** ようになりました。

```ts
const alwaysSmall = computed((previous) => {
  if (count.value <= 3) {
    return count.value;
  }
  return previous;
});
```

---

## 留意点・デメリット

### 1. 複雑な処理を computed に入れすぎると逆に読みにくくなる

算出ロジックが肥大化した場合は、
**関数として切り出す / composable 化する** など別の整理が必要。

### 2. 依存関係が暗黙になる

computed は依存を自動で追跡するため、
間接的な依存が増えると循環依存や把握しづらい状態を生む可能性がある。

### 3. 非同期処理には不向き

computed は同期的な計算が前提。
非同期値は `watch` や独自 composable を使う方が適切。

### 4. 算出した値の変更を避ける（computed の戻り値は読み取り専用）

computed の値は 派生結果の“スナップショット” であり書き換えることはできません。
値を変えたい場合は、必ず依存元の状態（ref / reactive）を更新します。

---
