const sdk = require('node-appwrite');

// BU KISIMLARI KENDİ PROJENE GÖRE DOLDUR
const client = new sdk.Client();
client
    .setEndpoint('https://fra.cloud.appwrite.io/v1') // Kendi endpoint'in (Cloud kullanıyorsan bu kalır)
    .setProject('69a791fa002d1b9cbef8') // Appwrite Project ID
    .setKey('standard_3435ab2401772dc401fac3459eec9814b873539d7dd0fbb44c9c78225317832dbe706fa93fe1e5fb7177e006e9051a9a7fd32ed0dc03b64a9616b06015726e00790ceee8b4e897946e4a734230c01b6920f6ca99fa2d4b057f0adb94c60798b15390c4d10412e59cf102dbf20345ea886224b22f37559512b7ed0bcf606b3080'); // API Key (Konsoldan "API Keys" bölümünden oluştur, tüm yetkileri ver)

const databases = new sdk.Databases(client);

const DB_NAME = 'CryptoDB';
const DB_ID = 'crypto_db'; // ID'ler genelde küçük harf ve alt çizgi olur
const COLLECTION_NAME = 'Portfolio';
const COLLECTION_ID = 'portfolio';

// Forum Koleksiyonları
const TOPICS_COLLECTION_ID = 'forum_topics';
const COMMENTS_COLLECTION_ID = 'forum_comments';

async function setup() {
    // Yardımcı Fonksiyonlar (Hata yönetimi için)
    const createString = async (db, coll, key, size, req) => {
        try { await databases.createStringAttribute(db, coll, key, size, req); console.log(`+ Sütun eklendi: ${key}`); } 
        catch(e) { console.log(`- Sütun geçildi (${key}): ${e.message}`); }
    };
    const createFloat = async (db, coll, key, req) => {
        try { await databases.createFloatAttribute(db, coll, key, req); console.log(`+ Sütun eklendi: ${key}`); } 
        catch(e) { console.log(`- Sütun geçildi (${key}): ${e.message}`); }
    };
    const createDate = async (db, coll, key, req) => {
        try { await databases.createDatetimeAttribute(db, coll, key, req); console.log(`+ Sütun eklendi: ${key}`); } 
        catch(e) { console.log(`- Sütun geçildi (${key}): ${e.message}`); }
    };

    // 1. Veritabanı
    try {
        console.log('Veritabanı oluşturuluyor...');
        await databases.create(DB_ID, DB_NAME);
        console.log('Veritabanı oluşturuldu.');
    } catch (error) {
        console.log('Veritabanı adımı geçildi: ' + error.message);
    }

    // 2. Portfolio Koleksiyonu
    try {
        console.log('Portfolio koleksiyonu kontrol ediliyor...');
        await databases.createCollection(DB_ID, COLLECTION_ID, COLLECTION_NAME);
        console.log('Portfolio oluşturuldu.');
    } catch (error) {
        console.log('Portfolio koleksiyonu adımı geçildi: ' + error.message);
    }
    // Portfolio Sütunları
    await createString(DB_ID, COLLECTION_ID, 'userId', 255, true);
    await createString(DB_ID, COLLECTION_ID, 'symbol', 10, true);
    await createFloat(DB_ID, COLLECTION_ID, 'amount', true);
    await createFloat(DB_ID, COLLECTION_ID, 'averageBuyPrice', true);

    // 3. Forum Topics Koleksiyonu
    try {
        console.log('Forum Topics koleksiyonu kontrol ediliyor...');
        await databases.createCollection(DB_ID, TOPICS_COLLECTION_ID, 'Forum Topics');
        console.log('Forum Topics oluşturuldu.');
    } catch (error) {
        console.log('Forum Topics koleksiyonu adımı geçildi: ' + error.message);
    }
    // Forum Topics Sütunları
    await createString(DB_ID, TOPICS_COLLECTION_ID, 'title', 128, true);
    await createString(DB_ID, TOPICS_COLLECTION_ID, 'content', 5000, true);
    await createString(DB_ID, TOPICS_COLLECTION_ID, 'userId', 255, true);
    await createString(DB_ID, TOPICS_COLLECTION_ID, 'authorName', 128, true);
    await createDate(DB_ID, TOPICS_COLLECTION_ID, 'createdAt', true);

    // 4. Forum Comments Koleksiyonu
    try {
        console.log('Forum Comments koleksiyonu kontrol ediliyor...');
        await databases.createCollection(DB_ID, COMMENTS_COLLECTION_ID, 'Forum Comments');
        console.log('Forum Comments oluşturuldu.');
    } catch (error) {
        console.log('Forum Comments koleksiyonu adımı geçildi: ' + error.message);
    }
    // Forum Comments Sütunları
    await createString(DB_ID, COMMENTS_COLLECTION_ID, 'topicId', 255, true);
    await createString(DB_ID, COMMENTS_COLLECTION_ID, 'content', 2000, true);
    await createString(DB_ID, COMMENTS_COLLECTION_ID, 'userId', 255, true);
    await createString(DB_ID, COMMENTS_COLLECTION_ID, 'authorName', 128, true);
    await createDate(DB_ID, COMMENTS_COLLECTION_ID, 'createdAt', true);

    console.log('Kurulum tamamlandı.');
}

setup();
