#!/usr/bin/env nu

# Import FSOY into scriptures.db

let db_path = ($env.FILE_PWD | path join ".." "scriptures.db")
let fsoy_dir = $env.FILE_PWD

# Helper: run a sql statement
def sql [statement: string] {
    sqlite3 $db_path $statement
}

# Helper: escape single quotes for SQL
def esc [s: string] {
    $s | str replace --all "'" "''"
}

# 1. Insert source (idempotent: delete first)
sql "DELETE FROM books WHERE source_id='fsoy';"
sql "DELETE FROM sources WHERE id='fsoy';"
sql "INSERT INTO sources (id, title, sort_order) VALUES ('fsoy', 'For the Strength of Youth', 6);"

print "Inserted source: fsoy"

# 2. Get all FSOY md files sorted by filename
let files = (ls $fsoy_dir | where name =~ "_\\d+-.*\\.md$" | sort-by name)

for file in $files {
    let filename = ($file.name | path basename)

    # Extract N from _N-*.md
    let sort_num = ($filename | parse "_{n}-{rest}.md" | get n | first | into int)

    # Read file content
    let content = (open $file.name)
    let raw_lines = ($content | lines)

    # Extract book title from first non-empty line (strip any heading markers)
    let title_line = ($raw_lines | where {|l| ($l | str trim) != ""} | first)
    let book_title = ($title_line | str replace --regex "^#{1,6} " "")
    let book_title_esc = (esc $book_title)

    # Derive short_name slug from filename (strip _N- prefix and .md suffix)
    let short_name = ($filename | str replace --regex "^_\\d+-" "" | str replace ".md" "")

    # Insert book
    let insert_book_sql = $"INSERT INTO books \(source_id, name, short_name, sort_order\) VALUES \('fsoy', '($book_title_esc)', '($short_name)', ($sort_num)\);"
    sql $insert_book_sql

    # Get book_id
    let book_id_str = (sql $"SELECT id FROM books WHERE source_id='fsoy' AND name='($book_title_esc)';")
    let book_id = ($book_id_str | into int)

    print $"Inserted book: ($book_title) \(id=($book_id)\)"

    # Parse lines into blocks (skip the first non-empty line which is the title)
    mut blocks = []
    mut para_lines: list<string> = []
    mut sort_order = 0
    mut skipped_title = false

    for line in $raw_lines {
        # Skip the title line (first non-empty line)
        if not $skipped_title {
            if ($line | str trim) != "" {
                $skipped_title = true
                continue
            } else {
                continue
            }
        }
        if ($line | str starts-with "## ") {
            # Flush pending paragraph
            if ($para_lines | length) > 0 {
                let text = ($para_lines | str join " ")
                $blocks = ($blocks | append {sort_order: $sort_order, block_type: "paragraph", content: $text})
                $sort_order = $sort_order + 1
                $para_lines = []
            }
            let heading_text = ($line | str replace --regex "^## " "")
            $blocks = ($blocks | append {sort_order: $sort_order, block_type: "heading", content: $heading_text})
            $sort_order = $sort_order + 1
        } else if ($line | str starts-with "# ") {
            # Flush pending paragraph
            if ($para_lines | length) > 0 {
                let text = ($para_lines | str join " ")
                $blocks = ($blocks | append {sort_order: $sort_order, block_type: "paragraph", content: $text})
                $sort_order = $sort_order + 1
                $para_lines = []
            }
            let heading_text = ($line | str replace --regex "^# " "")
            $blocks = ($blocks | append {sort_order: $sort_order, block_type: "heading", content: $heading_text})
            $sort_order = $sort_order + 1
        } else if ($line | str starts-with "- ") {
            # Flush pending paragraph
            if ($para_lines | length) > 0 {
                let text = ($para_lines | str join " ")
                $blocks = ($blocks | append {sort_order: $sort_order, block_type: "paragraph", content: $text})
                $sort_order = $sort_order + 1
                $para_lines = []
            }
            let item_text = ($line | str replace --regex "^- " "")
            $blocks = ($blocks | append {sort_order: $sort_order, block_type: "list_item", content: $item_text})
            $sort_order = $sort_order + 1
        } else if ($line =~ "^\\d+\\. ") {
            # Numbered list item: "1. foo"
            if ($para_lines | length) > 0 {
                let text = ($para_lines | str join " ")
                $blocks = ($blocks | append {sort_order: $sort_order, block_type: "paragraph", content: $text})
                $sort_order = $sort_order + 1
                $para_lines = []
            }
            $blocks = ($blocks | append {sort_order: $sort_order, block_type: "list_item", content: $line})
            $sort_order = $sort_order + 1
        } else if ($line | str trim) == "" {
            # Blank line: flush paragraph
            if ($para_lines | length) > 0 {
                let text = ($para_lines | str join " ")
                $blocks = ($blocks | append {sort_order: $sort_order, block_type: "paragraph", content: $text})
                $sort_order = $sort_order + 1
                $para_lines = []
            }
        } else {
            # Regular line: accumulate into paragraph
            $para_lines = ($para_lines | append $line)
        }
    }

    # Flush any remaining paragraph
    if ($para_lines | length) > 0 {
        let text = ($para_lines | str join " ")
        $blocks = ($blocks | append {sort_order: $sort_order, block_type: "paragraph", content: $text})
    }

    # Insert blocks
    for block in $blocks {
        let escaped = (esc $block.content)
        let insert_sql = $"INSERT INTO content_blocks \(book_id, sort_order, block_type, content\) VALUES \(($book_id), ($block.sort_order), '($block.block_type)', '($escaped)'\);"
        sql $insert_sql
    }

    print $"  Inserted ($blocks | length) blocks"
}

print "Done!"
