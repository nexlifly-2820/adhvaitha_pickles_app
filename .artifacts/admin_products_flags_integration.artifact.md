# Admin Dashboard Guide: Dedicated Section Flags (Most Loved, Best Seller, Fresh Pick)

This guide shows you exactly what to do in your MySQL database, PHP backend, and Admin Panel UI so you can display **different, dedicated products** in each home screen section while keeping the exact same card design.

---

## 1. Database Table Update (MySQL)

In your MySQL database table (`app_products`), add two new boolean columns if they don't already exist:

```sql
ALTER TABLE app_products
ADD COLUMN is_most_loved TINYINT(1) DEFAULT 0,
ADD COLUMN is_fresh_pick TINYINT(1) DEFAULT 0;
```

---

## 2. Updated API JSON Structure (`app_products.php`)

Each product returned by your server API must include these three boolean flags:

```json
[
  {
    "name": "Bellam Avakaya",
    "description": "The King of Pickles...",
    "weightPriceMap": {
      "250g": 140.0,
      "500g": 260.0,
      "1kg": 500.0
    },
    "rating": 4.9,
    "image": "https://api.adhvaithafoods.in/uploads/bellam_avakaya.jpg",
    "category": "Pickles",
    "isBestSeller": false,
    "isMostLoved": true,
    "isFreshPick": false,
    "subCategory": "The Royal Sweet & Spicy Classic",
    "trustBadges": ["100% Natural", "No Preservatives"]
  }
]
```

### Flag Definitions:
- **`isMostLoved`** (`true`/`false`): Check this to display the product in **Most Loved Products**.
- **`isBestSeller`** (`true`/`false`): Check this to display the product in **Best Sellers**.
- **`isFreshPick`** (`true`/`false`): Check this to display the product in **Fresh Picks**.

---

## 3. Backend PHP Script (`app_products.php`)

```php
<?php
header('Content-Type: application/json');
require_once 'db_connection.php';

$stmt = $pdo->prepare("SELECT * FROM app_products ORDER BY id DESC");
$stmt->execute();
$products = $stmt->fetchAll(PDO::FETCH_ASSOC);

$formatted = [];
foreach ($products as $p) {
    $p['weightPriceMap'] = json_decode($p['weight_price_json'], true);
    $p['trustBadges'] = json_decode($p['trust_badges_json'], true);
    $p['isBestSeller'] = (bool)$p['is_bestseller'];
    $p['isMostLoved'] = (bool)$p['is_most_loved'];
    $p['isFreshPick'] = (bool)$p['is_fresh_pick'];
    $formatted[] = $p;
}

echo json_encode(['products' => $formatted]);
?>
```

---

## 4. Admin Dashboard UI Checkboxes (HTML / PHP)

In your product edit/add form in the admin panel, add three checkboxes:

```html
<div class="form-group">
  <label>Section Flags:</label><br>
  <label>
    <input type="checkbox" name="is_most_loved" value="1"> Most Loved Product
  </label>&nbsp;&nbsp;
  <label>
    <input type="checkbox" name="is_best_seller" value="1"> Best Seller
  </label>&nbsp;&nbsp;
  <label>
    <input type="checkbox" name="is_fresh_pick" value="1"> Fresh Pick
  </label>
</div>
```
