

#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)


boolean check_slick_version(_str ver)
{
   return pos(ver, _getVersion(false)) != 0;
}

boolean check_slick_version2(_str ver)
{
   return pos(ver, get_env('VSROOT'), 1, 'I') != 0;
}


_command void   ffff() name_info(',')
{
   say(check_slick_version2('SLICKEDITV19'));    
   say(check_slick_version2('slickeditv19'));   
   say(check_slick_version2('slickeditv18'));    
   say(_getVersion(false));
   say(check_slick_version('19.0.1'));
}

/*
        QT73
        KJ52
        QJ8
        42
85             962
87             A964
AK732          94
KJT5           Q876
        AKJ4
        QT3
        T65
        A93



*/



// aaaaaaaaaaaaaa
// bbb 
// ccc 

// aaaaaaaaaaaaab
// bbb 

// ccc 




// ab#cdeg

//_command void find_symbol_word_at_cursor() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
//{
//   int xx;
//   _control ctl_search_for;
//   _str s = cur_word(xx);
//   int wid = activate_tool_window('_tbfind_symbol_form', true, 'ctl_search_for');
//   wid.ctl_search_for.p_text = s;
//   wid.ctl_search_for._set_sel(1,length(s)+1);
//}
//
//
//_command void find_symbol_in_current_file() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
//{
//   int xx;
//   _control ctl_search_for;
//   _control ctl_lookin;
//   int wid = activate_tool_window('_tbfind_symbol_form', true, 'ctl_search_for');
//   wid.ctl_lookin.p_text = '<Current File>';
//   //wid.ctl_search_for.p_text = '';
//   //wid.ctl_search_for._set_sel(1,1);
//}





#if 0
static int timer_handle1;
static _str filename_to_check;
static boolean was_it_found;

int check_buffername()
{
   if (p_buf_name == filename_to_check) {
      was_it_found = true;
   }
   return 0;
}

static void check_buffer_still_open_timer_callback()
{
   was_it_found = false;
   for_each_buffer('check_buffername');
   if (!was_it_found) {
      //_message_box("not found");
      //_kill_timer(timer_handle1);
      safe_exit();
   }
}

_command void dashr(_str s1='default') name_info(',')
{
   if (!file_exists(s1)) {
      safe_exit();
      return;
   }
   edit(s1);
   filename_to_check = s1;
   timer_handle1 = _set_timer(1000,check_buffer_still_open_timer_callback);
}


#endif




//void _prjconfig_switch_usercpp()
//{
//   switch(_project_name)
//   {
//       case "proj1" :
//          switch (getActiveProjectConfig())
//          {
//             case "debug" :
//                file_copy(proj1-debug-usercpp.h, usercpp.h);
//                message("proj1-debug-usercpp.h selected");
//                return;
//          }
//   }
//}







#if 0
defeventtab _tbfilelist_form;

int def_filestb_single_click_mode;

void ctl_file_list.lbutton_double_click()
{
   if (def_filestb_single_click_mode == 0)
      call_event(p_window_id,ENTER);
}

void ctl_file_list.lbutton_up()
{
   if (def_filestb_single_click_mode == 0 || _IsKeyDown(CTRL) || _IsKeyDown(SHIFT))
      return;
   call_event(p_window_id,ENTER);
}

void ctl_file_list.mbutton_up()
{
   def_filestb_single_click_mode = (int)!def_filestb_single_click_mode;
   message("Single click mode = " :+ (def_filestb_single_click_mode ? "On" : "Off") );
}

#endif




#if 0


static _str ofiles[];

int _generate_nonWorkSpace_files()
{
   if (!_FileExistsInCurrentWorkspace(p_buf_name) && 
       length(p_buf_name)) ofiles[ofiles._length()] =p_buf_name;
   return 0;
}

