# Admin Dashboard Integration Guide: Snacks with a Story

This guide explains how to manage the **"Snacks with a Story"** section cards dynamically from your **Admin Dashboard / BigRock PHP Backend / MySQL database** without requiring an app update.

---

## 1. Database Storage (`products` table / JSON payload)

In your MySQL database table storing product details for snack items (such as Chakinalu, Boondi, Palli Mixture, Ribbon Pakoda, etc.), ensure you include the following fields:
- **`storyImage`**: URL or asset path for the illustrative story header image.
- **`description`**: Descriptive text explaining the tradition and heritage of the snack.
- **`trustBadges`**: Array of feature tags / badges (e.g. `["Rice Flour", "Homemade", "Mild Spicy"]`).
- **`name`**: Product name.
- **`weightPriceMap`**: Size variants and prices.

---

## 2. JSON Payload Structure Example

```json
{
  "name": "Chakinalu",
  "category": "Snacks",
  "storyImage": "https://api.adhvaithafoods.in/uploads/chakinalu_story.png",
  "description": "Traditional Sankranti spiral snacks handcrafted with rice flour and carom seeds.",
  "trustBadges": ["Rice Flour", "Homemade", "Mild Spicy"],
  "weightPriceMap": {
    "250g": 120.0,
    "500g": 230.0
  },
  "price": 120.0
}
```

---

## 3. What You Need to Do in the Admin Dashboard

1. **Upload Story Image (`storyImage`)**:
   - Provide the CDN / network URL of the story graphic for each snack product.
2. **Add Snack Story Description (`description`)**:
   - Write a short, evocative sentence describing the snack's heritage.
3. **Configure Trust Badges (`trustBadges`)**:
   - Add up to 3 characteristic tags (e.g. ingredients or preparation methods) that appear on the card tags row.
