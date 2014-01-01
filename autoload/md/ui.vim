function! s:getNumber(name)
  let patt =  '_\(\d\d*\)$'
  if match(a:name, patt) != -1
    return matchlist(a:name, patt)[1]
  else
    return 0
  endif
endfunction

function! s:safeName(name)
  let safe = a:name
  while bufnr(safe) != -1
    let fnum = s:getNumber(safe)
    if fnum
      let safe = substitute(safe, "_" . fnum . "$", "_" . (fnum + 1), "")
    else
      let safe = safe . "_1"
    endif
  endwhile
  return safe
endfunction

function! s:newBuffer(name)
  let bname = s:safeName(a:name)
  execute "badd " . bname
  return bufnr(bname)
endfunction

function! s:store(ui)
  if !exists("g:mdpp_ui_store")
    let g:mdpp_ui_store = {}
  endif
  let g:mdpp_ui_store[a:ui['name']] = a:ui
endfunction

function! s:handle(name)
  execute g:mdpp_ui_store[a:name].handlers[line('.') - 1]
endfunction

function! md#ui#new(name)
  let ui = {}
  let ui['name'] = s:safeName(a:name)
  let ui['lines'] = []
  let ui['handlers'] = []
  let ui['buffer'] = s:newBuffer(a:name)
  let ui['onshow'] = "setlocal buftype=nofile\n"
        \          . "setlocal hidden\n"
        \          . "setlocal nomodifiable\n"
        \          . "setlocal readonly\n"
        \          . "setlocal cursorline\n"
        \          . "nnoremap <buffer> <CR> :call \<SID>handle('" . ui['name'] . "')<CR>\n"
  call s:store(ui)
  return ui
endfunction

function! s:setBufferContent(content)
  let stored = @a
  setlocal modifiable
  setlocal noreadonly
  let @a = a:content
  execute 'normal! ggVG"ap'
  let @a = stored
  setlocal readonly
  setlocal nomodifiable
endfunction

function! md#ui#showVert(ui)
  execute "silent vert leftabove sbuffer " . a:ui['buffer']
  if len(a:ui['onshow'])
    execute a:ui['onshow']
    let a:ui['onshow'] = ''
  endif
  call s:setBufferContent(join(a:ui['lines'], "\n"))
endfunction

function! s:addLine(ui, line)
  call add(a:ui.lines, a:line)
endfunction

function! s:addHandler(ui, handler)
  call add(a:ui.handlers, a:handler)
endfunction

" spec should be an object containing exprs using 'a:branch' to generate the
" ui text and behaviour
function! s:addBranch(ui, spec, branch)
  execute "let line = " . a:spec.line
  execute "let handler = " . a:spec.handler
  call s:addLine(a:ui, line)
  call s:addHandler(a:ui, handler)
  " FIXME add children
  for child in a:branch['children']
    call s:addBranch(a:ui, a:spec, child)
  endfor
endfunction

function! md#ui#newFromTree(name, spec, tree)
  let ui = md#ui#new(a:name)
  for branch in a:tree
    call s:addBranch(ui, a:spec, branch)
  endfor
  return ui
endfunction

" """ Sample using ui-spec
" " TODO handle indentation here
" let g:ui = md#ui#newFromTree("blah", 
"       \ {'line': "a:branch['state'] . ': ' . a:branch['content']",
"       \  'handler': '"echom \"" . a:branch["content"] . "\""'},
"       \ [
"       \   {'content' : 'foo', 'state' : 'TODO', 'children' : [{'content': 'blah blah blah', 'state': 'TODO', 'children': []}]},
"       \   {'content' : 'bar', 'state' : 'DONE', 'children' : []}
"       \ ])

" """ Random playgroud code
" function! Indent(num)
"   let str = ''
"   let counter = a:num
"   while counter
"     let str = str . ' '
"     let counter = counter - 1
"   endwhile
"   return str
" endfunction

" function! s:string(indent, tree)
"   let output = ''
"   for node in a:tree
"     let output = output . s:indent(a:indent) . node['content'] . "\n"
"     if has_key(node, 'children') && len(node['children'])
"       let output = output . s:string(a:indent + 2, node['children'])
"     endif
"   endfor
"   return output
" endfunction

" let g:test_tree = [{'content': 'this is an item', 'children': [{'content': 'this is a child'}, {'content': 'another child', 'children': [{'content' : 'with its own child'}]}]}, {'content': 'this is the second item'}]

" " testing the window stuff
" function! RunTest()
"   let g:ui = md#ui#new("foo")
"   call add(g:ui['lines'], "hello world!")
"   call add(g:ui['lines'], "goodbye world!")
"   call add(g:ui['handlers'], "echom 'hello world!'")
"   call add(g:ui['handlers'], "echom 'goodbye world!'")
"   call md#ui#showVert(g:ui)
" endfunction
