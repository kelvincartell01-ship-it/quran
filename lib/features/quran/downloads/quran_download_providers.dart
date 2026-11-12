import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quran_download_controller.dart';

final quranDownloadControllerProvider = Provider<QuranDownloadController>(
  (ref) => const UnavailableQuranDownloadController(),
);
