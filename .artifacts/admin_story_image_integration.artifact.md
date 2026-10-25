# Admin Dashboard Guide: Snack Story Artwork Images (`storyImage`)

This guide shows you exactly what to do in your MySQL database, PHP backend, and Admin Panel UI so you can manage the **Story Artwork Image** shown above each snack card dynamically from your admin dashboard.

---

## 1. Database Table Update (MySQL)

In your MySQL database table (`app_products`), add a new column for the story image:

```sql
ALTER TABLE app_products
ADD COLUMN story_image VARCHAR(512) DEFAULT '';
```

---

## 2. API JSON Structure (`app_products.php`)

Each product returned by your server API must include the `storyImage` field:

```json
[
  {
    "name": "Chakinalu",
    "category": "Snacks",
    "description": "Traditional Sankranti spiral snacks.",
    "image": "https://api.adhvaithafoods.in/uploads/chakinalu.jpg",
    "storyImage": "https://api.adhvaithafoods.in/uploads/chakinalu_story.png",
    "weightPriceMap": {"250g": 120.0, "500g": 220.0},
    "isBestSeller": false
  }
]
```

### Field Definition:
- **`storyImage`**: The direct image URL (or asset path) of the wavy story artwork displayed directly above the snack product card on the home screen.

---

## 3. Backend PHP Script (`app_products.php`)

Ensure your PHP backend script maps the database column to `storyImage`:

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
    $p['storyImage'] = $p['story_image']; // Map database column to API field
    $formatted[] = $p;
}

echo json_encode(['products' => $formatted]);
?>
```

---

## 4. Admin Dashboard UI Form Field (HTML / PHP)

In your product add/edit form in the admin panel, add an input field for the story image URL:

```html
<div class="form-group">
  <label>Snack Story Artwork Image URL:</label>
  <input type="text" name="story_image" placeholder="https://api.adhvaithafoods.in/uploads/story.png" class="form-control">
</div>
```
