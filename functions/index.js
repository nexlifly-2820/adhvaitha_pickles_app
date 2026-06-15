const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// --- 1. USER & PROFILE LOGIC ---

/**
 * Saves or updates user address.
 */
exports.saveUserAddress = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  const { title, address, isDefault } = request.data;

  if (!title || !address) {
    throw new HttpsError("invalid-argument", "Title and Address are required.");
  }

  try {
    const addressRef = admin.firestore().collection("users").doc(uid).collection("addresses").doc();
    await addressRef.set({
      id: addressRef.id,
      title,
      fullAddress: address,
      isDefault: isDefault || false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, message: "Address saved." };
  } catch (error) {
    throw new HttpsError("internal", error.message);
  }
});

// --- 2. ORDER LOGIC ---

/**
 * Creates a new order.
 */
exports.createRoyalOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const uid = request.auth.uid;
  const { items, subtotal, deliveryFee, discountAmount, total, shippingAddress, paymentMethod } = request.data;

  if (!items || items.length === 0) {
    throw new HttpsError("invalid-argument", "Cart is empty.");
  }

  try {
    const orderId = `ADH-${Date.now()}-${Math.floor(100 + Math.random() * 899)}`;
    const batchId = `BCH-${new Date().getFullYear()}${Math.floor(1000 + Math.random() * 9000)}`;

    const orderData = {
      orderId,
      userId: uid,
      items,
      subtotal,
      deliveryFee,
      discountAmount,
      total,
      shippingAddress,
      paymentMethod,
      status: "Placed",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      estimatedDelivery: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 5 * 24 * 60 * 60 * 1000)),
      batchId,
      spiceOrigin: "Guntur Royal Markets",
    };

    await admin.firestore().collection("orders").doc(orderId).set(orderData);

    // Update User Summary
    await admin.firestore().collection("users").doc(uid).set({
      lastOrderAt: admin.firestore.FieldValue.serverTimestamp(),
      totalOrders: admin.firestore.FieldValue.increment(1),
      totalSpent: admin.firestore.FieldValue.increment(total)
    }, { merge: true });

    return { success: true, orderId };
  } catch (error) {
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Trigger: When an order is created, notify admin (placeholder for messaging).
 */
exports.notifyAdminOnNewOrder = onDocumentCreated("orders/{orderId}", async (event) => {
    const order = event.data.data();
    console.log(`NEW ORDER RECEIVED: ${event.params.orderId} for ₹${order.total}`);
    // Here you would use admin.messaging().send(...) to alert the Admin Dashboard app
});

/**
 * Trigger: When status changes, update rewards and notify user.
 */
exports.onOrderStatusUpdate = onDocumentUpdated("orders/{orderId}", async (event) => {
  const newData = event.data.after.data();
  const oldData = event.data.before.data();

  // 1. Reward logic on Delivery
  if (newData.status === "Delivered" && oldData.status !== "Delivered") {
    const rewardCoins = Math.floor(newData.total / 10); // 10% back
    const uid = newData.userId;

    const batch = admin.firestore().batch();
    const userRef = admin.firestore().collection("users").doc(uid);
    const rewardRef = userRef.collection("rewards").doc();

    batch.set(rewardRef, {
      amount: rewardCoins,
      type: "earned",
      orderId: newData.orderId,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    batch.set(userRef, {
      coins: admin.firestore.FieldValue.increment(rewardCoins)
    }, { merge: true });

    await batch.commit();
    console.log(`Rewarded ${rewardCoins} coins to ${uid}`);
  }

  // 2. Notify User of status change (placeholder)
  if (newData.status !== oldData.status) {
    console.log(`ORDER ${newData.orderId} is now ${newData.status}`);
  }
});

// --- 3. ADMIN & INVENTORY LOGIC (For Dashboard) ---

/**
 * Updates product stock or price from Admin Dashboard.
 */
exports.adminUpdateProduct = onCall(async (request) => {
  // Logic to verify request.auth has admin custom claims:
  // if (!request.auth.token.admin) throw new HttpsError("permission-denied", "Admin only.");

  const { productId, updates } = request.data;
  try {
    await admin.firestore().collection("products").doc(productId).update({
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return { success: true };
  } catch (error) {
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Fetches summary for Admin Dashboard.
 */
exports.getAdminDashboardStats = onCall(async (request) => {
  try {
    const ordersSnap = await admin.firestore().collection("orders").get();
    const usersSnap = await admin.firestore().collection("users").get();

    let revenue = 0;
    ordersSnap.forEach(doc => {
        if(doc.data().status !== "Cancelled") revenue += doc.data().total;
    });

    return {
      totalOrders: ordersSnap.size,
      totalUsers: usersSnap.size,
      totalRevenue: revenue,
      activeOrders: ordersSnap.docs.filter(d => d.data().status === "Placed" || d.data().status === "Shipped").length
    };
  } catch (error) {
    throw new HttpsError("internal", error.message);
  }
});

// --- 4. PUBLIC & CRM ---

exports.submitContactInquiry = onCall(async (request) => {
    const { name, email, phone, message } = request.data;
    try {
        await admin.firestore().collection("inquiries").add({
            name, email, phone, message,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            status: "New"
        });
        return { success: true };
    } catch (error) {
        throw new HttpsError("internal", error.message);
    }
});