_str _list_buffers_nonworkspace_callback(int reason,_str & result,_str key)
{
   _nocheck _control _sellistcombo;
   _nocheck _control _sellist;
   _nocheck _control _sellistok;

   _sellistok.p_default=1;
   _str fn;

   if (reason==SL_ONDEFAULT) {  // Enter key
      result=_sellist._lbget_text();
      return 1;
   }

   if (reason == SL_ONUSERBUTTON) {
      if (key == 3) {
         // close buffer button
         int orig_wid = p_window_id;
         start_again :
         while (1) {
            if (_sellist._lbfind_selected(1))
               break;
            fn = _sellist._lbget_text();
            _sellist._delete_line();
            _save_non_active(fn, true);
            continue start_again;
         }
         p_window_id = orig_wid;
         return 1;
      } else if (key==4) { // close all clicked or shortcut pressed
         result='c';
         return result; // this will close it dialog
      }
   }
   return '';
}


_command void list_buffers_nonworkspace() name_info(',')
{
   ofiles._makeempty();
   for_each_buffer('_generate_nonWorkSpace_files');
   _str buttons = '&Select,&Close Buffer,Close &All';
   typeless result=show("-modal -xy _sellist_form",
                        "Non workspace related buffers",
                        SL_SIZABLE|SL_DEFAULTCALLBACK|SL_ALLOWMULTISELECT,
                        ofiles,
                        buttons,
                        '',
                        '',
                        '_list_buffers_nonworkspace_callback',
                        '',
                        'list_ofiles',
                        '','','',0);
   if (result=='c') close_buffers_nonworkspace();
   else if (length(result)>1)  edit(maybe_quote_filename(result));
   ofiles._makeempty();

}

_command void close_buffers_nonworkspace() name_info(',')
{
   typeless status=0;
   int first_buf_id=p_buf_id;
   for (;;) {
      _next_buffer('HNR');
      int buf_id=p_buf_id;
      if ( ! (p_buf_flags & VSBUFFLAG_HIDDEN) ) {
         if (!_FileExistsInCurrentWorkspace(p_buf_name))
            close_buffer(true);
         // _save_non_active(maybe_quote_filename(p_buf_name),true);
         status=rc;
      }
      if ( buf_id== first_buf_id ) {
         break;                      
      }

   }
}

#endif




#if 0
_command void show_attrib() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _str attrs = file_list_field(p_buf_name, DIR_ATTR_COL, DIR_ATTR_WIDTH);
   message(attrs :+ '  :  ' :+ p_buf_name);
}

static _str ofiles[];

int generate_ofiles()
{
   _str attrs = file_list_field(p_buf_name, DIR_ATTR_COL, DIR_ATTR_WIDTH);

   if (!_FileExistsInCurrentWorkspace(p_buf_name)) {
      // ofiles[ofiles._length()] = attrs :+ '  ' :+ strip_filename(p_buf_name,'p') :+
      //                     '  ' :+ strip_filename(p_buf_name,'n');
      ofiles[ofiles._length()] = p_buf_name;
   }
   return 0;
}

_str list_ofiles_callback(int reason,_str & result,_str key)
{
   _nocheck _control _sellistcombo;
   _nocheck _control _sellist;
   _nocheck _control _sellistok;
   _str fn;
   if (reason==SL_ONDEFAULT) {  // Enter key
      return 1;
   }
   if (reason == SL_ONUSERBUTTON) {
      if (key == 3) {
         // close buffer button
         int orig_wid = p_window_id;
         start_again :
         while (1) {
            if (_sellist._lbfind_selected(1))
               break;
            fn = _sellist._lbget_text();
            _sellist._delete_line();
            _save_non_active(fn, true);
            continue start_again;
            //status=_sellist._lbfind_selected(0);
         }
         p_window_id = orig_wid;
      }
   }
   return '';
}



_command void list_ofiles() name_info(',')
{
   ofiles._makeempty();
   for_each_buffer('generate_ofiles');

   _str buttons = 'b1,Close buffer,b3';
   typeless result=show("-modal -xy _sellist_form",
                        "Open buffers",
                        SL_COMBO|SL_SIZABLE|SL_DEFAULTCALLBACK|SL_ALLOWMULTISELECT,
                        ofiles,
                        buttons,
                        '',
                        '',
                        'list_ofiles_callback',
                        '',
                        'list_ofiles',
                        '','','',0);

   ofiles._makeempty();
   message(result);
}


#endif


#if 0
// option hello you

_command void gg1() name_info(',')
{
   int xx = find_index('xretrace.ex',MODULE_TYPE);
   if (xx != 0) {
      _message_box(name_name(xx));
      _message_box(name_info(xx));
   }
}

