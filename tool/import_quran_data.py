#!/usr/bin/env python3
"""Validate and import licensed Tanzil and HQKSTD source files."""

import argparse
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path, PurePosixPath
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
SURAH_METADATA = ROOT / "assets" / "data" / "surahs.json"
ARABIC_SOURCE_OUTPUT = (
    ROOT / "assets" / "data" / "source" / "tanzil-uthmani-v1.1.xml"
)
ARABIC_OUTPUT = ROOT / "assets" / "data" / "quran-uthmani.json"
SORANI_OUTPUT = ROOT / "assets" / "data" / "sorani-translation.json"
MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"


def expected_references():
    metadata = json.loads(SURAH_METADATA.read_text(encoding="utf-8"))
    surahs = metadata["surahs"]
    if len(surahs) != 114:
        raise ValueError(f"Expected 114 Surahs in {SURAH_METADATA}.")

    return [
        (surah["number"], verse_number)
        for surah in surahs
        for verse_number in range(1, surah["verseCount"] + 1)
    ]


def read_tanzil(path, references):
    source_bytes = path.read_bytes()
    source_bytes.decode("utf-8", errors="strict")
    root = ET.fromstring(source_bytes)
    if root.tag != "quran":
        raise ValueError("The Tanzil source must have a quran root element.")

    records = []
    for surah in root.findall("sura"):
        try:
            surah_number = int(surah.attrib["index"])
        except (KeyError, ValueError) as error:
            raise ValueError(
                f"Invalid Tanzil Surah number {surah.attrib.get('index')}."
            ) from error
        for aya in surah.findall("aya"):
            try:
                verse_number = int(aya.attrib["index"])
            except (KeyError, ValueError) as error:
                raise ValueError(
                    f"Invalid Tanzil verse number in Surah {surah_number}."
                ) from error
            arabic_text = aya.attrib.get("text", "")
            bismillah = aya.attrib.get("bismillah")
            if not arabic_text:
                raise ValueError(
                    f"Empty Arabic text at Surah {surah_number}, "
                    f"verse {verse_number}."
                )
            if bismillah is not None and verse_number != 1:
                raise ValueError(
                    f"Unexpected Surah-opening Bismillah at Surah "
                    f"{surah_number}, verse {verse_number}."
                )
            records.append(
                {
                    "surahNumber": surah_number,
                    "verseNumber": verse_number,
                    "arabicText": arabic_text,
                    "surahOpeningBismillah": bismillah,
                }
            )

    actual_references = [
        (record["surahNumber"], record["verseNumber"]) for record in records
    ]
    if actual_references != references:
        mismatch = next(
            (
                index
                for index, (actual, expected) in enumerate(
                    zip(actual_references, references), start=1
                )
                if actual != expected
            ),
            min(len(actual_references), len(references)) + 1,
        )
        raise ValueError(
            f"Tanzil verse order/count mismatch at record {mismatch}: "
            f"found {len(actual_references)} records, expected "
            f"{len(references)}."
        )
    return source_bytes, records


def tanzil_copyright_notice(source_bytes):
    source_text = source_bytes.decode("utf-8", errors="strict")
    notices = re.findall(
        r"Copyright \(C\) 2007-\d{4} Tanzil Project",
        source_text,
    )
    if len(notices) != 1:
        raise ValueError(
            "Expected one Tanzil copyright notice in the source XML."
        )
    return (
        f"Tanzil Quran Text {notices[0]}. "
        "License: Creative Commons Attribution 3.0"
    )


def cell_column(cell_reference):
    column = 0
    for character in cell_reference:
        if not character.isalpha():
            break
        column = column * 26 + ord(character.upper()) - ord("A") + 1
    return column - 1


def cell_value(cell, shared_strings):
    cell_type = cell.attrib.get("t")
    if cell_type == "inlineStr":
        return "".join(
            node.text or "" for node in cell.iter(f"{{{MAIN_NS}}}t")
        )
    value = cell.find(f"{{{MAIN_NS}}}v")
    if value is None or value.text is None:
        return ""
    if cell_type == "s":
        return shared_strings[int(value.text)]
    return value.text


