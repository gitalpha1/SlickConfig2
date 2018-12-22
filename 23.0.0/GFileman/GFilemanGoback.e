


#include "slick.sh"

#import '..\my-macros\dlinklist.e'



#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)




struct buffer_item_s {
    int buf_id;
};



// goback_buffer_list is the linked list that holds the list of buffer IDs
static dlist goback_buffer_list;


// buffer_validate_list is an array that is populated by for_each_buffer and is used to
// validate the buffer IDs in goback_buffer_list
static int buffer_validate_list [];
static int buffer_validate_list_num_buffers;


// suspend_goback_buffer_history is set true to stop the _switchbuf callback
// from executing.  It can be set/cleared by the goback_toggle_buffer_list_history_enable()
// command and is temporarily set true by goback_step_thru_buffer_list
static boolean suspend_goback_buffer_history;

static boolean goback_buffer_pending_flag;
static int goback_buffer_pending_buf_id;
static boolean goback_buf_id_is_pending;

static int goback_buffer_list_array[];


static int switchbuf_goback_no_re_entry;


static void move_buf_id_to_front(int buf_id)
{
   dlist_iterator iter = dlist_iterator_new(goback_buffer_list);
   while (dlist_next(iter)) {
      buffer_item_s * gip = dlist_getp(iter);
      if (gip->buf_id == buf_id) {
         dlist_move_to_front(iter);
         return;
      }
   }
   buffer_item_s it;
   it.buf_id = buf_id;
   dlist_push_front(goback_buffer_list, it);
}


// goback_buffer_for_each_buf_list1() is called by for_each_buffer()
// for_each_buffer steps thru visible buffers from "oldest" to
// most recently accessed
int goback_buffer_for_each_buf_list1()
{
    buffer_validate_list[buffer_validate_list_num_buffers++] = p_buf_id;
    return 0;
}


// The list of buf_ids in goback_buffer_list is validated by using
// for_each_buffer to get a list of current buf_ids.  buf_ids that no longer
// exist are removed from goback_buffer_list.
static void validate_goback_buffer_list()
{
    buffer_validate_list_num_buffers = 0;
    _mdi.p_child.for_each_buffer( 'goback_buffer_for_each_buf_list1' );

    dlist_iterator iter = dlist_iterator_new(goback_buffer_list);
    dlist_iterator iter2 = iter;
    while (dlist_next(iter)) {
       buffer_item_s * gip = dlist_getp(iter);
       int bufid = gip->buf_id;
       int x1;
       for (x1 = buffer_validate_list_num_buffers - 1; x1 >= 0; --x1) {
           if (bufid == buffer_validate_list[x1])
               break;
       }
       if (x1 < 0) {
          // not found so remove
          dlist_erase(iter);
          iter = iter2;
       }
       else {
          iter2 = iter;
       }
    }
}


static void switchbuf_goback_buffer_list()
{
   static int last_buf_id, buf_id;
   // buf_id = _mdi.p_child.p_buf_id;
   buf_id = p_buf_id;
   if (last_buf_id == buf_id) {
      return;
   }
   last_buf_id = buf_id;

   if (!suspend_goback_buffer_history) {
      if (_mdi.p_child.p_buf_flags & HIDE_BUFFER) {
         return;
      }
      if (pos('.',_mdi.p_child.p_buf_name) == 1) {
         return;
      }
      /************************************************************************
      _str this_buffer = _mdi.p_child.p_buf_name;

      if (this_buffer == '') {
         return;
      }
      if (this_buffer == '.command') {
         return;
      }
      if (this_buffer == '.process') {
         return;
      }
      if (this_buffer == '.slickc_stack') {
         return;
      }
      if (this_buffer == '.References Window Buffer') {
         return;
      }
      if (this_buffer == '.Tag Window Buffer') {
         return;
      }
      ************************************************************************/

      if (goback_buffer_pending_flag) {
         goback_buffer_pending_flag = false;
         goback_buf_id_is_pending = true;
         goback_buffer_pending_buf_id = buf_id;
      } else {
         if (goback_buf_id_is_pending) {
            if (goback_buffer_pending_buf_id == buf_id)
               return;
            goback_buf_id_is_pending = false;
            move_buf_id_to_front(goback_buffer_pending_buf_id);
         }
         move_buf_id_to_front(buf_id);
      }
   }
}