// see _get_grep_buffer_id
static int my_get_grep_buffer_id(int how)
{
   if (how == -1) {
      return add_new_grep_buffer();
   } else if (how == -2) {
      return auto_increment_grep_buffer();
   } else {
      return how;
   }
}


//   mark_all_occurences('mark_all','IH?','0','0','1','0','1','0');


_command void process_search_results() name_info(',')
{
   //add_grep_buffer();
   //activate_search(); 
   set_grep_buffer(my_get_grep_buffer_id(-1), '');

   //message(_get_grep_buffer_view());
   //mark_all_occurences('','',VSSEARCHRANGE_CURRENT_BUFFER,0,0,false,true,false);
   //#if 0
   _str bufname = _get_grep_buffer_view().p_buf_name;
   _str id;
   parse bufname with '.search' id;
   if (id <= _get_last_grep_buffer()) {
      int temp_view_id;
      int orig_wid = _find_or_create_temp_view(temp_view_id, '', bufname, 
                                               false, VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN|VSBUFFLAG_KEEP_ON_QUIT);
      if (p_buf_name == bufname) {
         delete_all(); 
         if (get("c:/temp/results.txt") == 0) {
            activate_search();
         } else {
            _message_box("Failed to read file c:/temp/results.txt");
         }
      }
   }
   //#endif
}


_command MyGrep() name_info(',')
{ // bind to Control-G
   _str pattern;
   int col;
   if (get_string(pattern,"RemoteFGrep Pattern:",'',cur_word(col)) != 0)
      return '';
   if (pattern == "") return '';

   // extra options to pass to the remote program
   // Currently supports i for ignore case
   // all other options are filters on the list of files to search
   static _str lastopts;
   _str opts;
   if (get_string(opts,"RemoteFGrep Options:",'',lastopts) != 0)
      return '';
   lastopts = opts;

   // http://community.slickedit.com/index.php?topic=5452.0

   _str cmd = "ssh myth /home/arcamax/bin/slickeditremote cmd='grep" :+
              "' pattern='" :+ pattern :+
              "' options='" :+ opts :+
              "' outpath='M:/ln.arcamax'" :+
              " > ~/remotefgrep.out";
   shell(cmd, "QPN");

   set_grep_buffer(my_get_grep_buffer_id(-1), '');
   _str bufname = _get_grep_buffer_view().p_buf_name;

   _str id;
   parse bufname with '.search' id;
   if (id <= _get_last_grep_buffer()) {
      int temp_view_id;
      int orig_wid = _find_or_create_temp_view(temp_view_id, '', bufname, 
                                               false, VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN|VSBUFFLAG_KEEP_ON_QUIT);
      delete_all(); 
      if (get("M:/remotefgrep.out") == 0)
         activate_search();
      else
         _message_box("Failed to read file M:/remotefgrep.out");
   }
}



#endif


// 1 2 3 4 5

// 1 2 3 

#if 0

   #define UNDO_BACKUP_FOLDER 'C:/temp'

// non static allows inspection with set-var
_str my_normal_backup_folder;
int x_redo_timer_handle;
int x_undo_timer_handle;
int x_undo_holdoff_counter;
int x_redo_holdoff_counter;

/**
 * Writes current buffer to filename.  This function is a hook function 
 * that the user may replace.  Options allowed by <b>_save_file</b> 
 * built-in may be specified.
 * @param filename parameter should not contain options.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories File_Functions
 * 
 */
_str save_file(_str filename,_str options)
{
   boolean was_undo = false;
   // the following 3 lines are added to handle x_redo
   _str vb = get_env('VSLICKBACKUP');
   if (vb == UNDO_BACKUP_FOLDER) {
      set_env('VSLICKBACKUP', my_normal_backup_folder );
      was_undo = true;
   }
   say(vb);

   typeless status=_save_file(options " "filename);
   if (!status && file_eq(strip(filename,'B','"'),p_buf_name)) {
      call_list('_cbsave_');
      if (def_autotag_flags2&AUTOTAG_ON_SAVE) {
         TagFileOnSave();
      }
   }
   if (was_undo && _tbIsVisible('_tbdeltasave_form')) {
      set_env('VSLICKBACKUP', UNDO_BACKUP_FOLDER );
   }
   return(status);
}


