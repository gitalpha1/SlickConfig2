
#include "slick.sh"
#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)

//#import "window.e"


static boolean is_wordchar(_str s1)
{
   //return isalnum(s1) || (s1=='_');
   return pos('['p_word_chars']',s1,1,'R') > 0;
}


static boolean is_whitespace(_str s1)
{
   return (s1==' ') || (s1==\n) || (s1==\t) || (s1==\r) ;
}


/* cursor_to_next_token_stop_on_all
   - skips whitespace,
   - stops at start and end of a word,
   - stops on any other non whitespace char
*/
_command void cursor_to_next_token_stop_on_all() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int lim = 0;
   if ( is_wordchar(get_text()) ) {
      while ( is_wordchar(get_text()) ) {
         if (++lim > 2000)
            return;
         cursor_right();
      }
   } else {
      cursor_right();
   }
   lim = 0;
   _str s1 = get_text();
   while ( is_whitespace(s1) ) {
      if (++lim > 2000)
         return;
      if ((s1==\n) || (s1==\r)) {
         begin_line();
         cursor_down();
      } else {
         cursor_right();
      }
      s1 = get_text();
   }
}


/* cursor_to_prev_token_stop_on_all
   - skips whitespace,
   - stops at start and end of a word,
   - stops on any other non whitespace char
*/
_command void cursor_to_prev_token_stop_on_all() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int lim = 0;
   cursor_left();
   while ( is_whitespace(get_text()) ) {
      if (++lim > 2000)
         return;
      cursor_left();
      if (get_text()==\r) {
         return;
      }
   }
   lim = 0;
   if ( is_wordchar(get_text()) ) {
      while ( is_wordchar(get_text()) ) {
         if (++lim > 2000)
            return;
         cursor_left();
      }
      cursor_right();
   }
}

/* cursor_to_next_token
   - stops at start and end of a word
*/
_command void cursor_to_next_token() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int lim = 0;
   if ( is_wordchar(get_text()) ) {
      while ( is_wordchar(get_text()) ) {
         if (++lim > 2000)
            return;
         cursor_right();
      }
      return;
   } else {
      while ( !is_wordchar(get_text()) ) {
         if (++lim > 2000)
            return;
         cursor_right();
      }
      return;
   }
}


/* cursor_to_prev_token
   - stops at start and end of a word
*/
_command void cursor_to_prev_token() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int lim = 0;
   cursor_left();
   if ( is_wordchar(get_text()) ) {
      while ( is_wordchar(get_text()) ) {
         if (++lim > 2000)
            return;
         cursor_left();
      }
      cursor_right();
      return;
   } else {
      while ( !is_wordchar(get_text()) ) {
         if (++lim > 2000)
            return;
         cursor_left();
      }
      cursor_right();
      return;
   }
}


static _str the_word;

/* find_next_word_at_cursor
   - finds next "whole word" matching
   - repeat the search in the same direction with repeat_find_word_at_cursor
   - repeat the search in the reverse direction with repeat_find_word_at_cursor_reverse
*/
_command void find_next_word_at_cursor() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int lim = 0;
   if ( !is_wordchar(get_text()) ) {
      cursor_left();
      if (!is_wordchar(get_text())) {
         while ( !is_wordchar(get_text()) ) {
            cursor_to_next_token();
            if (++lim > 2000)
               return;
         }
         return;
      }
   }
   lim = 0;
   the_word = '';
   while ( is_wordchar(get_text()) ) {
      cursor_left();
      if (++lim > 2000)
         return;
   }
   cursor_right();
   while ( is_wordchar(get_text()) ) {
      the_word = the_word :+ get_text();
      cursor_right();
      if (++lim > 2000)
         return;
   }
   //old_search_string = the_word;
   if ( find(the_word,'IHPW') == 0 ) {
      _deselect();
      _select_char();
      cursor_right(length(the_word));
      _select_char();
      cursor_left(length(the_word));
      return;
   }
   top();
   message('***** wrapping to top *****');
   find(the_word,'IH');
}


