const crypto = require('node:crypto');
const fs = require('node:fs');

const asarPath = process.argv[2];
if (!asarPath) {
  console.error('Usage: node verify-asar.js <app.asar>');
  process.exit(2);
}

const targetPath = '/webview/assets/image-preview-dialog-DNK1huHU.js';
const patchedMarker =
  'we=async e=>{if(_.startsWith(`http`))return;e.preventDefault();';

function sha256(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

function findNode(root, wantedPath) {
  let found = null;
  function walk(node, currentPath) {
    if (found) return;
    if (node.files) {
      for (const [name, child] of Object.entries(node.files)) {
        walk(child, `${currentPath}/${name}`);
      }
      return;
    }
    if (currentPath === wantedPath) found = node;
  }
  walk(root, '');
  return found;
}

const fd = fs.openSync(asarPath, 'r');
try {
  const prefix = Buffer.alloc(16);
  fs.readSync(fd, prefix, 0, prefix.length, 0);
  const headerPayloadSize = prefix.readUInt32LE(8);
  const headerJsonSize = prefix.readUInt32LE(12);
  const contentBase = 12 + headerPayloadSize;
  const headerBuffer = Buffer.alloc(headerJsonSize);
  fs.readSync(fd, headerBuffer, 0, headerBuffer.length, 16);
  const header = JSON.parse(headerBuffer.toString('utf8'));
  const target = findNode(header, targetPath);
  if (!target || target.unpacked) throw new Error('Packed target not found');

  const targetOffset = contentBase + Number(target.offset);
  const targetBuffer = Buffer.alloc(Number(target.size));
  fs.readSync(fd, targetBuffer, 0, targetBuffer.length, targetOffset);
  const actualHash = sha256(targetBuffer);
  const source = targetBuffer.toString('utf8');
  const markerCount = source.split(patchedMarker).length - 1;
  const blockHashes = target.integrity?.blocks ?? [];
  const integrityMatches =
    target.integrity?.hash === actualHash &&
    blockHashes.length > 0 &&
    blockHashes.every((hash) => hash === actualHash);

  const result = {
    asarPath,
    targetPath,
    targetOffset,
    targetSize: targetBuffer.length,
    actualHash,
    headerHash: target.integrity?.hash ?? null,
    blockHashes,
    markerCount,
    integrityMatches,
    sizePreserved: targetBuffer.length === Number(target.size),
  };
  console.log(JSON.stringify(result, null, 2));
  if (markerCount !== 1 || !integrityMatches || !result.sizePreserved) {
    process.exitCode = 1;
  }
} finally {
  fs.closeSync(fd);
}
