import json
import unittest

import import_quran_data


TANZIL_SOURCE = import_quran_data.ARABIC_SOURCE_OUTPUT
QURAN_ASSET = import_quran_data.ARABIC_OUTPUT


class TanzilImportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        _, cls.source_records = import_quran_data.read_tanzil(
            TANZIL_SOURCE,
            import_quran_data.expected_references(),
        )
        cls.asset = json.loads(QURAN_ASSET.read_text(encoding="utf-8"))

    def test_every_arabic_record_matches_the_official_xml(self):
        self.assertEqual(len(self.source_records), 6236)
        self.assertEqual(self.asset["verses"], self.source_records)
        self.assertEqual(
            self.asset["copyrightNotice"],
            import_quran_data.tanzil_copyright_notice(
                TANZIL_SOURCE.read_bytes()
            ),
        )

    def test_bismillah_is_separate_and_source_exceptions_are_preserved(self):
        records = {
            (record["surahNumber"], record["verseNumber"]): record
            for record in self.source_records
        }
        fatihah_first = records[(1, 1)]
        baqarah_first = records[(2, 1)]
        tawbah_first = records[(9, 1)]
        nas_first = records[(114, 1)]

        self.assertEqual(
            fatihah_first["arabicText"],
            "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        )
        self.assertIsNone(fatihah_first["surahOpeningBismillah"])
        self.assertEqual(baqarah_first["arabicText"], "الٓمٓ")
        self.assertIsNotNone(baqarah_first["surahOpeningBismillah"])
        self.assertIsNone(tawbah_first["surahOpeningBismillah"])
        self.assertIsNotNone(nas_first["surahOpeningBismillah"])


if __name__ == "__main__":
    unittest.main()
