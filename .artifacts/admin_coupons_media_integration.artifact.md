# Admin Dashboard Integration Guide: Coupons Section (Media Cards)

This guide explains how to manage the **Home Page Coupons / Privileges section** dynamically from your **Admin Dashboard / BigRock PHP Backend / MySQL database** without requiring an app update.

---

## 1. Database Storage (`app_settings` table)

In your MySQL database table `app_settings`, ensure you have a row where:
- `doc_id` = `'coupons'`
- `content` = JSON payload storing the list of active coupon media items.

---

## 2. JSON Payload Structure (Images & Videos, No Text Overlays)

```json
{
  "active_list": [
    {
      "type": "image",
      "image": "https://api.adhvaithafoods.in/uploads/homecoupon1.png"
    },
    {
      "type": "video",
      "video_url": "https://api.adhvaithafoods.in/uploads/coupon_promo.mp4"
    },
    {
      "type": "image",
      "image": "https://api.adhvaithafoods.in/uploads/homecoupon3.png"
    }
  ]
}
```

### Field Definitions:
- **`active_list`**: Array of coupon cards.
- **`type`**: `"image"` or `"video"`.
- **`image` / `video_url`**: Network URL (or local asset path) for the media file.
- **No Text Overlays**: As requested, the app displays *only* the raw media (image or video) with zero text overlays on the card, so all design/text is handled directly inside your uploaded media files.

---

## 3. Backend PHP Script (`app_settings.php`)

Your PHP endpoint (`http://api.adhvaithafoods.in/api/app_settings.php?doc_id=coupons`) fetches and returns this JSON payload.