def read_workbook(path, references):
    with zipfile.ZipFile(path) as workbook:
        names = set(workbook.namelist())
        book = ET.fromstring(workbook.read("xl/workbook.xml"))
        relationships = ET.fromstring(
            workbook.read("xl/_rels/workbook.xml.rels")
        )
        relationship_targets = {
            relationship.attrib["Id"]: relationship.attrib["Target"]
            for relationship in relationships.findall(
                f"{{{PKG_REL_NS}}}Relationship"
            )
        }
        sheets = book.find(f"{{{MAIN_NS}}}sheets")
        if sheets is None or len(sheets) != 1:
            raise ValueError("Expected one cleaned translation worksheet.")
        sheet = sheets[0]
        relationship_id = sheet.attrib[f"{{{REL_NS}}}id"]
        target = PurePosixPath(relationship_targets[relationship_id])
        sheet_path = (
            target.as_posix().lstrip("/")
            if target.is_absolute()
            else (PurePosixPath("xl") / target).as_posix()
        )

        shared_strings = []
        if "xl/sharedStrings.xml" in names:
            shared_xml = ET.fromstring(workbook.read("xl/sharedStrings.xml"))
            shared_strings = [
                "".join(
                    node.text or "" for node in item.iter(f"{{{MAIN_NS}}}t")
                )
                for item in shared_xml.findall(f"{{{MAIN_NS}}}si")
            ]

        worksheet = ET.fromstring(workbook.read(sheet_path))
        sheet_data = worksheet.find(f"{{{MAIN_NS}}}sheetData")
        rows = [] if sheet_data is None else sheet_data.findall(
            f"{{{MAIN_NS}}}row"
        )
        if not rows:
            raise ValueError("The cleaned translation worksheet is empty.")

        header_cells = {
            cell_column(cell.attrib["r"]): cell_value(cell, shared_strings)
            for cell in rows[0].findall(f"{{{MAIN_NS}}}c")
        }
        column_by_name = {
            name: column for column, name in header_cells.items()
        }
        required = {"Index", "SurahNumber", "AyahNumber",
                    "CleanedKurdishTranslation"}
        missing = required - column_by_name.keys()
        if missing:
            raise ValueError(
                f"Missing required workbook columns: {', '.join(sorted(missing))}."
            )

        entries = []
        for index, row in enumerate(rows[1:]):
            cells = {
                cell_column(cell.attrib["r"]): cell_value(cell, shared_strings)
                for cell in row.findall(f"{{{MAIN_NS}}}c")
            }

            def value(name):
                return cells.get(column_by_name[name], "")

            try:
                source_index = int(value("Index"))
                reference = (
                    int(value("SurahNumber")),
                    int(value("AyahNumber")),
                )
            except ValueError as error:
                raise ValueError(
                    f"Invalid verse key in cleaned workbook row {index + 2}."
                ) from error

            if source_index != index:
                raise ValueError(
                    f"Workbook Index mismatch at row {index + 2}: "
                    f"found {source_index}, expected {index}."
                )
            if index >= len(references) or reference != references[index]:
                raise ValueError(
                    f"Workbook verse alignment mismatch at row {index + 2}: "
                    f"found {reference}, expected "
                    f"{references[index] if index < len(references) else 'end of data'}."
                )

            translation = value("CleanedKurdishTranslation")
            if not translation.strip():
                raise ValueError(
                    f"Missing Sorani translation at Surah {reference[0]}, "
                    f"verse {reference[1]}."
                )
            entries.append(
                {
                    "surahNumber": reference[0],
                    "verseNumber": reference[1],
                    "globalVerseNumber": index + 1,
                    "translation": translation,
                }
            )

    if len(entries) != len(references):
        raise ValueError(
            f"Expected {len(references)} translation rows; found {len(entries)}."
        )
    return entries


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tanzil", type=Path, required=True)
    parser.add_argument("--translation-xlsx", type=Path, required=True)
    arguments = parser.parse_args()

    references = expected_references()
    tanzil_bytes, arabic_records = read_tanzil(arguments.tanzil, references)
    translations = read_workbook(arguments.translation_xlsx, references)
    if len(arabic_records) != len(translations):
        raise ValueError("Arabic and Sorani datasets have different lengths.")

    ARABIC_SOURCE_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    ARABIC_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    SORANI_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(arguments.tanzil, ARABIC_SOURCE_OUTPUT)
    ARABIC_OUTPUT.write_text(
        json.dumps(
            {
                "schemaVersion": 1,
                "source": "Tanzil Quran Text",
                "version": "1.1",
                "copyrightNotice": tanzil_copyright_notice(tanzil_bytes),
                "verses": arabic_records,
            },
            ensure_ascii=False,
            separators=(",", ":"),
        )
        + "\n",
        encoding="utf-8",
        newline="\n",
    )
    SORANI_OUTPUT.write_text(
        json.dumps(
            {"schemaVersion": 1, "translations": translations},
            ensure_ascii=False,
            separators=(",", ":"),
        )
        + "\n",
        encoding="utf-8",
        newline="\n",
    )

    print(f"Imported {len(arabic_records)} Arabic verses and translations.")
    print(f"Tanzil XML SHA-256: {hashlib.sha256(tanzil_bytes).hexdigest()}")
    print(
        "Tanzil JSON UTF-8 SHA-256: "
        f"{hashlib.sha256(ARABIC_OUTPUT.read_bytes()).hexdigest()}"
    )
    print(
        "Sorani JSON UTF-8 SHA-256: "
        f"{hashlib.sha256(SORANI_OUTPUT.read_bytes()).hexdigest()}"
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, zipfile.BadZipFile, ET.ParseError) as error:
        raise SystemExit(str(error)) from error