// Functions that start with _switchbuf_ get called via call_list when a new
// buffer becomes active.
void _switchbuf_goback_buffer()
{
   // This code protects against re-entry but its main job is to avoid calling
   // the switchbuf_goback_buffer_list() function if the last call didn't exit
   // normally.  This avoids getting repeated "slick C stacks" that could make
   // the editor unusable.
   if (switchbuf_goback_no_re_entry > 0) {
      return;
   }
   ++switchbuf_goback_no_re_entry;
   if (switchbuf_goback_no_re_entry == 1) {
      switchbuf_goback_buffer_list();
   }
   --switchbuf_goback_no_re_entry;
}



/*****************************************************************************
int callback_gb1(int cmd, dlist_iterator & it)
{
   if (cmd == LIST_CALLBACK_PROCESS_ITEM) {
      message('List item ' :+ ((buffer_item_s*)dlist_getp(it))->buf_id :+
                 ' Pos ' :+ dlist_get_distance(it));
   }
   return 0;
}

_command void show_goback() name_info(',')
{
   dlist_iterate_list(goback_buffer_list, 'callback_gb1');
}
******************************************************************************/


void goback_set_buffer_history_pending_mode()
{
    goback_buffer_pending_flag = true;
}


void goback_process_pending_buffer_history()
{
    if (!suspend_goback_buffer_history)
    {
        if (goback_buf_id_is_pending) {
            move_buf_id_to_front(goback_buffer_pending_buf_id);
        }
    }
    goback_buf_id_is_pending = false;
    goback_buffer_pending_flag = false;
}


void goback_build_buffer_list_array(int (&blist)[])
{
    blist._makeempty();
    dlist_iterator iter = dlist_iterator_new(goback_buffer_list);
    while (dlist_next(iter)) {
       buffer_item_s * gip = dlist_getp(iter);
       blist[blist._length()] =  gip->buf_id;
    }
}



// goback_step_thru_buffer_list steps through the buffers recently visited.
//    F12 cycles the two most recent buffers
//    C-F12 cycles 3 most recent buffers
//    Numeric keys (n) 1 - 9 cycle that number with immediate jump to buffer n
//    Up, down, left, right cycle the full list
//    ESC exits
//    Any other key exits and is currently ignored - if you want such keys to
//    be processed, uncomment the call to call_key.
//
// if parameter cmode is true, the previous buffer is switched to, with immediate exit
_command void goback_step_thru_buffer_list(boolean cmode = false)
{
   if (suspend_goback_buffer_history)
      return;

   // pos of zero is first buffer in the list
   // on entry, go to the second buffer in the list

   int lmpos = 1,mpos = 1,cpos = 1;
   _str keyt = '';
   typeless key;
   boolean direction = true;

   if (_Nofbuffers() <= 1)
      return;

   validate_goback_buffer_list();
   goback_build_buffer_list_array(goback_buffer_list_array);
   if (goback_buffer_list_array._length() == 0)
      return;

   suspend_goback_buffer_history = true;

   for (;;)
   {
      if (cpos >= goback_buffer_list_array._length()) {
         cpos = 0;
         mpos = lmpos = goback_buffer_list_array._length()-1;
      }

      if (cmode) {
         suspend_goback_buffer_history = false;
         if (cpos >= goback_buffer_list_array._length())
             cpos = 0;
         p_buf_id = goback_buffer_list_array[cpos];
         edit(p_buf_name);
         return;
      }

      if (cpos >= goback_buffer_list_array._length())
          cpos = 0;
      p_buf_id = goback_buffer_list_array[cpos];
      message('Posn  ' :+ (cpos+1) :+ '    ' :+ strip_filename(p_buf_name,'D''P'));

      key = get_event('N');   // refresh screen and get a key
      keyt = event2name(key);
      direction = true;
      switch (keyt) {
         case 'F12' :
            mpos = 1;
            break;
         case 'C-F12' :
            mpos = 2;
            break;

         case 'UP' :
         case 'LEFT' :
            direction = false;
         case 'RIGHT' :
         case 'DOWN' :
            mpos = lmpos = goback_buffer_list_array._length()-1;
            break;

         case '1' :
         case '2' :
         case '3' :
         case '4' :
         case '5' :
         case '6' :
         case '7' :
         case '8' :
         case '9' :
            mpos = (int)key - 1;
            break;

         case 'ESC' :
            suspend_goback_buffer_history = false;
            edit(p_buf_name);
            message(strip_filename(p_buf_name,'D''P'));
            return;

         default:
            suspend_goback_buffer_history = false;
            edit(p_buf_name);
            message(strip_filename(p_buf_name,'D''P'));
            //if (length(keyt)==1) {
            //   call_key(key);
            //}
            return;
      }

      if (lmpos != mpos) {
         // change of key, go straight to new pos
         cpos = lmpos = mpos;
      } else {
         // same key or special key, step one position
         if (direction) {
            if (cpos < mpos)
               ++cpos;
            else
               cpos = 0;
         } else {
            if (cpos > 0)
               --cpos;
            else
               cpos = mpos;
         }
      }
   }
}