static int x_redo_holdoff_counter;

void x_redo_timer_callback(boolean force_normal = false)
{
   if (x_redo_holdoff_counter > 0) {
      say(' kk4 ' :+ x_redo_holdoff_counter);
      --x_redo_holdoff_counter;
      return;
   }
   _str vb = get_env('VSLICKBACKUP');
   if (vb != UNDO_BACKUP_FOLDER) {
      _kill_timer(x_redo_timer_handle);
      _cbsave_BackupHistory();  // force refresh
      return;
   }
   if (!_tbIsVisible('_tbdeltasave_form') || force_normal) {
      say(' kk5 ' :+ x_undo_holdoff_counter);
      set_env('VSLICKBACKUP', my_normal_backup_folder );
      _kill_timer(x_redo_timer_handle);
//    int wid = _find_formobj("_tbdeltasave_form", 'n');
//    if (wid) {
//       wid.p_caption = 'Backup History';
//    }
      _cbsave_BackupHistory();  // force refresh
      return;
   }
}



void x_undo_timer_callback()
{
   say(' kk1 ' :+ x_undo_holdoff_counter);
   if (--x_undo_holdoff_counter <= 0) {
      _kill_timer(x_undo_timer_handle);
   }
}


_command void x_undo() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX/*|VSARG2_NOEXIT_SCROLL*/)
{
   if (x_undo_holdoff_counter > 0) {
      x_undo_holdoff_counter = 10; // seconds
      undo();
      x_redo_timer_callback(true);
      say(' kk2 ' :+ x_undo_holdoff_counter);
      return;
   }
   x_undo_holdoff_counter = 10; // seconds
   say(' kk3 ' :+ x_undo_holdoff_counter);
   set_env('VSLICKBACKUP', UNDO_BACKUP_FOLDER );
   _save_file(p_buf_name :+ ' -O +DD -Z -ZR -E -S -L ');
   set_env('VSLICKBACKUP', my_normal_backup_folder );
   undo();
   undo();
   x_undo_timer_handle = _set_timer(1000,x_undo_timer_callback);
   x_redo_timer_callback(true);
}


_command void x_redo() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   _control ctl_BH_comment_note2;
   x_redo_holdoff_counter = 2;
   if (redo() == NOTHING_TO_REDO_RC) {
      set_env('VSLICKBACKUP', UNDO_BACKUP_FOLDER );
      activate_deltasave();
      _cbsave_BackupHistory();  // force refresh
      x_redo_timer_handle = _set_timer(500,x_redo_timer_callback);
      int wid = _find_formobj("_tbdeltasave_form", 'n');
      if (wid) {
         //wid.p_caption = 'Backup History $$$$$  UNDO  $$$$$';
         wid.ctl_BH_comment_note2.p_text = 
         '<FONT face="Helvetica" size="2"><b>$$$ UNDO HISTORY $$$</b><br>PATH: ' :+ UNDO_BACKUP_FOLDER ;
      }
   }
}


// 1 2 

// 1 2 3
// 1 2 
// 1 2 3

definit ()
{
   if (arg(1)!="L") {
      my_normal_backup_folder = get_env('VSLICKBACKUP');
   }
   x_undo_holdoff_counter = 0;
   x_redo_holdoff_counter = 0;
}

defeventtab _tbdeltasave_form;
void ctl_BH_comment_note2.lbutton_down()
{
   _str vb = get_env('VSLICKBACKUP');
   if (vb != UNDO_BACKUP_FOLDER) {
      set_env('VSLICKBACKUP', UNDO_BACKUP_FOLDER );
      _cbsave_BackupHistory();  // force refresh
      int wid = _find_formobj("_tbdeltasave_form", 'n');
      if (wid) {
         //wid.p_caption = 'Backup History $$$$$  UNDO  $$$$$';
         wid.ctl_BH_comment_note2.p_text = 
         '<FONT face="Helvetica" size="2"><b>$$$ UNDO HISTORY $$$</b><br>PATH: ' :+ 
         UNDO_BACKUP_FOLDER :+ '<br>Left click here to swap' ;
      }
   } else {
      set_env('VSLICKBACKUP', my_normal_backup_folder );
      _cbsave_BackupHistory();  // force refresh
   }
}


