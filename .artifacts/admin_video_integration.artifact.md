# Admin Dashboard Integration Guide: Home Screen Video & Banners

This guide explains how to manage and update the **Home Screen Video** and **Banner Cards Carousel** dynamically from your **Admin Dashboard / BigRock PHP Backend / MySQL database** without requiring an app update.

---

## 1. Architecture Flow

```
[ Admin Dashboard UI ] ──► [ MySQL Database (app_settings table) ]
                                      │
                                      ▼ (HTTP GET /app_settings.php?doc_id=home_video or banners)
[ AppConfigRepository ]
                                      │
                                      ▼ (Real-time Stream)
[ HomePage (Flutter App) ] ──► Dynamically renders video and banner cards
```

---

## 2. Home Screen Video Configuration (`doc_id = 'home_video'`)

In your `app_settings` table, store a row where:
- `doc_id` = `'home_video'`
- `content` = JSON payload:

```json
{
  "enabled": true,
  "video_url": "https://api.adhvaithafoods.in/uploads/ambhujakshi-all.mp4",
  "title": "AmbhuJakshi Royal Collection"
}
```

---

## 3. Banner Cards Carousel Configuration (`doc_id = 'banners'`)

The cards displayed immediately after the video on the home screen are driven by `doc_id = 'banners'`. You can add, remove, or reorder as many cards as you like from your admin panel.

### JSON Payload Structure:
```json
{
  "main_banners": [
    {
      "title": "AUTHENTIC ANDHRA",
      "category": "Pickles",
      "image": "https://api.adhvaithafoods.in/uploads/homeFirst.png"
    },
    {
      "title": "TRADITIONAL SNACKS",
      "category": "Snacks",
      "image": "https://api.adhvaithafoods.in/uploads/homeSecond.png"
    },
    {
      "title": "PURE SPICES",
      "category": "Spices",
      "image": "https://api.adhvaithafoods.in/uploads/homeThird.png"
    }
  ],
  "ad_banners": []
}
```

### Adding New Cards:
To add a new card, simply append a new object to the `"main_banners"` array in your database with your image URL (`image` or `img`) and `category`. The mobile app will automatically create a new card in the carousel in real-time.

---

## 4. Backend PHP Script (`app_settings.php`)

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
    echo json_encode([]);
}
?>
```
