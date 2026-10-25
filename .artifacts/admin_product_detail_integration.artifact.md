# Admin Dashboard Guide: Complete Product Detail Page Fields

This guide outlines every single section, card, and field that appears on the **Product Detail Page** (`ProductDetailPage`), and how to fill them out in your **Admin Dashboard / Database**.

---

## 1. Summary & Header Info (Top Card)
- **Product Name (`name`)**: The main title (e.g., *Bellam Avakaya*).
- **Subtitle (`subCategory`)**: Descriptive subtitle (e.g., *Sweet Jaggery Mango Pickle*).
- **Rating (`rating`)**: Star rating number (e.g., `4.9`).
- **Main Image & Gallery Thumbnails (`image` + Gallery array)**:
  - Main product image URL.
  - 4 additional thumbnail/sub-image URLs shown in the horizontal row below the main image. Clicking a thumbnail updates the main view.
- **Weights & Prices (`weightPriceMap`)**: Size variants and prices (e.g., `250g: ₹140`, `500g: ₹260`, `1kg: ₹500`).

---

## 2. Description & Highlights
- **3-Line Description (`description`)**: Bulleted or paragraph description highlighting traditional heritage and taste.
- **Trust Badges (`trustBadges`)**: List of badges (e.g., `["100% Natural", "No Preservatives", "Sun-Dried", "Hand-Sorted"]`).

---

## 3. Secret Ingredient Card
- **Secret Ingredient Name (`secretIngredient.name`)**: E.g., *Organic Palm Jaggery*.
- **Secret Ingredient Description (`secretIngredient.description`)**: Detailed backstory.
- **Secret Ingredient Image (`secretIngredient.image`)**: Image URL of the secret ingredient.

---

## 4. Master Artisan Card
- **Artisan Name (`artisanName`)**: E.g., *Smt. Annapurna*.
- **Artisan Image (`artisanImage`)**: Photo URL of the master maker.
- **Artisan Bio (`artisanDescription`)**: Experience and heritage bio.

---

## 5. Curated Sommelier Pairings
- **Pairing Cards List (`sommelierPairings`)**:
  - **Title**: E.g., *Artisanal Sourdough*.
  - **Description**: How it pairs.
  - **Icon**: Icon identifier (e.g., `bakery_dining`, `lunch_dining`).

---

## 6. Traditional Recipes & Serving Suggestions
- **Recipes List (`recipes`)**:
  - **Title**: E.g., *The Coastal Classic*.
  - **Instruction**: Step-by-step pairing instruction.
- **Origin (`origin`)**: E.g., *Coastal Andhra, India*.
- **Ingredients List (`ingredients`)**: Array of raw ingredients.
- **Preparation Method (`preparationMethod`)**: Traditional process.
- **Shelf Life (`shelfLife`)**: E.g., *12 Months*.
- **Storage Instructions (`storageInstructions`)**: Care and glass jar instructions.
- **Serving Suggestion (`servingSuggestion`)**: Best ways to serve.

---

## 7. Complete JSON Payload Example for Admin Dashboard

```json
{
  "name": "Bellam Avakaya",
  "subCategory": "Sweet Jaggery Mango Pickle",
  "rating": 4.9,
  "image": "https://api.adhvaithafoods.in/uploads/bellam_avakaya.jpg",
  "gallery": [
    "https://api.adhvaithafoods.in/uploads/bellam_avakaya_1.jpg",
    "https://api.adhvaithafoods.in/uploads/bellam_avakaya_2.jpg",
    "https://api.adhvaithafoods.in/uploads/bellam_avakaya_3.jpg",
    "https://api.adhvaithafoods.in/uploads/bellam_avakaya_4.jpg"
  ],
  "weightPriceMap": {
    "250g": 140.0,
    "500g": 260.0,
    "1kg": 500.0
  },
  "description": "The King of Pickles crafted from premium sun-dried mango chunks.\nPreserved in wood-pressed oils with organic jaggery and secret spices.",
  "trustBadges": ["100% Natural", "No Preservatives", "Sun-Dried"],
  "secretIngredient": {
    "name": "Organic Palm Jaggery",
    "description": "Our secret sweetness comes from organic palm jaggery.",
    "image": "https://api.adhvaithafoods.in/uploads/jaggery.jpg"
  },
  "artisanName": "Smt. Annapurna",
  "artisanImage": "https://api.adhvaithafoods.in/uploads/artisan.jpg",
  "artisanDescription": "Master Pickle Maker with over 40 years of experience.",
  "sommelierPairings": [
    {
      "title": "Artisanal Sourdough",
      "description": "The tangy crust complements the sweet-spicy notes.",
      "icon": "bakery_dining"
    }
  ],
  "recipes": [
    {
      "title": "The Coastal Classic",
      "instruction": "Mix with steaming hot rice and a generous dollop of Desi Ghee."
    }
  ],
  "origin": "Coastal Andhra, India",
  "ingredients": ["Premium Mango", "Pure Jaggery", "Cold-Pressed Peanut Oil"],
  "preparationMethod": "Mangoes are hand-cut and sun-dried for 48 hours.",
  "shelfLife": "12 Months",
  "storageInstructions": "Keep in an airtight glass jar. Always use a dry spoon.",
  "servingSuggestion": "Pairs best with steaming hot rice and a dollop of ghee."
}
```
