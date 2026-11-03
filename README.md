# Glow

A full-screen, browser-based screensaver for Windows: classic Matrix digital rain plus four more scenes, synced across every PC in the house and controlled from a tiny web panel.

![Matrix rain](preview.png)

**▶ Live demo:** https://kdiiizzll.github.io/matrix-screensaver/
*(click, Space or → for the next scene · keys 1–5 jump to a scene · or add `?mode=paris`)*

## Features
- **Matrix rain:** katakana and digit glyphs with glowing heads and fading trails, drawn from a pre-baked sprite atlas so it stays smooth on any monitor.
- **Paris night:** the Eiffel Tower in gold above the city skyline and the Seine, with a sparkle show 5 s out of every 15 s, a sweeping beacon, and shooting stars that leave little notes.
- **More scenes:** starfield warp, fireworks and a neon lava lamp.
- **Multi-PC:** turn it on, off or switch scenes on one PC and every PC listed in `peers.txt` follows.
- **Control panel:** big ON/OFF and "Next" buttons at `http://localhost:8765/`, easy to use from a phone on the same Wi-Fi.
- **Kiosk mode:** fills every monitor in Edge kiosk mode, hides the taskbar and cursor, and puts everything back when you press Esc.

![Paris night](preview-paris.png)

## Install (Windows 10/11)
1. Download or clone this repo.
2. *(Optional, for multi-PC)* copy `peers.example.txt` to `peers.txt` and list the LAN IPs of your other PCs.
3. In the folder, run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```
   Approve the one-time admin prompt, which opens port 8765 on private networks.
4. Open **http://localhost:8765/** (or the *Glow Control* shortcut on your desktop) and press **Turn ON**. Press **Esc** to exit.

The installer puts its files in `%USERPROFILE%\Glow` and adds two hidden startup scripts: `server.ps1` (state and control on port 8765) and `agent.ps1` (opens and closes the full-screen windows). To uninstall, delete that folder and the two `Glow*.vbs` files in your Startup folder.

## Files
| File | What it does |
|---|---|
| `index.html` | The screensaver (all scenes). Runs standalone in any browser. |
| `server.ps1` | Tiny HTTP server: `/state`, `/set`, `/peers`, the panel and the saver |
| `agent.ps1` | Watches the state and opens or closes kiosk windows on every monitor |
| `panel.html` | Control panel |
| `install.ps1` | Installer |

## License
MIT © 2026 Kyle Fitzgerald. See [LICENSE](LICENSE).