#endif



#if 0

_command void new_file_from_template(_str fn = '') name_info(',')
{
   _str pt = strip_filename(fn,'N');
   _str nm = strip_filename(fn,'P');

   if (fn=='') {
      return;
   }
   switch (get_extension(fn)) {
   default:
      edit(fn);
      return;
   case 'h' :
      add_item('%VSROOT%sysconfig\templates\ItemTemplates\C++\Class\Header\Header.setemplate',
               fn,pt,'0','0','0');
      return;
   case 'c' :
      add_item('%VSROOT%sysconfig\templates\ItemTemplates\C++\Application\Main\Main.setemplate',
               fn,pt,'0','0','0');
      return;
   }
}



_command void myspell() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   int ecol;
   typeless ddd;
   _save_pos2(ddd);
   next_word();
   prev_word();
   _str s1 = cur_word(ecol);
   _str s2='';
   _str s3='';
   int res = _spell_check(s3,s2,ecol,s1);
   if (res == SPELL_NO_MORE_WORDS_RC || res == SPELL_REPEATED_WORD_RC) {
      message(s1 :+ '  spelling checked');
      _restore_pos2(ddd);
   } else
      spell_check_word();
}


_command void show_attrib() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _str attrs = file_list_field(p_buf_name, DIR_ATTR_COL, DIR_ATTR_WIDTH);
   message(attrs :+ '  :  ' :+ p_buf_name);
}

static _str ofiles[];

int generate_ofiles()
{
   _str attrs = file_list_field(p_buf_name, DIR_ATTR_COL, DIR_ATTR_WIDTH);
   ofiles[ofiles._length()] = attrs :+ '  ' :+ strip_filename(p_buf_name,'p') :+
                              '  ' :+ strip_filename(p_buf_name,'n');
   return 0;
}

void gp_callback(typeless sss)
{
   say(sss);
}


_command void list_ofiles() name_info(',')
{
   ofiles._makeempty();
   for_each_buffer('generate_ofiles');

   typeless result=show("-modal -xy _sellist_form","Open buffers",SL_COMBO|SL_SIZABLE|SL_ALLOWMULTISELECT,ofiles,'','','','gp_callback','',
                        'list_ofiles','','','',7);
   //say(result);
   ofiles._makeempty();
}

#endif


#if 0

static int gcode_round_places = 2;
static boolean gcode_round_prompt = true;

_command void gcode_round(_str options = '')
{
   if ((last_index('','w') && options == '') || pos(options,'h')) {
      message('Option n to select dec. places; p to prompt; x to not prompt'); 
      return;
   }

   if (pos(options,'n')) {
      _str x1 = prompt('','Enter number of places ',gcode_round_places);
      if (isinteger(x1)) {
         gcode_round_places = (int)x1;
      }
   }

   if (pos(options,'p'))
      gcode_round_prompt = true;

   if (pos(options,'x'))
      gcode_round_prompt = false;

   if (search('[0-9\.]#|$','<R?') == 0) {
      _str tx = get_match_text();
      if (length(tx) > 1) {
         replace(tx,round(tx,gcode_round_places), gcode_round_prompt?'':'*');
      }
   }
}


_command void show_attrib() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _str attrs = file_list_field(p_buf_name, DIR_ATTR_COL, DIR_ATTR_WIDTH);
   message(attrs :+ '  :  ' :+ p_buf_name);
}

static _str ofiles[];

int generate_ofiles()
{
   _str attrs = file_list_field(p_buf_name, DIR_ATTR_COL, DIR_ATTR_WIDTH);
   ofiles[ofiles._length()] = attrs :+ '  ' :+ strip_filename(p_buf_name,'p') :+
                              '  ' :+ strip_filename(p_buf_name,'n');
   return 0;
}

_command void list_ofiles() name_info(',')
{
   for_each_buffer('generate_ofiles');

   typeless result=show("-modal _sellist_form","Open buffers",SL_COMBO|SL_SIZABLE,ofiles);

   // this ought to work but doesn't ????????????????????????????
   // typeless result=show("-modal _sellist_form","Open buffers",SL_COMBO|SL_SIZABLE,ofiles,'','','','',
   //'list_ofiles','','',strip_filename(p_buf_name,'P'),7);

   ofiles._makeempty();
}




