# Onboarding Page Admin Dashboard & Database Integration Guide

This guide details how the **Onboarding Page** (`lib/onboarding_page.dart`) connects dynamically to your **BigRock PHP backend / MySQL database** via the admin dashboard, allowing you to update titles, subtitles, descriptions, background images, and overlays in real-time without releasing an app update.

---

## 1. Architecture Overview

```
[ Admin Dashboard / MySQL DB ]
           │
           ▼ (HTTP GET /app_settings.php?doc_id=onboarding)
[ ApiService.getAppConfig('onboarding') ]
           │
           ▼
[ AppConfigRepository.getOnboardingStream() ]
           │
           ▼ (Real-time Stream)
[ OnboardingPage (StatefulWidget) ] ──► Dynamically updates UI (PageView)
```

---

## 2. Database JSON Structure (BigRock Backend)

In your MySQL database table (typically `app_settings` or equivalent), store a record where `doc_id = 'onboarding'`. The `content` or `data` column should contain valid JSON structured as follows:

```json
{
  "steps": [
    {
      "title": "Taste\nThe Legacy",
      "subtitle": "Authentic Taste",
      "desc": "Experience handcrafted pickles and traditional flavors made with generations of love and care.",
      "img": "assets/images/onboarding1.jpg",
      "overlay": ""
    },
    {
      "title": "Made The\nTraditional Way",
      "subtitle": "Time-Honored Recipes",
      "desc": "Prepared using authentic recipes, natural ingredients, and the warmth of home.",
      "img": "assets/images/onboarding2.jpg",
      "overlay": "Good Food\nBrings People\nCloser ♡"
    },
    {
      "title": "Freshness\nIn Every Bite",
      "subtitle": "Pure Ingredients",
      "desc": "Carefully selected spices, farm-fresh ingredients, and authentic recipes come together to create unforgettable flavors.",
      "img": "assets/images/onboarding3.jpg",
      "overlay": ""
    }
  ]
}
```

### Field Definitions:
- **`title`**: Main headline (supports `\n` line breaks; the last word or line is automatically styled in golden accent color).
- **`subtitle`**: Small pill badge text displayed at the top left of each onboarding slide.
- **`desc`**: Paragraph description displayed below the title.
- **`img`**: Background image source. Can be a local asset path (e.g. `'assets/images/onboarding1.jpg'`) or a full network image URL from your server/cloud storage (e.g. `'https://api.adhvaithafoods.in/uploads/onboarding1.jpg'`).
- **`overlay`**: Optional cursive script text overlay positioned near the bottom right of the image (e.g., `'Good Food\nBrings People\nCloser ♡'`).

---

## 3. Admin Dashboard Implementation Model

In your admin dashboard backend (PHP), provide an interface to edit the onboarding JSON payload.

### PHP Endpoint Example (`app_settings.php`):
When the app requests `http://api.adhvaithafoods.in/api/app_settings.php?doc_id=onboarding`, your PHP script should query the database and return the JSON payload above.

---

## 4. Mobile App Implementation Highlights

### A. Repository Stream (`lib/app_config_repository.dart`)
```dart
  Stream<List<Map<String, String>>> getOnboardingStream() async* {
    yield [];
    try {
      final data = await ApiService.getAppConfig('onboarding');
      final List<dynamic> list = data['steps'] ?? [];
      yield list.map((item) => Map<String, String>.from(item)).toList();
    } catch (_) {}
  }
```

### B. Dynamic UI Rendering (`lib/onboarding_page.dart`)
- **Live Stream Listener**: Automatically updates `_steps` whenever database changes are detected.
- **Hybrid Image Loader**: Automatically detects whether `img` is a local asset path or a remote network URL (`Image.network` vs `Image.asset`), complete with fallback error handling.
- **Fallback Mechanism**: Instantly displays built-in default steps (`_defaultSteps`) while loading or when offline.
