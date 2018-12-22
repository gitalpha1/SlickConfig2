

#include "slick.sh"

#pragma option(strictsemicolons,on)
//#pragma option(strict,on)
//#pragma option(autodecl,off)
#pragma option(strictparens,on)


#import 'dlinklist.e'

#define MY_NAME 'xtemp-file-manager.e'


// =============================================================================================================
//
//                                       Temporary file manager utility
//
// =============================================================================================================


static dlist   xtemp_files_list;

static int     xtemp_list_regenerate_timer;
static int     xtemp_wkspace_opened_timer;
static int     xtemp_buffer_add_timer;

static boolean xtemp_list_regenerate_timer_is_active;
static boolean xtemp_wkspace_opened_timer_is_active;
static boolean xtemp_buffer_add_timer_is_active;




static boolean xtemp_no_timer;
static _str    xremember_first_file;
static boolean xtemp_wkspace_has_been_closed;


#define TEMP_FILES_PATH  _ConfigPath() :+ 'temporary_files' :+  FILESEP
#define NOKEEP  'NoKeep-'

#define XTEMP_FILE_LIST_FILENAME  _ConfigPath() :+ 'xtemporary_file_list.txt'

_command void xtemp_new_temporary_file_no_keep(_str ext = '.txt') name_info(',')
{
   xnew_temp_file(true, '', ext);
}


_command void xtemp_new_temporary_file(boolean nokeep = false, _str aprefix = 'DA-', _str ext = '.txt') name_info(',')
{
   start_xtemp_list_regenerate_timer();
   if ( nokeep ) {
      aprefix = NOKEEP;
   }
   _str xpath = TEMP_FILES_PATH;
   if (!path_exists(xpath)) {
      make_path(xpath);
   }
   
   _str index_filename = xpath :+ 'AA-index.txt';
   boolean already_exists = file_exists(index_filename);
   boolean was_open = false;
   tempView := 0;
   origView := 0;
   // _open_temp_view creates the file if it doesn't exist
   status := _open_temp_view(index_filename, tempView, origView, "", was_open, false, false, 0, true);
   if (status) {
      _msg_box("Error reading/creating index file:\n" :+ index_filename :+ "\nErrorcode - " :+ status);
      return;
   }
   int xx = 1;
   if ( already_exists ) {
      top();
      typeless line = "";
      get_line(line);
      parse line with auto xval .;
      if ( isnumber(xval) ) {
         xx = (int)xval;
         if ( xx > 999999) {
            xx = 1;
         }
      }
   }
   int mm;
   for ( mm = 0 ; mm < 1000; ++mm, ++xx ) {
      _str fn = (_str)xx;
      // add zeroes at front
      while ( fn._length() < 6 ) {
         fn = '0' :+ fn;
      }
      _str target_filename = xpath :+ aprefix :+ fn :+ ext;
      if ( !file_exists(target_filename) ) {
         // update index file
         top();
         replace_line(xx + 1);
         _save_file('+O');   // no backup
         _delete_temp_view(tempView);
         p_window_id = origView;
         edit(maybe_quote_filename(target_filename));
         bottom();
         if ( !nokeep ) {
            insert_line("");
         }
         return;
      }
   }
   _message_box("Search limit exceeded.  Update index file:\n" :+ index_filename :+ "\nwith a free six digit number");
   _delete_temp_view(tempView);
   p_window_id = origView;
}


// if a temporary file is closed, start the list regenerate timer
void _cbquit_xtemp_file_close(int bufId, _str bufName)
{
   if ( xtemp_no_timer ) {
      return;
   }
   if ( pos(TEMP_FILES_PATH, bufName )) {
      start_xtemp_list_regenerate_timer();
      say(' quit ' :+ bufName);
   }
}


void _wkspace_close_xtemp_save_file_list()
{
   say('wkspace close hook');
   // all buffers have already been closed by slick but there's a delay before
   // the list is regenerated, allowing the list to be saved as it was before the workspace was closed
   xtemp_save_file_list_to_disk();
   xtemp_wkspace_has_been_closed = true;
}



