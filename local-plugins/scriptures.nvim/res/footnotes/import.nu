#!/usr/bin/env nu

# Import footnotes from JSON files into SQLite database

def main [] {
    let db_path = '../standard-works.sqlite'

    # Create footnotes table if it doesn't exist
    print "Creating footnotes table..."
    ^sqlite3 $db_path "
        CREATE TABLE IF NOT EXISTS footnotes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            origin_chapter TEXT NOT NULL,
            note_id TEXT NOT NULL,
            content TEXT NOT NULL,
            refs TEXT NOT NULL,
            UNIQUE(origin_chapter, note_id)
        );
        CREATE INDEX IF NOT EXISTS idx_footnotes_origin ON footnotes(origin_chapter);
        CREATE INDEX IF NOT EXISTS idx_footnotes_note_id ON footnotes(note_id);
    "

    print "Table created successfully"

    # Get all JSON files
    let json_files = ls *.json | get name

    print $"Found ($json_files | length) JSON files to import"

    # Import each file
    for file in $json_files {
        print $"Importing ($file)..."

        let footnotes = open $file

        for note in $footnotes {
            let origin = $note.origin_chapter
            let note_id = $note.noteId
            let content = $note.content | str replace -a "'" "''"  # Escape single quotes
            let refs = $note.refs | to json | str replace -a "'" "''"  # Convert array to JSON string

            let sql = $"INSERT OR REPLACE INTO footnotes \(origin_chapter, note_id, content, refs\) VALUES \('($origin)', '($note_id)', '($content)', '($refs)'\);"

            ^sqlite3 $db_path $sql
        }
    }

    print "Import complete!"

    # Verify the import
    let count = ^sqlite3 $db_path "SELECT COUNT\(*\) FROM footnotes;" | str trim
    print $"Total footnotes imported: ($count)"

    # Ask if user wants to delete JSON files
    print ""
    print "Import successful! Would you like to delete the JSON files? (y/n)"
    let response = input

    if $response == "y" or $response == "Y" {
        print "Deleting JSON files..."
        rm *.json
        print "JSON files deleted!"
    } else {
        print "JSON files kept."
    }
}
