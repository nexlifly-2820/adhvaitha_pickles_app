# Admin Dashboard Integration Guide: Shop / Categories Section (Parent Cards & Small Cards)

This guide explains how to configure and manage the **Shop / Category Section** dynamically from your **Admin Dashboard / PHP Backend / MySQL database** without requiring any app updates.

---

## 1. Database Storage (`app_settings` table)

In your MySQL database table `app_settings`, ensure you have a row where:
- `doc_id` = `'categories'`
- `content` = JSON payload storing the list of parent category cards (image-only carousel) and their small sub-cards (displayed in rows of 2).

---

## 2. JSON Payload Structure

```json
{
  "list": [
    {
      "label": "Pickles",
      "img": "https://api.adhvaithafoods.in/uploads/pickles_parent.jpg",
      "subs": [
        {
          "img": "https://api.adhvaithafoods.in/uploads/bellam_avakaya.jpg",
          "title": "Bellam Avakaya",
          "sub": "Sweet & Spicy Mango",
          "prod": "Bellam Avakaya"
        },
        {
          "img": "https://api.adhvaithafoods.in/uploads/allam_velluli.jpg",
          "title": "Allam Velluli",
          "sub": "Ginger Garlic Pickle",
          "prod": "Allam Velluli"
        },
        {
          "img": "https://api.adhvaithafoods.in/uploads/usiri_pickle.jpg",
          "title": "Usiri Pickle",
          "sub": "Amla Traditional",
          "prod": "Usiri Pickle"
        },
        {
          "img": "https://api.adhvaithafoods.in/uploads/pandu_mirchi.jpg",
          "title": "Pandu Mirchi",
          "sub": "Red Chilli Pickle",
          "prod": "Pandu Mirchi"
        }
      ]
    },
    {
      "label": "Snacks",
      "img": "https://api.adhvaithafoods.in/uploads/snacks_parent.jpg",
      "subs": [
        {
          "img": "https://api.adhvaithafoods.in/uploads/chakinalu.jpg",
          "title": "Chakinalu",
          "sub": "Crispy Spiral Delight",
          "prod": "Chakinalu"
        },
        {
          "img": "https://api.adhvaithafoods.in/uploads/janthukalu.jpg",
          "title": "Janthukalu",
          "sub": "Crunchy Snack",
          "prod": "Janthukalu"
        }
      ]
    }
  ]
}
```

### Field Definitions:
- **`list`**: Array of parent category cards. You can add as many parent category cards as you want (they form the image-only carousel at the top of the shop section).
- **`img` (Parent Card)**: Image URL for the parent banner (displayed image-only with no text overlay).
- **`subs`**: Array of small sub-cards displayed in rows of 2 below the active parent card. You can add multiple small cards here.
- **`img` (Small Card)**: Image URL for the small card.
- **`title`**: Title text on the small card.
- **`sub`**: Subtitle/description text on the small card.
- **`prod` / `title`**: Product name or category keyword used when the small card is tapped to open the product detail or listing page.

---

## 3. Backend PHP Script (`app_settings.php`)

Your PHP endpoint (`http://api.adhvaithafoods.in/api/app_settings.php?doc_id=categories`) fetches and returns this JSON:

```php
<?php
header('Content-Type: application/json');
require_once 'db_connection.php';

$doc_id = isset($_GET['doc_id']) ? $_GET['doc_id'] : '';

if (empty($doc_id)) {
    echo json_encode(['error' => 'Missing doc_id']);
    exit;
}

$stmt = $pdo->prepare("SELECT content FROM app_settings WHERE doc_id = ?");
$stmt->execute([$doc_id]);
$row = $stmt->fetch(PDO::FETCH_ASSOC);

if ($row && !empty($row['content'])) {
    echo $row['content'];
} else {
    echo json_encode(['list' => []]);
}
?>
```

---

## 4. Admin Dashboard UI Form Example (PHP / HTML)

```html
<div class="card">
  <h2>Manage Shop / Categories Section (Parent & Small Cards)</h2>
  <form action="update_categories.php" method="POST">
    <div class="form-group">
      <label>Categories JSON Payload:</label>
      <textarea name="content" rows="15" class="form-control" required>{
  "list": [
    {
      "label": "Pickles",
      "img": "https://api.adhvaithafoods.in/uploads/pickles_parent.jpg",
      "subs": [
        {
          "img": "https://api.adhvaithafoods.in/uploads/bellam_avakaya.jpg",
          "title": "Bellam Avakaya",
          "sub": "Sweet & Spicy Mango",
          "prod": "Bellam Avakaya"
        }
      ]
    }
  ]
}</textarea>
    </div>
    <button type="submit" class="btn btn-primary">Save Categories to Server</button>
  </form>
</div>
```
