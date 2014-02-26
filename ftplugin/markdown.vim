" TODO
" - ensure no mappings are overwritten
" - syntax for md filetype
" - option to switch off interactive features (todo, tables, shell)

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
onoremap <buffer> im :call md#core#insideMetadata()<CR>
onoremap <buffer> am :call md#core#aroundMetadata()<CR>

vnoremap <buffer> is :<C-u>call md#core#insideSection()<CR>
vnoremap <buffer> as :<C-u>call md#core#aroundSection(0)<CR>
vnoremap <buffer> it :<C-u>call md#core#insideTree()<CR>
vnoremap <buffer> at :<C-u>call md#core#aroundTree()<CR>
vnoremap <buffer> ih :<C-u>call md#core#insideHeading()<CR>
vnoremap <buffer> ah :<C-u>call md#core#aroundHeading()<CR>
vnoremap <buffer> im :<C-u>call md#core#insideMetadata()<CR>
vnoremap <buffer> am :<C-u>call md#core#aroundMetadata()<CR>

" tree manipulation mappings
nnoremap <buffer> [h :call md#core#decHeading(1)<CR>
nnoremap <buffer> ]h :call md#core#incHeading(1)<CR>
nnoremap <buffer> [H :call md#core#decHeading(0)<CR>
nnoremap <buffer> ]H :call md#core#incHeading(0)<CR>
nnoremap <buffer> [m :call md#core#moveSectionBack()<CR>
nnoremap <buffer> ]m :call md#core#moveSectionForward()<CR>
nnoremap <buffer> [M :call md#core#raiseSectionBack()<CR>
nnoremap <buffer> ]M :call md#core#raiseSectionForward()<CR>
nnoremap <buffer> gR :call md#core#nestSection()<CR>A

" movement mappings
nnoremap <buffer> [s :call md#move#toPreviousHeading()<CR>
nnoremap <buffer> ]s :call md#move#toNextHeading()<CR>
nnoremap <buffer> [[ :call md#move#toPreviousSibling()<CR>
nnoremap <buffer> ]] :call md#move#toNextSibling()<CR>
nnoremap <buffer> (  :call md#move#toParentHeading()<CR>
nnoremap <buffer> )  :call md#move#toFirstChildHeading()<CR>

" FIXME make these motions better (store V state, no yucky echom, etc.)
vnoremap <buffer> [h :<C-u>call md#move#toPreviousHeading()<CR>
vnoremap <buffer> ]h :<C-u>call md#move#toNextHeading()<CR>
vnoremap <buffer> [[ :<C-u>call md#move#toPreviousSibling()<CR>
vnoremap <buffer> ]] :<C-u>call md#move#toNextSibling()<CR>
vnoremap <buffer> (  :<C-u>call md#move#toParentHeading()<CR>
vnoremap <buffer> )  :<C-u>call md#move#toFirstChildHeading()<CR>

if g:with_todo_features
  call md#todo#init()

  nnoremap <buffer> [d :call md#core#decTodo()<CR>
  nnoremap <buffer> ]d :call md#core#incTodo()<CR>
endif
