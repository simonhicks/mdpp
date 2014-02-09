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
