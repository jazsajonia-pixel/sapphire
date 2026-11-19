# Links, backlinks and search

## Supported link syntax

| Syntax | Example | Notes |
| --- | --- | --- |
| Wiki link | `[[Note]]` | Matched by note title (file name without `.md`), case-insensitive |
| Wiki link with folder | `[[Folder/Note]]` | Matches a path ending in `Folder/Note.md` |
| Alias | `[[Note\|shown text]]` | Escaped `\|` inside tables is handled |
| Heading / block | `[[Note#Heading]]`, `[[Note#^id]]` | Links to the note; the heading is not scrolled to yet |
| Embed | `![[Note]]` | Counted as a link; content is not embedded in the preview |
| Markdown link | `[text](Other.md)`, `[t](../Folder/Note%20Two.md)`, `[t](<With Space.md>)` | Relative to the linking note; `/x.md` is relative to the vault root; extension optional |

Not counted as note links: images, external URLs (`https:`, `mailto:`,
`obsidian:` …), same-note anchors (`#x`, `[[#x]]`), attachments (`.pdf`,
`.png` …), and anything inside fenced code blocks or inline code.

## Resolution rules

- Links are matched only against notes found in the vault listing. Resolution
  never opens a path, so a link cannot reach outside the vault; links that
  climb above the vault root (`../..`) are reported as **outside vault**.
- **Duplicate names** (`A/Plan.md`, `B/Plan.md`): `[[Plan]]` prefers an exact
  case match, then the linking note's folder, then the shallowest path, then
  alphabetical order. Such links are flagged as ambiguous in the links sheet.
  Use `[[A/Plan]]` to be explicit.
- Unmatched links are **broken**. Renaming or deleting a note outside Sapphire
  turns its incoming links into broken links after the next rescan.
- External links in the preview are never opened automatically; Sapphire
  shows the URL and offers to copy it.

## The index

- Built in memory from the Markdown files whenever a vault is opened, and
  updated incrementally: only files whose size or modification time changed
  are re-read on **Rescan**. Notes saved in Sapphire update immediately.
- **Rebuild index** (Brain → ⋮) discards the index and re-reads every note.
  Indexing only reads files; it never writes, moves or deletes notes.
- Files that cannot be read (e.g. larger than 8 MB) are listed under
  *Unlinked notes → Could not index*.

- Since 1.2.0 the index is also saved to the app's private files
  (`files/index/<vault hash>.json`) after it changes. On the next launch it
  is restored first, so only notes whose size or modification time changed
  since then are re-read. The cache is derived data: it never lives in the
  vault, and deleting it (or uninstalling) only costs one full re-read.

**Deviation from the original plan:** the project overview suggested a SQLite
metadata database. The index is kept in memory with the regenerable JSON cache
above, which keeps the vault the only source of truth and avoids a database
dependency.

## Loading screen (1.2.0)

When the app starts it shows a loading screen that does the start-up work
before Home appears: open the remembered vault, run the first GitHub sync (if
sync is set up and automatic sync is on), index every note, and lay out the
global graph. The status line reports the real step and progress. There is
no artificial delay; with no vault it disappears after one frame. **Open now**
appears after 4 seconds, the sync step gives up after 40 seconds (offline or
slow network) and the screen never stays longer than 90 seconds.

## Find in note (1.2.0)

Notes open in view mode (rendered Markdown); **Edit** (button or pencil)
switches to the editor, and new notes open in the editor. The search icon in
a note opens a find bar: case-insensitive, shows "n of m", next/previous wrap
around, and the current match is scrolled into view. In view mode it searches
the rendered text (matches that cross formatting, e.g. half bold, and text in
code blocks are not found); in edit mode it searches the raw Markdown.
Opening a note from vault search starts find with the search text.

## Search

Case-insensitive substring search over titles, folder names and note text.
Every space-separated term must match. Results are ranked: exact title, title
match, title prefix, then number of matches in the text.
Not supported yet: fuzzy matching, accent-insensitive matching, tags/front
matter filters.
