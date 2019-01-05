
#include "slick.sh"

#pragma option(strictsemicolons,on)
//#pragma option(strict,on)
//#pragma option(autodecl,off)
#pragma option(strictparens,on)




_menu xmenu2 {
   "Set diff region", "xset_diff_region", "","","";
   "Compare diff region", "xcompare_diff_region", "","","";
   "Beautify project", "xbeautify_project", "","","";
   "Diff last two buffers", "diff_last_two_buffers", "","","";

   "--","","","","";
   "&New temporary file", "xtemp_new_temporary_file", "","","";
   submenu "More","","","" {
      "New temporary file no keep", "xtemp_new_temporary_file_no_keep", "","","";
      "Start xtemp file handler","start_xtemp_files_handler","","",""; 
      "Stop xtemp file handler","stop_xtemp_files_handler","","",""; 
      "xnotepad cur line","xnotepad","","",""; 
      "xnotepad cur word","xnotepad_word","","",""; 
   }

   "--","","","","";
   "Transpose chars","transpose-chars","","","";
   "Transpose words","transpose-words","","","";
   "Transpose lines","transpose-lines","","","";
   "Append word to clipboard", "xappend_word_to_clipboard","","","";
   submenu "Copy names >>","","","" {
      "Copy cur buffer name to clipboard","xcurbuf-name-to-clip","","",""; 
      "Copy cur buffer path+name to clipboard","xcurbuf-path-to-clip","","",""; 
      "Copy active project name to clipboard","xproject_name_to_clip","","",""; 
   }
   "--","","","","";
   "Float &1","xfloat1","","",""; 
   "Float &2","xfloat2","","",""; 
   "Float &3","xfloat3","","",""; 
   submenu "Set float","","","" {
      "Float &1","xset_float1","","",""; 
      "Float &2","xset_float2","","",""; 
      "Float &3","xset_float3","","",""; 
   }
   "Save app layout","xsave_named_toolwindow_layout","","",""; 
   "Restore app layout","xload_named_toolwindow_layout","","",""; 
   "Save session","save_named_state","","",""; 
   "Restore session","load_named_state","","",""; 
   "--","","","","";

   submenu "&Bookmarks","","","" {
      "&Save bookmarks","xsave_bookmarks","","",""; 
      "&Restore bookmarks","xrestore_bookmarks","","",""; 
      "Save bookmarks and clear","xsave_and_clear_bookmarks","","",""; 
      "Clear and restore bookmarks","xclear_and_restore_bookmarks","","",""; 
   }

   submenu "Complete","","","" {
      "complete-prev-no-dup","complete_prev_no_dup","","","";
      "complete-next-no-dup","complete_next_no_dup","","","";
      "complete-prev","complete_prev","","","";
      "complete-next","complete_next","","","";
      "complete-list","complete_list","","","";
      "complete-more","complete_more","","","";
   }

   submenu "Select / Hide","","","" {
      "select code block","select_code_block","","","";
      "select paren","select_paren_block","","","";
      "select procedure", "select_proc", "","","";
      "hide code block","hide_code_block","","","";
      "hide selection","hide_selection","","","";
      "hide comments","hide_all_comments","","","";
      "show all","show-all","","","";
   }

   submenu "Open / E&xplore","","open-file or explore folder","" {
      "Open from here","xopen_from_here","","","open from current buffer path";
      "Open from config","xopen_from_config","","","open file from configuration folder";
      "Open vsstack error file","xopvss","","","Open Slick C error file";
      "-","","","","";
      "Explore current buffer","explore_cur_buffer","","","explore folder of current buffer";
      "Explore config folder","explore_config","","",""; 
      "Explore installation folder", "explore_vslick","","",""; 
      "Explore docs","explore_docs","","",""; 
      "Explore project","explore_vpj","","","";
   }

   submenu "&Case conversion","","","" {
      "&Lowcase selection","lowcase-selection","","","";
      "&Upcase selection","upcase-selection","","","";
      "Lowcase word","lowcase-word","","","";
      "Upcase word","upcase-word","","","";
      "Upcase &char","xupcase-char","","","";
      "Lowcase &char","xlowcase-char","","","";
      "Cap &selection","cap-selection", "","","";
   }

   submenu "Extra","","","" {
      "Float window","my_float_window","","","";
      "Decrease font size","decrease-font-size","","","";
      "Increase font size","increase-font-size","","","";
      "Toggle font","toggle-font","","","";
      "Save all","save-all-inhibit-buf-history","","","";
      "-","","","","";
      "&1 Function comment", "func-comment","","","";
      "&2 Save bookmarks", "xsave_bookmarks","","","";
      "&3 Restore bookmarks", "xrestore_bookmarks","","","";


   }

}



_command show_xmenu2() name_info(',')
{
   mou_show_menu('xmenu2');
}



_command void my_float_window() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   hsplit_window();
   float_window();
   //applyLayout("gp1");
   //mdisetfocus();
   //activate_files();
   //zoom_window();
}


_command void force_load(_str fn = '') name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( fn != '' ) {
      edit(fn);
   }
   _save_file('+o');
   load(fn);
}

_command void xnotepad_create_time_date_string() name_info(',')
{
   xnotepad(false, stranslate(_date('I'),'-','/') :+ '-' :+ stranslate(_time('M'), '-', ':'));  
}


//_command gui_save_config(_str save_immediate='') name_info(','VSARG2_EDITORCTL)
//{
//   int status=_promptSaveConfig();
//   if (status!=1) {
//      return(status);
//   }
//   status = (save_config(save_immediate));
//
//   if ( status == 0 ) {
//      result = _message_box("Export all options?", '', IDYES|IDNO|MB_ICONQUESTION,IDNO);
//      if ( result != IDYES ) {
//         return 0;
//      }
//      _mdi.export_options('-a  C:\SlickConfig\save-config\V23-' :+ stranslate(_date('I'),'-','/') :+ '-' :+ 
//                                                                   stranslate(_time('M'), '-', ':') :+ '.zip');
//   }
//   return status;
//}



_command void my_gui_find() name_info(',')
{
   gui_find();
}



_command void collapse_case() name_info(',')
{
   typeless p1,p2;
   int k1, k2;
   _save_pos2(p1);
   if ( search("^ #case", "RI?") == 0) {
      _deselect();
      _begin_line();
      if ( down() == 0 ) {
         k1 = p_line;
         if ( search("^ #case", "RI?") == 0) {
            _deselect();
            if ( k1 < p_line ) {
               k2 = p_line;
               p_line  = k1;
               say(k2 - k1);
               _begin_line();
               _select_char('','E');
               cursor_down(k2 - k1);
               select_it("CHAR",'','E');
               hide_selection();
               _deselect();
               return;
            }
         }
      }
   }
   _restore_pos2(p1);
}
