#!/usr/bin/env python3
"""Generate images and video from the Gemini API. Standard library only.

Reads the key from GEMINI_API_KEY (or GOOGLE_API_KEY).

  gemini_media.py image "a red bicycle" -o bike.jpg
  gemini_media.py image "add a wizard hat" -o out.png --edit bike.jpg
  gemini_media.py video "the bicycle rides off" -o clip.mp4 --image bike.jpg
  gemini_media.py models
"""

import argparse
import base64
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request

BASE = "https://generativelanguage.googleapis.com/v1beta"

IMAGE_MODELS = {
    "lite": "gemini-3.1-flash-lite-image",   # fastest/cheapest, 1K only
    "flash": "gemini-3.1-flash-image",       # workhorse, 512px-4K
    "pro": "gemini-3-pro-image",             # best text rendering, 4K
    "legacy": "gemini-2.5-flash-image",
}
VIDEO_MODELS = {
    "lite": "veo-3.1-lite-generate-preview",  # cheapest, no 4K/extend
    "fast": "veo-3.1-fast-generate-preview",
    "pro": "veo-3.1-generate-preview",        # 4K, best consistency
}


def die(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def api_key():
    key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if not key:
        die("GEMINI_API_KEY is not set. See the skill's SKILL.md for setup.")
    return key


def request(method, url, body=None, raw=False):
    """Call the API. Returns parsed JSON, or raw bytes when raw=True."""
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("x-goog-api-key", api_key())
    if data:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=600) as resp:
            payload = resp.read()
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:2000]
        die(f"HTTP {e.code} from {url.split('?')[0]}\n{detail}")
    except urllib.error.URLError as e:
        die(f"network failure: {e.reason}")
    return payload if raw else json.loads(payload)


def walk(node):
    """Yield every dict nested anywhere inside node."""
    if isinstance(node, dict):
        yield node
        for v in node.values():
            yield from walk(v)
    elif isinstance(node, list):
        for v in node:
            yield from walk(v)


def find_image(payload):
    """Pull base64 image bytes out of a response.

    The Interactions API schema has shifted more than once (outputs -> steps),
    so match on shape rather than on a fixed path.
    """
    for node in walk(payload):
        for key in ("data", "bytesBase64Encoded", "b64_json"):
            blob = node.get(key)
            if not isinstance(blob, str) or len(blob) < 512:
                continue
            mime = node.get("mime_type") or node.get("mimeType") or ""
            if mime and not mime.startswith("image/"):
                continue
            try:
                return base64.b64decode(blob, validate=True), mime or "image/png"
            except Exception:
                continue
    return None, None


def find_video_uri(payload):
    for node in walk(payload):
        uri = node.get("uri")
        if isinstance(uri, str) and uri.startswith("http"):
            return uri
    return None


def find_text(payload):
    """Models often explain a refusal in a text field instead of returning bytes."""
    out = []
    for node in walk(payload):
        text = node.get("text")
        if isinstance(text, str) and text.strip():
            out.append(text.strip())
    return "\n".join(out[:3])


def encode_file(path):
    if not os.path.isfile(path):
        die(f"no such file: {path}")
    mime = mimetypes.guess_type(path)[0] or "application/octet-stream"
    with open(path, "rb") as fh:
        return base64.b64encode(fh.read()).decode(), mime


def dump_raw(payload, out_path):
    sidecar = out_path + ".response.json"
    with open(sidecar, "w") as fh:
        json.dump(payload, fh, indent=2)
    return sidecar


def cmd_image(args):
    model = IMAGE_MODELS.get(args.model, args.model)
    parts = [{"type": "text", "text": args.prompt}]
    for path in args.edit or []:
        blob, mime = encode_file(path)
        parts.append({"type": "image", "mime_type": mime, "data": blob})

    out_mime = "image/png" if args.out.lower().endswith(".png") else "image/jpeg"
    body = {
        "model": model,
        "input": parts,
        "response_format": {
            "type": "image",
            "mime_type": out_mime,
            "aspect_ratio": args.aspect,
            "image_size": args.size,
        },
    }
    print(f"generating with {model} ({args.aspect}, {args.size})...", file=sys.stderr)
    payload = request("POST", f"{BASE}/interactions", body)

    image, mime = find_image(payload)
    if image is None:
        note = find_text(payload)
        sidecar = dump_raw(payload, args.out)
        die(f"no image in response. raw saved to {sidecar}\n{note}")

    with open(args.out, "wb") as fh:
        fh.write(image)
    print(f"{args.out}  ({len(image) // 1024} KB, {mime})")


