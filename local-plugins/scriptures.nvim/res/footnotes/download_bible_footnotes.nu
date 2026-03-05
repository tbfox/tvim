#!/usr/bin/env nu

# Download footnotes for any scripture source and insert into database
# Usage (single book): ./download_bible_footnotes.nu <source> <book_short_name>
# Usage (all books):   ./download_bible_footnotes.nu <source>
# Example: ./download_bible_footnotes.nu nt mat
# Example: ./download_bible_footnotes.nu nt
# Example: ./download_bible_footnotes.nu ot
# Example: ./download_bible_footnotes.nu pgp
# Example: ./download_bible_footnotes.nu dc

def main [
    source: string  # "nt", "ot", "pgp", or "dc"
    bookShort?: string  # optional: short name like "mat", "gen", etc. If omitted, processes all books
] {
    let db_path = $"(pwd)/../scriptures.db";

    # If no book specified, get all books for the source
    let books = if ($bookShort | is-empty) {
        sqlite3 $db_path $"SELECT short_name FROM books WHERE source_id='($source)' ORDER BY sort_order;"
        | lines
        | where {|x| $x != ""}
    } else {
        [$bookShort]
    };

    let source_upper = ($source | str upcase);
    let book_count = ($books | length);

    print $"(ansi magenta)========================================(ansi reset)";
    print $"(ansi magenta)Processing ($source_upper) - ($book_count) book\(s\)(ansi reset)";
    print $"(ansi magenta)========================================(ansi reset)";

    for book in $books {
        process-book $source $book $db_path;
    }

    print $"(ansi magenta)========================================(ansi reset)";
    print $"(ansi magenta)Completed all books for ($source_upper)(ansi reset)";
    print $"(ansi magenta)========================================(ansi reset)";
}

def process-book [
    source: string
    bookShort: string
    dbPath: string
] {
    # Get book_id and max chapter from database
    let book_info = (
        sqlite3 $dbPath $"SELECT b.id, MAX\(v.chapter_number\) FROM books b JOIN verses v ON b.id = v.book_id WHERE b.source_id='($source)' AND b.short_name='($bookShort)' GROUP BY b.id;"
        | split row "|"
    );

    if ($book_info | length) < 2 {
        print $"(ansi red)Error: Book not found in database: ($source)/($bookShort)(ansi reset)";
        return;
    }

    let book_id = ($book_info | get 0);
    let chapter_count = ($book_info | get 1 | into int);

    print $"(ansi cyan)Processing ($source)/($bookShort) - Book ID: ($book_id), Chapters: ($chapter_count)(ansi reset)";

    for chapter in 1..$chapter_count {
        print $'(ansi green)  Started: ($source)/($bookShort)/($chapter)(ansi reset)';
        download-and-insert-footnotes $source $bookShort $book_id $chapter $dbPath;
        print $'(ansi yellow)  Finished: ($source)/($bookShort)/($chapter)(ansi reset)';
    }

    print $"(ansi cyan)Completed ($source)/($bookShort)(ansi reset)";
    print "";
}

def download-and-insert-footnotes [
    source: string
    bookShort: string
    bookId: string
    chapter: int
    dbPath: string
] {
    let filename = $"($source)_($bookShort)_($chapter)";
    let temp_path = $'(pwd)/temp_($filename).html';

    # Map short_name to URL slug (some books use different slugs than short_name)
    let url_slug = get-url-slug $bookShort;

    # Map source to URL source (DC uses "dc-testament" in URLs)
    let url_source = if $source == "dc" { "dc-testament" } else { $source };

    # Download HTML if not already cached
    if (not ($temp_path | path exists)) {
        ^curl $'https://www.churchofjesuschrist.org/study/scriptures/($url_source)/($url_slug)/($chapter)?lang=eng' -o $temp_path;
        sleep 1sec;  # Be nice to the server
    }

    # Extract footnotes from HTML
    let footnotes = (
        open $temp_path
        | ^htmlq 'p.verse'
        | lines
        | enumerate
        | each {|verse_elem|
            let verse_idx = ($verse_elem.index + 1);

            $verse_elem.item
            | ^htmlq 'a.study-note-ref'
            | lines
            | each {|note_line|
                let note_id = ($note_line | ^htmlq -a data-scroll-id 'a.study-note-ref' | str trim);
                let highlighted_text = ($note_line | ^htmlq --text 'a.study-note-ref' | str trim);

                # Extract note letter (last character, e.g., "1a" -> "a")
                let note_letter = ($note_id | str substring ($note_id | str length | $in - 1)..);

                # Get scripture references from the footnote
                let refs = (
                    open $temp_path
                    | ^htmlq $'li#($note_id)'
                    | ^htmlq 'a.scripture-ref'
                    | lines
                    | each {|ref_line|
                        let href = ($ref_line | ^htmlq -a href 'a.scripture-ref' | str trim);
                        parse-scripture-reference $href
                    }
                    | where type == "scripture"
                );

                # Check if there are topical guide references
                let has_tg = (
                    open $temp_path
                    | ^htmlq $'li#($note_id)'
                    | ^htmlq 'a[href*="/study/scriptures/tg/"]'
                    | lines
                    | length
                ) > 0;

                {
                    verse_number: $verse_idx,
                    note_letter: $note_letter,
                    highlighted_text: $highlighted_text,
                    refs: $refs,
                    has_topical_guide: $has_tg
                }
            }
        }
        | flatten
    );

    # Insert footnotes into database
    for footnote in $footnotes {
        insert-footnote $dbPath $bookId $chapter $footnote;
    }

    # Clean up temp file
    rm $temp_path;
}

