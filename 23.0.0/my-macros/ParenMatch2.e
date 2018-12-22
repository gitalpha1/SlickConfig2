
#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)

#import "./wstack.e"

_str def_pmatch_chars;

static struct cpos {
   int line;
   int col;
   _str buf_name;
};





stack_s cpos_stack;
stack_s cpos_no_pop_stack;

static void pop_cpos()
{
   cpos cp;
   if (pop_stack(cpos_stack, cp))
   {
      if (cp.buf_name != p_buf_name) {
         edit(maybe_quote_filename(cp.buf_name));
      }
      p_line = cp.line;
      p_col = cp.col;
   }
   else
      message('Stack empty');
}


static push_cpos()
{
   cpos cp;
   cp.line = p_line;
   cp.col = p_col;
   cp.buf_name = p_buf_name;
   push_stack(cpos_stack, cp);
   push_stack(cpos_no_pop_stack, cp);
}

static init_cpos_stack()
{
   cpos cp;
   cp.line = cp.col = 0;
   cp.buf_name = '';
   init_stack(cpos_stack, 32, true, cp);
   init_stack(cpos_no_pop_stack, 32, true, cp);
}


_command int cpos_stack_item_callback(int cmd = 0, stack_s & stk = null, int sx = 0, _str str = '')
{
   cpos temp;
   temp.buf_name = '';
   if (cmd == STACK_CALLBACK_ERROR) {
      reset_stack(stk, temp);
      message('Stack error, resetting');
      return 0;
   }

   if (cmd == STACK_CALLBACK_RESET) {
      reset_stack(stk, temp);
      message('Resetting stack');
      return 0;
   }

   if (cmd != STACK_CALLBACK_SHOW_ITEM) {
      message('Unknown stack cmd ' :+ cmd);
      return -2;
   }

   // have to use a pointer coz stk.stack[sx].buf_name doesn't work!
   cpos * p = &stk.stack[sx];
   if (edit( maybe_quote_filename(p->buf_name) ) != 0){
      return -1;
   }
   _mdi.p_child.p_line = p->line;
   _mdi.p_child.p_col = p->col;
   message(str :+ strip_filename(_mdi.p_child.p_buf_name,'DP') );
   return 0;
}



static void cycle_cursor_pos_stack(stack_s & stk)
{
   cycle_stack(stk, 'cpos_stack_item_callback');
}

_command void cycle_cpos_no_pop_stack() name_info(',')
{
   cycle_cursor_pos_stack(cpos_no_pop_stack);
}


_command int cursor_left_with_line_wrap()
{
   int col, line;
   col = p_col;
   line = p_line;

   if (p_col <= 1) {
      if (up(1,1) == 0) 
         _end_line();
      else
         // start of file
         return -1;
   }
   else
      left();

   if (line == p_line && col == p_col) {
      return -1;
   }
   return 0;
}

_command int cursor_right_with_line_wrap()
{
   int col, line;
   col = p_col;
   line = p_line;

   // change > to >= in the following line to avoid landing on newline char
   if (p_col > _text_colc()) {
      if (down(1,1) == 0) 
         _begin_line();
      else
         // end of file
         return -1;
   }
   else
      right();
   
   if (line == p_line && col == p_col) {
      return -1;
   }
   return 0;
}



static boolean has_cursor_moved(int line, int col)
{
   return p_col != col || p_line != line;
}

static boolean string_select_includes_delimiter = false;

static void inclusive_char_select(typeless spos, typeless epos)
{
   int line, col;
   typeless tpos = spos;
   restore_pos(epos);
   line = p_line;
   col = p_col;
   restore_pos(spos);
   if (p_line > line || (p_line == line && p_col > col)) {
      // cursor has gone backwards, swap spos, epos
      spos = epos;
      epos = tpos;
      restore_pos(spos);
   }
   _select_char();
   restore_pos(epos);
   _select_char();
   restore_pos(tpos);
}

