" general util functions
function! s:isBlank(str)
  return match(a:str, '^[[:space:]]*$') != -1
endfunction

function! s:trim(str)
  return matchlist(a:str, '[[:space:]]*\(.\{-}\)[[:space:]]*$')[1]
endfunction

function! s:line(lnum)
  if type(a:lnum) ==# 0
    return a:lnum
  else
    return line(a:lnum)
  endif
endfunction

" heading functions

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""
" The heading level of the specified line
"
"   @arg  lnum  The Line to check
"
"   @return   The heading level of lnum
""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:headingLevel(lnum)
  let l1 = s:underlinedHeadingLevel(a:lnum)
  if l1 > 0
    return l1
  else
    return s:hashHeadingLevel(a:lnum)
  endif
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Is the specified line number a heading.
"
"   @arg  lnum  The line to check
"
"   @return   1 iff lnum is a heading else 0
""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:isHeading(lnum)
  return s:headingLevel(a:lnum) > 0
endfunction

function! s:gotoHeading(dir)
  let result = -1
  try
    let pattern = @/
    execute a:dir . "^\\(#\\|.*\\n[-=]\\{2,\\}\\)"
    let result = s:line('.')
  catch
    " nop
  finally
    let @/ = pattern
  endtry
  return result
endfunction

function! s:gotoNextHeading()
  return s:gotoHeading("/")
endfunction

function! s:gotoPreviousHeading()
  return s:gotoHeading("?")
endfunction

function! s:goBackToTargetLevel(target)
  if s:sectionLevel('.')
    let start = s:line('.')
    let storedpos = getpos('.')
    while (s:gotoPreviousHeading() < start) && (s:headingLevel('.') >= a:target)
      if s:headingLevel('.') ==# a:target
        return s:line('.')
      endif
    endwhile
    call setpos('.', storedpos)
  endif
  return -1
endfunction

function! s:gotoPreviousSibling()
  return s:goBackToTargetLevel(s:sectionLevel('.'))
endfunction

function! s:goForwardToTargetLevel(target)
  if s:sectionLevel('.')
    let start = s:line('.')
    let storedpos = getpos('.')
    while (s:gotoNextHeading() > start) && (s:headingLevel('.') >= a:target)
      if s:headingLevel('.') ==# a:target
        return s:line('.')
      endif
    endwhile
    call setpos('.', storedpos)
  endif
  return -1
endfunction

function! s:gotoNextSibling()
  return s:goForwardToTargetLevel(s:sectionLevel('.'))
endfunction

function! s:gotoParentHeading()
  if !s:sectionLevel('.')
    return
  elseif s:isHeading('.')
    return s:goBackToTargetLevel(s:headingLevel('.') - 1)
  else
    return s:gotoPreviousHeading()
  endif
endfunction

function! s:gotoFirstChildHeading()
  return s:goForwardToTargetLevel(s:sectionLevel('.') + 1)
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
  let storedlnum = s:line('.')
  let storedpos = getpos('.')
  execute a:lnum
  call s:gotoPreviousHeading()
  let curr = s:line('.')
  if curr < storedlnum
    let answer = curr
  endif
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

" code folding

setlocal foldmethod=expr
setlocal foldexpr=MarkdownFoldFunction(v:lnum)


" mappings TODO make these motions better (store V state, no yucky echom, etc.)

nnoremap <buffer> [h :call <SID>gotoPreviousHeading()<CR>
nnoremap <buffer> ]h :call <SID>gotoNextHeading()<CR>
nnoremap <buffer> [[ :call <SID>gotoPreviousSibling()<CR>
nnoremap <buffer> ]] :call <SID>gotoNextSibling()<CR>
nnoremap <buffer> ( :call <SID>gotoParentHeading()<CR>
nnoremap <buffer> ) :call <SID>gotoFirstChildHeading()<CR>

vnoremap <buffer> [h :call <SID>gotoPreviousHeading()<CR>
vnoremap <buffer> ]h :call <SID>gotoNextHeading()<CR>
vnoremap <buffer> [[ :call <SID>gotoPreviousSibling()<CR>
vnoremap <buffer> ]] :call <SID>gotoNextSibling()<CR>
vnoremap <buffer> ( :call <SID>gotoParentHeading()<CR>
vnoremap <buffer> ) :call <SID>gotoFirstChildHeading()<CR>

" FIXME remove debug mapping
nnoremap <buffer> g<CR> :echom <SID>isBlank(getline('.'))<CR>
