function! md#checklist#init()
  " nop so far
endfunction

function! md#checklist#toggle(box)
  return a:box ==# 'X' ? ' ' : 'X'
endfunction

function! s:parse(line)
  let parts = matchlist(a:line, '^\( *\)\[\(.\)\] \(.*\)')
  let content = md#str#trim(parts[3])
  return {'nesting': len(parts[1]),
        \ 'content': content,
        \ 'done': (parts[2] ==# 'X'),
        \ 'started': (parts[2] !=# ' '),
        \ 'children': []}
endfunction

function! s:addItem(items, newItem)
  if len(a:items) >= 1
    let lastItem = a:items[-1]
    if a:newItem['nesting'] > lastItem['nesting']
      call s:addItem(lastItem['children'], a:newItem)
    elseif a:newItem['nesting'] == lastItem['nesting']
      call add(a:items, a:newItem)
    endif
  else
    call add(a:items, a:newItem)
  endif
endfunction

function! s:getLines(start, finish)
  let started = @a
  let mark_a = getpos("'<")
  let mark_b = getpos("'>")
  let answer = ""
  try
    execute a:start . "," . a:finish . "yank a"
    let answer = @a
  finally
    let @a = started
    call setpos("'<", mark_a)
    call setpos("'>", mark_b)
  endtry
  return split(answer, "\n")
endfunction

function! s:getItems(lines)
  let items = []
  for line in a:lines
    call s:addItem(items, s:parse(line))
  endfor
  return items
endfunction

function! s:hasChildren(item)
  return len(a:item['children']) > 0
endfunction

function! s:updateItem(item)
  if s:hasChildren(a:item)
    let done = 1
    let started = 0
    for child in a:item['children']
      call s:updateItem(child)
      let done = done && child['done']
      let started = started || child['started']
    endfor
    let a:item['done'] = done
    let a:item['started'] = started
  endif
endfunction

function! s:printItem(item)
  let str = ""
  let cnt = a:item['nesting']
  while cnt != 0
    let str = str . " "
    let cnt = cnt - 1
  endwhile
  let str = str . "[" .(a:item['done'] ? 'X' : (a:item['started'] ? '/' : ' ')). "]"
  let str = str . " " . a:item['content']
  if s:hasChildren(a:item)
    let str = str . "\n" . s:printList(a:item['children'])
  endif
  return str
endfunction

function! s:printList(items)
  let lines = []
  for item in a:items
    call add(lines, s:printItem(item))
  endfor
  return join(lines, "\n")
endfunction

function! md#checklist#refresh(start, end)
  let start = getpos('.')
  let lines = s:getLines(a:start, a:end)
  let items = s:getItems(lines)
  for item in items
    call s:updateItem(item)
  endfor
  let text = s:printList(items)
  execute md#line#num(a:start) . "," . md#line#num(a:end) . "d"
  call append(md#line#num(a:start) - 1, split(text, "\n"))
  call setpos('.', start)
endfunction