// switch to the previous buffer
_command void goback_last_buffer()
{
    if (!suspend_goback_buffer_history)
        goback_step_thru_buffer_list(true);
    else
       message('buffer history is currently disabled');
}


_command void goback_toggle_buffer_list_history_enable(){
    if (suspend_goback_buffer_history)
    {
        suspend_goback_buffer_history = false;
        message('buffer history enabled');
    }
    else
    {
        suspend_goback_buffer_history = true;
        message('buffer history disabled');
    }
}


_command void goback_enable_buffer_list_history(){
    suspend_goback_buffer_history = false;
}


_command void goback_suspend_buffer_list_history(){
    suspend_goback_buffer_history = true;
}


/**
 * Goes to bookmark identified by a letter or number corresponding to the
 * key pressed which invoked this command.  This command may only be bound
 * to the keys Alt+0..Alt+9, Alt+A..Alt+Z, Ctrl+1..Ctrl+9, and Ctrl+A..Ctrl+Z.
 *
 * Unlike alt_gtbookmark, this function does a _switchbuf_goback_buffer_list call
 * to get the newly selected buffer to the top of the buffer-list history
 *
 * @appliesTo Edit_Window
 *
 * @see set_bookmark
 * @see goto_bookmark
 * @see next_bookmark
 * @see prev_bookmark
 * @see alt_bookmark
 * @see alt_gtbookmark
 * @categories Bookmark_Functions
 */
_command alt_gtbookmark_new() name_info(','VSARG2_LASTKEY|VSARG2_EDITORCTL)
{
    alt_gtbookmark();
    _switchbuf_goback_buffer();
}






#if 0


/******************************************************************************
*******************************************************************************
**            ***********************************************                **
**            *                                             *                **
**            *         The line goback mechanism.          *                **
**            *                                             *                **
**            ***********************************************                **
******************    ****    ****    ****    ****    ****    *****************
*******************************************************************************/


struct goback_item
{
   _str buf_name;
   int mid_line;
   int last_line;
   int col;
};


struct goback_list {
   _str     list_name;
   dlist   list;
};


//*****************************************************************************
// global variables
//*****************************************************************************
boolean goback_project_changed;

// set def_goback_persistent_history to non zero to get goback line history
// saved/restored to file on exit/startup
int def_goback_persistent_history;



//*****************************************************************************
// local variables
//*****************************************************************************

// There are always two active lists - list zero (the "global" list), plus the
// list corresponding to the active project.
static goback_list  goback_lists[];

static goback_list goback_modified_lines_list;

static boolean goback_region_modified_flag;
static int goback_modified_line;
static int goback_modified_col;

static int goback_active_list;
static boolean goback_use_line_modify_flag;


static int goback_buf_id;
static _str goback_buf_name;
static int goback_lower_line;
static int goback_upper_line;
static int goback_max_line_range;
static int goback_last_line;
static int goback_last_col;
static boolean goback_was_modified;

static boolean goback_history_disabled;
static int goback_switching_projects_counter;
static boolean goback_startup;
static int goback_no_re_entry = 0;
static int mcount = 0;


