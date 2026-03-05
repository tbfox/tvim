" Syntax highlighting for scripture buffers

if exists("b:current_syntax")
  finish
endif

" Verse numbers at the beginning of lines (e.g., "1. ", "2. ", etc.)
syntax match scriptureVerseNumber /^\d\+\./

" Footnote markers with concealment using circled letters
" Conceal the prefix with circled letter replacements
syntax match scriptureFootnoteMarkA "(a)|" conceal cchar=ⓐ
syntax match scriptureFootnoteMarkB "(b)|" conceal cchar=ⓑ
syntax match scriptureFootnoteMarkC "(c)|" conceal cchar=ⓒ
syntax match scriptureFootnoteMarkD "(d)|" conceal cchar=ⓓ
syntax match scriptureFootnoteMarkE "(e)|" conceal cchar=ⓔ
syntax match scriptureFootnoteMarkF "(f)|" conceal cchar=ⓕ
syntax match scriptureFootnoteMarkG "(g)|" conceal cchar=ⓖ
syntax match scriptureFootnoteMarkH "(h)|" conceal cchar=ⓗ
syntax match scriptureFootnoteMarkI "(i)|" conceal cchar=ⓘ
syntax match scriptureFootnoteMarkJ "(j)|" conceal cchar=ⓙ
syntax match scriptureFootnoteMarkK "(k)|" conceal cchar=ⓚ
syntax match scriptureFootnoteMarkL "(l)|" conceal cchar=ⓛ
syntax match scriptureFootnoteMarkM "(m)|" conceal cchar=ⓜ
syntax match scriptureFootnoteMarkN "(n)|" conceal cchar=ⓝ
syntax match scriptureFootnoteMarkO "(o)|" conceal cchar=ⓞ
syntax match scriptureFootnoteMarkP "(p)|" conceal cchar=ⓟ
syntax match scriptureFootnoteMarkQ "(q)|" conceal cchar=ⓠ
syntax match scriptureFootnoteMarkR "(r)|" conceal cchar=ⓡ
syntax match scriptureFootnoteMarkS "(s)|" conceal cchar=ⓢ
syntax match scriptureFootnoteMarkT "(t)|" conceal cchar=ⓣ
syntax match scriptureFootnoteMarkU "(u)|" conceal cchar=ⓤ
syntax match scriptureFootnoteMarkV "(v)|" conceal cchar=ⓥ
syntax match scriptureFootnoteMarkW "(w)|" conceal cchar=ⓦ
syntax match scriptureFootnoteMarkX "(x)|" conceal cchar=ⓧ
syntax match scriptureFootnoteMarkY "(y)|" conceal cchar=ⓨ
syntax match scriptureFootnoteMarkZ "(z)|" conceal cchar=ⓩ

" Conceal the trailing pipe
syntax match scriptureFootnoteEnd "\(([a-z])|[^|]\+\)\@<=|" conceal

" Highlight the footnoted text (between the markers)
syntax match scriptureFootnoteText "(\w)|\zs[^|]\+\ze|"

" Link verse numbers to the same highlight group as markdown h1 headings
" Markdown h1s typically use the Title highlight group
highlight link scriptureVerseNumber Title

" Link footnote text to markdown link URL color (bluish)
highlight link scriptureFootnoteText @markup.link.url

let b:current_syntax = "scripture"