/* find_prev_word_at_cursor
   - finds previous "whole word" matching
   - repeat the search in the same direction with repeat_find_word_at_cursor
   - repeat the search in the reverse direction with repeat_find_word_at_cursor_reverse
*/
_command void find_prev_word_at_cursor() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int lim = 0;
   if ( !is_wordchar(get_text()) ) {
      cursor_left();
      if (!is_wordchar(get_text())) {
         while ( !is_wordchar(get_text()) ) {
            cursor_to_prev_token();
            if (++lim > 2000)
               return;
         }
         return;
      }
   }
   lim = 0;
   the_word = '';
   while ( is_wordchar(get_text()) ) {
      cursor_left();
      if (++lim > 2000)
         return;
   }
   cursor_right();
   while ( is_wordchar(get_text()) ) {
      the_word = the_word :+ get_text();
      cursor_right();
      if (++lim > 2000)
         return;
   }
   cursor_to_prev_token();
   cursor_left();
   //old_search_string = the_word;
   if ( find(the_word,'-IHPW') == 0 ) {
      _deselect();
      _select_char();
      cursor_right(length(the_word));
      _select_char();
      cursor_left(length(the_word));
      return;
   }
   bottom();
   message('***** wrapping to bottom now *****');
   find(the_word,'-IH');
}


/* repeat_find_word_at_cursor
   - see find_prev_word_at_cursor, find_next_word_at_cursor
*/
_command void repeat_find_word_at_cursor() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (find_next() == 0) {
      _deselect();
      _select_char();
      cursor_right(length(the_word));
      _select_char();
      cursor_left(length(the_word));
      return;
   }
}


/* repeat_find_word_at_cursor_reverse
   - see find_prev_word_at_cursor, find_next_word_at_cursor
*/
_command void repeat_find_word_at_cursor_reverse() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (find_next(true) == 0) {
      _deselect();
      _select_char();
      cursor_right(length(the_word));
      _select_char();
      cursor_left(length(the_word));
      return;
   }
}


// name_info attributes are commented here because they make this function fail
// when it is used repeatedly to extend the selection - with name_info attributes
// uncommented, the previous selection gets lost
_command select_to_next_token() // name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _select_char();
   cursor_to_next_token_stop_on_all();
   _select_char();
}


// name_info attributes are commented here because they make this function fail
// when it is used repeatedly to extend the selection - with name_info attributes
// uncommented, the previous selection gets lost
_command void select_to_prev_token() // name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _select_char();
   cursor_to_prev_token_stop_on_all();
   _select_char();
}


_command void delete_next_token(boolean leave_a_space = true) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _deselect();
   if (is_wordchar(get_text())) {
      delete_word();
      return;
   }
   if (leave_a_space) {
      _str s1 = get_text();
      if (is_whitespace(s1) && (p_col > 1) && s1!=\r && s1!=\n) {
         cursor_left();
         if (is_whitespace(get_text())) {
            // there is already whitespace before the current character so don't skip any
            cursor_right();
         } else {
            cursor_right();
            if (get_text(2) :== '  ')
               cursor_right(); // leave one whitespace character
         }
      }
   }
   select_to_next_token();
   delete_selection();
}
 


_command void delete_prev_token() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _deselect();
   _select_char();
   cursor_left();
   _str s1 = get_text();
   int lim = 0;
   if (is_whitespace(s1)) {
      while (is_whitespace(s1)) {
         if (s1==\r || s1 == \n) {
            _select_char();
            delete_selection();
            return;
         }
         if (++lim > 2000){
            _deselect();
            return;
         }
         cursor_left();
         s1 = get_text();
      }
      cursor_right();
      _select_char();
      delete_selection();
      return;
   }
   _deselect();
   cursor_right();
   select_to_prev_token();
   delete_selection();
}


/**** slick_fast_move is for use with voice commands

_command slick_fast_move(int dr = 1, int speed = 180)
{

    _set_timer(speed);
    for(;;){
       event=get_event();
       if (event==on_timer){
           switch (dr) {
           case 1:cursor_to_prev_token(); break;
           case 2: cursor_to_next_token(); break;
           case 3: up();  break;
           case 4: down(); break;
           case 5: page_up(); break;
           case 6: page_down(); break;
           }
       } else {
           break;
       }
    }
    _kill_timer();

}
_command slick_fast_pageup ()
{
    slick_fast_move(5,300);
}
_command slick_fast_page_down ()
{
    slick_fast_move(6,300);
}
//control shift one
_command slick_fast_left ()
{
    slick_fast_move(1);
}
//control shift two
_command slick_fast_right()
{
    slick_fast_move(2);
}
//control shift three
_command slick_fast_up()
{
    slick_fast_move(3);
}
//control shift four
_command slick_fast_down()
{
    slick_fast_move(4);
}

*******************/




