# Admin Dashboard Guide: Product Ingredients (Name + Image Grid)

This guide shows you exactly what to do in your MySQL database, PHP backend, and Admin Panel UI so you can manage the **Ingredients Grid** (circular ingredient images and titles) dynamically from your admin dashboard.

---

## 1. Database Table Update (MySQL)

Ensure your database table (`app_products`) has a text/JSON column for ingredients:

```sql
ALTER TABLE app_products
ADD COLUMN ingredients_json TEXT;
```

---

## 2. API JSON Payload Structure (`app_products.php`)

Each product returned by your server API must include an array of ingredient objects containing `name` and `image`:

```json
[
  {
    "name": "Bellam Avakaya",
    "category": "Pickles",
    "ingredients": [
      {
        "name": "Raw Mangoes",
        "image": "https://api.adhvaithafoods.in/uploads/mango.jpg"
      },
      {
        "name": "Pure Jaggery",
        "image": "https://api.adhvaithafoods.in/uploads/jaggery.jpg"
      },
      {
        "name": "Red Chilli Powder",
        "image": "https://api.adhvaithafoods.in/uploads/chilli.jpg"
      },
      {
        "name": "Mustard Seeds",
        "image": "https://api.adhvaithafoods.in/uploads/mustard.jpg"
      }
    ]
  }
]
```

### Field Definitions:
- **`name`**: The display name of the ingredient (e.g. *Raw Mangoes*).
- **`image`**: The direct image URL (or asset path) of the ingredient thumbnail.

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
    $p['ingredients'] = json_decode($p['ingredients_json'], true); // Decodes JSON array of name & image
    $formatted[] = $p;
}

echo json_encode(['products' => $formatted]);
?>
```

---

## 4. Admin Dashboard UI Form (Dynamic Repeater for Ingredients)

In your admin dashboard product form, allow the admin to add multiple ingredient rows (Name + Image URL):

```html
<div class="form-group">
  <label><strong>Product Ingredients (Name & Image):</strong></label>
  <div id="ingredients-container">
    <div class="ingredient-row" style="display:flex; gap:10px; margin-bottom:10px;">
      <input type="text" name="ingredient_name[]" placeholder="Ingredient Name (e.g. Raw Mangoes)" class="form-control">
      <input type="text" name="ingredient_image[]" placeholder="Image URL (https://...)" class="form-control">
    </div>
  </div>
  <button type="button" onclick="addIngredientRow()" class="btn btn-sm btn-secondary">+ Add Ingredient</button>
</div>

<script>
function addIngredientRow() {
  const container = document.getElementById('ingredients-container');
  const row = document.createElement('div');
  row.className = 'ingredient-row';
  row.style.cssText = 'display:flex; gap:10px; margin-bottom:10px;';
  row.innerHTML = `
    <input type="text" name="ingredient_name[]" placeholder="Ingredient Name" class="form-control">
    <input type="text" name="ingredient_image[]" placeholder="Image URL" class="form-control">
  `;
  container.appendChild(row);
}
</script>
```
