const crypto = require('node:crypto');
const fs = require('node:fs');

const asarPath = process.argv[2];

if (!asarPath) {
  console.error('Usage: node patch-asar.js <app.asar>');
  process.exit(2);
}

const targetPath = '/webview/assets/image-preview-dialog-DNK1huHU.js';
const expectedOriginalHash =
  'd9e045888f9d980d74192a7b57f317b64cb70f8ea227aadbeef7a63bca72b75f';
const originalHandler =
  'we=e=>{if(!_.startsWith(`data:`))return;e.preventDefault();let t=wr(_),n=URL.createObjectURL(t),r=document.createElement(`a`);r.href=n,r.download=Ce,r.style.display=`none`,document.body.append(r),r.click(),r.remove(),window.setTimeout(()=>URL.revokeObjectURL(n),0)}';
const patchedHandler =
  'we=async e=>{if(_.startsWith(`http`))return;e.preventDefault();let t=_.startsWith(`data:`)?wr(_):await(await fetch(_)).blob(),n=URL.createObjectURL(t),r=document.createElement(`a`);r.href=n,r.download=Ce,r.click(),setTimeout(()=>URL.revokeObjectURL(n),0)}';

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

if (Buffer.byteLength(patchedHandler) > Buffer.byteLength(originalHandler)) {
  throw new Error('Patched handler must not be larger than the original handler');
}

const fd = fs.openSync(asarPath, 'r+');
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

  if (!target || target.unpacked) {
    throw new Error(`Packed target not found: ${targetPath}`);
  }

  const targetOffset = contentBase + Number(target.offset);
  const targetBuffer = Buffer.alloc(Number(target.size));
  fs.readSync(fd, targetBuffer, 0, targetBuffer.length, targetOffset);
  const originalHash = sha256(targetBuffer);

  if (originalHash !== expectedOriginalHash) {
    throw new Error(
      `Unexpected target hash: ${originalHash}. Expected ${expectedOriginalHash}`,
    );
  }

  const source = targetBuffer.toString('utf8');
  const firstIndex = source.indexOf(originalHandler);
  const secondIndex = source.indexOf(originalHandler, firstIndex + 1);
  if (firstIndex < 0 || secondIndex >= 0) {
    throw new Error('Expected exactly one original download handler');
  }

  const paddedHandler = patchedHandler.padEnd(
    Buffer.byteLength(originalHandler),
    ' ',
  );
  const patchedSource =
    source.slice(0, firstIndex) +
    paddedHandler +
    source.slice(firstIndex + originalHandler.length);
  const patchedBuffer = Buffer.from(patchedSource, 'utf8');

  if (patchedBuffer.length !== targetBuffer.length) {
    throw new Error('Patch changed the packed file size');
  }

  const patchedHash = sha256(patchedBuffer);
  target.integrity.hash = patchedHash;
  target.integrity.blocks = target.integrity.blocks.map(() => patchedHash);

  const patchedHeader = Buffer.from(JSON.stringify(header), 'utf8');
  if (patchedHeader.length !== headerBuffer.length) {
    throw new Error('Patch changed the ASAR header size');
  }

  fs.writeSync(fd, patchedBuffer, 0, patchedBuffer.length, targetOffset);
  fs.writeSync(fd, patchedHeader, 0, patchedHeader.length, 16);
  fs.fsyncSync(fd);

  console.log(
    JSON.stringify(
      {
        asarPath,
        targetPath,
        targetOffset,
        targetSize: patchedBuffer.length,
        originalHash,
        patchedHash,
      },
      null,
      2,
    ),
  );
} finally {
  fs.closeSync(fd);
}