_command void toggle_font() name_info(',' VSARG2_MACRO | VSARG2_REQUIRES_EDITORCTL | VSARG2_MARK | VSARG2_READ_ONLY)
{
   if (p_encoding != 0) {
      _message_box("This function currently only supports SBCS/DBCS window text");
      return;
   }

   _str     Font = p_font_name;
   typeless Size = p_font_size;
   _str flags;

   if (Font=='Lucida Sans Typewriter') {
       Font = 'Consolas';
       Size = 13;
       _default_font(CFG_WINDOW_TEXT,Font','Size',0,1,');
       flags = F_BOLD;
   }
   else {
       Font = 'Lucida Sans Typewriter';
       Size = 9;
       _default_font(CFG_WINDOW_TEXT,Font','Size',0,1,');
       flags = 0;
   }

   setall_wfonts(Font,Size,flags,'1','2');
}





/**
 * @author Ryan Anderson
 * @description Increases the current editor font size
 * @version 0.0  -  2004/06/08
 */
_command void increase_font_size() name_info(',' VSARG2_MACRO | VSARG2_REQUIRES_EDITORCTL | VSARG2_MARK | VSARG2_READ_ONLY)
{
   if (p_encoding != 0) {
      _message_box("This function currently only supports SBCS/DBCS window text");
      return;
   }
   _str     Font = p_font_name;
   typeless Size = p_font_size;

   Size+=1;
   message("Font Size = "Size);

   _default_font(CFG_WINDOW_TEXT,Font','Size',0,1,');
   setall_wfonts(Font,Size,'0','1','2');
}

/**
 * @author Ryan Anderson
 * @description Decreases the current editor font size
 * @version 0.0  -  2004/06/08
 */
_command void decrease_font_size() name_info(',' VSARG2_MACRO | VSARG2_REQUIRES_EDITORCTL | VSARG2_MARK | VSARG2_READ_ONLY)
{
   if (p_encoding != 0) {
      _message_box("This function currently only supports SBCS/DBCS window text");
      return;
   }
   _str     Font = p_font_name;
   typeless Size = p_font_size;

   if (Size>1) {
      Size-=1;
   }
   message("Font Size = "Size);

   _default_font(CFG_WINDOW_TEXT,Font','Size',0,1,');
   setall_wfonts(Font,Size,'0','1','2');
}

_command show_my_fave_cmds1()
{
   mou_show_menu('fave_cmds1');
}

_command void upcase_char()name_info(',' VSARG2_REQUIRES_EDITORCTL)
{
   _select_char();
   cursor_right();
   _select_char();
   upcase_selection();
}


_command void lowcase_char()name_info(',' VSARG2_REQUIRES_EDITORCTL)
{
   _select_char();
   cursor_right();
   _select_char();
   lowcase_selection();
}


_command save_all_inhibit_buf_history()
{
   goback_suspend_buffer_list_history();
   save_all();
   goback_enable_buffer_list_history();
}


