# Most Loved Products Section: Admin Dashboard & Image Prompt Guide

This guide provides the exact AI image generation prompts for bowl-shaped product images with transparent backgrounds, along with database seeding scripts to ensure **at least 5 products** appear in the Most Loved section.

---

## 1. AI Image Generation Prompt (Bowl-Shaped, Transparent Background)

When generating or editing product images for the Most Loved section (using Midjourney, DALL-E, or Stable Diffusion), use this exact prompt structure to ensure the product is in a traditional bowl with **no white rectangular backdrop or harsh background**:

> **Prompt:**
> ```text
> Professional food photography of [Product Name e.g., Traditional Andhra Mango Pickle / Bellam Avakaya] served in an ornate traditional brass and ceramic bowl, 45-degree angle top-down view, isolated on a pure transparent background or subtle warm dark vignette, studio lighting, hyper-detailed texture, mouth-watering homemade quality, clean edge isolation, no white background backdrop --v 6.0 --transparent
> ```

---

## 2. Seeding at Least 5 Products in Admin Dashboard (JSON / Database)

To ensure the Most Loved section displays **at least 5 products** from your admin backend, use this JSON structure or PostgreSQL insert script:

### JSON Payload for API (`/api/home/most-loved` or config repository):
```json
{
  "settings": {
    "enabled": true,
    "kicker": "THE LOVE CHART",
    "title": "Most loved",
    "titleAccent": "products",
    "intervalMs": 2500,
    "maxItems": 10
  },
  "products": [
    {
      "id": "p1",
      "name": "Bellam Avakaya",
      "short": "Avakaya",
      "tagline": "sweet jaggery meets fiery mango",
      "image": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg",
      "loves": "2.1k",
      "badge": "👑 No.1 this week",
      "colors": ["#F7B733", "#E2722B"],
      "rating": 4.8,
      "soldToday": 320,
      "spice": 2,
      "variants": [
        {"id": "v1", "label": "250g", "price": 120, "mrp": 136, "inStock": true},
        {"id": "v2", "label": "500g", "price": 230, "mrp": 260, "inStock": true},
        {"id": "v3", "label": "1kg", "price": 440, "mrp": 500, "inStock": true}
      ]
    },
    {
      "id": "p2",
      "name": "Idli Karam Podi",
      "short": "Karam Podi",
      "tagline": "authentic gun powder spice blend",
      "image": "assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg",
      "loves": "1.8k",
      "badge": "🔥 Bestseller",
      "colors": ["#8E1B2B", "#5C0A0D"],
      "rating": 4.9,
      "soldToday": 280,
      "spice": 3,
      "variants": [
        {"id": "v4", "label": "200g", "price": 139, "mrp": 150, "inStock": true},
        {"id": "v5", "label": "500g", "price": 320, "mrp": 350, "inStock": true}
      ]
    },
    {
      "id": "p3",
      "name": "Kara Murukku",
      "short": "Murukku",
      "tagline": "crispy spiral festive savory",
      "image": "assets/images/karam_janthukalu_murukku_strings_snack.jpg",
      "loves": "1.4k",
      "badge": "✨ Crunchy",
      "colors": ["#18453B", "#235D4E"],
      "rating": 4.7,
      "soldToday": 195,
      "spice": 1,
      "variants": [
        {"id": "v6", "label": "250g", "price": 129, "mrp": 140, "inStock": true},
        {"id": "v7", "label": "500g", "price": 249, "mrp": 270, "inStock": true}
      ]
    },
    {
      "id": "p4",
      "name": "Sunnunda Laddu",
      "short": "Sunnunda",
      "tagline": "roasted urad dal & pure cow ghee",
      "image": "assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg",
      "loves": "1.9k",
      "badge": "🍯 Ghee Special",
      "colors": ["#8B4513", "#B8860B"],
      "rating": 4.9,
      "soldToday": 210,
      "spice": 0,
      "variants": [
        {"id": "v8", "label": "250g", "price": 199, "mrp": 220, "inStock": true},
        {"id": "v9", "label": "500g", "price": 380, "mrp": 420, "inStock": true}
      ]
    },
    {
      "id": "p5",
      "name": "Gongura Pickle",
      "short": "Gongura",
      "tagline": "tangy sorrel leaves with garlic",
      "image": "assets/images/gongura_pickle.png",
      "loves": "1.6k",
      "badge": "🌿 Andhra Pride",
      "colors": ["#1E7A46", "#0F3F33"],
      "rating": 4.9,
      "soldToday": 245,
      "spice": 3,
      "variants": [
        {"id": "v10", "label": "250g", "price": 130, "mrp": 145, "inStock": true},
        {"id": "v11", "label": "500g", "price": 245, "mrp": 275, "inStock": true}
      ]
    }
  ]
}
```
