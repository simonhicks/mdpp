" general string functions
function! s:IsBlank(str)
  return match(a:str, '^[[:space:]]*$') != -1
endfunc

function! s:Trim(str)
  return matchlist(a:str, '[[:space:]]*\(.\{-}\)[[:space:]]*$')[1]
endfunc

" heading functions
function! s:IsHeading(str)
  return match(a:str, '^#') != -1
endfunc

function! s:HeadingLevel(str)
  return len(matchstr(a:str, "^#*"))
endfunc

" function! s:HeadingText(str)
"   return s:Trim(matchlist(a:str, '^#*\(.*\)')[1])
" endfunc

function! MdFoldFunction(lnum)
  let thisLine = getline(a:lnum)
  let nextLine = getline(a:lnum + 1)
  if s:IsHeading(thisLine)
    return '>' . s:HeadingLevel(thisLine)
  elseif s:IsBlank(thisLine) && s:IsHeading(nextLine)
    return '' . (s:HeadingLevel(nextLine) - 1)
  else
    return '='
  endif
endfunc

setlocal foldmethod=expr
setlocal foldexpr=MdFoldFunction(v:lnum)