_menu fave_cmds1 {
   //"favourite commands #1","","","","";
   submenu "More","","","" {
      "F9 complete-prev-no-dup","complete_prev_no_dup","","","";
      "S-F9  complete-next-no-dup","complete_next_no_dup","","","";
      "C-F9  complete-prev","complete_prev","","","";
      "C-S-F9  complete-next","complete_next","","","";
      "A-F9  complete-list","complete_list","","","";
      "A-S-F9  complete-more","complete_more","","","";
      "--","","","","";
      "F8  select-code-block","select_code_block","","","";
      "S-F8  hide-code-block","hide_code_block","","","";
      "C-F8  hide-selection","hide_selection","","","";
      "S-A-F8  hide-comments","hide_all_comments","","","";
      "C-S-F8  select-paren","select_paren_block","","","";
      "show-all","show-all","","","";
   }

   submenu "Open / Explore / Copy / Diff","","open-file or explore folder","" {
      "Open from here (op)","open-from","","","open from current buffer path";
      "Open from config (opc)","opc","","","open file from configuration folder";
      "Open from project root (opp)","opp","","","";
      "Open vsstack error file (opvss)","opvss","","","Open Slick C error file";
      "-","","","","";
      "Explore current buffer (xp)","xp","","","explore from folder of current buffer";
      "Explore config folder (xpc)","xpc","","",""; 
      "Explore installation folder (xps)", "xps","","",""; 
      "Explore docs (xpdocs)","xpdocs","","",""; 
      "Explore project root (xpp)","xpp","","","";
      "-","","","",""; 
      "Copy cur buffer name to clipboard","curbuf-name-to-clip","","",""; 
      "Copy cur buffer path to clipboard","curbuf-path-to-clip","","",""; 
      "-","","","",""; 
      "Diff last two buffers (diff2)","diff2","","","";
   }
   submenu "&Case conversion","","","" {
      "lowcase selection","lowcase-selection","","","";
      "upcase selection","upcase-selection","","","";
      "&Lowcase word","lowcase-word","","","";
      "&Upcase word","upcase-word","","","";
      "Upcase &char","upcase-char","","","";
      "Cap &selection","cap-selection", "","","";
   }
   "&Goback","GFH-step-thru-goback-history","","","";
   "&Kill my timer","kill-gfileman-timer","","","";
   "&Transpose chars (ctrl T)","transpose-chars","","","";
   "transpose words (C S T)","transpose-words","","","";
   "transpose lines  (alt T)","transpose-lines","","","";
   "-","","","",""; 
   "&Decrease font size C-S-F7","decrease-font-size","","","";
   "&Increase font size S-F7","increase-font-size","","","";
   "toggle font","toggle-font C-F7","","","";
   "&Highlight word","hlWord","","","";
   "&save all","save-all-inhibit-buf-history","","","";
   "-","","","","";
   "&1 Function comment", "func-comment","","","";
   "&2 Save bookmarks", "xsave_bookmarks","","","";
   "&3 Restore bookmarks", "xrestore_bookmarks","","","";
}



_menu fave_cmds2 {
// submenu "More","","","" {
//    "F9 complete-prev-no-dup","complete_prev_no_dup","","","";
// }
   " &open", "activate_open", "", "", "";
   " doc-buffers", "document_tab_list_buffers", "", "", "";
   " &h deltasave",  "activate_deltasave"                      ,"","","";
   " &bookmarks activate", "activate_bookmarks", "","","";
   " &find_symbol",  "activate_find_symbol"                  ,"","","";
   " &context",      "activate_context"                      ,"","","";
   " &defs",         "activate_defs"                         ,"","","";
   " &projects",     "activate_projects"                     ,"","","";
   " &references",   "activate_references"                   ,"","","";
   " &search",       "activate_search"                       ,"","","";
   " &v preview",    "activate_preview"                        ,"","","";
   " &y symbol",     "activate_symbol"                         ,"","","";
   " files",         "activate_files"                         ,"","","";
   " todo",          "activate_todo"                         ,"","","";
   " build",         "activate_build"                         ,"","","";

}


_command show_my_fave_cmds2()
{
   mou_show_menu('fave_cmds2');
}


_menu fave_cmds3 {
// submenu "More","","","" {
//    "F9 complete-prev-no-dup","complete_prev_no_dup","","","";
// }
   "&bookmarks toggle", "toggle_bookmarks", "","","";
   " &context",         "toggle_context"                      ,"","","";
   " &defs",            "toggle_defs"                         ,"","","";
   " &find_symbol",     "toggle_find_symbol"                  ,"","","";
   " &h deltasave",     "toggle_deltasave"                      ,"","","";
   " &projects",        "toggle_projects"                     ,"","","";
   " &references",      "toggle_refs"                         ,"","","";
   " &search",          "toggle_search"                       ,"","","";
   " &v preview",       "toggle_preview"                        ,"","","";
   " &y symbol",        "toggle_symbol"                         ,"","","";

}


_command show_my_fave_cmds3()
{
   mou_show_menu('fave_cmds3');
}



_command void show_config_dir() name_info(',')
{
   message(_config_path());
}


_command void goto_function_end() name_info(',')
{
   _macro('R',1);
   down();
   prev_tag();
   //open_collapsed();
   search('{','I?');
   _deselect();
   find_matching_paren();
}

static int win1, win2, dwin;

static void synch_scroll_down()
{
   scroll_down();
   if (dwin == 0)
      return;
   activate_window(win2);
   scroll_down();
   activate_window(win1);
}