/*******************************************************************************
 *  remove_duplicate looks through the list to find an entry that has a mid-line
 *  within a certain distance of the newest entry in the list.  If found, the
 *  older entry is removed so that "go-back" doesn't step through the same
 *  location twice.
*******************************************************************************/
static void remove_duplicate(dlist & alist)
{
   goback_item * ip;
   dlist_iterator iter = dlist_begin(alist);
   goback_item * mp = dlist_getp(iter);

   _str strb = mp->buf_name;
   int mid_line = mp->mid_line;
   int dist = goback_max_line_range/2 + 1;

   while (dlist_next(iter)) {
      ip = dlist_getp(iter);
      if (abs(mid_line - ip->mid_line) < dist ){
         if (ip->buf_name == strb) {
            // stop looking when we find one, even though there might be more
            dlist_erase(iter);
            return;
         }
      }
   }
}


/*******************************************************************************
 *  add_new_goback_item updates the newest entry in the list with the supplied
 *  data, removes duplicates of it, then adds a new entry to the list which is
 *  initialized to the supplied values.  The new entry will be updated by the
 *  next call to this function.
*******************************************************************************/
static void add_new_goback_item(dlist & the_list,
                                boolean remove_dup,
                                _str bufname, int mid_line, int last_line, int col)
{
   goback_item item;
   if (dlist_is_empty(the_list)) {
      dlist_push_back(the_list, item);
   }
   // get a pointer to the data of the last item in the list and update it
   dlist_iterator it = dlist_end(the_list);
   goback_item * mp = dlist_getp(it);
   mp->buf_name = bufname;
   mp->mid_line = mid_line;
   mp->last_line = last_line;
   mp->col = col;
   if (remove_dup)
      remove_duplicate(the_list);
   // add the new location to the list - this will get updated when the cursor
   // moves out of range and a new item is added to the list
   item.buf_name = bufname;
   item.mid_line = mid_line;
   item.last_line = mid_line;
   item.col = col;
   dlist_push_back(the_list, item);
}


static void goback_update_list(dlist & the_list, boolean remove_dup = true)
{
   // update the active/last item in the list, then add a new entry to the list
   add_new_goback_item(
      the_list, remove_dup, goback_buf_name,
      goback_lower_line + ((goback_upper_line - goback_lower_line) >> 1),
      goback_last_line, goback_last_col);
}


// maintain_line_buffer_goback_history - is called from a timer callback
// re-entry protection isn't currently needed.
void maintain_line_buffer_goback_history()
{
   if (goback_no_re_entry > 0) {
      return;
   }
   ++goback_no_re_entry;
   if (goback_no_re_entry == 1) {
      maintain_line_buffer_goback_history2();
   }
   --goback_no_re_entry;
}


static boolean goback_undo_flag;
static int goback_undo_line_num;

_command goback_undo() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX/*|VSARG2_NOEXIT_SCROLL*/)
{
   goback_undo_flag = true;
   undo();
   goback_undo_line_num = _mdi.p_child.p_line;
}


