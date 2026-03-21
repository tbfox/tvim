if exists("b:current_syntax")
  finish
endif

" Missed lines (****0 prefix)
syn match luacovMissed        /^\*\+0\s.*/
" Hit count (leading number before code)
syn match luacovHitCount      /^\s*\d\+\ze\s/ contained
syn match luacovHitLine       /^\s*\d\+\s.*/ contains=luacovHitCount
" Uncounted lines (comments, blanks, structure lines with no count)
syn match luacovUncounted     /^\s\{6\}\S.*/

" Section headers (====... lines and file paths between them)
syn match luacovSeparator     /^=\{10,\}/
syn match luacovFilePath      /^\/.\+\.lua$/

" Summary section
syn match luacovSummaryHeader /^Summary$/
syn match luacovSummaryDivider /^-\{10,\}/
syn match luacovSummaryTotal  /^Total\s.*/
" Coverage percentage — color by threshold
syn match luacovPct100        /\s1\{0,2\}00\.00%/
syn match luacovPctHigh       /\s[89][0-9]\.\d\+%/
syn match luacovPctMid        /\s[5-7][0-9]\.\d\+%/
syn match luacovPctLow        /\s[0-4][0-9]\.\d\+%/

hi def luacovMissed        guifg=#f38ba8 gui=bold   ctermfg=1 cterm=bold
hi def luacovHitCount      guifg=#a6e3a1             ctermfg=2
hi def luacovUncounted     guifg=#585b70             ctermfg=8
hi def luacovSeparator     guifg=#45475a             ctermfg=8
hi def luacovFilePath      guifg=#89b4fa gui=bold   ctermfg=4 cterm=bold
hi def luacovSummaryHeader guifg=#cba6f7 gui=bold   ctermfg=5 cterm=bold
hi def luacovSummaryDivider guifg=#45475a            ctermfg=8
hi def luacovSummaryTotal  guifg=#cdd6f4 gui=bold   ctermfg=7 cterm=bold
hi def luacovPct100        guifg=#a6e3a1 gui=bold   ctermfg=2 cterm=bold
hi def luacovPctHigh       guifg=#a6e3a1             ctermfg=2
hi def luacovPctMid        guifg=#f9e2af             ctermfg=3
hi def luacovPctLow        guifg=#f38ba8             ctermfg=1

let b:current_syntax = "luacov"