static void synch_scroll_up()
{
   scroll_up();
   if (dwin == 0)
      return;
   activate_window(win2);
   scroll_up();
   activate_window(win1);
}


static boolean synch_scroll_active = false;

_command void my_fast_scroll() name_info(',')
{
   fast_scroll();
   if (!synch_scroll_active || (dwin == 0)) return;
   activate_window(win2);
   fast_scroll();
   activate_window(win1);
}


static void do_synch_scroll(int dr, int speed)
{
    _str event, keyt;
    int xyz = 0;
    dwin = 0;
    if (Nofwindows() > 1) {
       dwin = 1;
       win1 = _mdi.p_child.p_window_id;
       activate_window(win1);
       prev_window();
       win2 = _mdi.p_child.p_window_id;
       activate_window(win1);
    }
    synch_scroll_active = true;
    _set_timer(speed);
    mou_mode(1);
    mou_capture();

    outerloop:
    for(;;){
       event = get_event();  // refresh screen and get a key
       //say(++xyz);
       if (event == on_timer){
           switch (dr) {
           case 1: cursor_to_prev_token(); break;
           case 2: cursor_to_next_token(); break;
           case 3: up();  break;
           case 4: down(); break;
           case 5: page_up(); break;
           case 6: page_down(); break;
           case 7: synch_scroll_up();  break;
           case 8: synch_scroll_down(); break;
           case 9 : scroll_right(); break;
           case 10 : scroll_left(); break;
           }
       } else {
          keyt = event2name(event);
          //say(++xyz);
          message(keyt);
          switch(keyt)
          {
             case 'UP' : dr = 0; synch_scroll_up(); break;
             case 'DOWN' : dr = 0; synch_scroll_down(); break;
             case 'C-UP' : dr = 3; break;
             case 'C-DOWN' : dr = 4; break;
             case 'C-RIGHT' : dr = 9; break;
             case 'C-LEFT' : dr = 10; break;
             case 'A-UP' : dr = 7; break;
             case 'A-DOWN' : dr = 8; break;
             case 'ESC' :
             case 'ENTER' : 
                break outerloop;
             case ' ' : speed += 20; _kill_timer(); _set_timer(speed); break;
             case 'C- ' : 
                if (speed > 20) {
                   speed -= 20; 
                   _kill_timer(); 
                   _set_timer(speed); 
                }
                break;

             case 'MOUSE-MOVE':
                break;
                // if (first_time) {
                //    y_last = y_now = form_id.mou_last_y();
                //    x_last = x_now = form_id.mou_last_x();
                //    prev_y_greater_x = first_time = false;
                //    proc_count = 0;
                // }
                // else if (++proc_count < 5) {
                //    //y_now = form_id.mou_last_y();   // pixels
                //    //x_now = form_id.mou_last_x();
                //    //say("Less5 " :+ x_last :+ " " :+ x_now :+ " " :+ y_last :+ " " :+ y_now);
                // }
                // else {
                //    proc_count = 0;
                //    y_now = form_id.mou_last_y();   // pixels
                //    x_now = form_id.mou_last_x();
                //    if (abs(x_on_entry - x_now) > 40) {
                //       exit_event_loop = true;
                //       break;
                //    }
                //    int diff = abs(y_last - y_now) - abs(x_last - x_now);
                //    if (diff > 2) {
                //       //say("diff " :+ diff :+ " " :+ x_last :+ " " :+ x_now :+ " " :+ y_last :+ " " :+ y_now);
                //       process_scrollbar_mouse_move(form_id, y_now, y_last);
                // 
                //    }
                //    /**********
                //    else if (diff > 0 && prev_y_greater_x) {
                //       process_scrollbar_mouse_move(form_id, y_now, y_last);
                //    }
                //    prev_y_greater_x = (diff > 0);
                //    *************/
                //    x_last = x_now;
                //    y_last = y_now;
                // }
                // break;



          }
       }
    }
    synch_scroll_active = false;
    _kill_timer();
    mou_mode(0);
    mou_release();
}


_command slick_synch_scroll(int dr = 0, int speed = 180)
{
   do_synch_scroll(dr, speed);
   synch_scroll_active = false;
}



