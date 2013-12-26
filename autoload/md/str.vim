function! md#str#isBlank(str)
  return match(a:str, '^[[:space:]]*$') != -1
endfunction

function! md#str#trim(str)
  return matchlist(a:str, '[[:space:]]*\(.\{-}\)[[:space:]]*$')[1]
endfunction

function! md#str#headingContent(heading)
  return substitute(a:heading, "^#* *", "", "")
endfunction

function! md#str#headingPrefix(heading)
  return matchstr(a:heading, "^#* *")
endfunction

if g:with_todo_features
  call md#todo#init()

  function! md#str#getTodoState(str)
    let str = md#str#headingContent(a:str)
    let word = matchstr(str, "[^[:space:]]*")
    return index(g:mdpp_todo_states, word) != -1 ? word : ""
  endfunction

  function! md#str#setTodoState(str, state)
    let pattern = "^" . md#str#getTodoState(a:str) . " *"
    let replacement = md#str#isBlank(a:state) ? a:state : a:state . " "
    let content = md#str#headingContent(a:str)
    let content = substitute(content, pattern, replacement, "")
    return md#str#headingPrefix(a:str) . content
  endfunction
end

if g:with_checklist_features
  call md#checklist#init()

  function! md#str#getChecklistState(str)
    return matchlist(a:str, '^ *\[\(.\)\]')[1]
  endfunction

  function! md#str#toggleChecklist(str)
    let state = md#str#getChecklistState(a:str)
    return substitute(a:str, '\['.state.'\]', '['.md#checklist#toggle(state).']', '')
  endfunction
endif
