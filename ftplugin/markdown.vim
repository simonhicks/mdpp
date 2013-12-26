" general util functions
function! s:up()
  execute "normal! k"
endfunction

function! s:down()
  execute "normal! j"
endfunction

function! s:isBlank(str)
  return match(a:str, '^[[:space:]]*$') != -1
endfunction

function! s:trim(str)
  return matchlist(a:str, '[[:space:]]*\(.\{-}\)[[:space:]]*$')[1]
endfunction

"""""""""""""""""""""""""""""""""""""""""
" convert lnum to a number representation
"""""""""""""""""""""""""""""""""""""""""
function! s:line(lnum)
  if type(a:lnum) ==# 0
    return a:lnum
  else
    return line(a:lnum)
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" returns true, if lnum is a non heading line, or a heading of level `minimum`
" or greater
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:atLeastLevel(minimum, lnum)
  let level = s:headingLevel(a:lnum)
  return level ==# 0 || level >= a:minimum
endfunction

""""""""""""""""""""""""""""""""""""""""
" returns true if lnum is a heading line
""""""""""""""""""""""""""""""""""""""""
function! s:isHeading(lnum)
  let lnum = s:line(a:lnum)
  return s:headingLevel(lnum) > 0
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" returns true if lnum is a blank line immediately before a heading line
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:isBlankBeforeHeading(lnum)
  let lnum = s:line(a:lnum)
  return s:isBlank(getline(lnum)) && s:isHeading(lnum + 1)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""
