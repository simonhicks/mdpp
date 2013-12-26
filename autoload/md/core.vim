" code folding

function! s:listItemNesting(lnum)
  return len(matchstr(getline(a:lnum), "^[[:space:]]*")) / 2
endfunction

function! s:listFoldModifier(lnum)
  if md#line#isListItem(a:lnum)
    return s:listItemNesting(a:lnum) + 1
  else
    return s:listItemNesting(a:lnum)
  endif
endfunction

function! md#core#fold(lnum)
  if md#line#isBlank(a:lnum)
    return '-1'
  endif
  let l = md#line#sectionLevel(a:lnum) + s:listFoldModifier(a:lnum)
  if md#line#isHeading(a:lnum)
    return '>' . l
  elseif md#line#isListItem(a:lnum)
    return '>' . l
  else
    return '' . l
  endif
endfunction

" text objects

function! md#core#insideSection()
  call md#move#toParentHeading()
  let target = md#line#headingLevel('.')
  normal! j
  if md#line#isUnderline('.')
    normal! j
  endif
  normal! V
  call md#move#downUntilLevel(target)
  if md#line#isBlankBeforeHeading('.')
    normal! k
  endif
endfunction

function! md#core#aroundSection(op)
  if a:op
    normal! l
  endif
  if !((getpos("'<") == getpos("'>")) && (col('.') == 1) && md#line#isHeading('.'))
    call md#move#toParentHeading()
  endif
  let target = md#line#headingLevel('.')
  normal! V
  call md#move#downUntilLevel(target)
endfunction

function! md#core#insideTree()
  call md#move#toRootHeading()
  normal! j
  if md#line#isUnderline('.')
    normal! j
  endif
  normal! V
  call md#move#downUntilLevel(1)
  if md#line#isBlankBeforeHeading('.')
    normal! k
  endif
endfunction

function! md#core#aroundTree()
  call md#move#toRootHeading()
  normal! V
  call md#move#downUntilLevel(1)
endfunction

function! md#core#insideHeading()
  if !md#line#isHeading('.')
    call md#move#toParentHeading()
  endif
  if match(getline('.'), '^#') != -1
    execute "normal! f lvg_o"
  else
    normal! vg_o
  endif
endfunction

function! md#core#aroundHeading()
  if !md#line#isHeading('.')
    call md#move#toParentHeading()
  endif
  if match(getline('.'), '^#') != -1
    normal! vg_o
  else
    normal! Vjo
  endif
endfunction

" tree manipulation

function! md#core#incHeading()
  let pos = getpos('.')
  normal! l
  call md#move#toParentHeading()
  let underline = md#line#underlinedHeadingLevel('.')
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

function! md#core#decHeading()
  let pos = getpos('.')
  normal! l
  call md#move#toParentHeading()
  let underline = md#line#underlinedHeadingLevel('.')
  if underline == 1
    return -1
  elseif underline == 2
    normal! jviwr=k
  else
    normal! x
  endif
  call setpos('.', pos)
endfunction

function! md#core#raiseSectionBack()
  let stored = @a
  let level = md#line#sectionLevel('.')
  normal "adas
  call md#move#upToLevel(level - 1)
  normal! "aP
  call md#core#decHeading()
  let @a = stored
endfunction

function! md#core#raiseSectionForward()
  let stored = @a
  let level = md#line#sectionLevel('.')
  normal "adas
  normal! k
  call md#move#downToLevel(level - 1)
  normal! "aP
  call md#core#decHeading()
  let @a = stored
endfunction