_str remember[];


static void close_remembered_files()
{
   if (remember._length() < 1)
   {
      return;
   }
   _str bufname = p_buf_name;
   xtemp_no_timer = true;
   int k = 0;
   for ( ;k < remember._length(); ++k) {
      if ( bufname == p_buf_name ) {
         bufname = '';
      }
      edit(remember[k]);
      quit(false);
   }
   remember._makeempty();
//   if ( bufname != '' ) {
//      edit(bufname);
//   }
   xtemp_no_timer = false;
}


int xtemp_remember_file()
{
   if ( pos(TEMP_FILES_PATH, p_buf_name ) ) {
      remember[remember._length()] = p_buf_name;
   }
   return 0;
}


void _workspace_opened_handle_xtemp_files()
{
   say('wkspace opened hook');
   xtemp_wkspace_has_been_closed = false;
   xremember_first_file = p_buf_name;
   // close any temporary files that the workspace has remembered
   remember._makeempty();
   for_each_buffer('xtemp_remember_file');
   // re-open temporary files using xtemp_files_list
   start_wkspace_opened_timer();
}


int xtemp_add_file_to_list()
{
   if ( pos(TEMP_FILES_PATH, p_buf_name )) {
      _str fn2 = strip_filename(p_buf_name, 'PDE');
      if ( substr(fn2,1,length(NOKEEP)) != NOKEEP ) {
         _str s1 = p_buf_name;
         dlist_push_back(xtemp_files_list, s1);
      }
   }
   return 0;
}

static void xtemp_regenerate_temporary_files_list()
{
   dlist_reset(xtemp_files_list);
   for_each_buffer('xtemp_add_file_to_list');
}



// "_buffer_add" fires for every file when a workspace is opened
void gp_buffer_add_xtemp_files(int newBufId, _str bufName)
{
   if ( pos(TEMP_FILES_PATH, bufName )) {
      _str fn2 = strip_filename(bufName, 'PDE');
      if ( substr(fn2,1,length(NOKEEP)) != NOKEEP && fn2 != 'AA-index') {
         start_buffer_add_timer();
      }
   }
}



 static void xtemp_list_buffer_add_callback()
 {
    say(' buffer add callback ');
    _kill_timer(xtemp_buffer_add_timer);
    xtemp_buffer_add_timer_is_active = false;
    if ( !xtemp_list_regenerate_timer_is_active ) {
       start_xtemp_list_regenerate_timer();
    }
 }


static void start_buffer_add_timer()
{
   say(' start add ' );
   xtemp_buffer_add_timer = _set_timer(5000, xtemp_list_buffer_add_callback);
   xtemp_buffer_add_timer_is_active = true;
}


static void xtemp_list_regenerate_timer_callback()
{
   _kill_timer(xtemp_list_regenerate_timer);
   xtemp_list_regenerate_timer_is_active = false;

   if ( xtemp_wkspace_has_been_closed ) {
      // keep the temporary files open when the workspace is closed 
      // this operation is cancelled if another workspace has been opened
      say(' list regenerate callback 1');
      xtemp_wkspace_has_been_closed = false;
      xtemp_load_temporary_files();
   }
   else 
   {
      say(' list regenerate callback 2');
      xtemp_regenerate_temporary_files_list();
      xtemp_save_file_list_to_disk();
   }
}

static void start_xtemp_list_regenerate_timer()
{
   // after 3 seconds, re-generate the list and save to disk
   xtemp_list_regenerate_timer = _set_timer(3000, xtemp_list_regenerate_timer_callback);
   xtemp_list_regenerate_timer_is_active = true;
}

static void xtemp_wkspace_opened_timer_callback()
{
   say('wkspace open callback');
   _kill_timer(xtemp_wkspace_opened_timer);
   xtemp_wkspace_opened_timer_is_active = false;
   close_remembered_files();
   xtemp_load_temporary_files();
   edit('+b ' :+ xremember_first_file);
}

