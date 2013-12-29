if !exists("g:with_todo_features")
  let g:with_todo_features = 1
endif

if exists("g:mdpp_path") && len(g:mdpp_path)
  if !exists("g:mdpp_create_if_not_found")
    let g:mdpp_create_if_not_found = 1
  endif

  if !exists("g:mdpp_default_create_dir")
    let g:mdpp_default_create_dir = g:mdpp_path[0]
  endif

  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete Motes call md#lookup#notesCommand(<q-bang>, '', <f-args>)
  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete HMotes call md#lookup#notesCommand(<q-bang>, 'split', <f-args>)
  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete VMotes call md#lookup#notesCommand(<q-bang>, 'vert', <f-args>)
  command! -nargs=* -bang -complete=customlist,md#lookup#autocomplete TMotes call md#lookup#notesCommand(<q-bang>, 'tab', <f-args>)
endif
