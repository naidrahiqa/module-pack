const { ZipArchive } = require('archiver');
const fs = require('fs');
const path = require('path');

const modules = [
  { name: 'evanescia', dir: 'evanescia', zip: 'evanescia-v1.0.0.zip' },
  { name: 'hyacine-io', dir: 'hyacine_io', zip: 'hyacine-io-v1.0.0.zip' },
  { name: 'kairitsu-safe', dir: 'kairitsu_safe', zip: 'kairitsu-safe-v1.0.0.zip' },
  { name: 'spoof_fierce', dir: 'spoof_fierce', zip: 'spoof_fierce-v1.0.0.zip' },
  { name: 'h_thermal', dir: 'h_thermal', zip: 'h_thermal-v1.0.0.zip' },
];

function walkDir(dir) {
  let results = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) results = results.concat(walkDir(fullPath));
    else results.push(fullPath);
  }
  return results;
}

function createZip(mod) {
  return new Promise((resolve, reject) => {
    const modDir = path.join(__dirname, mod.dir);
    const outPath = path.join(__dirname, mod.zip);
    if (fs.existsSync(outPath)) fs.unlinkSync(outPath);
    const output = fs.createWriteStream(outPath);
    const archive = new ZipArchive({ zlib: { level: 9 } });
    output.on('close', () => { console.log(`${mod.zip}: ${archive.pointer()} bytes`); resolve(); });
    archive.on('error', reject);
    archive.pipe(output);
    for (const filePath of walkDir(modDir)) {
      const relPath = path.relative(modDir, filePath).split(path.sep).join('/');
      archive.file(filePath, { name: relPath });
    }
    archive.finalize();
  });
}

async function main() {
  for (const mod of modules) {
    console.log(`Building ${mod.zip}...`);
    await createZip(mod);
  }
  console.log('Done!');
}

main().catch(console.error);