#define EE_EXIT 0
#define EE_ENTRY 1
#define EE_UPDATE_SPOS 2
#define EE_EXIT_RESTORE_CURSOR 3
// if entry is true, select true specifies to create a new selection
// if entry is false, select true => line selection, select false => char select
static boolean entry_exit(int code = EE_EXIT, boolean select = false)
{
   static int col, line;
   static boolean orig_select;
   static typeless m, ss, sf, sw, sr, sf2;
   static typeless start_pos;
   typeless new_pos;

   switch (code) {
      case EE_UPDATE_SPOS :
         col = p_col;
         line = p_line;
         save_pos(start_pos);
         return true;

      case EE_ENTRY :
         // Entering
         push_cpos();
         save_pos(start_pos);
         orig_select = select;
         if (!select) {
            save_selection( m );
         }
         save_search( ss, sf, sw, sr, sf2 );
         col = p_col;
         line = p_line;
         return false;

      case EE_EXIT_RESTORE_CURSOR :
         restore_pos(start_pos);
         // fall through
      case EE_EXIT :
         // Exiting.  When exiting, select param true => line select, else char select
         save_pos(new_pos);
         if (!orig_select || !has_cursor_moved(line,col)) {
            restore_selection( m );
         }
         else if (select) {
            // create a line selection
            _deselect();
            restore_pos(start_pos);
            _select_line();
            restore_pos(new_pos);
            _select_line();
         } else {
            // create a char selection
            _deselect();
            if (pos(get_text(),def_pmatch_chars))
            {
               // let select_paren_block find the start and end because we don't 
               // always know the end point here and select_paren_block has some
               // magic regarding selecting and cursor positioning
               select_paren_block();
               _begin_select();
               if (p_line == line && p_col == col) {
                  // if we started at the start point of the selected text, then
                  // go to the end, otherwise, stay at the start
                  _end_select();
               }
            }
            else 
               inclusive_char_select(start_pos, new_pos);
         }
         restore_search( ss, sf, sw, sr, sf2 );
         return has_cursor_moved(line,col);
   }
   return false;
}

// return true if current character at the cursor is an opening paren
// def_pmatch_chars holds pairs of characters e.g. []{}()
static boolean at_opening_paren()
{
   return pos(get_text(),def_pmatch_chars)%2 != 0;
}


static boolean is_whitespace(_str s1)
{
   return (s1==' ') || (s1==\n) || (s1==\t) || (s1==\r) ;
}


static boolean in_func()
{
   if (p_lexer_name=='') {
      return false;
   }
   int color = _clex_find(0,'g');
   return color==CFG_FUNCTION;
}


static boolean get_func_name2() 
{
   if (prev_tag(true) != 0)
      return false;

   int line = p_line;
   while (!in_func()) {
      if (cursor_right_with_line_wrap() != 0)
         return false;
      if (p_line - line > 10) {
         return false;
      }
   }
   message(cur_word(line));
   copy_word();
   return true;
}

_command void get_func_name() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless p;
   save_pos(p);
   if (!get_func_name2())
      message('Not found');
   restore_pos(p);
}





boolean _in_preproc()
{
   if (p_lexer_name=='') {
      return false;
   }
   int color = _clex_find(0,'g');
   return(color==CFG_PPKEYWORD);
}


_command boolean goto_nearest_preproc() name_info(',')
{
   int status;

   // push cursor pos and save search state
   entry_exit(EE_ENTRY);
   boolean b = _in_preproc();

   while (1) {
      status = search('#','-@CP');
      if (status == 0) {
         switch (get_text(3))
         {
            case '#if' :
            case '#el' :
               if (b) {
                  _find_matching_paren();
               }
               return entry_exit();
            case '#en' :
               _find_matching_paren();
               if (b) {
                  return entry_exit();
               }
               break;
         }
      } else {
         break;
      }
      b = false;
      if (cursor_left_with_line_wrap()) {
         break;
      }
   }
   message('Not found');
   return entry_exit(EE_EXIT_RESTORE_CURSOR);
}



_command boolean goto_selection_start_end() name_info(',')
{
   int col = p_col, line = p_line, status;
   if (select_active()) {
      if (_in_preproc()) {
         status = search('#','-@CP');
         if (status == 0) {
            switch (get_text(3))
            {
               case '#if' :
               case '#el' :
               case '#en' :
                  _deselect();
                  entry_exit(EE_ENTRY);
                  _find_matching_paren();
                  return entry_exit();
            }
         }
      }
      // go to the start of the selection unless we're already at the start
      _begin_select();

      #ifndef NO_SCROLL_SELECTION_IN_VIEW
      next_buffer();   // Do next/prev because it's the only way 
      prev_buffer();   // I can find to get the selection in view.
      //center_line();   // It's better without this
      #endif

      if (p_col == col && p_line == line) {
         _end_select();
         return true;
      }
      _end_select();
      // we weren't at the beginning or the end so remember where we were
      if (p_col != col || p_line != line) {
         push_cpos();
      }
      _begin_select();
      return true;
   }
   return false;
}