static void maintain_line_buffer_goback_history2()
{
   static boolean not_this_buffer;
   if (_no_child_windows() || goback_history_disabled || (_get_focus() != _mdi.p_child)) 
      return;

   int line_now = _mdi.p_child.p_line;
   int col_now = _mdi.p_child.p_col;
       
   if (goback_use_line_modify_flag && _mdi.p_child._lineflags() & MODIFY_LF) 
   {
      if (goback_undo_flag) {
         // once undo has been used on a line, lineflags modify flag is left
         // set, because clearing it results in "fighting" with undo!
         if (goback_undo_line_num != line_now) {
            goback_undo_flag = false;
         }
      }
      else {
         // clear the line modify flag
         _mdi.p_child._lineflags(0, MODIFY_LF); 
      }
      goback_modified_col = col_now;
      if ((goback_modified_line == line_now) && goback_region_modified_flag) {
         if (++mcount & 7) 
            return;
         mcount = 0;  // every eighth time 
      }
      goback_region_modified_flag = true;
      goback_modified_line = line_now;
      //say('mod ' :+ goback_modified_line :+ ' ' :+ goback_modified_col :+ ' ' :+ goback_max_line_range :+ ' ' :+ goback_switching_projects_counter);
   }
   else if (goback_last_line == line_now) {
      // if the line number didn't change, the current buffer might have changed
      // so need to check every few times
      if (++mcount & 7) 
         return;
      mcount = 0;  // every eighth time 
   }
    
   if (goback_switching_projects_counter > 1) {
      --goback_switching_projects_counter;
      mcount = -1;
      return;
   }
   // if the buf_id changes, check if the new buffer is one we're not interested in
   if (not_this_buffer || (_mdi.p_child.p_buf_id != goback_buf_id)) {
      _str fn = strip_filename(_mdi.p_child.p_buf_name,'P');
      if (substr(strip_filename(_mdi.p_child.p_buf_name,'P'),1,4) == 'grep') {
         not_this_buffer = true;
         return;
      }
      if (strip_filename(_mdi.p_child.p_buf_name,'NE') == '') {
         not_this_buffer = true;
         return;
      }
      not_this_buffer = false;
   }
   if ((goback_switching_projects_counter == 0) &&
       (_mdi.p_child.p_buf_id == goback_buf_id) &&
       (_mdi.p_child.p_buf_name == goback_buf_name)) {

      // check whether the range of lines the cursor has traversed through 
      // exceeds the max range - if it does, it's time to make a new goback
      // entry and start a new region.
      // goback_last_line and goback_last_col are updated ONLY if the cursor
      // has stayed in the range  - if the cursor has gone outside the range,
      // then need to keep the previous values of goback_last_col/line until
      // they have been saved on the goback list.
      
      if (line_now < goback_lower_line) {
         if ((goback_upper_line - line_now) <= goback_max_line_range) {
            goback_last_line = goback_lower_line = line_now;
            goback_last_col = col_now;
            return;
         }
         // else gone outside range
      } else if (line_now > goback_upper_line) {
         if ((line_now - goback_lower_line) <= goback_max_line_range) {
            goback_last_line = goback_upper_line = line_now;
            goback_last_col = col_now;
            return;
         }
         // else gone outside range
      }
      else {
         // no change to lower or upper line
         goback_last_col = col_now;
         goback_last_line = line_now;
         return;  
      }
   }
   // add new item to the active lists
   if (goback_buf_name != '') {
      //say(' add ' :+ goback_last_line :+ ' ' :+ goback_last_col);
      goback_update_list(goback_lists[0].list);
      goback_update_list(goback_lists[goback_active_list].list);
      if (goback_region_modified_flag) {
         //say(' mmm ' :+ goback_modified_line :+ ' ' :+ goback_modified_col);
         add_new_goback_item(
            goback_modified_lines_list.list, true, goback_buf_name,
            goback_lower_line + ((goback_upper_line - goback_lower_line) >> 1),
            goback_modified_line, goback_modified_col);
      }
   }
   if (goback_switching_projects_counter > 0) {
      // find the list for the active project and make it the active list
      goback_switching_projects_counter = 0;
      int k;
      for (k = 1; k < goback_lists._length(); ++k) {
         if (goback_lists[k].list_name == _project_get_filename()) {
            break;
         }
      }
      if (k >= goback_lists._length()) {
         k = make_new_goback_list(_project_get_filename());
      }
      goback_active_list = k;
   }
   goback_buf_name = _mdi.p_child.p_buf_name;
   goback_buf_id = _mdi.p_child.p_buf_id;
   goback_lower_line = goback_upper_line = goback_last_line = line_now;
   goback_last_col = col_now;

   // create new entries in the lists - they'll be updated later
   dlist_iterator it = dlist_end(goback_lists[0].list);
   goback_item * mp = dlist_getp(it);
   mp->buf_name = goback_buf_name;
   mp->mid_line = goback_last_line;
   mp->last_line = goback_last_line;
   mp->col = goback_last_col;
   remove_duplicate(goback_lists[0].list);

   it = dlist_end(goback_lists[goback_active_list].list);
   mp = dlist_getp(it);
   mp->buf_name = goback_buf_name;
   mp->mid_line = goback_last_line;
   mp->last_line = goback_last_line;
   mp->col = goback_last_col;
   remove_duplicate(goback_lists[goback_active_list].list);

   if (goback_region_modified_flag) {
      goback_region_modified_flag = false;
      it = dlist_end(goback_modified_lines_list.list);
      mp = dlist_getp(it);
      mp->buf_name = goback_buf_name;
      mp->mid_line = goback_last_line;
      mp->last_line = goback_last_line;
      mp->col = goback_last_col;
      remove_duplicate(goback_modified_lines_list.list);
   }
}


