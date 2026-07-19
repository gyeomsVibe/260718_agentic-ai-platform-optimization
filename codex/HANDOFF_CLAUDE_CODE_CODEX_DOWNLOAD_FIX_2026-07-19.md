# Claude Code CLI handoff — Codex local download/open fix

## Checkpoint

- Handoff ID: `CODEX-DOWNLOAD-FIX-20260719-0415-KST`
- Workspace (canonical): `D:\D_Workspace_NB\-google-workspace\-antigravity-workspace\260718_agentic-ai-platform-optimization`
- Codex build: `OpenAI.Codex_26.715.4045.0_x64__2p2nqsd0c76g0`
- Status: read-only root-cause analysis completed; installed app not patched
- Resume at: report the minimum patch surface, confirm backup/integrity plan, then apply only the approved change

## User-visible failures

1. A local image opens in Codex image preview, but its top-right download icon
   silently creates no file.
2. A local ZIP opens a Codex tab that says archive preview is unsupported.
   The archive viewer itself has no verified open/reveal/save action.
3. Copying artifacts into `Downloads` is only a workaround. It does not fix the
   Codex controls and must not be reported as the product fix.

## Claude CLI progress at handoff

The live Claude Code terminal showed three tasks:

- completed: verify read access to the installed Codex app and ASAR
- completed: extract ASAR and trace image-download and ZIP-open code
- in progress: report root cause and minimum patch location, then request
  approval for mutation

The terminal contains a user input of `승인한다`, but no evidence was found that
the installed app had been modified. Before a write, confirm which exact change
that approval covered and preserve a rollback path.

## Installed application

```text
C:\Program Files\WindowsApps\OpenAI.Codex_26.715.4045.0_x64__2p2nqsd0c76g0\app\resources\app.asar
```

Do not patch this signed/Store-managed installation before recording owner,
ACL, app version, source hash, ASAR-integrity/fuse result, and a recoverable
backup. Do not weaken Windows security or package-signature checks.

## Claude scratchpad and extracted sources

```text
C:\Users\Kimyoongyeom\AppData\Local\Temp\claude\
D--D-Workspace-NB--google-workspace--antigravity-workspace-260713-pc-optimization\
1c9c7245-8119-4801-ab6a-3356c36871bb\scratchpad
```

Reusable analysis utilities:

- `asar-header.js`
- `find-ctx.js`
- `scan.js`
- `verify-offset.js`

Extracted targets and pre-patch SHA-256:

| Target | SHA-256 |
|---|---|
| `codex-asar\extracted\webview\assets\image-preview-dialog-DNK1huHU.js` | `D9E045888F9D980D74192A7B57F317B64CB70F8EA227AADBEEF7A63BCA72B75F` |
| `codex-asar\extracted\webview\assets\review-file-source-tab-lzTmVI5b.js` | `CC1D2ADE385020E1C4AE048F1695AEFBA20B719D54D23F603F58ABF3473A48AC` |
| `codex-asar\extracted\.vite\build\main-CmXfwZWv.js` | `1547506917C6071CEB8C606DABF0E45BED27B9F38E722541753F95086249250F` |

## Confirmed root-cause evidence

### Local image download

`image-preview-dialog-DNK1huHU.js` renders an anchor similar to:

```javascript
<a href={downloadSrc} download={filename} onClick={downloadHandler}>
```

The handler only takes ownership of `data:` sources:

```javascript
event => {
  if (!downloadSrc.startsWith("data:")) return;
  event.preventDefault();
  // data URL -> Blob -> temporary object URL -> anchor click
}
```

Therefore local absolute paths, `file:` URLs, and Codex-local protocols fall
through to Chromium's ordinary `<a download>` behavior. That path does not
reliably save local-protocol resources inside the Windows Codex/Electron
renderer, producing a silent no-op.

The app already has native RPC handlers for:

- `read-file-binary` with `hostId` and `path`
- `save-file` with `kind: "contents"`, `suggestedFilename`, and
  `contentsBase64`

Prefer reusing this existing path through the image preview's `onDownload`
callback rather than broadening renderer protocol permissions.

### ZIP/archive viewer

`review-file-source-tab-lzTmVI5b.js` contains the unsupported-archive state.
The prior trace found no open/reveal/save action wired into that archive-viewer
state. Trace the surrounding toolbar/caller and reuse an existing native
open-path or reveal-in-Explorer action if available. Do not implement archive
extraction merely to disguise the missing action.

## Minimum safe implementation direction

1. At the local-file preview call site, supply a real `onDownload` callback.
2. The callback must call `read-file-binary`, then `save-file`, preserve the
   original filename, surface errors, and honor save cancellation.
3. Keep existing `data:`, `blob:`, and HTTP behavior unchanged.
4. For unsupported archives, wire `Open externally` or `Reveal in Explorer`
   to a native validated path operation. If the required native RPC does not
   exist, report that exact boundary instead of shell-concatenating user input.
5. Prefer source/call-site wiring over invasive edits to the generic minified
   image-preview component.

## Required tests

- `data:` PNG download
- local PNG from an English path
- local PNG from a path containing Korean, spaces, and parentheses
- Codex temporary clipboard image
- workspace-local image
- ZIP open/reveal from English and Korean paths
- missing file and permission-denied error display
- save-dialog cancellation
- duplicate filename handling
- downloaded SHA-256 equals source SHA-256
- full Codex restart and re-test

No test is a pass until the user can observe the created file or the external
archive app/Explorer opening. A preview-only screenshot is insufficient.

## Rollback and acceptance boundary

Before mutation, create and verify:

- original `app.asar` backup outside the installation directory
- original SHA-256 and patched SHA-256
- exact restore command/script
- process-stop/restart procedure
- Store update implications

If ASAR integrity, package signing, WindowsApps ACL, or Store self-repair makes
the patch unsafe, stop and provide a reproducible source patch or overlay. Do
not take ownership of the WindowsApps tree, disable integrity, or weaken ACLs.

## Existing workaround artifacts — not the fix

```text
C:\Users\Kimyoongyeom\Downloads\Codex-Exports\
gyeom-motion-self-test-20260719-025241.zip
```

Current ZIP SHA-256:

```text
71E2275ABE66724C8E0BAC896BB593ADA3FF65B4D8C38D9D4ADDFE40FE7A338D
```

## Repository hygiene

The worktree was already dirty. Preserve all unrelated/user-owned changes.
Notably observed:

- modified `.claude/settings.local.json`
- deleted tracked files under `custom-pet-manual/`
- untracked `AGENTS.md`, pet rebuild data, and notebook/scratch content

Do not restore, delete, stage, commit, or include these unrelated changes in an
app patch without explicit scope confirmation. No commit or push is authorized
by this handoff.

## Resume instruction

```text
Read HANDOFF_CLAUDE_CODE_CODEX_DOWNLOAD_FIX_2026-07-19.md completely.
Continue from “Minimum safe implementation direction”. Reuse the existing
Claude scratchpad and extracted ASAR; do not repeat completed discovery.
First report the exact call-site patch and backup/integrity result. Then apply
only the explicitly approved mutation, run the full test matrix, and produce a
rollback script. Do not call the Downloads copy workaround a fix.
```