def cmd_video(args):
    model = VIDEO_MODELS.get(args.model, args.model)
    instance = {"prompt": args.prompt}
    if args.image:
        blob, mime = encode_file(args.image)
        instance["image"] = {"inlineData": {"mimeType": mime, "data": blob}}
    if args.last_frame:
        blob, mime = encode_file(args.last_frame)
        instance["lastFrame"] = {"inlineData": {"mimeType": mime, "data": blob}}

    params = {
        "aspectRatio": args.aspect,
        "resolution": args.resolution,
        "durationSeconds": str(args.duration),
    }
    if args.negative:
        params["negativePrompt"] = args.negative

    print(f"submitting to {model} ({args.resolution}, {args.duration}s)...", file=sys.stderr)
    op = request("POST", f"{BASE}/models/{model}:predictLongRunning",
                 {"instances": [instance], "parameters": params})
    name = op.get("name")
    if not name:
        die(f"no operation name returned:\n{json.dumps(op)[:1000]}")

    # Veo runs take a couple of minutes; poll until done or the budget runs out.
    deadline = time.time() + args.timeout
    waited = 0
    while True:
        if time.time() > deadline:
            die(f"timed out after {args.timeout}s. resume with:\n"
                f"  curl -H \"x-goog-api-key: $GEMINI_API_KEY\" {BASE}/{name}")
        time.sleep(10)
        waited += 10
        op = request("GET", f"{BASE}/{name}")
        if op.get("done"):
            break
        print(f"  ...still rendering ({waited}s)", file=sys.stderr)

    if "error" in op:
        die(f"generation failed: {json.dumps(op['error'])[:1000]}")

    uri = find_video_uri(op)
    if not uri:
        sidecar = dump_raw(op, args.out)
        die(f"no video URI in response. raw saved to {sidecar}")

    print("downloading...", file=sys.stderr)
    blob = request("GET", uri, raw=True)
    with open(args.out, "wb") as fh:
        fh.write(blob)
    print(f"{args.out}  ({len(blob) // 1024} KB, {waited}s)")


def cmd_models(args):
    payload = request("GET", f"{BASE}/models?pageSize=200")
    for m in payload.get("models", []):
        name = m.get("name", "").replace("models/", "")
        if any(k in name for k in ("image", "veo", "imagen")):
            print(f"{name:45} {m.get('displayName', '')}")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("image", help="text-to-image, or edit with --edit")
    p.add_argument("prompt")
    p.add_argument("-o", "--out", required=True, help="output path (.png or .jpg)")
    p.add_argument("-m", "--model", default="flash",
                   help="lite | flash | pro | legacy, or a full model id")
    p.add_argument("-a", "--aspect", default="1:1",
                   help="1:1 3:2 2:3 3:4 4:3 4:5 5:4 9:16 16:9 21:9")
    p.add_argument("-s", "--size", default="2K", help="512px | 1K | 2K | 4K")
    p.add_argument("--edit", nargs="+", metavar="IMG",
                   help="input image(s) to edit or use as reference")
    p.set_defaults(func=cmd_image)

    p = sub.add_parser("video", help="text-to-video, or image-to-video with --image")
    p.add_argument("prompt")
    p.add_argument("-o", "--out", required=True, help="output path (.mp4)")
    p.add_argument("-m", "--model", default="fast",
                   help="lite | fast | pro, or a full model id")
    p.add_argument("-a", "--aspect", default="16:9", help="16:9 or 9:16")
    p.add_argument("-r", "--resolution", default="720p", help="720p | 1080p | 4k")
    p.add_argument("-d", "--duration", type=int, default=8, help="4, 6, or 8 seconds")
    p.add_argument("--image", help="first frame, for image-to-video")
    p.add_argument("--last-frame", help="target final frame")
    p.add_argument("--negative", help="what to avoid")
    p.add_argument("--timeout", type=int, default=900, help="poll budget in seconds")
    p.set_defaults(func=cmd_video)

    p = sub.add_parser("models", help="list image/video models your key can reach")
    p.set_defaults(func=cmd_models)

    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
