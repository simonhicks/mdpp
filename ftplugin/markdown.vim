" general string functions
function! s:IsBlank(str)
  return match(a:str, '^[[:space:]]*$') != -1
endfunc

function! s:Trim(str)
  return matchlist(a:str, '[[:space:]]*\(.\{-}\)[[:space:]]*$')[1]
endfunc

" heading functions
function! s:UnderlinedHeadingLevel(linenum)
  let nextLine = s:Trim(getline(a:linenum + 1))
  if match(nextLine, '^==*$') != -1
    return 1
  elseif match(nextLine, '^--*$') != -1
    return 2
  else
    return 0
  endif
endfunc

function! s:HashHeadingLevel(linenum)
  return len(matchstr(getline(a:linenum), "^#*"))
endfunc

function! s:HeadingLevel(linenum)
  let l1 = s:UnderlinedHeadingLevel(a:linenum)
  if l1 > 0
    return l1
  else
    return s:HashHeadingLevel(a:linenum)
  endif
endfunc

function! s:IsHeading(linenum)
  return s:HeadingLevel(a:linenum) > 0
endfunc

function! MdFoldFunction(lnum)
  let thisLine = a:lnum
  let nextLine = a:lnum + 1
  if s:IsHeading(thisLine)
    return '>' . s:HeadingLevel(thisLine)
  elseif s:IsBlank(getline(thisLine)) && s:IsHeading(nextLine)
    return '' . (s:HeadingLevel(nextLine) - 1)
  else
    return '='
  endif
endfunc

setlocal foldmethod=expr
setlocal foldexpr=MdFoldFunction(v:lnum)