_command boolean goto_string_start_end(boolean select = true) name_info(',')
{
   int scol = p_col;
   int sline = p_line;

   if (_in_string()) {
      entry_exit(EE_ENTRY, select);
      // search backwards for non string character
      int status=search('?','-r@xsv');
      // search forwards for the start of the string
      status=search('?','r@Cs');  
      boolean at_start = (p_line == sline && (scol - p_col <= 1));
      if (!string_select_includes_delimiter) {
         cursor_right_with_line_wrap();
      }
      if (!at_start && !select) {
         // exit with cursor at the start and no selection
         return entry_exit();
      } 
      entry_exit(EE_UPDATE_SPOS);  // update start_pos
      // search forwards for the end of the string
      search('?','r@xsv');   
      status=search('?','-r@Cs');  // search backwards for the string delimiter
      entry_exit();
      if (select && at_start) {
         // _end_select will leave the cursor on the string delimiter because
         // the end delimiter isn't part of the selection
         _end_select();
         // check anyway, it might change in future!
         if (!_in_string()) {
            cursor_left_with_line_wrap();
         }
      }
      return true;
   }
   return false;
}


_command boolean goto_comment_start_end(boolean select = false) name_info(',')
{
   int scol = p_col;
   int sline = p_line;
   if (_in_comment()) {
      // remember the current search settings and push cursor pos
      entry_exit(EE_ENTRY, select);
      // search backwards for non comment non whitespace character
      int status=search('[^ \r\n\t]','-r@xc');                                        
      int fline = p_line;  // remember the line number
      // find the start of the comment
      status=search('?','r@Cc');  
      int nline = p_line;
      fline = fline - p_line;
      // fline is now zero if the comment is preceded by non whitespace/non 
      // comment on the same line.

      int fcol = p_col;
      boolean at_start = (p_line == sline && (scol - p_col <= 1));
      if (!at_start && !select) {
         // exit with cursor at the start and no selection
         return entry_exit();
      } 
      entry_exit(EE_UPDATE_SPOS);  // update start_pos
      // search forwards for the end of the comment and not whitespace
      search('[^ \r\n\t]','r@xc');                                                  
      int lline = p_line;
      status=search('?','-r@Cc');  // search backwards for the end of the comment
      lline = lline - p_line;
      // lline is now zero if the comment is followed by non whitespace/non 
      // comment on the same line.

      nline = p_line - nline;    // number of lines
      int lcol = p_col;
      right();

      // If the comment is on a single line or if the first/last line of the
      // comment is preceded/succeeded by non whitespace on the same line,
      // then a char selection is created (if selecting), otherwise a line
      // selection.
      if (fline && lline && nline)
         entry_exit(EE_EXIT, true);  // line selection    
      else
         entry_exit(); // char selection

      if (select && at_start) {
         _end_select();
         p_col = lcol;
      } else if (select) {
         _begin_select();
         p_col = fcol;
      }
      return has_cursor_moved(sline,scol);
   }
   return false;
}


boolean def_enable_select_goto_enclosure;

/**
 * @goto_enclosure
 * An extension to find_matching_paren().  If find_matching_paren returns failure, 
 * find_matching_paren_u2 calls this function  which searches backwards for the nearest 
 * parenthesis and goes to the "beginning/opening" matching parenthesis if not there 
 * already.  If currently within a comment or string, goes to the start of the comment or 
 * string.  If at the start of the comment or string, goes to the end. 
 *  
 * @param select   if true, the code block is selected if the cursor was not
 * already on a parenthesis 
 *  
 * @see find_matching_paren 
 * @see show_matching_paren 
 * @see select_paren_block 
 * @see keyin_match_paren
 * @see def_pmatch_chars
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *  
 * @return Returns 0 if cursor pos is changed.  Common return codes are
 * TOO_MANY_SELECTIONS_RC and STRING_NOT_FOUND_RC.
 */   
_command boolean goto_enclosure(boolean select = false) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int status, scol = p_col, sline = p_line;

   // If a selection is active, go to the start or end
   if (select_active()) {
      return goto_selection_start_end();
   }

   if (_in_string()) {
      return goto_string_start_end(true);
   }

   if (_in_comment()) {
      return goto_comment_start_end(select);
   }
   else if (is_whitespace(get_text())) {
      cursor_left_with_line_wrap();     
      if (_in_comment()) {
         return goto_comment_start_end(select);
      }
      cursor_right_with_line_wrap();     
   }

   entry_exit(EE_ENTRY, select);

   // Not in a comment or string.
   // Need to call find_matching_paren because it finds more than just [({ -
   // it also finds/matches #ifdef/#endif/begin/end.
   // find_matching_paren moves the cursor if it's on the word "return" for some reason
   if ((cur_word(status) != 'return') && 
       (find_matching_paren(true) == 0 || has_cursor_moved(sline,scol))) {
      // the cursor was already on a parenthesis or #ifdef etc.
      if (pos(get_text(),def_pmatch_chars))
         return entry_exit();
      // must have been on #ifdef or begin end etc
      // if selecting, create a line selection from where we were to where we are now
      return entry_exit(EE_EXIT, true);
   }

   // Not in a string or comment and not on parenthesis.
   // Search backwards for a parenthesis - if none, search forwards
  
   if (search('['_escape_re_chars(def_pmatch_chars)']','-r@xcsv')) {
      search('['_escape_re_chars(def_pmatch_chars)']','r@xcsv');
      return entry_exit();
   }

   // Searching backwards found a parenthesis.  If it's not an opening paren,
   // search forwards for a closing paren.  If don't find a closing paren, go 
   // back to the previously found closing paren.
   if ( !at_opening_paren() ) {   
      typeless spos;
      save_pos(spos);
      // search forwards for a closing paren
      if (search('['_escape_re_chars(def_pmatch_chars)']','r@xcsv') || at_opening_paren())
         restore_pos(spos);  // didn't find a closing paren
   }
   return entry_exit();
}


