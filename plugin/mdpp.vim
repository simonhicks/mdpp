if !exists("g:with_todo_features")
  let g:with_todo_features = 1
endif

if exists("g:mdpp_path") && len(g:mdpp_path)
  if !exists("g:mdpp_create_if_not_found")
    let g:mdpp_create_if_not_found = 1
  endif

  let g:mdpp_path = map(g:mdpp_path, 'fnamemodify(v:val, ":p")')

  if !exists("g:mdpp_default_create_dir")
    let g:mdpp_default_create_dir = g:mdpp_path[0]
  endif

  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete Notes call md#lookup#notesCommand(<q-bang>, '', <f-args>)
  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete HNotes call md#lookup#notesCommand(<q-bang>, 'split', <f-args>)
  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete VNotes call md#lookup#notesCommand(<q-bang>, 'vert', <f-args>)
  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete TNotes call md#lookup#notesCommand(<q-bang>, 'tab', <f-args>)

  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete Index call md#ui#indexCommand(<q-bang>, 'headings', <f-args>)
  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete Todos call md#ui#todoCommand(<q-bang>, <f-args>)
endif

function! s:highlightCodeSnippet(filetype,textSnipHl) abort
  let ft=toupper(a:filetype)
  let group='textGroup'.ft
  if exists('b:current_syntax')
    let s:current_syntax=b:current_syntax
    " Remove current syntax definition, as some syntax files (e.g. cpp.vim)
    " do nothing if b:current_syntax is defined.
    unlet b:current_syntax
  endif
  execute 'syntax include @'.group.' syntax/'.a:filetype.'.vim'
  try
    execute 'syntax include @'.group.' after/syntax/'.a:filetype.'.vim'
  catch
  endtry
  if exists('s:current_syntax')
    let b:current_syntax=s:current_syntax
  else
    unlet b:current_syntax
  endif
  let l:start = ' *[~`][~`][~`][~`]*.*\.' . a:filetype . '.*}'
  let l:end = ' *[~`][~`][~`][~`]*'
  execute 'syntax region textSnip'.ft.'
  \ matchgroup='.a:textSnipHl.'
  \ start="'.l:start.'" end="'.l:end.'"
  \ contains=@'.group
endfunction

if !exists("g:mdpp_inline_highlight_syntaxes")
  let g:mdpp_inline_highlight_syntaxes = ['java', 'javascript', 'c', 'cpp', 'ruby', 'python', 'coffee', 'haskell', 'clojure', 'sh', 'groovy', 'scala', 'yaml', 'vim']
endif

function! s:highlightCodeSnippets()
  for syntaxName in g:mdpp_inline_highlight_syntaxes
    call s:highlightCodeSnippet(syntaxName, 'SpecialComment')
  endfor
endfunction

autocmd! Syntax markdown call <SID>highlightCodeSnippets()
