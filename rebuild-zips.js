const { ZipArchive } = require('archiver');
const fs = require('fs');
const path = require('path');

const modules = [
  { name: 'evanescia', dir: 'evanescia', zip: 'evanescia-v1.2.0-ksunext.zip' },
  { name: 'hyacine-io', dir: 'hyacine_io', zip: 'hyacine-io-v1.4.0-ksunext.zip' },
  { name: 'kairitsu-safe', dir: 'kairitsu_safe', zip: 'kairitsu-safe-v1.2.0-ksunext.zip' },
  { name: 'spoof_fierce', dir: 'spoof_fierce', zip: 'spoof_fierce-v2.0.0-ksunext.zip' },
  { name: 'h_thermal', dir: 'h_thermal', zip: 'h_thermal-v1.1.0-ksunext.zip' },
  { name: 'game-perftune', dir: 'game_perftune', zip: 'game_perftune-v2.0.0-ksunext.zip' },
  { name: 'multi-audio', dir: 'multi_audio', zip: 'multi-audio-v1.0.0-ksunext.zip' },
  { name: 'media-fix', dir: 'media_fix', zip: 'media-fix-v1.0.0-ksunext.zip' },
  { name: 'storage-fix', dir: 'storage_fix', zip: 'storage-fix-v1.0.0-ksunext.zip' },
  { name: 'ui-enhance', dir: 'ui_enhance', zip: 'ui-enhance-v1.0.0-ksunext.zip' },
  { name: 'network-fix', dir: 'network_fix', zip: 'network-fix-v1.0.0-ksunext.zip' },
  { name: 'battery-fix', dir: 'battery_fix', zip: 'battery-fix-v1.0.0-ksunext.zip' },
  { name: 'camera-fix', dir: 'camera_fix', zip: 'camera-fix-v1.0.0-ksunext.zip' },
  { name: 'gps-fix', dir: 'gps_fix', zip: 'gps-fix-v1.0.0-ksunext.zip' },
  { name: 'font-swap', dir: 'font_swap', zip: 'font-swap-v1.0.0-ksunext.zip' },
  { name: 'touch-fix', dir: 'touch_fix', zip: 'touch-fix-v1.0.0-ksunext.zip' },
  { name: 'statusbar-mod', dir: 'statusbar_mod', zip: 'statusbar-mod-v1.0.0-ksunext.zip' },
  { name: 'wifi-boost', dir: 'wifi_boost', zip: 'wifi-boost-v1.0.0-ksunext.zip' },
  { name: 'power-menu', dir: 'power_menu', zip: 'power-menu-v1.0.0-ksunext.zip' },
  { name: 'display-color', dir: 'display_color', zip: 'display-color-v1.0.0-ksunext.zip' },
  { name: 'fingerprint-speed', dir: 'fingerprint_speed', zip: 'fingerprint-speed-v1.0.0-ksunext.zip' },
  { name: 'speaker-boost', dir: 'speaker_boost', zip: 'speaker-boost-v1.0.0-ksunext.zip' },
  { name: 'volume-steps', dir: 'volume_steps', zip: 'volume-steps-v1.0.0-ksunext.zip' },
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
