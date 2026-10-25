# Admin Dashboard Integration Guide: User CRM & Database Sync

This guide explains how user data sent from the mobile app is structured and how to manage it in your **Admin Dashboard / BigRock PHP Backend / MySQL database**.

---

## 1. Database Table (`users` table)

In your MySQL database, ensure you have a `users` table to store customer accounts so that incoming orders (`orders` table) can be successfully linked to registered users.

### Recommended SQL Schema:
```sql
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## 2. API Endpoint (`users.php`)

The mobile app automatically sends a `POST` request to `https://api.adhvaithafoods.in/api/users.php` whenever a user logs in with their email or updates their profile in Edit Profile.

### Payload Sent by App:
```json
{
  "user_id": "USER-hemanth_s_example_com",
  "name": "HEMANTH SILLA",
  "email": "hemanth.s@example.com",
  "phone": "hemanth.s@example.com"
}
```

---

## 3. What to Check in the Admin Dashboard

1. **Customer CRM Section**:
   - Navigate to your Admin Dashboard's **Customer CRM** or **Users** tab.
   - Verify that users logging into the mobile app appear in your database table with their correct **Name**, **Email**, and generated **User ID**.
2. **Order Linking**:
   - Ensure your order placement script (`orders.php`) reads the `user_id` or `email` from incoming orders and links them to the `users` table for seamless tracking.
