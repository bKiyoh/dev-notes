# 『Tidy First?』 JavaScript Example
本に書かれている考え方をJavaScriptの実装例として作成

## 🧹 第Ⅰ部：整頓（コードをきれいにする）

**例題：ガード節を使って読みやすくする**

### Before（整頓前）

```js
function getDiscount(price, isMember) {
  let discount = 0
  if (isMember) {
    if (price > 10000) {
      discount = price * 0.1
    } else {
      discount = price * 0.05
    }
  } else {
    discount = 0
  }
  return discount
}
```

### After（整頓後：ガード節を使う）

```js
function getDiscount(price, isMember) {
  if (!isMember) return 0
  if (price > 10000) return price * 0.1
  return price * 0.05
}
```

👉 **ポイント：**

* 条件が合わない場合は早めにreturn（これを「ガード節」）
* ネスト（ifの中にifがある）を減らして、上から下に「読むだけ」で理解できる

---

### 🧩 説明変数を使って意味を明確にする

### Before

```js
if (user.age > 18 && user.role === 'admin') {
  allowAccess()
}
```

### After

```js
const isAdultAdmin = user.age > 18 && user.role === 'admin'
if (isAdultAdmin) {
  allowAccess()
}
```

👉 **ポイント：**

* 複雑な条件式に「名前をつける」と、コードの意図がすぐわかる
* 「何をしているか」より「なぜそうしているか」が伝わる

---

### ✂️ 冗長なコメントを削除する

### Before

```js
// 変数aを1増やす
a = a + 1
```

### After

```js
a += 1
```

👉 **コメントで説明するより、コードをわかりやすく書くことが第一。**
コメントは「理由」や「背景」など、コードでは表せない情報に使う。

---

## ⚙️ 第Ⅱ部：管理術（整頓のタイミングややり方）

整頓は常にやればいいというものではなく、**タイミング**と**範囲**が大事。

### 💡 例：バッチサイズ（小さく直す）

### 悪い例：一度に全部書き換える

```js
// 一気に関数名・ロジック・構造すべて変更
```

### 良い例：小さく分けて直す

1. 変数名を変更する
2. 関数の責務を分ける
3. 新しい関数に置き換える

#### 例：

```js
// Step 1: 関数名だけ整理
function calcDiscount(price, member) { ... }

// Step 2: 条件分岐をシンプルに
function calcDiscount(price, member) {
  if (!member) return 0
  return price > 10000 ? price * 0.1 : price * 0.05
}

// Step 3: 定数を分離
const HIGH_PRICE = 10000
const HIGH_DISCOUNT = 0.1
const NORMAL_DISCOUNT = 0.05
function calcDiscount(price, member) {
  if (!member) return 0
  return price > HIGH_PRICE ? price * HIGH_DISCOUNT : price * NORMAL_DISCOUNT
}
```

👉 **ポイント：**

* 「小さく直す → テストする → 小さく直す」を繰り返す
* 大きな変更より「いつでも戻せる」変更を心がける

---

## 🧠 第Ⅲ部：理論（なぜ整えるのか）

### 🧩 結合と分離（部品をゆるくつなぐ）

### 悪い例（強い結合）

```js
function sendEmail(user) {
  const email = `${user.firstName}.${user.lastName}@example.com`
  console.log(`Send mail to ${email}`)
}
```

この関数は「メールアドレスの作り方」に強く依存している
もし仕様が変わったら、ここを必ず直さなければいけない

### 良い例（ゆるく結合）

```js
function formatEmail(user) {
  return `${user.firstName}.${user.lastName}@example.com`
}

function sendEmail(email) {
  console.log(`Send mail to ${email}`)
}

const email = formatEmail(user)
sendEmail(email)
```

👉 **ポイント：**

* 関数を分けることで、1つを変更しても他に影響しにくい
* これが「結合を弱める」「凝集を高める」設計

---
