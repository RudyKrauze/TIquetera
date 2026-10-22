/**
 * scripts/optimize-images.js
 * Script one-shot para optimizar imágenes estáticas antes del deploy.
 * Genera versiones WebP de logo y favicon para reducir egress en Vercel.
 * Ejecutar: node scripts/optimize-images.js
 */
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const publicDir = path.join(__dirname, '../public');

async function optimizeImages() {
    console.log('🖼️  Optimizando imágenes...\n');

    // 1. logo.png → logo.webp (max 400px ancho, calidad 85)
    const logoInput = path.join(publicDir, 'logo.png');
    const logoOutput = path.join(publicDir, 'logo.webp');
    const logoMeta = await sharp(logoInput).metadata();
    await sharp(logoInput)
        .resize(Math.min(logoMeta.width, 400), null, { withoutEnlargement: true })
        .webp({ quality: 85 })
        .toFile(logoOutput);
    const logoOrigSize = fs.statSync(logoInput).size;
    const logoNewSize = fs.statSync(logoOutput).size;
    console.log(`✅ logo.webp: ${(logoOrigSize/1024).toFixed(0)}KB → ${(logoNewSize/1024).toFixed(0)}KB (${Math.round((1-logoNewSize/logoOrigSize)*100)}% reducción)`);

    // 2. favicon.png → favicon-32.png (32x32, compresión máxima)
    const faviconInput = path.join(publicDir, 'favicon.png');
    const faviconOutput = path.join(publicDir, 'favicon-32.png');
    await sharp(faviconInput)
        .resize(32, 32)
        .png({ compressionLevel: 9 })
        .toFile(faviconOutput);
    const favOrigSize = fs.statSync(faviconInput).size;
    const favNewSize = fs.statSync(faviconOutput).size;
    console.log(`✅ favicon-32.png: ${(favOrigSize/1024).toFixed(0)}KB → ${(favNewSize/1024).toFixed(0)}KB (${Math.round((1-favNewSize/favOrigSize)*100)}% reducción)`);

    // 3. logo.png → apple-touch-icon.webp (180x180 para iOS)
    const appleOutput = path.join(publicDir, 'apple-touch-icon.webp');
    await sharp(logoInput)
        .resize(180, 180, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
        .webp({ quality: 90 })
        .toFile(appleOutput);
    const appleSize = fs.statSync(appleOutput).size;
    console.log(`✅ apple-touch-icon.webp: ${(appleSize/1024).toFixed(0)}KB`);

    console.log('\n🎉 Optimización completada. Actualizá los <link> en index.html si es necesario.');
}

optimizeImages().catch(err => {
    console.error('❌ Error:', err.message);
    process.exit(1);
});