_command void find_symbol_word_at_cursor() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   int xx;
   _control ctl_search_for;
   _str s = cur_word(xx);
   int wid = activate_tool_window('_tbfind_symbol_form', true, 'ctl_search_for');
   wid.ctl_search_for.p_text = s;
   wid.ctl_search_for._set_sel(1,length(s)+1);
}


_command void my_comment_wrap_toggle() name_info(',')
{
   comment_wrap_toggle();
   if (_GetCommentWrapFlags(CW_ENABLE_COMMENT_WRAP)) 
      message('comment wrap on');
   else
      message('comment wrap off');
}




#if 0
// Search the workspace for the project containing the current file (or the
// specified file) and show the project toolbar with the file selected
_command void showx(_str filename = '', boolean quiet = false) name_info(',')
{
   int state,bm1,bm2,flags;

   if (filename == '') {
      if (_no_child_windows()) {
         _message_box('Error : no filename specified');
         return;
      }
      filename = _mdi.p_child.p_buf_name;
   }
   _str project_found = _WorkspaceFindProjectWithFile(filename, _workspace_filename, true, quiet);

   if (project_found == '') {
      _message_box('File not found : ' :+ filename);
      return;
   }
   message('Project : ' :+ project_found :+ '   File : ' :+ filename :+ '  SE ' :+ _getVersion());

   activate_projects();

   int hTree = _find_object('_tbprojects_form._proj_tooltab_tree');
   if (hTree > 0) {
      int index = hTree._TreeSearch(
         TREE_ROOT_INDEX, strip_filename(project_found,'P') :+ "\t" :+ project_found, 'IH');  
      if (index < 0) {
         _message_box('Project not found in toolbar');
         return;
      }
      if (hTree._projecttbIsProjectNode(index)
          && hTree._TreeGetFirstChildIndex(index)<0   ) {
         hTree.toolbarBuildFilterList(hTree._projecttbTreeGetCurProjectName(index),index);
         // Rebuilding the filter list for the project just expanded
         // will re-set the current index. Refocus the project node
         hTree._TreeSetCurIndex(index);
      }

      int index2 = hTree._TreeSearch(
         TREE_ROOT_INDEX,strip_filename(filename,'P') :+ "\t" :+ filename, 'TIH');
      if (index2 > 0)
      {
        hTree._TreeSetAllFlags(0,TREENODE_SELECTED);
        hTree._TreeGetInfo(index2,state,bm1,bm2,flags);
        hTree._TreeSetInfo(index2,state,bm1,bm2,flags|TREENODE_SELECTED);
        hTree._TreeSetCurIndex(index2);

        //_message_box(hTree._TreeGetCaption(index));
         //_str s1 = hTree._TreeGetCaption(index);
         //int k;
         //for (k=8;k <= s1._length();++k) {
         //   say(_asc(substr(s1,k,1)));
         //}
      }
   }
}


int trace_id;

_str trace_cross_ref[];

_command add_trace() name_info(','VSARG2_MACRO|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   top();
   int line1;
   _str filen = strip_filename(p_buf_name,'DP');
   while (next_tag('Y') == 0)
   {
      find('{','I?');
      _deselect();
      end_line();
      c_enter();
      begin_line();
      _insert_text("XTRACE(" :+ (_str)++trace_id :+ ');');
      line1 = p_line;
      find('{','I-?');
      _deselect();
      find_matching_paren(true);
      keyin_enter();
      cursor_up();
      _insert_text("XTRACE_EXIT(" :+ (_str)trace_id :+ ');');

      _str cur_proc = '', cur_class = '';

      cur_proc = current_proc(false);
      cur_class = current_class(false);
      if ( length(cur_class))
         cur_proc = cur_class :+ '::' :+ cur_proc;

      trace_cross_ref[trace_cross_ref._length()] =
         (_str)trace_id :+ ' lines: ' :+ field(line1,5) :+ ' ' :+ field(p_line,5) :+
             ' ' :+ field(cur_proc,35) :+ '  ' :+ field('"' :+ filen :+ '"', 16) :+  '  "' :+ p_buf_name :+ '"';
   }
}

_str trace_files[];


int add_to_trace_list()
{
   if (p_extension == 'c') {
      trace_files[trace_files._length()] = p_buf_name;
   }
   return 0;
}

