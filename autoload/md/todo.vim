function! md#todo#init()
  if !exists("g:mdpp_todo_loaded")

    " apply default states
    if !exists("g:mdpp_todo_states")
      let g:mdpp_todo_states = [
            \"TODO",
            \"INPROGRESS",
            \"DONE"
            \]
    endif

    " apply default todo state coloring
    if !exists("g:mdpp_todo_colors")
      let g:mdpp_todo_colors = {
            \  "TODO": {
            \    "guifg": "#ff0000",
            \    "gui": "bold",
            \    "ctermfg": "red"
            \  },
            \  "DONE": {
            \    "guifg": "#00cf00",
            \    "gui": "bold",
            \    "ctermfg": "green"
            \  },
            \  "__default__": {
            \    "guifg": "#ffcf00",
            \    "gui": "bold",
            \    "ctermfg": "yellow"
            \  }
            \}
    endif

    " apply default aggregation method
    if !exists("g:mdpp_todo_aggregation_method")
      let g:mdpp_todo_aggregation_method = 'simple'
    endif

    " apply settings for 'rules' aggregation method
    if g:mdpp_todo_aggregation_method ==# 'rules'
      if exists("g:mdpp_todo_aggregation_rules")
        let s:aggregation_rules = g:mdpp_todo_aggregation_rules
        let s:aggregation_function = function('md#todo#applyAggregationRules')
      else
        echom "TODO aggregation method set to 'rules', but g:mdpp_todo_aggregation_rules was not defined. "
              \ . "Defaulting to 'simple' aggregation instead."
        call input("Hit <Enter> to continue...")
        let g:mdpp_todo_aggregation_method = 'simple'
      endif
    endif

    " apply settings for 'function' aggregation method
    if g:mdpp_todo_aggregation_method ==# 'function'
      if exists("g:mdpp_todo_aggregation_function")
        let s:aggregation_function = function(g:mdpp_todo_aggregation_function)
      else
        echom "TODO aggregation method set to 'function', but g:mdpp_todo_aggregation_function was not defined. "
              \ . "Defaulting to 'simple' aggregation instead."
        call input("Hit <Enter> to continue...")
        let g:mdpp_todo_aggregation_method = 'simple'
      endif
    endif

    " apply settings for 'simple' aggregation method
    if g:mdpp_todo_aggregation_method ==# 'simple'
      " assume the first state represents an unstarted thing, and if there are
      " more than 2 states, the second represents a thing that is started, but
      " hasn't reached any workflow specific checkpoints
      if !exists("g:mdpp_todo_in_progress_state")
        let numStates = len(g:mdpp_todo_states)
        if numStates <= 2
          let g:mdpp_todo_in_progress_state = g:mdpp_todo_states[0]
        else
          let g:mdpp_todo_in_progress_state = g:mdpp_todo_states[1]
        endif
      endif

      let s:aggregation_rules = [[g:mdpp_todo_states, g:mdpp_todo_in_progress_state]]

      let s:aggregation_function = function('md#todo#applyAggregationRules')
    endif

    " set primary states, aggregate states and all states
    let g:mdpp_todo_primary_states = g:mdpp_todo_states
    if exists("g:mdpp_todo_aggregate_states")
      let g:mdpp_todo_aggregate_states = g:mdpp_todo_aggregate_states
    else
      let g:mdpp_todo_aggregate_states = []
      if exists("s:aggregation_rules")
        for rule in s:aggregation_rules
          if index(g:mdpp_todo_primary_states, rule[1]) == -1 && index(g:mdpp_todo_aggregate_states, rule[1]) == -1
            call add(g:mdpp_todo_aggregate_states, rule[1])
          end
        endfor
      endif
    endif
    let g:mdpp_todo_all_states = extend([], g:mdpp_todo_primary_states)
    call extend(g:mdpp_todo_all_states, g:mdpp_todo_aggregate_states)

    let g:mdpp_todo_loaded = 1
  endif
endfunction

function! s:aggregationRuleMatches(conditionStates, childrenStates)
  for child in a:childrenStates
    if index(a:conditionStates, child) == -1
      return 0
    end
  endfor
  return 1
endfunction

function! md#todo#applyAggregationRules(childrenStates)
  if len(a:childrenStates) == 0
    return ""
  endif
  " check if all children are the same
  for state in g:mdpp_todo_all_states
    if s:aggregationRuleMatches([state], a:childrenStates)
      return state
    endif
  endfor
  " check rules
  for rule in s:aggregation_rules
    if s:aggregationRuleMatches(rule[0], a:childrenStates)
      return rule[1]
    endif
  endfor
  return ""
endfunction

function! md#todo#aggregateState(childrenStates)
  return s:aggregation_function(a:childrenStates)
