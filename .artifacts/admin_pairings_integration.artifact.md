# Admin Dashboard Integration Guide: "The Art of Pairing" (Curated Combos)

This guide explains how to manage **"The Art of Pairing"** section (Parent combos and their sibling cards) dynamically from your **Admin Dashboard / BigRock PHP Backend / MySQL database** without requiring an app update.

---

## 1. Database Storage (`app_settings` table)

In your MySQL database table `app_settings`, ensure you have a row where:
- `doc_id` = `'pairings'`
- `content` = JSON payload storing the list of parent combos and their siblings.

---

## 2. JSON Payload Structure

```json
{
  "list": [
    {
      "isImageOnly": true,
      "title": "THE COASTAL CLASSIC",
      "subtitle": "Rice + Ghee +\nAvakaya",
      "desc": "A timeless combination that brings out the best of Andhra flavors.",
      "tagline": "Simple Food\nExtraordinary\nHappiness",
      "img": "https://api.adhvaithafoods.in/uploads/art1.png",
      "searchKey": "Avakaya",
      "subs": [
        {
          "isImageOnly": true,
          "title": "Curd Rice +\nMango Pickle",
          "sub": "Cooling curd meets tangy spice.",
          "img": "https://api.adhvaithafoods.in/uploads/artsib1.png",
          "prod": "Avakaya"
        },
        {
          "isImageOnly": true,
          "title": "Pappu +\nAvakaya",
          "sub": "The ultimate comfort meal.",
          "img": "https://api.adhvaithafoods.in/uploads/artsib2.png",
          "prod": "Avakaya"
        },
        {
          "isImageOnly": true,
          "title": "Pappu +\nAvakaya",
          "sub": "The ultimate comfort meal.",
          "img": "https://api.adhvaithafoods.in/uploads/artsib3.png",
          "prod": "Avakaya"
        },
        {
          "isImageOnly": true,
          "title": "Pappu +\nAvakaya",
          "sub": "The ultimate comfort meal.",
          "img": "https://api.adhvaithafoods.in/uploads/artsib4.png",
          "prod": "Avakaya"
        }
      ]
    }
  ]
}
```

### Field Definitions:
- **`list`**: Array of parent pairing cards. You can add as many parent items as you want.
- **`title` / `subtitle` / `desc` / `tagline`**: Main hero card texts.
- **`img`**: Image URL (network CDN URL or local asset path).
- **`searchKey`**: Keyword to search when "See Details" is clicked.
- **`subs`**: Array of sibling cards (displayed in a 2x2 grid below the hero card). You can add 2, 4, or more siblings here.

---

## 3. Backend PHP Script (`app_settings.php`)

Your PHP endpoint (`http://api.adhvaithafoods.in/api/app_settings.php?doc_id=pairings`) fetches and returns this JSON:

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
  <h2>Manage "The Art of Pairing" (Curated Combos)</h2>
  <form action="update_pairings.php" method="POST">
    <div class="form-group">
      <label>Pairings JSON Payload (Parents & Siblings):</label>
      <textarea name="content" rows="15" class="form-control" required>{
  "list": [
    {
      "title": "THE COASTAL CLASSIC",
      "subtitle": "Rice + Ghee + Avakaya",
      "desc": "A timeless combination.",
      "tagline": "Simple Food",
      "img": "https://api.adhvaithafoods.in/uploads/art1.png",
      "searchKey": "Avakaya",
      "subs": [
        {
          "title": "Curd Rice + Mango Pickle",
          "sub": "Cooling curd meets tangy spice.",
          "img": "https://api.adhvaithafoods.in/uploads/artsib1.png",
          "prod": "Avakaya"
        }
      ]
    }
  ]
}</textarea>
    </div>
    <button type="submit" class="btn btn-primary">Save Pairings to Server</button>
  </form>
</div>
```
