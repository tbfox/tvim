" Syntax highlighting for scripture buffers

if exists("b:current_syntax")
  finish
endif

" Verse numbers at the beginning of lines (e.g., "1. ", "2. ", etc.)
syntax match scriptureVerseNumber /^\d\+\./

" Link verse numbers to the same highlight group as markdown h1 headings
" Markdown h1s typically use the Title highlight group
highlight link scriptureVerseNumber Title

let b:current_syntax = "scripture"