endfunction

function! md#todo#getColors(state)
  if has_key(g:mdpp_todo_colors, a:state)
    return g:mdpp_todo_colors[a:state]
  else
    return g:mdpp_todo_colors["__default__"]
  endif
endfunction

function! s:highlight(state, obj)
  if index(s:colored_states, a:state) == -1
    let desc = ""
    for key in keys(a:obj)
      let desc = desc . " " . key . "=" . a:obj[key]
    endfor
    execute "highlight markdownState" . a:state . desc

    execute "syn keyword markdownState" . a:state . " " . a:state
          \." containedin=markdownH1,markdownH2,markdownH3,markdownH4,markdownH5,markdownH6 contained"

    call add(s:colored_states, a:state)
  endif
endfunction

function! md#todo#setupColors()
  let s:colored_states = []
  for state in g:mdpp_todo_states
    call s:highlight(state, md#todo#getColors(state))
  endfor
  " handle states generated by aggregation rules
  " NOTE: can't use g:mdpp_todo_all_states here, because this runs before it's
  "       created ... FIXME does it???
  if exists("g:mdpp_todo_aggregation_rules")
    for rule in g:mdpp_todo_aggregation_rules
      call s:highlight(rule[1], md#todo#getColors(rule[1]))
    endfor
  endif
  " handle explicitly colored states
  for state in keys(g:mdpp_todo_colors)
    if state !=# "__default__"
      call s:highlight(state, md#todo#getColors(state))
    endif
  endfor
endfunction

call md#todo#init()

function! md#todo#next(state)
  let ind = index(g:mdpp_todo_primary_states, a:state)
  let state = (ind + 1 == len(g:mdpp_todo_primary_states) ? -1 : ind + 1)
  return state == -1 ? "" : g:mdpp_todo_states[state]
endfunction

function! md#todo#prev(state)
  let ind = index(g:mdpp_todo_primary_states, a:state)
  let state = (ind == -1 ? len(g:mdpp_todo_primary_states) - 1 : ind - 1)
  return state == -1 ? "" : g:mdpp_todo_states[state]
endfunction

function! md#todo#getTodoState(lnum)
  if md#line#isHeading(a:lnum)
    return md#str#getTodoState(getline(a:lnum))
  else
    let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
              \ . " Can't get todo state for non heading line"
    throw message
  endif
endfunction

function! md#todo#setTodoState(lnum, state)
  if md#line#isHeading(a:lnum)
    let string = md#str#setTodoState(getline(a:lnum), a:state)
    call setline(a:lnum, string)
    call md#todo#updateParentState(a:lnum)
  else
    let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
              \ . "Can't modify todo state for non heading line"
    throw message
  endif
endfunction

function! md#todo#childStates(lnum)
  let pos = getpos('.')
  let states = []
  try
    call md#move#toLine(a:lnum)
    let target = md#line#headingLevel('.') + 1
    call md#move#toEndOfSection()
    while md#line#num('.') != a:lnum
      if md#line#isHeading('.') && md#line#headingLevel('.') == target
        let state = md#todo#getTodoState('.')
        if state !=# ""
          call add(states, state)
        endif
      endif
      normal! k
    endwhile
  finally
    call setpos('.', pos)
  endtry
  return states
endfunction

" update the todo state of the heading on line a:lnum based on the heading
" states of it's children
function! md#todo#updateState(lnum)
  if md#line#isHeading(a:lnum)
    let newState = md#todo#aggregateState(md#todo#childStates(a:lnum))
    call md#todo#setTodoState(a:lnum, newState)
  endif
endfunction

function! md#todo#updateParentState(lnum)
  if md#line#headingLevel(a:lnum) > 1
    let pos = getpos('.')
    try
      call md#move#toLine(a:lnum)
      call md#move#toParentHeading()
      let parentLine = md#line#num('.')
    finally
      call setpos('.', pos)
    endtry
    call md#todo#updateState(parentLine)
  endif
endfunction

function! md#todo#incTodoState(lnum)
  if md#line#isHeading(a:lnum)
    let state = md#todo#next(md#todo#getTodoState(a:lnum))
    return md#todo#setTodoState(a:lnum, state)
  else
    let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
              \ . "Can't modify todo state for non heading line"
    throw message
  endif
endfunction

function! md#todo#decTodoState(lnum)
  if md#line#isHeading(a:lnum)
    let state = md#todo#prev(md#todo#getTodoState(a:lnum))
    return md#todo#setTodoState(a:lnum, state)
  else
    let message = "Line " . md#line#num(a:lnum) . " is not a heading." 
              \ . "Can't modify todo state for non heading line"
    throw message
  endif
endfunction
