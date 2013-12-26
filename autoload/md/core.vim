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
  " if cursor is on the first character of a heading line, and there's no
  " existing visual selection, then select that section... otherwise select
  " the section surrounding the cursor
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
  call md#move#ensureHeading()
  if match(getline('.'), '^#') != -1
    execute "normal! f lvg_o"
  else
    normal! vg_o
  endif
endfunction

function! md#core#aroundHeading()
  call md#move#ensureHeading()
  if match(getline('.'), '^#') != -1
    normal! vg_o
  else
    normal! Vjo
  endif
endfunction

function! md#core#insideMetadata()
  let start = getpos('.')
  call md#move#ensureHeading()
  if md#line#hasMetadata('.')
    normal! 0f{vi{
  else
    call setpos('.', start)
  endif
endfunction

function! md#core#aroundMetadata()
  let start = getpos('.')
  call md#move#ensureHeading()
  if md#line#hasMetadata('.')
    normal! 0f{va{
  else
    call setpos('.', start)
  endif
endfunction

" tree manipulation

function! md#core#incHeading()
  let pos = getpos('.')
  try
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
  finally
    call setpos('.', pos)
  endtry
endfunction

function! md#core#decHeading()
  let pos = getpos('.')
  try
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
  finally
    call setpos('.', pos)
  endtry
endfunction

" NOTE: this depends on the user's mappings for " & d being the defaults.
" Hopefully that's not going to be a problem
function! md#core#raiseSectionBack()
  let stored = @a
  try
    let level = md#line#sectionLevel('.')
    normal "adas
    call md#move#upToLevel(level - 1)
    normal! "aP
    call md#core#decHeading()
  finally
    let @a = stored
  endtry
endfunction

" NOTE: this depends on the user's mappings for " & d being the defaults.
" Hopefully that's not going to be a problem
function! md#core#raiseSectionForward()
  let stored = @a
  try
    let level = md#line#sectionLevel('.')
    normal "adas
    normal! k
    call md#move#downToLevel(level - 1)
    normal! "aP
    call md#core#decHeading()
  finally
    let @a = stored
  endtry
endfunction

" todo state cycling
if g:with_todo_features
  call md#todo#init()

  function! md#core#incTodo()
    let pos = getpos('.')
    try
      call md#move#ensureHeading()
      call md#line#incTodoState('.')
    finally
      call setpos('.', pos)
    endtry
  endfunction

  function! md#core#decTodo()
    let pos = getpos('.')
    try
      call md#move#ensureHeading()
      call md#line#decTodoState('.')
    finally
      call setpos('.', pos)
    endtry
  endfunction
endif

" checklist toggling
if g:with_checklist_features
  call md#checklist#init()

  function! md#core#toggleChecklist()
    let pos = getpos('.')
    let mark_a = getpos("'<")
    let mark_b = getpos("'>")
    try
      if md#line#isChecklistItem('.')
        normal! vip
        let firstLine = line("'<")
        let lastLine = line("'>")
        execute "normal! \<esc>"
        call setpos('.', pos)
        call md#line#toggleChecklistItem('.')
        call md#checklist#refresh(firstLine, lastLine)
      endif
    finally
      call setpos('.', pos)
      call setpos("'<", mark_a)
      call setpos("'>", mark_b)
    endtry
  endfunction
endif
