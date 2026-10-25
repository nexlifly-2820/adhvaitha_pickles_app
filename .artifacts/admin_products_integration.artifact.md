# Admin Dashboard Integration Guide: "Most Loved Products" & Product Cards

This guide details how every line, title, subtitle, badge, price, and weight inside the **"Most Loved Products"** and product cards (`_PremiumProductCard`) is loaded dynamically from your **Admin Dashboard / BigRock PHP Backend / MySQL database** without app updates.

---

## 1. Architecture Flow

```
[ Admin Dashboard UI ] ──► [ MySQL Database (app_products table) ]
                                      │
                                      ▼ (HTTP GET /app_products.php)
[ ProductRepository._mapToProduct() ]
                                      │
                                      ▼
[ HomePage / Product Cards ] ──► Renders every line dynamically in real-time
```

---

## 2. Product Database JSON Structure (`app_products.php`)

Each product returned by your server API endpoint (`http://api.adhvaithafoods.in/api/app_products.php`) must follow this exact JSON structure to populate every line inside the product card:

```json
[
  {
    "name": "Bellam Avakaya",
    "description": "The King of Pickles crafted from premium sun-dried mango chunks.\nPreserved in wood-pressed oils with organic jaggery and secret spices.",
    "weightPriceMap": {
      "250g": 140.0,
      "500g": 260.0,
      "1kg": 500.0
    },
    "rating": 4.9,
    "image": "https://api.adhvaithafoods.in/uploads/bellam_avakaya.jpg",
    "color": "0xFF18453B",
    "category": "Pickles",
    "isBestSeller": true,
    "isOutOfStock": false,
    "stockCount": 8,
    "isVeg": true,
    "subCategory": "The Royal Sweet & Spicy Classic",
    "viewCount": 42,
    "purchaseCount": 15,
    "trustBadges": [
      "100% Natural",
      "No Preservatives",
      "Sun-Dried",
      "Hand-Sorted"
    ],
    "origin": "Coastal Andhra, India",
    "ingredients": [
      "Premium Mango",
      "Pure Jaggery",
      "Cold-Pressed Peanut Oil"
    ],
    "preparationMethod": "Mangoes are hand-cut and sun-dried for 48 hours.",
    "shelfLife": "12 Months",
    "storageInstructions": "Keep in an airtight glass jar. Always use a dry spoon.",
    "servingSuggestion": "Pairs best with steaming hot rice and a dollop of ghee.",
    "canRequestTempering": true,
    "secretIngredient": {
      "name": "Organic Palm Jaggery",
      "description": "Our secret sweetness comes from organic palm jaggery.",
      "image": "https://api.adhvaithafoods.in/uploads/jaggery.jpg"
    }
  }
]
```

---

## 3. Field-by-Field Breakdown of What Appears Inside the Card

| JSON Field Name | Where it Appears on the Product Card |
| :--- | :--- |
| **`image`** | Top product image (with `BoxFit.cover` & zoom animation). |
| **`isBestSeller`** | Top-left badge: Displays **`#1 Bestseller`** (if `true`) or **`♥ Most Loved`** (if `false`). |
| **`name`** | Main product title in bold Philosopher font (e.g. *Bellam Avakaya*). |
| **`subCategory`** | Subtitle line right below the name (e.g. *The Royal Sweet & Spicy Classic*). |
| **`description`** | 2-line description paragraph summarizing the product. |
| **`trustBadges`** | Trust badges row at the bottom (e.g. `🍃 100% Natural  |  🥣 No Preservatives`). |
| **`weightPriceMap`** | Interactive weight selector chips (`250g`, `500g`, `1kg`) which dynamically update the displayed price. |
| **`rawPrice`** | Active price for the selected weight (e.g. `₹260`). |
| **`oldPrice`** | Strikethrough original price calculated automatically (`15%` higher). |
| **`discount`** | Discount badge (`12% OFF`). |

---

## 4. Backend PHP Script Example (`app_products.php`)

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
    $p['ingredients'] = json_decode($p['ingredients_json'], true);
    $p['isBestSeller'] = (bool)$p['is_bestseller'];
    $p['isOutOfStock'] = (bool)$p['is_out_of_stock'];
    $p['isVeg'] = (bool)$p['is_veg'];
    $formatted[] = $p;
}

echo json_encode(['products' => $formatted]);
?>
```