_command void add_trace_all() name_info(','VSARG2_MACRO|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   trace_id = 10000;
   trace_files._makeempty();
   trace_cross_ref._makeempty();
   for_each_buffer('add_to_trace_list');
   trace_files._sort('F');
   int k;
   for (k = 0; k < trace_files._length(); ++k) {
      _str ext = get_extension(trace_files[k]);
      if ( ext == 'c' || ext == 'cpp') {
         message('Trace ' :+ field(trace_id,5) :+ ' ' :+ strip_filename(p_buf_name,'DP'));
         edit(maybe_quote_filename(trace_files[k]));
         add_trace();
      }
   }
   edit('trace_cross_ref.txt');
   bottom();
   for (k = 0; k < trace_cross_ref._length(); ++k) {
      keyin_enter();
      _insert_text(trace_cross_ref[k]);
   }
   keyin_enter();
   keyin_enter();
   _insert_text('End cross reference');
   keyin_enter();
}

#endif




//defeventtab _tbtagrefs_form;
//
//void _tbtagrefs_form.'ESC'()
//{
//   call_event(p_window_id,ESC,'2');
//   toggle_refs();
//   if (_mdi.p_child._no_child_windows()==0) {
//      _mdi.p_child._set_focus();
//   }
//}


_command void my_hide_code_block() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   // Check to see if the very last command executed is the same command:
   int expandBlock = 0;
   _str name = name_name( prev_index( '', 'C' ) );
   if ( name == "hide-code-block" || name == "my-hide-code-block" ) expandBlock = 1;

   //Check if the first non-blank character of this line is a comment
   save_pos(auto p);
   first_non_blank();
   if (_clex_find(0,'g')==CFG_COMMENT) {
      hide_code_block();
      return;
   }

   restore_pos(p);
   int status=cs_hide_code_block( expandBlock );
   if (!status && select_active()) {
      hide_selection();
      restore_pos(p);
   } else {
      down();
      down();
      prev_tag('', 'A');
      // try again
      down();
      hide_code_block();
   }
   // Make this command the last command executed:
   last_index( find_index( 'hide_code_block', COMMAND_TYPE ), 'C' );
}

/**
 * FUNCTION : my_plusminus 
 *  
 * 
 * @author Administrator (21/11/2009)
 */
_command void my_plusminus() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (plusminus())
      my_hide_code_block();
}

_command void my_set_bookmark() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   set_bookmark(get_bookmark_name());
}


_command void my_next_bookmark() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   next_bookmark();
   center_line();
}

_command void func_comment() name_info(',')
{
   _str ll;
   get_line(ll);
   if (length(strip(ll)) == 0) {
      next_proc();
      up();
   }
   else {
      down();
      prev_proc();
      up();
   }
   keyin("funccom");
   expand_alias();
}

/*******************************************************************************
 * FUNCTION NAME : int gp_find_or_add_picture(_str filename)
 * 
 * DESCRIPTION : 
 *     
 *
 * INPUTS : 
 *     @param filename 
 *
 * OUTPUTS : 
 *     @return int 
 *
 ******************************************************************************/
int gp_find_or_add_picture(_str filename)
{
   index := find_index(filename, PICTURE_TYPE);
   //index := find_index(strip_filename(filename, 'P'), PICTURE_TYPE);
   if (!index) {
      //say(filename :+ ' ' :+ temp_config_modify :+ ' ' :+ _config_modify);
      //say(filename :+ ' ' :+ strip_filename(filename, 'P'));
      index = _update_picture(-1, filename);
   }
   return index;
}


// undo only cursor movements
_command void xundo() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int line = p_line;
   int col = p_col;
   cursor_right();
   if (p_line == line && p_col == col) {
      top();
      if (p_line == line && p_col == col) {
         bottom();
      }
   }
   if (undo_cursor() != CURSOR_MOVEMENT_UNDONE)
      _message_box("WARNING - check status line for undo message");
}


_command void myhelp() name_info(',')
{
   if (get_extension(_mdi.p_child.p_buf_name) == 'e')
      help();
   else
      help_index();
}


_command void show_preview() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   int window_id = p_window_id;
   activate_tool_window("_tbtagwin_form", true, "ctltaglist");
   p_window_id = window_id;
   window_id._set_focus();
}


_command void preview_push_tag() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   show_preview();
   push_tag();
}

// TODO!:  MY TODO 1
// TODO:  my todo 2


