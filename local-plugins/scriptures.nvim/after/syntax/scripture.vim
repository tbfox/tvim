" Syntax highlighting for scripture buffers

if exists("b:current_syntax")
  finish
endif

" Verse numbers at the beginning of lines (e.g., "1. ", "2. ", etc.)
syntax match scriptureVerseNumber /^\d\+\./

" Footnote markers with concealment
" Pattern: (letter)|text| - conceals the (letter)| and trailing |, showing only text
syntax region scriptureFootnoteMarker matchgroup=Conceal start="(\w\+)|" end="|" concealends oneline

" Link verse numbers to the same highlight group as markdown h1 headings
" Markdown h1s typically use the Title highlight group
highlight link scriptureVerseNumber Title

" Link footnote marker content to markdown link URL color (bluish)
highlight link scriptureFootnoteMarker @markup.link.url

let b:current_syntax = "scripture"
