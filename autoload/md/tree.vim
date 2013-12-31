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

function! s:newUiBuffer(name)
  let bname = s:safeName(a:name)
  execute "badd " . bname
  return bufnr(bname)
endfunction

function! s:storeUi(ui)
  if !exists("g:mdpp_ui_store")
    let g:mdpp_ui_store = {}
  endif
  let g:mdpp_ui_store[a:ui['name']] = a:ui
endfunction

function! s:handle(name)
  execute g:mdpp_ui_store[a:name].handlers[line('.') - 1]
endfunction

function! md#tree#newUi(name)
  let ui = {}
  let ui['name'] = s:safeName(a:name)
  let ui['lines'] = []
  let ui['handlers'] = []
  let ui['buffer'] = s:newUiBuffer(a:name)
  let ui['onshow'] = "setlocal buftype=nofile\n"
        \          . "setlocal hidden\n"
        \          . "setlocal nomodifiable\n"
        \          . "setlocal readonly\n"
        \          . "setlocal cursorline\n"
        \          . "nnoremap <buffer> <CR> :call \<SID>handle('" . ui['name'] . "')<CR>\n"
  call s:storeUi(ui)
  return ui
endfunction

function! s:setContent(content)
  let stored = @a
  setlocal modifiable
  setlocal noreadonly
  let @a = a:content
  execute 'normal! ggVG"ap'
  let @a = stored
  setlocal readonly
  setlocal nomodifiable
endfunction

function! md#tree#showVert(ui)
  execute "silent vert leftabove sbuffer " . a:ui['buffer']
  if len(a:ui['onshow'])
    execute a:ui['onshow']
    let a:ui['onshow'] = ''
  endif
  call s:setContent(join(a:ui['lines'], "\n"))
endfunction


"" playground stuff for trees
" function! s:indent(num)
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

"" testing the window stuff
function! RunTest()
  let g:ui = md#tree#newUi("foo")
  call add(g:ui['lines'], "hello world!")
  call add(g:ui['lines'], "goodbye world!")
  call add(g:ui['handlers'], "echom 'hello world!'")
  call add(g:ui['handlers'], "echom 'goodbye world!'")
  call md#tree#showVert(g:ui)
endfunction
