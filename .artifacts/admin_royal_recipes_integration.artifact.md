# Admin Dashboard Integration Guide: "Royal Recipes" Section

This guide explains how to manage the **"Royal Recipes"** section dynamically from your **Admin Dashboard / BigRock PHP Backend / MySQL database** for each product without requiring an app update.

---

## 1. Database Storage (`products` table / JSON payload)

In your MySQL database table storing product details (or JSON payload), ensure the `recipes` array contains objects with:
- `image` (or `img`): Image URL for the recipe card.
- `title`: Title of the recipe (e.g. *Avakaya with Hot Rice*).
- `subtitle` (or `instruction` / `desc`): Subtitle or description text displayed below the title (e.g. *A timeless classic.*).

---

## 2. JSON Payload Structure Example

```json
{
  "name": "Bellam Avakaya",
  "recipes": [
    {
      "image": "https://api.adhvaithafoods.in/uploads/recipe1.jpg",
      "title": "Avakaya with Hot Rice",
      "subtitle": "A timeless classic."
    },
    {
      "image": "https://api.adhvaithafoods.in/uploads/recipe2.jpg",
      "title": "Avakaya Paratha",
      "subtitle": "A spicy twist."
    }
  ]
}
```

---

## 3. Implementation Details in App

- **`ProductRepository`**: Parses `recipes` array and normalizes `title`, `subtitle`/`instruction`, and `image`/`img`.
- **`ProductDetailPage`**: `_buildExpandedRoyalRecipes()` renders each recipe card horizontally with the image at the top, bold title below, and subtitle/instruction beneath it. If network images are provided (`https://`), `Image.network` is used; otherwise fallback/asset images are loaded.
