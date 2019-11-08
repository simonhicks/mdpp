function! s:repl_type(lnum)
  let line = getline(a:lnum)
  if match(line, "^```.*") != -1
    return 'markdown'
  end
  for id in synstack(a:lnum, 1)
    let name = synIDattr(id, 'name')
    if match(name, '^textSnip') != -1
      return tolower(substitute(name, '^textSnip', '', ''))
    endif
  endfor
  return &filetype
endfunction

function! s:repl_name(repl_type)
  return 'mdpp_' . bufnr('.') . '_' . a:repl_type
endfunction

function! s:dynamicReplSend(repl_type, lines)
  let repl = s:repl_name(a:repl_type)
  if !repl#is_running(repl) && has_key(g:mdpp_repl_configs, a:repl_type)
    call repl#start(repl, g:mdpp_repl_configs[a:repl_type])
    sleep 1
  endif
  if repl#is_running(repl)
    call repl#send(repl, a:lines)
  endif
endfunction

function! s:range_repl_type(start, end)
  let lnum = a:start
  while lnum <= a:end
    let l:repl_type = s:repl_type(lnum)
    if l:repl_type != 'markdown'
      return l:repl_type
    end
    let lnum = lnum + 1
  endwhile
  return 'markdown'
endfunction

function! md#repl#dynamicReplOperator(type)
  let sel_save = &selection
  let &selection = "inclusive"
  let reg_save = @@
  let lnums = []
  try
    if a:type ==# 'v' || a:type ==# 'V' || a:type ==# ''
	    silent exe "normal! gvy"
      let lnums = [line("'<"), line("'>")]
    elseif a:type ==# 'line'
	    silent exe "normal! '[V']y"
      let lnums = [line("'["), line("']")]
    elseif type(a:type) ==# v:t_number
      silent exe "normal! ".a:type."yy"
      let lnums = [line('.'), line('.') + a:type - 1]
    else
	    silent exe "normal! `[v`]y"
      let lnums = [line("'["), line("']")]
    endif
    let repl_type = s:range_repl_type(lnums[0], lnums[1])
    let raw_lines = split(@@, "\n")
    let lines = []
    for line in raw_lines
      if match(line, "^```.*") == -1
        call add(lines, line)
      endif
    endfor
    call s:dynamicReplSend(repl_type, lines)
  finally
	  let &selection = sel_save
	  let @@ = reg_save
  endtry
endfunction