def insert-footnote [
    dbPath: string
    bookId: string
    chapter: int
    footnote: record
] {
    let verse = $footnote.verse_number;
    let letter = $footnote.note_letter;
    let text = ($footnote.highlighted_text | sql-escape);

    # Insert footnote and get its ID
    let insert_sql = $"INSERT OR IGNORE INTO footnotes \(book_id, chapter_number, verse_number, note_letter, highlighted_text\) VALUES \(($bookId), ($chapter), ($verse), '($letter)', '($text)'\);";
    sqlite3 $dbPath $insert_sql;

    let footnote_id = (sqlite3 $dbPath $"SELECT id FROM footnotes WHERE book_id=($bookId) AND chapter_number=($chapter) AND verse_number=($verse) AND note_letter='($letter)';");

    # Insert scripture references
    for ref in ($footnote.refs | enumerate) {
        let sort = ($ref.index + 1);
        let r = $ref.item;

        let ref_sql = $"INSERT OR IGNORE INTO footnote_references \(footnote_id, reference_type, sort_order, ref_source_id, ref_book_short, ref_chapter, ref_verse_start, ref_verse_end\) VALUES \(($footnote_id), 'scripture', ($sort), '($r.source)', '($r.book)', ($r.chapter), ($r.verse_start), ($r.verse_end)\);";
        sqlite3 $dbPath $ref_sql;
    }

    # Insert topical guide marker if present
    if $footnote.has_topical_guide {
        let sort = (($footnote.refs | length) + 1);
        let tg_sql = $"INSERT OR IGNORE INTO footnote_references \(footnote_id, reference_type, sort_order, topical_guide_id\) VALUES \(($footnote_id), 'topical_guide', ($sort), 'unknown'\);";
        sqlite3 $dbPath $tg_sql;
    }
}

def parse-scripture-reference [
    href: string
] {
    # Example: /study/scriptures/ot/prov/22?lang=eng&id=1#1
    # Example: /study/scriptures/nt/luke/1?lang=eng&id=5-7#5

    if ($href | str contains "/study/scriptures/tg/") {
        return { type: "topical_guide" };
    }

    if not ($href | str contains "/study/scriptures/") {
        return { type: "unknown" };
    }

    # Split and parse the URL
    let parts = ($href | split row "/" | where {|x| $x != "" and $x != "study" and $x != "scriptures"});

    if ($parts | length) < 3 {
        return { type: "unknown" };
    }

    let source_raw = ($parts | get 0);
    # Map URL source back to database source (dc-testament -> dc)
    let source = if $source_raw == "dc-testament" { "dc" } else { $source_raw };
    let book = ($parts | get 1);
    let chapter_part = ($parts | get 2);

    # Extract chapter (before ?)
    # Note: not always numeric (e.g., "fac-2" for facsimiles)
    let chapter_str = ($chapter_part | split row "?" | get 0);

    # Try to convert to int, skip if not numeric (e.g., facsimiles, JST references)
    let chapter = try {
        $chapter_str | into int
    } catch {
        # If not a number, skip this reference
        return { type: "unknown" };
    };

    # Extract verse range from fragment (#1 or #5-7 or #p24)
    let fragment = if ($href | str contains "#") {
        $href | split row "#" | get 1 | split row "&" | get 0
    } else if ($href | str contains "id=") {
        $href | split row "id=" | get 1 | split row "&" | get 0
    } else {
        "1"
    };

    # Handle paragraph markers like "p24" by stripping the 'p' prefix
    let clean_fragment = if ($fragment | str starts-with "p") {
        $fragment | str substring 1..
    } else {
        $fragment
    };

    let verse_parts = ($clean_fragment | split row "-");
    let verse_start = ($verse_parts | get 0 | into int);
    let verse_end = if ($verse_parts | length) > 1 {
        $verse_parts | get 1 | into int
    } else {
        $verse_start
    };

    return {
        type: "scripture",
        source: $source,
        book: $book,
        chapter: $chapter,
        verse_start: $verse_start,
        verse_end: $verse_end
    };
}

def sql-escape [] {
    $in | str replace -a "'" "''"
}

def get-url-slug [
    short_name: string
] {
    # Map database short_name to URL slug for books that differ
    # Most books use short_name as-is, only map exceptions
    let mapping = {
        "mat": "matt",
    };

    if ($short_name in $mapping) {
        $mapping | get $short_name
    } else {
        $short_name
    }
}