_command save_goback_history()
{
   int section_view, current_view;
   current_view = _create_temp_view(section_view);
   if (current_view == '') {
       return 0;
   }
   activate_view(section_view);
   top();
   // need first line blank for easier load
   insert_line('');

   int k;
   //for (k = 0; k < goback_lists._length(); ++k) {
   for (k = 0; k < 1; ++k) {
      insert_line('[' maybe_quote_filename(goback_lists[k].list_name) ']');
      dlist_iterator iter = dlist_iterator_new(goback_lists[k].list);
      while (dlist_next(iter)) {
         goback_item * gip = dlist_getp(iter);
         insert_line(gip->mid_line :+ ' ' :+ gip->last_line :+
              ' ' :+ gip->col :+ ' ' :+ maybe_quote_filename(gip->buf_name));
      }
      insert_line('');
   }

   _save_file( _config_path() :+ "/goback.dat");
   _delete_temp_view(section_view);
   activate_view(current_view);
}


static int make_new_goback_list(_str list_name)
{
   int k = goback_lists._length();
   goback_lists[k].list_name = list_name;
   dlist_construct(goback_lists[k].list, 30, true);

   goback_item item;
   item.buf_name = 'empty';
   item.mid_line = 0;
   item.last_line = 0;
   item.col = 0;
   dlist_push_back(goback_lists[k].list, item);
   return k;
}


static void load_goback_history2()
{
   _str line, proj, vmid_line, vlast_line, vcol, fname;

   goback_lists._makeempty();
   fname = _config_path() :+ "/goback.dat";
   if (get(fname)) {
      message('load goback history failed - FILE: ' :+ fname);
      return;
   }

   top();
   while (true) {
      while (true) {
         if (down())
            return;
         get_line(line);
         if (substr(line,1,1) == '[') {
            proj = substr(line, 2, length(line)-2);
            break;
         }
      }
      int k = make_new_goback_list(proj);
      while (true) {
         if (down())
            return;
         get_line(line);
         if (substr(line,1,1) == ' ')
            break;
         parse line with vmid_line vlast_line vcol fname;
         fname = parse_file(fname, true);
         add_new_goback_item(goback_lists[k].list, false, fname, (int)vmid_line, (int)vlast_line, (int)vcol);
      }
   }
}


static void load_goback_history()
{
   int section_view, current_view;
   current_view = _create_temp_view(section_view);
   if (current_view == '') {
       return;
   }
   activate_view(section_view);
   load_goback_history2();
   _delete_temp_view(section_view);
   activate_view(current_view);
}


void _prjopen_goback_history()
{
   if (goback_startup) {
      goback_startup = false;
      int k;
      for (k = 1; k < goback_lists._length(); ++k) {
         if (goback_lists[k].list_name == _project_get_filename()) {
            break;
         }
      }
      if (k >= goback_lists._length()) {
         k = make_new_goback_list(_project_get_filename());
      }
      goback_active_list = k;
   }
   else
   {
      goback_switching_projects_counter = 3;
   }

   goback_project_changed = true;
}


static dlist * get_goback_list_address(int list_num = 0)
{
   return &goback_lists[0].list;
}


static int calculate_goback_history_length(int xx)
{
   return dlist_size(goback_lists[xx].list);
}


