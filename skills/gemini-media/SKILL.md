---
name: gemini-media
description: Generate or edit images and generate video using Google's Gemini API (Nano Banana image models, Veo 3.1 video) with the user's own GEMINI_API_KEY. Use when asked to generate/make/create an image, illustration, mockup asset, thumbnail, or photo; to edit, restyle, extend, upscale, or change an existing image; or to generate a video clip, animate a still image, or make an image-to-video. Prefer this over Higgsfield skills when the user wants direct Gemini API usage, wants to pay via their own key, or names Gemini, Nano Banana, Imagen, or Veo. NOT for Soul/identity training, ads/UGC, or narrated explainer videos — use the higgsfield-* skills for those.
---

# Gemini image & video generation

Calls the Gemini API directly with the user's key. Output lands on disk as a real file.

## Setup check

The key lives in `~/.zshrc` as `GEMINI_API_KEY`. If a call fails with "GEMINI_API_KEY is not set",
the shell didn't inherit it — tell the user to run `source ~/.zshrc`, or to add the export if missing.
**Never** print, echo, or paste the key value, and never write it into a project directory.

Verify reachable models any time a model id gets rejected:

```bash
python3 ~/.claude/skills/gemini-media/scripts/gemini_media.py models
```

## Images

```bash
S=~/.claude/skills/gemini-media/scripts/gemini_media.py

# text to image
python3 $S image "an isometric cutaway of a mechanical keyboard switch" -o switch.png -a 16:9 -s 2K

# edit / restyle / composite — pass one or more input images
python3 $S image "make the background a blueprint grid" -o v2.png --edit switch.png
python3 $S image "put the product from image 1 into the scene from image 2" -o ad.jpg --edit product.png scene.jpg
```

| Flag | Values | Default |
|---|---|---|
| `-m` | `lite` (fastest/cheapest, 1K only) · `flash` (workhorse) · `pro` (best text rendering) · `legacy` | `flash` |
| `-a` | `1:1 3:2 2:3 3:4 4:3 4:5 5:4 9:16 16:9 21:9` | `1:1` |
| `-s` | `512px` `1K` `2K` `4K` | `2K` |

Use `pro` when the image contains **readable text** (posters, UI mockups, diagrams) — the flash models
garble long strings. Use `lite` for throwaway drafts. `.png` output preserves transparency; `.jpg` is smaller.

## Video

Each call costs real money and takes 1-3 minutes. Confirm the prompt with the user before firing,
and don't loop over variations unasked.

```bash
# text to video
python3 $S video "slow dolly across a rain-slicked neon alley, distant thunder" -o alley.mp4

# animate a still (image-to-video) — the reliable move: generate a frame first, then animate it
python3 $S image "a paper boat on a dark lake, moonlit" -o boat.png -a 16:9
python3 $S video "the boat drifts forward, ripples spreading" -o boat.mp4 --image boat.png
```

| Flag | Values | Default |
|---|---|---|
| `-m` | `lite` (cheapest, no 4K) · `fast` · `pro` (4K, best consistency) | `fast` |
| `-a` | `16:9` `9:16` | `16:9` |
| `-r` | `720p` `1080p` `4k` | `720p` |
| `-d` | `4` `6` `8` | `8` |
| `--image` / `--last-frame` | first / target final frame | — |

Constraints the API enforces: `1080p` and `4k` require `-d 8`. `lite` cannot do `4k`.
Veo generates its own synchronized audio — describe the sound in the prompt, don't add it in post.

## Prompting

Veo and the image models respond to camera and lighting language, not to keyword soup.
Write a sentence describing subject, action, shot type, and lighting — "handheld medium shot,
golden hour backlight, shallow depth of field" beats "best quality, 4k, masterpiece, trending".

For a coherent sequence, generate a still first and chain it with `--image`; text-to-video
alone will not hold a character or product consistent across clips.

## Failure handling

On an unparseable response the script writes `<output>.response.json` next to the target and
names it in the error. Read that file — a refusal or a quota message is usually sitting in it.
Model ids move fast (Veo 3.0 and Imagen 4 were both retired in 2026); if one 404s, run `models`
and use a live id rather than guessing.
