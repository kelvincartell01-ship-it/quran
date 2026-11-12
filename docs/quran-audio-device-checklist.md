# Quran audio device acceptance checklist

The automated tests cover queue metadata, state transitions, persistence, and
reader highlighting. Complete these checks on physical devices before release:

## Android

- Grant notifications on Android 13+ and confirm the foreground media
  notification shows the current Surah/ayah and local artwork.
- Test play/pause, previous/next ayah, scrubbing, and repeat controls from the
  notification, lock screen, Bluetooth headset, and Android Auto where present.
- Start playback, background the app, switch apps, lock the screen, and verify
  audio continues; pause and confirm the notification remains usable.
- Test notification permission denial, transient audio-focus interruptions,
  permanent focus loss, and unplugging wired/Bluetooth headphones.
- Force-stop the app and confirm playback does not restart automatically.
- Relaunch, open the saved Surah, and confirm the explicit Play action resumes
  from the saved reciter, ayah, and position.
- Download a Surah, enable airplane mode, and verify its verses play from the
  selected reciter's local files without network access.
- Pause a download, resume it, and confirm it continues without corrupting or
  duplicating the audio file. Delete the download and verify playback falls
  back to the network only after connectivity returns.
- Relaunch and confirm completed downloads remain available offline.

## iOS

- Confirm Now Playing metadata, artwork, and controls appear on the Lock Screen
  and in Control Center.
- Background and lock the device; verify uninterrupted playback and test
  Bluetooth/headset controls.
- Test calls, Siri, alarms, navigation ducking, headphone removal, and an
  interruption that does not request resumption.
- Confirm interruption handling does not resume against user intent. The
  current `audio_session` interruption event does not expose Apple's
  `shouldResume` option, so automatic resumption is intentionally disabled on
  iOS; resume manually after an interruption.
- Force-quit and confirm playback does not restart automatically. Relaunch,
  open the saved Surah, and verify the explicit Play action restores position.
- Download a Surah, enable airplane mode, and verify its verses play from the
  selected reciter's local files without network access.
- Pause and resume a download, then background the app during another
  download. Verify partial files recover safely after relaunch; iOS may suspend
  app-managed transfers while the app is backgrounded.
- Relaunch and confirm completed downloads remain available offline.

## Network and provider terms

- Verify streaming and downloads over Wi-Fi and mobile data, including a
  dropped connection, retry, and resumed byte-range request.
- Downloaded Al Quran Cloud audio is stored in app-managed local storage and
  is scoped to the selected reciter; the app does not switch reciters when a
  matching offline file is unavailable.
- Confirm Al Quran Cloud's current usage terms and each reciter's rights before
  production release. The provider's permission does not replace rights held
  by reciters or their estates.
