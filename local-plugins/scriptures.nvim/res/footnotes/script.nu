# {
#     "1_Nephi": 22,
#     "2_Nephi": 33,
#     "Jacob": 7,
#     "Enos": 1,
#     "Jarom": 1,
#     "Omni": 1,
#     "Words_of_Mormon": 1,
#     "Mosiah": 29,
#     "Alma": 63,
#     "Helaman": 16,
#     "3_Nephi": 30,
#     "4_Nephi": 1,
#     "Mormon": 9,
#     "Ether": 15,
#     "Moroni": 10
# }
def main [
    bookId: string
    chapterCount: number
] {
    for i in 1..$chapterCount {
        let chapter = $"bofm/($bookId)/($i)" 
        print $'(ansi green)Started: ($chapter)(ansi reset)'
        make-notes $chapter
        print $'(ansi yellow)Finished: ($chapter)(ansi reset)'
    }
    # let chapter = $"bofm/w-of-m/1" 
    # print $'(ansi green)Started: ($chapter)(ansi reset)'
    # make-notes $chapter
    # print $'(ansi yellow)Finished: ($chapter)(ansi reset)'
}

def make-notes [
    chapter: string # ex: "bofm/1-ne/1"
] {
    let filename = $chapter | split row "/" | str join '_';
    let path = $'(pwd)/($filename).temp.html';
    let endPath = $'(pwd)/($filename).json';

    if (not ($path | path exists)) {
        ^curl $'https://www.churchofjesuschrist.org/study/scriptures/($chapter)?lang=eng' -o $path
    }

    open $path
    | ^htmlq 'p.verse'
    | lines
    | each {
        ^htmlq 'a.study-note-ref'
        | lines
        | each {|line|
            let noteId = $line | ^htmlq -a data-scroll-id 'a.study-note-ref';
            let content = $line | ^htmlq --text 'a.study-note-ref';
            let refs = open $path
            | ^htmlq $'li#($noteId)'
            | ^htmlq -a href $'a.scripture-ref'
            | lines
            | each {
                split row "/" 
                | where {|x| $x != '' and $x != study and $x != scriptures } 
                | str join ':'
                | split row "?lang=eng"
                | str join ''
                | split row "&id="
                | str join '_'
                | split row "dc-testament:dc"
                | str join 'dnc'
            };
            return {
                origin_chapter: $chapter
                noteId: $noteId
                content: $content
                refs: $refs
            }
        }
    }
    | flatten
    | to json
    | save $endPath;
    rm $path;

}
