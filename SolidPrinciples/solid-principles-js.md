# 🧱 SOLID原則（JavaScriptで例えると）
## 🧱 S：単一責任の原則（Single Responsibility Principle）

> 1つの関数・コンポーネントは、1つの仕事だけをする。

### ❌ 悪い例

```vue
<script setup>
function saveUser(user) {
  // バリデーション
  if (!user.name) throw new Error('名前が必要です')

  // データ保存
  localStorage.setItem('user', JSON.stringify(user))

  // 通知表示
  alert('保存しました！')
}
</script>
```

→ **バリデーション・保存・通知** を1つの関数でやってる。
修正するときに他の処理も壊す可能性がある。

### ✅ 良い例

```vue
<script setup>
function validateUser(user) {
  if (!user.name) throw new Error('名前が必要です')
}

function saveUser(user) {
  localStorage.setItem('user', JSON.stringify(user))
}

function notifySuccess() {
  alert('保存しました！')
}
</script>
```

→ 責任が分かれているので、**テストや修正がしやすい。**

---

## 🧩 O：開放・閉鎖の原則（Open-Closed Principle）

> 新しい機能を追加できるようにして、既存コードはできるだけ変えない。

### ❌ 悪い例

```js
function getDiscount(price, type) {
  if (type === 'student') return price * 0.8
  if (type === 'member') return price * 0.9
}
```

→ 新しい割引（例：`vip`）を追加するたびに、この関数を直さなきゃいけない。

### ✅ 良い例

```js
const discountStrategies = {
  student: (price) => price * 0.8,
  member: (price) => price * 0.9,
}

function getDiscount(price, type) {
  const discount = discountStrategies[type]
  return discount ? discount(price) : price
}
```

→ 新しい割引を「追加」するだけで済む。
**コードを直さずに拡張できる。**

---

## 🧠 L：リスコフの置換原則（Liskov Substitution Principle）

> 「親クラス（共通の型）」として扱っても、問題なく動くようにする。

### 例

```js
class Bird {
  fly() {
    console.log('飛んだ！')
  }
}

class Penguin extends Bird {
  fly() {
    throw new Error('ペンギンは飛べません！')
  }
}
```

→ どっちも「Bird」だけど、ペンギンだけエラーが出る。
これはLSP違反。

### ✅ 修正例

```js
class Bird {
  move() {
    console.log('動いた！')
  }
}

class Sparrow extends Bird {
  move() {
    console.log('空を飛んだ！')
  }
}

class Penguin extends Bird {
  move() {
    console.log('泳いだ！')
  }
}
```

→ 「動く」という抽象的な共通ルールにすれば、どの子も安心して使える。

---

## ⚙️ I：インターフェイス分離の原則（Interface Segregation Principle）

> 使う人に必要なメソッドだけ渡す。

### ❌ 悪い例

```js
class Printer {
  print() {}
  scan() {}
  fax() {}
}

function usePrinter(device) {
  device.print()
}
```

→ `usePrinter` は印刷だけ使うのに、`scan` や `fax` まで持ってる。

### ✅ 良い例（JSではインターフェイスの代わりに関数分割で表現）

```js
function createPrintService() {
  return {
    print: () => console.log('印刷！')
  }
}

function createScanService() {
  return {
    scan: () => console.log('スキャン！')
  }
}

const printer = createPrintService()
printer.print() // OK
```

→ 必要な機能だけを切り出して渡す。

---

## 🧰 D：依存関係逆転の原則（Dependency Inversion Principle）

> 具体的な機能に直接頼らず、「抽象的なルール」に頼る。

### ❌ 悪い例

```js
function saveToLocalStorage(data) {
  localStorage.setItem('data', JSON.stringify(data))
}
```

→ 保存先が「localStorage」に固定。サーバー保存に切り替えたい時、関数を書き換える必要がある。

### ✅ 良い例

```js
function saveData(data, storage) {
  storage.save(data)
}

// 抽象ルール（save）を持つオブジェクト
const localStorageSaver = {
  save: (data) => localStorage.setItem('data', JSON.stringify(data))
}

const serverSaver = {
  save: (data) => fetch('/api/save', { method: 'POST', body: JSON.stringify(data) })
}

// どちらにも対応できる
saveData({ name: 'Tarou' }, localStorageSaver)
saveData({ name: 'Tarou' }, serverSaver)
```

→ 「どんな保存方法でもOK」な形にしておけば、依存が逆転する。

---

## 🎯 Vueでの応用（ざっくりまとめ）

| 原則 | Vueでの考え方                     |
| -- | ---------------------------- |
| S  | 1つのコンポーネント・関数に1つの責任          |
| O  | propsやslotで拡張性を持たせる          |
| L  | 継承・Composableでも共通動作を崩さない     |
| I  | 小さいComposableやService関数に分割する |
| D  | 直接storeやAPIに依存せず、抽象化する       |

---