static void start_wkspace_opened_timer()
{
   xtemp_wkspace_opened_timer = _set_timer(1000, xtemp_wkspace_opened_timer_callback);
   xtemp_wkspace_opened_timer_is_active = true;
}


int xtemp_maybe_discard_file()
{
   _str fn = p_buf_name;
   if ( pos(TEMP_FILES_PATH, p_buf_name )) {
      _str fn2 = strip_filename(p_buf_name, 'PDE');
      if ( substr(fn2,1,length(NOKEEP)) :== NOKEEP ) {
         _delete_buffer();
         delete_file(fn);
      }
   }
   return 0;
}


void _on_load_module_xtemp_files(_str module_name)
{
   _str sm = strip(module_name, "B", "\'\"");
   if (strip_filename(sm, 'PD') == MY_NAME) {
      say('on load ' :+ xtemp_list_regenerate_timer_is_active :+ ' ' 
                     :+ xtemp_wkspace_opened_timer_is_active :+ ' ' :+ xtemp_buffer_add_timer_is_active);

      if ( xtemp_list_regenerate_timer_is_active ) 
         _kill_timer(xtemp_list_regenerate_timer);

      if ( xtemp_wkspace_opened_timer_is_active ) 
         _kill_timer(xtemp_wkspace_opened_timer);

      if ( xtemp_buffer_add_timer_is_active ) 
         _kill_timer(xtemp_buffer_add_timer);
   }
}



// slick is closing, save the list and discard no-keep files
void _exit_xtemp_handle_temporary_files()
{
   xtemp_wkspace_has_been_closed = false;
   xtemp_save_file_list_to_disk();
   for_each_buffer('xtemp_maybe_discard_file');
}


static void xtemp_load_temporary_files()
{
   say(' load temporary ');
   dlist_iterator iter = dlist_begin(xtemp_files_list);
   for ( ; dlist_iter_valid(iter); dlist_next(iter)) {
      _str fn = * dlist_getp(iter);
      if ( file_exists(fn) ) {
         edit( maybe_quote_filename(fn));
      }
   }
}

// load the list, (not the files)
static void xtemp_load_temporary_file_list()
{
   _str filename = XTEMP_FILE_LIST_FILENAME;
   _str line;
   // max 1000 temporary files open
   dlist_construct(xtemp_files_list, 1000, false);
   if (file_exists(filename)) {
      tempView := 0;
      origView := 0;
      status := _open_temp_view(filename, tempView, origView);
      if (!status) {
         top();
         for ( ;; ) {
            get_line(line);
            if ( line._length() > 0 ) {
               if ( pos(TEMP_FILES_PATH, line )) {
                  dlist_push_back(xtemp_files_list, line);
               }
            }
            if ( down() ) {
               break;
            }
         }
      }
      _delete_temp_view(tempView);
      p_window_id = origView;
   }
}


// save the list to disk, (not the files)
static void xtemp_save_file_list_to_disk()
{
   _str filename = XTEMP_FILE_LIST_FILENAME;

   tempView := 0;
   origView := 0;
   boolean was_open;
   // _open_temp_view creates the file if it doesn't exist or wipes it if it does
   status := _open_temp_view(filename, tempView, origView, "", was_open, true, false, 0, true);
   if ( !status ) {
      top();
      dlist_iterator iter = dlist_begin(xtemp_files_list);
      for ( ; dlist_iter_valid(iter); dlist_next(iter)) {
         insert_line(*dlist_getp(iter));
         say(' disk ' :+ *dlist_getp(iter));
      }
      _save_file('+O');
   }
   _delete_temp_view(tempView);
   p_window_id = origView;
}


definit()
{
   xtemp_buffer_add_timer_is_active = false;
   xtemp_wkspace_opened_timer_is_active = false;
   xtemp_list_regenerate_timer_is_active = false;

   xtemp_load_temporary_file_list();
   xtemp_no_timer = false;
   start_xtemp_list_regenerate_timer();
   xtemp_wkspace_has_been_closed = false;
}