static void step_thru_goback_history2(int list_index, int line_mode = 1)
{
   dlist * listptr;

   int list_index2 = list_index;
   int lpos,k;
   dlist_iterator iter;
   int startline = _mdi.p_child.p_line;
   int startcol = _mdi.p_child.p_col;
   int start_buf_id = _mdi.p_child.p_buf_id;
   boolean restart = true;

   while (true) {
      if (restart) {
         restart = false;
         listptr = &goback_lists[list_index2].list;

         if (dlist_is_empty(*listptr)) {
            return;
         }
         iter = dlist_end(*listptr);
      }
      lpos = dlist_get_distance(iter,true);
      goback_item * gob = (goback_item*)dlist_getp(iter);
      if (gob->last_line == 0 && gob->col == 0) {
         message('No history');
         return;
      }
      if (edit( maybe_quote_filename(gob->buf_name) ) != 0)
         return;

      _mdi.p_child.p_col = gob->col;
      _mdi.p_child.p_line = (line_mode ? gob->last_line : gob->mid_line);
      message('Goback ' :+ lpos :+ ' ' :+
              strip_filename(_mdi.p_child.p_buf_name,'DP') :+  ' ' :+
              gob->last_line :+ ' ' :+ gob->mid_line);

      _str key = get_event('N');   // refresh screen and get a key
      _str keyt = event2name(key);
      switch (keyt) {
         case 'F7' :
            line_mode = (line_mode ? 0 : 1);
            break;

         case 'C-F5' :
            //list_index2 of zero allows stepping through "all project" type
            //history, whereas list_index is just for the current project.
            //If you've just switched projects, you might want to go back to a file
            //in the previous project.
            if (list_index2 == list_index)
               list_index2 = 0;
            else
               list_index2 = list_index;
            restart = true;
            break;

         case 'UP' :
         case 'S-F5' :
         case 'F6' :
            if (dlist_next(iter)) {
               break;
            }
            // don't wrap
            iter = dlist_end(*listptr);
            break;
         case 'DOWN' :
         case 'F5' :
            if (dlist_prev(iter)) {
               break;
            }
            // don't wrap
            iter = dlist_begin(*listptr);
            break;

         case 'ESC' :
            edit('+Q +BI ' :+ start_buf_id);
            //edit( maybe_quote_filename(listptr->list[listptr->start_index].buf_name)  );
            //message('Goback to original :' :+ _mdi.p_child.p_buf_name);
            message('');  // clear
            _mdi.p_child.p_line = startline;
            _mdi.p_child.p_col = startcol;
            return;

         case 'RIGHT' :
         case 'LEFT' :
         default:
            message('End goback at ' :+ _mdi.p_child.p_buf_name);
            //if (length(keyt)==1)
            //   call_key(key);
            //else if (keyt=='RIGHT' || keyt=='LEFT' || keyt=='UP' || keyt=='DOWN') {
            // call_key(key);
            //}
            return;
      }
   }
}


_command void step_thru_goback_history()
{
   goback_set_buffer_history_pending_mode();
   goback_history_disabled = true;
   step_thru_goback_history2(0,1);
   goback_history_disabled = false;
   goback_process_pending_buffer_history();
}


void _exit_goback_save()
{
   if (def_goback_persistent_history)
      save_goback_history();
}
                              

void init_goback_history()
{
   goback_lists._makeempty();
   if (def_goback_persistent_history)
      load_goback_history();

   if (goback_lists._length()==0) {
      make_new_goback_list('all-projects');
   }

   if (goback_lists._length() < 2) {
      make_new_goback_list('empty_project');
   }

   // until a project is selected, use empty_project
   goback_active_list = 1;

   if (_no_child_windows()) {
      goback_buf_id = -1;
      goback_lower_line = goback_upper_line = goback_last_line = 1;
      goback_last_col = 1;
      goback_buf_name = '';
   }
   else {
      goback_buf_id = _mdi.p_child.p_buf_id;
      goback_lower_line = goback_upper_line = goback_last_line = _mdi.p_child.p_line;
      goback_last_col = _mdi.p_child.p_col;
      goback_buf_name = _mdi.p_child.p_buf_name;
   }

   goback_max_line_range = 4;

   goback_modified_lines_list.list_name = 'modified lines';
   dlist_construct(goback_modified_lines_list.list, 30, true);

   goback_item item;
   item.buf_name = 'empty';
   item.mid_line = 0;
   item.last_line = 0;
   item.col = 0;
   dlist_push_back(goback_modified_lines_list.list, item);
}


int callback_gb2(int cmd, dlist_iterator & it)
{
   if (cmd == LIST_CALLBACK_PROCESS_ITEM) {
      goback_item * gp = dlist_getp(it);
      say('List item ' :+ gp->buf_name :+ ' ' :+ gp->last_line :+ ' ' :+ gp->col :+
                 ' Pos ' :+ dlist_get_distance(it));
   }
   return 0;
}
           
_command void show_goback_modified() name_info(',')
{
   dlist_iterate_list(goback_modified_lines_list.list, 'callback_gb2');
}


#endif


definit ()
{
    //If this is an editor invocation
    if (arg(1)!="L") {
        //buffer_history_suspend = true;
        //goback_startup = true;
    }
    //goback_no_re_entry = 0;
    //init_goback_history();
    dlist_construct(goback_buffer_list, 100, true);
    switchbuf_goback_no_re_entry = 0;
}


     