" returns true if lnum is a heading underline
""""""""""""""""""""""""""""""""""""""""""""""
function! s:isUnderline(lnum)
  let lnum = s:line(a:lnum)
  return s:isHeading(lnum - 1) && match(getline(lnum), '^[=-][=-]*$') != -1
endfunction

function! s:underlinedHeadingLevel(lnum)
  let nextLine = s:trim(getline(s:line(a:lnum) + 1))
  if match(nextLine, '^==*$') != -1
    return 1
  elseif match(nextLine, '^--*$') != -1
    return 2
  else
    return 0
  endif
endfunction

function! s:hashHeadingLevel(lnum)
  return len(matchstr(getline(a:lnum), "^#*"))
endfunction

function! s:headingLevel(lnum)
  let l1 = s:underlinedHeadingLevel(a:lnum)
  if l1 > 0
    return l1
  else
    return s:hashHeadingLevel(a:lnum)
  endif
endfunction

function! s:upUntilLevel(target)
  let curr = s:line('.')
  while curr > 1 && s:atLeastLevel(a:target + 1, curr - 1)
    call s:up()
    let curr = s:line('.')
  endwhile
endfunction

function! s:downUntilLevel(target)
  let curr = s:line('.')
  let last = s:line('$')
  while !(curr ==# last) && s:atLeastLevel(a:target + 1, curr + 1)
    call s:down()
    let curr = s:line('.')
  endwhile
endfunction

function! s:upToLevel(target)
  let start = getpos('.')
  call s:upUntilLevel(a:target)
  call s:up()
  if s:isHeading('.')
    execute "normal! 0"
    return s:line('.')
  else
    call setpos('.', start)
    return -1
  endif
endfunction

function! s:downToLevel(target)
  let start = getpos('.')
  call s:downUntilLevel(a:target)
  call s:down()
  if s:isHeading('.')
    execute "normal! 0"
    return s:line('.')
  else
    call setpos('.', start)
    return -1
  endif
endfunction

function! s:gotoNextHeading()
  return s:downToLevel(10000)
endfunction

function! s:gotoPreviousHeading()
  return s:upToLevel(10000)
endfunction

function! s:gotoPreviousSibling()
  return s:upToLevel(s:sectionLevel('.'))
endfunction

function! s:gotoNextSibling()
  return s:downToLevel(s:sectionLevel('.'))
endfunction

function! s:gotoParentHeading()
  if !s:sectionLevel('.')
    return
  elseif s:isHeading('.') && col('.') != 1
    execute "normal! 0"
    return s:line('.')
  elseif s:isHeading('.')
    return s:upToLevel(s:headingLevel('.') - 1)
  else
    return s:gotoPreviousHeading()
  endif
endfunction

function! s:gotoRootHeading()
  if !s:sectionLevel('.')
    return
  else
    return s:upToLevel(1)
  endif
endfunction

function! s:gotoFirstChildHeading()
  return s:downToLevel(s:sectionLevel('.') + 1)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find the previous heading line. Returns -1 if there
" is no heading line before lnum.
"
"   @arg   lnum   The line to use as the starting
"                 point
"
"   @return   The line number of the line that was
"             found
""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:previousHeadingLine(lnum)
  let answer = -1
  " let storedlnum = s:line('.')
  let storedpos = getpos('.')
  execute a:lnum
  call s:gotoPreviousHeading()
  " let curr = s:line('.')
  " if curr < storedlnum
  "   let answer = curr
  " endif
  let answer = s:line('.')
  call setpos('.', storedpos)
  return answer
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""
" What's the heading level for the section
" containing the given line
"
"   @arg   lnum   The line to check
"
"   @return   The heading level of the section
"             containing lnum
""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:sectionLevel(lnum)
  if s:isHeading(a:lnum)
    return s:headingLevel(a:lnum)
  else
    return s:headingLevel(s:previousHeadingLine(a:lnum))
  endif
endfunction

" code folding

function! s:isListItem(lnum)
  return match(getline(a:lnum), "^[[:space:]]*- ") != -1
endfunction

function! s:listItemNesting(lnum)
  return len(matchstr(getline(a:lnum), "^[[:space:]]*")) / 2
endfunction

function! s:listFoldModifier(lnum)
  if s:isListItem(a:lnum)
    return s:listItemNesting(a:lnum) + 1
  else
    return s:listItemNesting(a:lnum)
  endif
endfunction

function! MarkdownFoldFunction(lnum)
  if s:isBlank(getline(a:lnum))
    return '-1'
  endif
  let l = s:sectionLevel(a:lnum) + s:listFoldModifier(a:lnum)
  if s:isHeading(a:lnum)
    return '>' . l
  elseif s:isListItem(a:lnum)
    return '>' . l
  else
    return '' . l
  endif
endfunction

setlocal foldmethod=expr
setlocal foldexpr=MarkdownFoldFunction(v:lnum)


" operator pending functions

function! s:insideSection()
  call s:gotoParentHeading()
  let target = s:headingLevel('.')
  call s:down()
  if s:isUnderline('.')
    call s:down()
  endif
  execute "normal! V"
  call s:downUntilLevel(target)
  if s:isBlankBeforeHeading('.')
    call s:up()
  endif
endfunction

function! s:aroundSection(op)
  if a:op
    execute "normal! l"
  endif
  if !((getpos("'<") == getpos("'>")) && (col('.') == 1) && s:isHeading('.'))
    call s:gotoParentHeading()
  endif
  let target = s:headingLevel('.')
  execute "normal! V"
  call s:downUntilLevel(target)
endfunction

function! s:insideTree()
  call s:gotoRootHeading()
  call s:down()
  if s:isUnderline('.')
    call s:down()
  endif
  execute "normal! V"
  call s:downUntilLevel(1)
  if s:isBlankBeforeHeading('.')
    call s:up()
  endif
endfunction

function! s:aroundTree()
  call s:gotoRootHeading()
  execute "normal! V"
  call s:downUntilLevel(1)
endfunction

function! s:insideHeading()
  if !s:isHeading('.')
    call s:gotoParentHeading()
  endif
  if match(getline('.'), '^#') != -1
    execute "normal! f lvg_o"
  else
    execute "normal! vg_o"
  endif
endfunction

function! s:aroundHeading()
  if !s:isHeading('.')
    call s:gotoParentHeading()
  endif
  if match(getline('.'), '^#') != -1
    execute "normal! vg_o"
  else
    execute "normal! Vjo"
  endif
endfunction

onoremap <buffer> is :call <SID>insideSection()<CR>
vnoremap <buffer> is :<C-u>call <SID>insideSection()<CR>
onoremap <buffer> as :call <SID>aroundSection(1)<CR>
vnoremap <buffer> as :<C-u>call <SID>aroundSection(0)<CR>
onoremap <buffer> it :call <SID>insideTree()<CR>
vnoremap <buffer> it :<C-u>call <SID>insideTree()<CR>
onoremap <buffer> at :call <SID>aroundTree()<CR>
vnoremap <buffer> at :<C-u>call <SID>aroundTree()<CR>
onoremap <buffer> ih :call <SID>insideHeading()<CR>
vnoremap <buffer> ih :<C-u>call <SID>insideHeading()<CR>
onoremap <buffer> ah :call <SID>aroundHeading()<CR>
vnoremap <buffer> ah :<C-u>call <SID>aroundHeading()<CR>

function! s:incHeading()
  let pos = getpos('.')
  normal! l
  call s:gotoParentHeading()
  let underline = s:underlinedHeadingLevel('.')
  if underline == 1
    normal! jviwr-k
  elseif underline == 2
    execute "normal! I### "
    normal! jddk
  else
    normal! I#
  endif
  call setpos('.', pos)
endfunction

function! s:decHeading()
  let pos = getpos('.')
  normal! l
  call s:gotoParentHeading()
  let underline = s:underlinedHeadingLevel('.')
  if underline == 1
    return -1
  elseif underline == 2
    normal! jviwr=k
  else
    normal! x
  endif
  call setpos('.', pos)
endfunction

nnoremap <buffer> [r :call <SID>decHeading()<CR>
nnoremap <buffer> ]r :call <SID>incHeading()<CR>

function! s:raiseSectionBack()
  let stored = @a
  let level = s:sectionLevel('.')
  normal "adas
  call s:upToLevel(level - 1)
  normal! "aP
  call s:decHeading()
  let @a = stored
endfunction

function! s:raiseSectionForward()
  let stored = @a
  let level = s:sectionLevel('.')
  normal "adas
  call s:downToLevel(level - 1)
  normal! "aP
  call s:decHeading()
  let @a = stored
endfunction

nnoremap <buffer> [m :call <SID>raiseSectionBack()<CR>
nnoremap <buffer> ]m :call <SID>raiseSectionForward()<CR>

" mappings TODO make these motions better (store V state, no yucky echom, etc.)

nnoremap <buffer> [h :call <SID>gotoPreviousHeading()<CR>
nnoremap <buffer> ]h :call <SID>gotoNextHeading()<CR>
nnoremap <buffer> [[ :call <SID>gotoPreviousSibling()<CR>
nnoremap <buffer> ]] :call <SID>gotoNextSibling()<CR>
nnoremap <buffer> ( :call <SID>gotoParentHeading()<CR>
nnoremap <buffer> ) :call <SID>gotoFirstChildHeading()<CR>

vnoremap <buffer> [h :<C-u>call <SID>gotoPreviousHeading()<CR>
vnoremap <buffer> ]h :<C-u>call <SID>gotoNextHeading()<CR>
vnoremap <buffer> [[ :<C-u>call <SID>gotoPreviousSibling()<CR>
vnoremap <buffer> ]] :<C-u>call <SID>gotoNextSibling()<CR>
vnoremap <buffer> ( :<C-u>call <SID>gotoParentHeading()<CR>
vnoremap <buffer> ) :<C-u>call <SID>gotoFirstChildHeading()<CR>
