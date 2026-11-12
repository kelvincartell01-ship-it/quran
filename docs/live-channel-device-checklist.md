# Makkah and Madinah channel verification

## Source verification

The official Aloula website now exposes these live pages:

- Makkah: <https://aloula.sba.sa/live/quran>
- Madinah / Sunnah: <https://aloula.sba.sa/live/sunna>

The pages were inspected through the official site's visible navigation. The
Madinah page is titled “المباشر - قناة السنة النبوية – البث المباشر - الأولى”
and shows a video player with a play control. The page carries Aloula branding,
and identifies the site as registered with the Saudi Digital Government
Authority. The Quran page links to the Sunnah page from its visible channel
navigation.

The browser page is accessible and contains a player, but its playback and
permission for embedding in this app have not been verified. No stream URL or
player internals were inspected. The app therefore continues to open the
official HTTPS pages externally, does not show a LIVE badge, and does not claim
in-app playback. `video_player` is intentionally not added until an authorized,
stable stream or embed flow is verified. Only `url_launcher` is used for the
external-page fallback.

The visible Aloula branding and government-site notice support site identity;
permission for third-party embedding still requires confirmation with SBA.

## Android

- Confirm each channel opens its matching official Aloula live page.
- Start Quran recitation, open a channel page, and confirm recitation pauses
  before the browser opens.
- Return to the app and confirm Quran recitation does not resume automatically.
- Test browser availability, connection failures, and retrying the page action.
- If SBA later supplies an authorized embeddable stream, verify playback,
  buffering, adaptive resolution, audio focus, lifecycle pause, fullscreen,
  and orientation on a physical Android device.

## iOS

- Confirm each channel opens its matching official Aloula live page.
- Start Quran recitation, open a channel page, and confirm recitation pauses
  before Safari or the configured browser opens.
- Return to the app and confirm Quran recitation does not resume automatically.
- Test browser availability, connection failures, and retrying the page action.
- If SBA later supplies an authorized embeddable stream, verify playback,
  buffering, adaptive resolution, audio focus, lifecycle pause, fullscreen,
  and orientation on a physical iOS device.

No physical-device playback or platform build verification has been completed.