_command void goto_enclosure_maybe_select() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   goto_enclosure(def_enable_select_goto_enclosure);
}


_command void goto_enclosure_and_select() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   goto_enclosure(true);
}


_command void undo_goto() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   pop_cpos();

   #ifndef NO_SCROLL_IN_VIEW
   next_buffer();   // do next/prev because it's the only way
   prev_buffer();   // I can find to get the selection in view
   //center_line();  
   #endif
}


/**
 * @find_matching_paren_u2
 * An extension to find_matching_paren().  If find_matching_paren returns failure, 
 * find_matching_paren_u2 calls goto_enclosure_maybe_select which searches backwards for 
 * the nearest parenthesis and goes to the "beginning/opening" matching parenthesis if not 
 * there already.  If currently within a comment or string, goes to the start of the 
 * comment or string.  If at the start of the comment or string, goes to the end. 
 *  
 * @param select   if true, the code block is selected if the cursor was not
 * already on a parenthesis 
 *  
 * @see find_matching_paren 
 * @see show_matching_paren 
 * @see select_paren_block 
 * @see keyin_match_paren
 * @see def_pmatch_chars
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *  
 * @return Returns 0 if cursor pos is changed.  Common return codes are
 * TOO_MANY_SELECTIONS_RC and STRING_NOT_FOUND_RC.
 */   
_command void find_matching_paren_u2() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int col = p_col;
   int line = p_line;
   if (find_matching_paren(true) == 0) {
      return;
   }
   if (p_col != col || p_line != line) {
      // find_matching_paren lied! - it sometimes does this when the cursor
      // is at the start of a multi line comment
      return;
   }
   goto_enclosure_maybe_select();
}


/**
 * @find_matching_paren_u4
 * An extension to find_matching_paren().  If find_matching_paren returns 
 * failure, find_matching_paren_u4 searches backwards for the 
 * nearest parenthesis and goes to the "beginning/opening" 
 * matching parenthesis if not there already.  If currently 
 * within a comment or string, goes to the start of the comment 
 * or string.  If at the start of the comment or string, goes to 
 * the end. 
 *  
 * @param select   if true, the code block is selected if the cursor was not
 * already on a parenthesis 
 *  
 * @see find_matching_paren 
 * @see show_matching_paren 
 * @see select_paren_block 
 * @see keyin_match_paren
 * @see def_pmatch_chars
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *  
 * @return  Returns 0 if match found.  Common return codes are
 * TOO_MANY_SELECTIONS_RC and STRING_NOT_FOUND_RC.
 */
_command int find_matching_paren_u4(boolean select = false) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int col,line;
   col = p_col;
   line = p_line;

   if (find_matching_paren(true) == 0) {
      return 0;
   }
   if (p_col != col || p_line != line) {
      // find_matching_paren lied! - it sometimes does this when the cursor
      // is at the start of a multi line comment
      return 0;
   }
   if (_in_string()) {
      cursor_left();
      if (_in_string()) {
         while(_in_string()) {
            cursor_left();
         }
         cursor_right();
         return 0;
      }
      // cursor was at the start of the string so go to the end
      cursor_right();
      while(_in_string()) {
         cursor_right();
      }
      cursor_left();
      return 0;
   }

   if (_in_comment()) {
      cursor_left();
      if (_in_comment()) {
         while(_in_comment()) {
            cursor_left();
         }
         cursor_right();
         return 0;
      }
      // cursor was at the start of the comment so go to the end
      cursor_right();
      while(_in_comment()) {
         cursor_right();
      }
      cursor_left();
      return 0;
   }

   show_matching_paren('y');
   if (!select) {
      deselect();
   }
   return find_matching_paren(true);
}



definit()
{
   init_cpos_stack();
}




#ifdef abc
int v1;
int v1;
int v1;
#else
int v1;
int v1;
#endif

  /**** 
 
 lll
  */


_command void tt1() name_info(',')
{
   message(_in_comment());
}













