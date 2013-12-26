
" code folding
setlocal foldmethod=expr
setlocal foldexpr=md#core#fold(v:lnum)

" operator pending mappings
onoremap <buffer> is :call md#core#insideSection()<CR>
onoremap <buffer> as :call md#core#aroundSection(1)<CR>
onoremap <buffer> it :call md#core#insideTree()<CR>
onoremap <buffer> at :call md#core#aroundTree()<CR>
onoremap <buffer> ih :call md#core#insideHeading()<CR>
onoremap <buffer> ah :call md#core#aroundHeading()<CR>

vnoremap <buffer> is :<C-u>call md#core#insideSection()<CR>
vnoremap <buffer> as :<C-u>call md#core#aroundSection(0)<CR>
vnoremap <buffer> it :<C-u>call md#core#insideTree()<CR>
vnoremap <buffer> at :<C-u>call md#core#aroundTree()<CR>
vnoremap <buffer> ih :<C-u>call md#core#insideHeading()<CR>
vnoremap <buffer> ah :<C-u>call md#core#aroundHeading()<CR>

" tree manipulation mappings
nnoremap <buffer> [r :call md#core#decHeading()<CR>
nnoremap <buffer> ]r :call md#core#incHeading()<CR>
nnoremap <buffer> [m :call md#core#raiseSectionBack()<CR>
nnoremap <buffer> ]m :call md#core#raiseSectionForward()<CR>

" movement mappings
" TODO make these motions better (store V state, no yucky echom, etc.)

nnoremap <buffer> [h :call md#move#toPreviousHeading()<CR>
nnoremap <buffer> ]h :call md#move#toNextHeading()<CR>
nnoremap <buffer> [[ :call md#move#toPreviousSibling()<CR>
nnoremap <buffer> ]] :call md#move#toNextSibling()<CR>
nnoremap <buffer> ( :call md#move#toParentHeading()<CR>
nnoremap <buffer> ) :call md#move#toFirstChildHeading()<CR>

vnoremap <buffer> [h :<C-u>call md#move#toPreviousHeading()<CR>
vnoremap <buffer> ]h :<C-u>call md#move#toNextHeading()<CR>
vnoremap <buffer> [[ :<C-u>call md#move#toPreviousSibling()<CR>
vnoremap <buffer> ]] :<C-u>call md#move#toNextSibling()<CR>
vnoremap <buffer> ( :<C-u>call md#move#toParentHeading()<CR>
vnoremap <buffer> ) :<C-u>call md#move#toFirstChildHeading()<CR>
