const admin = require('firebase-admin');
const webpush = require('web-push');

const VAPID_PUBLIC_KEY = process.env.VAPID_PUBLIC_KEY;
const VAPID_PRIVATE_KEY = process.env.VAPID_PRIVATE_KEY;
const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || 'https://habibbatista.github.io';

let vapidConfigured = false;
function ensureVapidConfigured() {
  if (vapidConfigured) return;
  webpush.setVapidDetails('mailto:support@example.com', VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);
  vapidConfigured = true;
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON))
  });
}

async function sendToSubscriptions(db, subsSnap, payload) {
  const results = await Promise.allSettled(subsSnap.docs.map(async (subDoc) => {
    const sub = subDoc.data();
    try {
      await webpush.sendNotification({ endpoint: sub.endpoint, keys: sub.keys }, payload);
    } catch (err) {
      if (err.statusCode === 404 || err.statusCode === 410) {
        await subDoc.ref.delete();
      }
      throw err;
    }
  }));
  return results.filter((r) => r.status === 'fulfilled').length;
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', ALLOWED_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') { res.status(204).end(); return; }
  if (req.method !== 'POST') { res.status(405).json({ error: 'Method not allowed' }); return; }

  try {
    ensureVapidConfigured();

    const authHeader = req.headers.authorization || '';
    const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!idToken) { res.status(401).json({ error: 'Missing auth token' }); return; }
    await admin.auth().verifyIdToken(idToken);

    const { recipientUid, title, body, type, tag, url } = req.body || {};
    if (!recipientUid || !title) { res.status(400).json({ error: 'Missing recipientUid or title' }); return; }

    const db = admin.firestore();
    const subsSnap = await db.collection('users').doc(recipientUid).collection('pushSubscriptions').get();
    if (subsSnap.empty) { res.status(200).json({ sent: 0, total: 0 }); return; }

    const payload = JSON.stringify({
      title: String(title).slice(0, 120),
      body: String(body || '').slice(0, 300),
      icon: 'icons/icon-192.png',
      tag: tag || 'riven-notification',
      type: type || 'generic',
      url: url || '.'
    });

    const sent = await sendToSubscriptions(db, subsSnap, payload);
    res.status(200).json({ sent, total: subsSnap.size });
  } catch (e) {
    console.error('send-push error:', e);
    res.status(500).json({ error: 'Internal error' });
  }
};
