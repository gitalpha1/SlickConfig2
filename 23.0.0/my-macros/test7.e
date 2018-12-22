
#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)





static _str get_search_cur_word()
{
   int start_col = 0;
   word := "";
   if (select_active2()) {
      if (!_begin_select_compare()&&!_end_select_compare()) {
         /* get text out of selection */
         last_col := 0;
         buf_id   := 0;
         _get_selinfo(start_col,last_col,buf_id);
         if (_select_type('','I')) ++last_col;
         if (_select_type()=='LINE') {
            get_line(auto line);
            word=line;
            start_col=0;
         } else {
            word=_expand_tabsc(start_col,last_col-start_col);
         }
         _deselect();
      }else{
         deselect();
         word=cur_word(start_col,'',1);
      }
   }else{
      word=cur_word(start_col,'',1);
   }
   return word;
}




_command int search_workspace_cur_word_now() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _str sw = get_search_cur_word();
   if (sw != '') {
      _str ss = _get_active_grep_view();
      _str grep_id = '0';
      if (ss != '') {
         parse ss with "_search" grep_id; 
      }
      return _mffind2(sw,'I','<Workspace>','*.*','','32',grep_id);
      //return _mffind2(sw,'I','<Workspace>','*.*','','32',auto_increment_grep_buffer());
   }
   return 0;
}


_command int search_cur_word() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _str sw = get_search_cur_word();
   if (sw == '') 
      return 0;

   int formid;
   if (isEclipsePlugin()) {
      show('-xy _tbfind_form');
      formid = _find_object('_tbfind_form._findstring');
      if (formid) {
         formid._set_focus();
      }
   } else {
      formid = activate_tool_window('_tbfind_form', true, '_findstring');
   }

   if (!formid) {
      return 0;
   }
   _control _findstring;
   formid._findstring.p_text = sw;
   formid._findstring._set_sel(1,length(sw)+1);
   return 1;
}


   // replace all, append to output, auto inc, perl reg exp
   // srch, repl, options, files, woldcards, exclude, mffflags, grep, show-diff 
   // options * = no prompt, I = ignore case, L = perl reg exp 



   
   
// aab
//  
//  
//  
// bbb 
// ccc 

// aaaaaaaaaaaaab
// bbb 

// ccc 