// zzz

_command void my_set_bookmark() name_info(',')
{
   set_bookmark(get_bookmark_name());
   double aaa = 234.4546;
}



defeventtab _tbfind_form;

void _tbfind_form.'C-F12'()
{
   _control _findfiles;
   int wid = _find_formobj('_tbfind_form');
   if (wid) {
      message('yes');
      wid._findfiles._delete_retrieve_list('_tbfind_form._findfiles');
   }
}

#endif

#if 0
_command void ms1() name_info(',')
{
   activate_preview();
   if (_tbIsVisible('_tbtagwin_form') <= 0) {
      toggle_preview();
   }
   find_in_files();
   //activate_search();
}

_command void ms2() name_info(',')
{
   //find_in_files();
   if (_tbIsVisible('_tbtagwin_form') <= 0) {
      toggle_preview();
   }
   if (_tbIsVisible('_tbsearch_form') <= 0) {
      toggle_preview();
   }
   //_str focus_ctl = _get_active_grep_view();
   //_tbToggleTabGroupToolbar('_tbsearch_form',focus_ctl);
}

_command void ms3() name_info(',')
{
   //find_in_files();
// if (_tbIsVisible('_tbtagwin_form') > 0)
// {
//    toggle_preview();
// }
// if (_tbIsVisible('_tbsearch_form') > 0)
// {
//    toggle_preview();
// }
   //_str focus_ctl = _get_active_grep_view();
   //_tbToggleTabGroupToolbar('_tbsearch_form',focus_ctl);

   tbSmartShow('_tbtagwin_form');
   //tbSmartShow('_tbsearch_form');
   find_in_files();
}

_command void ms4() name_info(',')
{
   int k = _find_formobj('_tbtagwin_form');
   if (k > 0) {
      tbClose(k);
   }
   k = _find_formobj('_tbsearch_form');
   if (k > 0) {
      tbClose(k);
   }
}

_command void grep_my_enter() name_info(','VSARG2_REQUIRES_EDITORCTL) // |VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   grep_enter();
   ms4();
   //_message_box('hiiii');
}

_command toggle_highlight_matching_symbols() name_info(','VSARG2_MACRO|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _str ext = _Filename2LangId(_mdi.p_child.p_buf_name);
   _SetLanguageOption(ext,'codehelp',_GetCodehelpFlags(ext) ^ VSCODEHELPFLAG_HIGHLIGHT_TAGS);
   typeless p;
   save_pos(p);
   next_word();
   _UpdateContextHighlights(true);
   prev_word();
   _UpdateContextHighlights(true);
   restore_pos(p);
   _UpdateContextHighlights(true);
}


_command Gets() name_info(','VSARG2_MACRO|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int k;
   typeless p;
   save_pos(p);
   _str s = cur_word(k);
   if (s != '') {
      top();
      if (find(s) == 0)
         return 0;
   }
   restore_pos(p);   
   message(s :+ '  string not found');
   return -1;
}



static int cursor_left_with_line_wrap()
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
   } else
      left();

   if (line == p_line && col == p_col) {
      return -1;
   }
   return 0;
}

static int cursor_right_with_line_wrap()
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
   } else
      right();

   if (line == p_line && col == p_col) {
      return -1;
   }
   return 0;
}

_command void select_string() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   typeless mypos;
   save_pos(mypos);
   if (_in_string()) {
      // find the start of the string
      while (_in_string()) {
         if (cursor_left_with_line_wrap()) {
            break;
         }
      }
      if (!_in_string())
         cursor_right_with_line_wrap();
   } else {
      // find first string on the line
      _begin_line();
      while (!_in_string()) {
         if (cursor_right_with_line_wrap()) {
            restore_pos(mypos);
            return;
         }
      }
   }
   // move off the leading quote
   cursor_right_with_line_wrap();
   _select_char();
   while (_in_string()) {
      if (cursor_right_with_line_wrap()) {
         break;
      }
   }
   cursor_left_with_line_wrap();
   _select_char();
   restore_pos(mypos);
}



#endif


#if 0



#endif








