const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const USER_DB = "./local_user_db.json";
const STATS_DB = "./local_stats.json";

async function runManagementEngine() {
    console.log('🧠 KBIDU MASTER BRAIN: STARTING...');
    
    // Find the key file
    const dirFiles = fs.readdirSync(__dirname);
    const keyFile = dirFiles.find(f => f.toLowerCase().includes('serviceaccountkey') && f.endsWith('.json'));

    if (!keyFile) {
        console.error('❌ ERROR: Missing serviceAccountKey.json in this folder.');
        return;
    }

    const serviceAccount = require(path.join(__dirname, keyFile));

    try {
        if (admin.apps.length === 0) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: serviceAccount.project_id
            });
        }

        const db = admin.firestore();
        const auth = admin.auth();

        console.log(`📡 Connecting to Project: ${serviceAccount.project_id}...`);

        // TEST CONNECTION
        try {
            await db.collection('_system').doc('heartbeat').set({ lastActive: new Date() });
            console.log('✅ DATABASE CONNECTED: Storage is online.');
        } catch (e) {
            console.error('\n❌ DATABASE OFFLINE');
            if (e.message.includes('NOT_FOUND')) {
                console.log('👉 FIX: You must go to the Firebase Console and click "Create Database" for Firestore.');
                console.log('🔗 URL: https://console.firebase.google.com/project/' + serviceAccount.project_id + '/firestore');
            } else {
                console.log('Error Detail:', e.message);
            }
            return;
        }

        // SYNC LOGIC
        console.log('🔄 Syncing Auth users to Brain storage...');
        const listUsers = await auth.listUsers(1000);
        console.log(`📊 Found ${listUsers.users.length} users.`);

        const stats = {
            total: listUsers.users.length,
            lastSync: new Date().toISOString()
        };

        // Update Brain (Firestore)
        await db.collection('stats').doc('global').set(stats);
        
        // Save Local Backup
        fs.writeFileSync(STATS_DB, JSON.stringify(stats, null, 2));
        console.log('💾 Local backup saved.');
        console.log('✨ BRAIN SYNC COMPLETE.');

    } catch (error) {
        console.error('❌ CRITICAL ERROR:', error.message);
    }
}

runManagementEngine();
