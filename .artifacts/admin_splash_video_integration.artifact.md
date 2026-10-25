# Admin Dashboard Integration Guide: Splash Screen Video

This guide explains how to manage the **Splash Screen background video** dynamically from your **Admin Dashboard / BigRock PHP Backend / MySQL database** without requiring an app update.

---

## 1. Database Storage (`app_settings` table)

In your MySQL database table `app_settings`, ensure you have a row where:
- `doc_id` = `'splash_video'`
- `content` = JSON payload storing video configuration.

---

## 2. JSON Payload Structure

```json
{
  "enabled": true,
  "video_url": "https://api.adhvaithafoods.in/uploads/splash_video.mp4",
  "title": "AmbhuJakshi Royal Collection"
}
```

### Field Definitions:
- **`enabled`**: Boolean (`true` or `false`) to enable or disable background video on the splash screen.
- **`video_url`**: Network video URL (or local asset path) played in the background of the splash screen.
- **`title`**: Title or description for admin reference.

---

## 3. Backend PHP Script (`app_settings.php`)

Your PHP endpoint (`http://api.adhvaithafoods.in/api/app_settings.php?doc_id=splash_video`) fetches and returns this JSON payload.
