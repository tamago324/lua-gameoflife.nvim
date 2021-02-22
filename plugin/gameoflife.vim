scriptencoding utf-8

if exists('g:loaded_gameoflife')
  finish
endif
let g:loaded_gameoflife = 1

command! -bang GameOfLifeStart exec "lua require'gameoflife.commands'.start(" .. <bang>0 .. ")"
command! -nargs=1 GameOfLifeLoadPattern lua require'gameoflife.commands'.load_pattern(<q-args>)
command! -nargs=1 GameOfLifeTimerSetStepPerSec lua require'gameoflife.commands'.set_step_per_sec(<q-args>)


function! s:mappings() abort
  nnoremap <buffer> <Plug>(gameoflife-next)              <Cmd>lua require'gameoflife.commands'.next()<CR>
  nnoremap <buffer> <Plug>(gameoflife-prev)              <Cmd>lua require'gameoflife.commands'.prev()<CR>
  nnoremap <buffer> <Plug>(gameoflife-spped-up)          <Cmd>lua require'gameoflife.commands'.speed_up()<CR>
  nnoremap <buffer> <Plug>(gameoflife-spped-down)        <Cmd>lua require'gameoflife.commands'.speed_down()<CR>
  nnoremap <buffer> <Plug>(gameoflife-timer-start)       <Cmd>lua require'gameoflife.commands'.timer_start()<CR>
  nnoremap <buffer> <Plug>(gameoflife-timer-pause)       <Cmd>lua require'gameoflife.commands'.timer_pause()<CR>
  nnoremap <buffer> <Plug>(gameoflife-timer-toggle)      <Cmd>lua require'gameoflife.commands'.timer_toggle()<CR>
  nnoremap <buffer> <Plug>(gameoflife-load-random-board) <Cmd>lua require'gameoflife.commands'.load_random_board()<CR>
  nnoremap <buffer> <Plug>(gameoflife-load-pattern)      :<C-u>GameOfLifeLoadPattern 

  map <buffer> <Right>  <Plug>(gameoflife-next)
  map <buffer> <Left> <Plug>(gameoflife-prev)
  map <buffer> <Up>    <Plug>(gameoflife-spped-up)
  map <buffer> <Down>  <Plug>(gameoflife-spped-down)
  map <buffer> S       <Plug>(gameoflife-timer-start)
  map <buffer> P       <Plug>(gameoflife-timer-pause)
  map <buffer> T       <Plug>(gameoflife-timer-toggle)
  map <buffer> R       <Plug>(gameoflife-load-random-board)
  map <buffer> L       <Plug>(gameoflife-load-pattern)
endfunction


augroup GameOfLife
  autocmd!
  autocmd CmdlineEnter,CmdwinEnter * lua require'gameoflife.timer'._onCmdlineEnter()
  autocmd CmdlineLeave,CmdwinLeave * lua require'gameoflife.timer'._onCmdlineLeave()
  autocmd Filetype gameoflife call s:mappings()
augroup END


highlight default GameOfLifeCell guifg=Black guibg=Black
