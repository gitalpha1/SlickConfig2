


#include "slick.sh"
#include "GFilemanHdr.sh"
//#include "toolbar.sh"

#include "se/ui/toolwindow.sh"

#import '../my-macros/DLinkList.e'
#import 'GFilemanGoback.e'
#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)

//#define debug1

// forms other than GFilemanForm1, inherit from GFilemanForm1 event table
defeventtab GFilemanForm1;


#define MAX_LISTVIEW_COLS 4

#define SCROLLBAR_MODE_CAN_HIDE 0
#define SCROLLBAR_MODE_NO_SHOW 1
#define SCROLLBAR_MODE_NO_HIDE 2



// the list of files can currently show two different kinds of information
// - open buffers or "goback" info.
#define DISPLAY_MODE_OPEN_BUFFERS 1
#define DISPLAY_MODE_GOBACK_HISTORY 2
#define DISPLAY_MODE_SHORTCUT_LIST 3


#define GFM_SORT_RECENT_ACCESS 1
#define GFM_SORT_DIRECTORY_FILENAME 2
#define GFM_SORT_FILESPEC 3
#define GFM_SORT_FILENAME 4
#define GFM_SORT_EXTENSION_FILENAME 5
#define GFM_SORT_DIRECTORY_EXTENSION_FILENAME 6


// the editbox on the form can be in different states according to what it
// is being used for.  When a filename is being entered, the state is TEXT_INFO1_STATE_FILESPEC
#define TEXT_INFO1_STATE_ACTIVE_FILE 1
#define TEXT_INFO1_STATE_ITEM_NUMBERS 2
#define TEXT_INFO1_STATE_SELECTED_FILE 3
#define TEXT_INFO1_STATE_FILESPEC 4

// the order of the buttons - the scrollbar button disappears when scrollbar is not needed
#define OPTIONS_BUTTON_P_X   3
#define GOBACK_BUTTON_P_X    25
#define SCROLLBAR_BUTTON_P_X 46


// The underlying list of buffer names/ filenames is a list of GFM_display_data_item
// There are two such lists in GFM_form_data - display_data_list holds the items
// that are actually shown (and sometimes has a list of directory names at the end)
// and buffer_list2, which is used to check if display_data_list is out of date
struct GFM_display_data_item {
   int buf_id;
   _str buf_name;
   boolean buf_modified;
   boolean directory_flag;
   boolean hide;
   boolean pinned;
   boolean not_a_file;
   boolean fileman_buffer;
};

// GFM_form_data contains save_directory_list, a list of dir_item, which is used
// to remember which directories are collapsed/ not collapsed when display_data_list
// is being regenerated
struct dir_item {
   _str name;
   boolean hide;
};



// GFM_form_data holds the (possibly large) amount of data associated with
// each GFileman form - each form has one GFM_form_data object, and these are
// in the GFM_form_data_array
struct GFM_form_data {
   _str                    form_name;
   int                     form_id;
   int                     form_display_mode;
   int                     requested_display_mode;
   int                     num_buffers;
   GFM_display_data_item   display_data_list [];
   GFM_display_data_item   buffer_list2 [];
   int                     num_buffers2;
   int                     alpha_directory_sorted_buf_indexes[];
   int                     alpha_directory_ext_sorted_buf_indexes[];
   int                     recent_access_sorted_buf_indexes[];
   int                     pinned_file_buf_indexes[];
   int                     path_alpha_sorted_minus_pinned_buf_indexes[];
   int                     full_path_alpha_sorted_buf_indexes[];
   int                     pinned_plus_alpha_sorted_buf_indexes[];
   int                     filename_alpha_sorted_buf_indexes[];
   int                     file_extension_alpha_sorted_buf_indexes[];

   int                     directory_names_start_index;
   int                     number_recent_access_sorted;
   int                     buffer_list_view_start_index;
   dir_item                save_directory_list[];
   int                     filespec_alpha_sorted_buf_indexes[];
   int                     redo_listview_list_counter;
   int                     GFM_file_order_mode;
   int                     GFM_save_file_order_mode;
   boolean                 GFileman_might_switch_focus;
   boolean                 viewx_col2_move_mode;
   boolean                 GFileman_file_info_showing;
   int                     text_info1_state;
   boolean                 last_ctrl_key_down_state;
   int                     number_of_pinned_files;

   popup_window_pos_data   win_pos_data;
   boolean                 listview_line_is_selected;
   int                     listview_num_lines_in_list[];
   int                     listview_num_lists;
   int                     listview_lines_per_list;
   int                     listview_selected_list_num;
   int                     listview_selected_line_num;
   boolean                 listview_force_line_reselect;
   int                     filename_editbox_p_y;
   int                     listview_p_y;
   int                     buttons_row1_p_y;
   int                     vse_v9_title_label_p_y;
   boolean                 buttons_row1_visible; 

   dlist *                 goback_list_ptr;

   GFileman_persistent_setup_data      setup_data; 

   int                     num_listview_columns_available;
   int                     listview_col1_control_list[];
   int                     listview_col2_control_list[];
   int                     listview_col3_control_list[];
   int                     listview_image_overlay_control_list[];
   int                     listview_vert_sep_bar_image_list[];
   boolean                 form_is_alive;

   boolean                 scrollbar_is_visible; 
   int                     scrollbar_mode; 
   _str                    pinned_filenames[];
   int                     ctltext1_window_id;
   int                     scrollbar_mousemove_counter; 
   int                     goback_selected_listnum; 
   _str                    file_names_from_dir_close[];
   boolean                 redo_form; 
   boolean                 ctltext1_scrolls_list_on_mouseover; 
   int                     keep_save_directory_list;
   int                     highlighted_item_index;
   int                     show_shortcuts_now;
   boolean                 kill_me;
   dlist_iterator          goback_iterator;
   dlist_iterator          goback_iterator2;
   boolean                 scrollbar_needed;
};

GFM_form_data GFM_form_data_array [];
GFM_form_data * form_data_ptr;

// form_data_ptr is used a lot so there is a shorter name for it - fdp
#define fdp form_data_ptr

//=============================================================================
// 
//                    >>>>>>>>   WARNING   <<<<<<<<
// 
// All form event handlers MUST call set_form_data_ptr() as the first thing
// they do, before using fdp.
//=============================================================================


static _str last_file_info_text;

static int _pic_index_col1_file_mod;
static int pic_index_col1_blank;
static int pic_index_col1_dir_collapsed;
static int pic_index_col1_dir_expanded; 
static int pic_index_col1_pin;
static int pic_index_col1_active_file;
static int pic_index_col1_active_file_mod;

static int pic_index_checkbox_ticked;
static int pic_index_checkbox_unticked;

_control ctlimage_editbox1_top_horiz_bar;
_control ctlimage_editbox1_left_vert_bar;
_control ctlimage_editbox1_bottom_horiz_bar;
_control ctlimage_editbox1_right_vert_bar;


// blackbox1 isn't used in slick V10 / V11 coz they had new-looking tool
// windows, but in slick V9, blackbox1 was an attempt to draw what V10/V11 have.
// This is currently somewhat incomplete and unsupported but can probably be
// made to work for Slick V9 users.
_control ctlimage_blackbox1_top_horiz_bar;
_control ctlimage_blackbox1_left_vert_bar;
_control ctlimage_blackbox1_bottom_horiz_bar;
_control ctlimage_blackbox1_right_vert_bar;
//_control ctlimage_blackbox1_bottom_horiz_bar_shadow;


_control blackbox1_title_label;
_control scrollbar_button;

_control ctlimage_listview_top_horiz_bar1;
_control ctlimage_listview_left_vert_bar1;
_control ctlimage_listview_bottom_horiz_bar1;
_control ctlimage_listview_right_vert_bar1;
_control ctlimage_listview_vert_sep_bar1;
_control ctlimage_listview_vert_sep_bar2;
_control ctlimage_listview_vert_sep_bar3;
_control ctltext1;

_control options1_button;
_control goback_button;

// A GFileman form can show up to 4 columns of information - each "column" consists
// of 3 listboxes - view1/2/3/4 here correspond to the 4 visible columns and
// col1/2/3 correspond to the 3 list boxes in each column
_control ctllist_view1_col1;
_control ctllist_view2_col1;
_control ctllist_view3_col1;
_control ctllist_view4_col1;

_control ctllist_view1_col2;
_control ctllist_view2_col2;
_control ctllist_view3_col2;
_control ctllist_view4_col2;

_control ctllist_view1_col3;
_control ctllist_view2_col3;
_control ctllist_view3_col3;
_control ctllist_view4_col3;


_control scrollbar_slider_image;
_control scrollbar_horizontal_indicator_image;

_control view1_ctlimage1;
_control view2_ctlimage1;
_control view3_ctlimage1;
_control view4_ctlimage1;


static boolean holdoff_file_view_list_update;

static _str last_filespec;


// umm, I think special_x/y are now redundant and the "tooltip" window is
// hidden by setting its width and height to zero
int special_x;
int special_y;

// GFM_timer_handle, the one second timer that refreshes the GFileman forms
// and drives goback history - must not be static
int GFM_timer_handle;

int col2_backcolor;

// Vslick V9 is currently not supported
static boolean vse_v9_mode = false;


static int scrollbar_mousemove_last_x;
static int scrollbar_mousemove_last_y;

static int scrollbar_move_pic;
static int scrollbar_move_alive_pic;
static int id_of_last_form_with_filename_editbox_target;
static _str name_of_last_form_with_filename_editbox_target;

static int goback_history_view_length;
static int goback_history_view_start_index;
static int goback_history_view_start_index2;
static int goback_history_view_start_line;


static int right_mouse_item_index;
static _str right_mouse_buf_name;

static int mouse_move_holdoff_counter;
static boolean holdoff_listview_update_mode;

static int fileman_id;

static int check_goback_history_range;

static int scrollbar_speed;
static int scrollbar_fast_speed;
static int scrollbar_slow_speed;
static int scrollbar_speed_mode;

static boolean force_buffer_list_check;

struct listman_shortcuts_item {
   _str key;
   _str name;
};

static listman_shortcuts_item  active_shortcuts_list[];

static void GFileman_timer_callback();


// a GFM_form_data object is reset by this function when a form is created
static void reset_form_data(GFM_form_data *fp)
{
   fp->num_buffers = 0;
   fp->display_data_list._makeempty();
   fp->buffer_list2._makeempty();
   fp->num_buffers2 = 0;

   fp->alpha_directory_sorted_buf_indexes._makeempty();
   fp->alpha_directory_ext_sorted_buf_indexes._makeempty();
   fp->recent_access_sorted_buf_indexes._makeempty();
   fp->pinned_file_buf_indexes._makeempty();
   fp->path_alpha_sorted_minus_pinned_buf_indexes._makeempty();
   fp->full_path_alpha_sorted_buf_indexes._makeempty();
   fp->pinned_plus_alpha_sorted_buf_indexes._makeempty();
   fp->file_extension_alpha_sorted_buf_indexes._makeempty();
   fp->filename_alpha_sorted_buf_indexes._makeempty();

   fp->directory_names_start_index = 0;
   fp->number_recent_access_sorted = 0;
   fp->buffer_list_view_start_index = 0;
   fp->save_directory_list._makeempty();
   fp->filespec_alpha_sorted_buf_indexes._makeempty();
   fp->redo_listview_list_counter = 0;
   fp->GFM_file_order_mode = 0;
   fp->GFM_save_file_order_mode = 0;
   fp->GFileman_might_switch_focus = false;
   fp->viewx_col2_move_mode = false;
   fp->GFileman_file_info_showing = false;
   fp->text_info1_state = 0;
   fp->last_ctrl_key_down_state = 0;

   fp->listview_col1_control_list._makeempty();
   fp->listview_col2_control_list._makeempty();
   fp->listview_col3_control_list._makeempty();

   fp->listview_line_is_selected = false;
   fp->listview_num_lines_in_list._makeempty();
   fp->listview_num_lists = 0;
   fp->listview_lines_per_list = 0;
   fp->listview_selected_list_num = 0;
   fp->listview_selected_line_num = 0;
   fp->listview_force_line_reselect = false;
   fp->filename_editbox_p_y = 2;
   fp->listview_p_y = 50;
   fp->buttons_row1_p_y = 25;
   fp->vse_v9_title_label_p_y = 4;
   fp->form_display_mode = DISPLAY_MODE_OPEN_BUFFERS;
   fp->requested_display_mode = DISPLAY_MODE_OPEN_BUFFERS;
   //fp->goback_list_ptr = &GFH_goback_datasets[0].steps_no_dup;
   fp->num_listview_columns_available = MAX_LISTVIEW_COLS;
   fp->scrollbar_is_visible = false;
   fp->scrollbar_mode = SCROLLBAR_MODE_CAN_HIDE;
   fp->form_is_alive = false;
   fp->pinned_filenames._makeempty();
   fp->scrollbar_mousemove_counter = 0;
   fp->goback_selected_listnum = 0;
   fp->file_names_from_dir_close._makeempty();
   fp->redo_form = true;
   fp->ctltext1_scrolls_list_on_mouseover = false;
   fp->keep_save_directory_list = 0;
   fp->highlighted_item_index = 0;
   fp->show_shortcuts_now = 0;
   fp->kill_me = false;
}




static boolean is_display_mode_open_buffers()
{
   return fdp->form_display_mode == DISPLAY_MODE_OPEN_BUFFERS;
}

static boolean is_display_mode_goback_history()
{
   return fdp->form_display_mode == DISPLAY_MODE_GOBACK_HISTORY;
}

static void set_display_mode_to_open_buffers()
{
   fdp->form_display_mode = DISPLAY_MODE_OPEN_BUFFERS;
}

static void set_display_mode_to_goback_history()
{
   fdp->form_display_mode = DISPLAY_MODE_GOBACK_HISTORY;
}


/******************************************************************************
*  FUNCTION :  set_form_data_ptr()
*  
*  Each form has an element of GFM_form_data_array associated with it that
*  holds all the state data for that form.
*  The p_user property of the form is used to remember the index into
*  GFM_form_data_array for the form.
******************************************************************************/
static void set_form_data_ptr(int form_id )
{
   // say('pppp ' :+ form_id);
   // say('yyyy ' :+ form_id.p_name);
   // _StackDump();

   if (form_id.p_name == 'GFilemanForm1') {
      form_id.p_user = 0;
   }
   else if (form_id.p_name == 'GFilemanForm2') {
      form_id.p_user = 1;
   }
   else
      form_id.p_user = 2;

   if ((form_id.p_user == null) ||
       (form_id.p_user < 0) ||
      (form_id.p_user >= GFM_form_data_array._length()) ||
      ( form_id.p_name != GFM_form_data_array[form_id.p_user].form_name) ) 
   {
      form_id.p_user = -1;
      int k;
      for (k = 0; k < GFM_form_data_array._length(); ++k) {
         if (form_id.p_name == GFM_form_data_array[k].form_name) {
            form_id.p_user = k;
            break;
         }
      }
      if (form_id.p_user < 0) {
         // create a new entry in GFM_form_data_array
         reset_form_data(&GFM_form_data_array[k]);
         GFM_form_data_array[k].form_name = form_id.p_name;
         form_id.p_user = k;
      }
   }
   fdp = &GFM_form_data_array[form_id.p_user];
   fdp->form_id = form_id;
}




static int find_or_create_GFM_form_data_array_entry(_str form_name, boolean reset = false)
{
   int k;
   for ( k = 0; k < GFM_form_data_array._length(); ++k ) {
      if (GFM_form_data_array[k].form_name == form_name) {
         if (reset)
            break;
         return k;
      }
   }
   // there is currently no entry in GFM_form_data_array for this form
   // so create a new one and load config data
   reset_form_data(&GFM_form_data_array[k]);
   GFM_form_data_array[k].form_name = form_name;
   GFileman_load_form_config( &GFM_form_data_array[k].setup_data, form_name); 
   return k;
}


// generate recent_access_sorted_buf_indexes
static void generate_recent_access_sorted_buf_indexes(boolean pinned_first = true)
{
   // This function is called after directory names have been added to the
   // end of the buffer list.  It forms a list of indexes into the buffer list
   // in order of "recent access"
   fdp->recent_access_sorted_buf_indexes._makeempty();
   int buflist[];
   int sel[];
   int alphasel[];
   int x,y,z;
   for (y=0; y < fdp->display_data_list._length(); y++) {
      sel[y] = 0;
      alphasel[y] = 0;
   }

   if (pinned_first)
      fdp->recent_access_sorted_buf_indexes = fdp->pinned_file_buf_indexes;
   int sidx = fdp->recent_access_sorted_buf_indexes._length();

   // get the list of filenames in order of recent access
   goback_build_buffer_list_array(buflist);

   z = 0;

   // TODO speed up this nested for loop by sorting etc.
   for (x=0; x < buflist._length(); x++) {
      // for each entry in the "recent access" buflist list, add it to the end
      // of recent_access_sorted_buf_indexes if it is in the display_data_list and 
      // is not pinned
      for (y=0; y < fdp->display_data_list._length(); y++) {
         if (fdp->display_data_list[y].directory_flag == false &&
            fdp->display_data_list[y].buf_id == buflist[x] && 
            (!pinned_first || !fdp->display_data_list[y].pinned) ) {
            fdp->recent_access_sorted_buf_indexes[sidx + z++] = y;
            sel[y] = 1;
            break;
         }
      }
   }

   // now add files to the end of the list that are in the buffer list but
   // not in the "recent access" list by looking through the alpha-sorted list
   // to see which entries are missing
   for (y=0; y < fdp->full_path_alpha_sorted_buf_indexes._length(); y++) {
      if (sel[fdp->full_path_alpha_sorted_buf_indexes[y]] == 1) {
         alphasel[y] = 1;
      } else {
         // the "sel[]" array doesn't include the pinned list so check if 
         // the buffer is in the pinned list
         int ux;
         for (ux = 0; ux < sidx; ++ux) {
            if (fdp->recent_access_sorted_buf_indexes[ux] == 
               fdp->full_path_alpha_sorted_buf_indexes[y]) {
               alphasel[y] = 1;
               break;
            }
         }
      }
   }
   // now add the missing entries to the end of recent-access list
   for (y=0; y < alphasel._length(); y++) {
      if (alphasel[y]==0) {
         fdp->recent_access_sorted_buf_indexes[sidx + z++] = 
            fdp->full_path_alpha_sorted_buf_indexes[y];
      }
   }
}


// generate_sorted_filename_lists generates several index lists - 
// these lists are contain indexes into the display_data_list array.
// The display_data_list array contains the actual filenames and the index arrays
// determine the order those filenames are displayed.
// Each GFileman form has its own set of all these arrays including its own set
// of pinned files.
// 
// 1. pinned_file_buf_indexes
// 2. path_alpha_sorted_minus_pinned_buf_indexes
// 3. full_path_alpha_sorted_buf_indexes
// 4. pinned_plus_alpha_sorted_buf_indexes
// 5. filename_alpha_sorted_buf_indexes
// 6. file_extension_alpha_sorted_buf_indexes
// 
// It also sets the "pinned" flag on the display_data_list item if that filename is pinned
// display_data_list does not include any directory names when this function is called
// - they are added afterwards by alpha_directory_sort_bufnames
static void generate_sorted_filename_lists()
{
   _str temp_data[] = null;
   _str temp_data2[] = null;
   _str temp_data3[] = null;
   int k,x,y,z,m;
   typeless bufname, buf_index;

   // copy the buffer list and to each entry, append a "\1" followed by the
   // entry index so that after the copied list is sorted, the new list 
   // contains sorted indexes
   for (x=0; x < fdp->display_data_list._length(); x++) {

      // path and filename
      temp_data[x] = fdp->display_data_list[x].buf_name :+ "\1" :+ x;

      // filename only
      if (fdp->GFM_file_order_mode == GFM_SORT_FILENAME) {
         temp_data2[x] = strip_filename(fdp->display_data_list[x].buf_name,'P') :+ "\1" :+ x;
      }

      if (fdp->GFM_file_order_mode == GFM_SORT_EXTENSION_FILENAME) {
         // extension first, followed by filename
         int flen = length(strip_filename(fdp->display_data_list[x].buf_name,'E'));
         temp_data3[x] = substr(fdp->display_data_list[x].buf_name,flen+1) :+ 
            strip_filename(fdp->display_data_list[x].buf_name,'P') :+ "\1" :+ x;
      }
   }

   // sort the copied path/filename list
   temp_data._sort('F'_fpos_case);

   // temp_data2 and temp_data3 have been left empty if they are not
   // needed for the current sort order
   
   // sort the filename only list, and the extension first list
   temp_data2._sort('I');
   temp_data3._sort('I');

   fdp->pinned_file_buf_indexes._makeempty();
   fdp->path_alpha_sorted_minus_pinned_buf_indexes._makeempty();
   fdp->full_path_alpha_sorted_buf_indexes._makeempty();
   fdp->filename_alpha_sorted_buf_indexes._makeempty();
   fdp->file_extension_alpha_sorted_buf_indexes._makeempty();


   // pinned_filenames is always kept sorted by _sort('F'_fpos_case)
   // temp_data has been sorted above also with _sort('F'_fpos_case)
   // step through temp_data looking for pinned files and set the pinned flag
   // in display_data_list for them
   // 
   // generate pinned_file_buf_indexes and path_alpha_sorted_minus_pinned_buf_indexes 

   y = z = k = m = 0;
   for (x=0; x < temp_data._length(); ++x ) {
      parse temp_data[x] with bufname "\1" buf_index;
      //say( 'sbl ' :+ bufname );
      fdp->full_path_alpha_sorted_buf_indexes[k++] = buf_index;
      int mx = 1;
      while (mx > 0) {
         // while buf_name is greater than pinned name, check next pinned name
         if (m < fdp->pinned_filenames._length()) {
            //say( 'spn ' :+ fdp->pinned_filenames[m] :+ ' ' :+ m);
            mx = stricmp(bufname, fdp->pinned_filenames[m]);
         } else
            mx = -1;
         if (mx == 0) {
            fdp->pinned_file_buf_indexes[y++] = buf_index;
            fdp->display_data_list[buf_index].pinned = true;
            ++m;
         } else if (mx < 0) {
            fdp->path_alpha_sorted_minus_pinned_buf_indexes[z++] = buf_index;
         } else {
            // check next pinned name if any
            ++m;
         }
      }
   }
   //say(y);
   fdp->pinned_plus_alpha_sorted_buf_indexes = fdp->pinned_file_buf_indexes;
   // add non pinned filenames in sorted order
   y = fdp->pinned_plus_alpha_sorted_buf_indexes._length();
   for (x=0; x < fdp->path_alpha_sorted_minus_pinned_buf_indexes._length(); ++x) {
      fdp->pinned_plus_alpha_sorted_buf_indexes[y++] = 
         fdp->path_alpha_sorted_minus_pinned_buf_indexes[x];
   }

   // pinned filenames are duplicated in filename_alpha_sorted_buf_indexes
   // TODO - make this a choice one day by 
   fdp->filename_alpha_sorted_buf_indexes = fdp->pinned_file_buf_indexes;
   k = fdp->filename_alpha_sorted_buf_indexes._length();
   for (x=0; x < temp_data2._length(); ++x ) {
      parse temp_data2[x] with bufname "\1" buf_index;
      // TODO - add buf_index to the list only if not pinned (check flag in display_data_list)
      fdp->filename_alpha_sorted_buf_indexes[k++] = buf_index;
   }

   // pinned filenames are duplicated in file_extension_alpha_sorted_buf_indexes
   // TODO - make this a choice one day?
   fdp->file_extension_alpha_sorted_buf_indexes = fdp->pinned_file_buf_indexes;
   k = fdp->file_extension_alpha_sorted_buf_indexes._length();
   for (x=0; x < temp_data3._length(); ++x ) {
      parse temp_data3[x] with bufname "\1" buf_index;
      // TODO - add buf_index to the list only if not pinned (check flag in display_data_list)
      fdp->file_extension_alpha_sorted_buf_indexes[k++] = buf_index;
   }

}


// alpha_sort_bufnames_filespec is not currently used - it leaves out directory
// names
#if 0
static void alpha_sort_bufnames_filespec(_str mtx)
{
   boolean regex = (pos('/',mtx) == 1);
   _str options = 'I';
   last_filespec = mtx;
   if (regex) {
      mtx = substr(mtx,2);
      options = 'IR';
   }
   fdp->filespec_alpha_sorted_buf_indexes._makeempty();
   int x;
   int y = 0;
   _str fname = null;
   for (x=0; x < fdp->full_path_alpha_sorted_buf_indexes._length(); x++) {
      fname = strip_filename(fdp->display_data_list[fdp->full_path_alpha_sorted_buf_indexes[x]].buf_name,'DP');
      if (pos(mtx,fname,1, options) == 1) {
         fdp->filespec_alpha_sorted_buf_indexes[y++] = fdp->full_path_alpha_sorted_buf_indexes[x];
      }
   }
}
#endif


// generate alpha_directory_sorted_buf_indexes and alpha_directory_ext_sorted_buf_indexes
// and add directory names to the end of display_data_list.
static void alpha_directory_sort_bufnames(_str mtx = '', boolean pinned_first = true)
{
   _str temp_data[] = null;
   _str dir_temp_data[] = null;
   int x,y,z,dx,z2;
   boolean hide;

   boolean regex = false;
   boolean selective = false;
   _str options = 'I';
   _str fname = null;

   if (mtx != '') {
      selective = true;
      //last_filespec = mtx;
      if (pos('/',mtx) == 1) {
         regex = true;
         mtx = substr(mtx,2);
         options = 'IR';
      }
   }

   // At this point, display_data_list contains a list of buffers/filenames.
   // This function appends the directory names to the display_data_list array
   // and generates alpha_directory_sorted_buf_indexes which is used to
   // show the files and directories in alphanumeric order with files grouped
   // into directories.  An entire directory can then be collapsed or expanded
   // - the "hide" flag is used for this.
   // If there are any pinned files, they are copied to the start of 
   // alpha_directory_sorted_buf_indexes first.
   // 
   // The array save_directory_list is generated just before this function is called


   // copy the buffer list (excluding pinned files)  and to each entry, append 
   // a "\1" followed by the entry index so that after the copied list is 
   // sorted, the new list contains sorted indexes

   z = 0;
   for (x=0; x < fdp->display_data_list._length(); x++) {
      if ( !pinned_first || !fdp->display_data_list[x].pinned ) {
         if (selective) {
            fname = strip_filename(fdp->display_data_list[x].buf_name,'DP');
            if (regex) {
               if (pos(mtx,fname,1, options) == 1)
                  temp_data[z++] = fdp->display_data_list[x].buf_name :+ "\1" :+ x;
            }
            else if (pos(mtx,fname,1, options) != 0) {
               temp_data[z++] = fdp->display_data_list[x].buf_name :+ "\1" :+ x;
            }
         } else {
            // not subset
            temp_data[z++] = fdp->display_data_list[x].buf_name :+ "\1" :+ x;
         }
      }
   }

   y = fdp->display_data_list._length();
   if (fdp->keep_save_directory_list == 0) {
      fdp->directory_names_start_index = y;
   }
   temp_data._sort('F'_fpos_case);

   typeless buf_name;
   typeless buf_index;
   fdp->alpha_directory_sorted_buf_indexes._makeempty();
   fdp->alpha_directory_ext_sorted_buf_indexes._makeempty();

   // get the pinned files if any (copy the entire pinned array)
   if (pinned_first) {
      fdp->alpha_directory_sorted_buf_indexes = fdp->pinned_file_buf_indexes;
      fdp->alpha_directory_ext_sorted_buf_indexes = fdp->pinned_file_buf_indexes;
   }

   if (y == 0)
      return;
   _str dr = '\1';
   z2 = z = fdp->alpha_directory_sorted_buf_indexes._length();
   dir_temp_data._makeempty();
   int dtd = 0;

   // step through the sorted list of filenames and when a new "path" is found
   // add it to the end of the buffer list
   for (x=0; x < temp_data._length(); x++) {
      parse temp_data[x] with buf_name "\1" buf_index;
      if (dr != strip_filename(buf_name,'N')) {
         // start of new directory
         if (dtd > 0) {
            // extension sort files from the previous directory
            dir_temp_data._sort('I');  // case insensitive
            int dtdx; 
            typeless dtdbx;
            _str ext;
            // add them to the list
            for (dtdx = 0; dtdx < dtd; ++dtdx) {
               parse dir_temp_data[dtdx] with ext "\1" dtdbx;
               fdp->alpha_directory_ext_sorted_buf_indexes[z2++] = dtdbx;
            }
            dir_temp_data._makeempty();
            dtd = 0;
         }
         hide = false;
         dr = strip_filename(buf_name,'N');
         fdp->alpha_directory_sorted_buf_indexes[z++] = y;
         fdp->alpha_directory_ext_sorted_buf_indexes[z2++] = y;
         // add the new directory to the end of buffer list
         fdp->display_data_list[y].buf_name = dr;
         fdp->display_data_list[y].buf_modified = false;
         fdp->display_data_list[y].hide = false;
         fdp->display_data_list[y].pinned = false;

         // see if the directory was previously collapsed by looking through
         // the previously saved list of directory names
         if (!selective) {
            for (dx=0; dx < fdp->save_directory_list._length(); ++dx) {
               if ((fdp->save_directory_list[dx].name :== dr) && fdp->save_directory_list[dx].hide) {
                  hide = true;   // stays true for rest of this directory
                  // keep it collapsed
                  fdp->display_data_list[y].hide = true;
                  break;
               }
            }
         }
         fdp->display_data_list[y++].directory_flag = true;
      }
      if (!hide) {
         // show the file if the directory is not hidden
         fdp->alpha_directory_sorted_buf_indexes[z++] = buf_index;
         // add to the list of files for this directory so that the files for
         // this directory can be extension sorted when we come to the end of 
         // the directory.  Each string added to dir_temp_data starts with the
         // file extension but has the filename added after the extension so
         // that files with the same extension are grouped together but sorted
         // by name

         int flen = length(strip_filename(buf_name,'E'));
         dir_temp_data[dtd++] = substr(buf_name,flen+1) :+ 
            strip_filename(buf_name,'P') :+ "\1" :+ buf_index;
         //say(dir_temp_data[dtd-1]);
      }
   }

   // add the last of the extension sorted files
   if (dtd > 0) {
      // extension sort files from the previous directory
      dir_temp_data._sort('I');  // case insensitive
      int dtdx;
      typeless dtdbx;
      _str ext;
      // add them to the list
      for (dtdx = 0; dtdx < dtd; ++dtdx) {
         parse dir_temp_data[dtdx] with ext "\1" dtdbx;
         fdp->alpha_directory_ext_sorted_buf_indexes[z2++] = dtdbx;
      }
   }
}


// callback for for_each_buffer
int GFM_add_to_buf_list1()
{
   fdp->display_data_list[fdp->num_buffers].buf_id = p_buf_id;
   fdp->display_data_list[fdp->num_buffers].buf_name = p_buf_name;
   fdp->display_data_list[fdp->num_buffers].buf_modified = p_modify;
   boolean fm = fdp->display_data_list[fdp->num_buffers].fileman_buffer = 
                                          _modename_eq(p_mode_name,'fileman');
   if (fm) fdp->display_data_list[fdp->num_buffers].buf_name = p_DocumentName;

   fdp->display_data_list[fdp->num_buffers].hide = false;
   fdp->display_data_list[fdp->num_buffers].pinned = false;
   fdp->display_data_list[fdp->num_buffers++].directory_flag = false;
   return 0;
}


// callback for for_each_buffer
int GFM_add_to_buf_list2()
{
   fdp->buffer_list2[fdp->num_buffers2].buf_id = p_buf_id;
   fdp->buffer_list2[fdp->num_buffers2].buf_name = p_buf_name;
   fdp->buffer_list2[fdp->num_buffers2++].buf_modified = p_modify;
   if (_modename_eq(p_mode_name,'fileman')) {
      fdp->buffer_list2[fdp->num_buffers2].buf_name = p_DocumentName;
   }
   return 0;
}


static int find_buf_id_index(int buf_id)
{
   int k;
   for (k=0;k<fdp->num_buffers;++k) {
      if (fdp->display_data_list[k].buf_id == buf_id)
         return k+1;
   }
   return 0;
}

static void generate_buffer_list_and_indexes()
{
   if (fdp->keep_save_directory_list == 0) {
      // because display_data_list doesn't always contain the full list of open 
      // buffer names, save_directory_list is not always regenerated here.  
      fdp->save_directory_list._makeempty();
      int x,dx = 0;
      // copy the directory names that are at the end of the buffer list
      // so their "hide/unhide" status can be remembered
      for (x = fdp->directory_names_start_index; x < fdp->display_data_list._length(); x++) {
         if (fdp->display_data_list[x].directory_flag) {
            fdp->save_directory_list[dx].name = fdp->display_data_list[x].buf_name;
            fdp->save_directory_list[dx++].hide = fdp->display_data_list[x].hide;
         }
      }
   } else {
      --fdp->keep_save_directory_list;
   }

   fdp->num_buffers = 0;
   fdp->display_data_list._makeempty();
   _mdi.p_child.for_each_buffer( 'GFM_add_to_buf_list1' );

   generate_sorted_filename_lists();

   // Form a filename-with-path alpha sorted list of indexes into the buffer
   // list.  This adds directory names to the end of the buffer list and the
   // sorted list of buffer indexes includes an entry for each directory so
   // that files are displayed in order of dir1, file1 ... file-n, dir2 .. etc

   // alpha_directory_sort_bufnames is always called even if the display order
   // isn't set to use this, so as to retain the directory list with its "hide" flags
   if ( fdp->GFM_file_order_mode == GFM_SORT_FILESPEC ) {
      fdp->keep_save_directory_list = 1;
      alpha_directory_sort_bufnames(last_filespec, false);
   }
   else
      alpha_directory_sort_bufnames();

   if (fdp->GFM_file_order_mode == GFM_SORT_RECENT_ACCESS) {
      generate_recent_access_sorted_buf_indexes();
   }
}


static void populate_open_buffer_item( int k, int form_id, int ctidleft, int ctidm1 )
{
   k = k - fdp->buffer_list_view_start_index;

   if (fdp->display_data_list[get_display_data_list_index(k)].directory_flag) {
      // it's a directory name
      ctidm1._lbadd_item(
         form_id._ShrinkFilename( fdp->display_data_list[get_display_data_list_index(k)].buf_name,
                                  pix2scale(ctidm1.p_client_width-15, form_id)) );
      if (fdp->display_data_list[get_display_data_list_index(k)].hide) 
         ctidleft._lbadd_item("",20,pic_index_col1_dir_collapsed);
      else
         ctidleft._lbadd_item("",20,pic_index_col1_dir_expanded);
   } else {
      if (fdp->display_data_list[get_display_data_list_index(k)].fileman_buffer) {
         // it's a file manager buffer
         ctidm1._lbadd_item('.fileman ' :+ ++fileman_id :+ ' ' :+
                            fdp->display_data_list[get_display_data_list_index(k)].buf_name);
      }
      else {
          //_str skey = lookup_reverse_active_shortcut_list(
          //      fdp->display_data_list[get_display_data_list_index(k)].buf_name);
          //if (skey != '') {
          //   skey = ' [' :+ skey :+ ']';
          // }
          ctidm1._lbadd_item(
             strip_filename(
                fdp->display_data_list[get_display_data_list_index(k)].buf_name,'DP') );
      }
      
      // now add the icons or shortcut key name to the left hand column
      _str skey = '';
      if (fdp->setup_data.gfconfig.show_shortcuts_in_col1 || fdp->show_shortcuts_now) {
         skey = '  ' :+ lookup_reverse_active_shortcut_list(
               fdp->display_data_list[get_display_data_list_index(k)].buf_name);
      }
      if (fdp->display_data_list[get_display_data_list_index(k)].buf_modified) {
         if ((fdp->display_data_list[get_display_data_list_index(k)].buf_name == _mdi.p_child.p_buf_name) ||
             (fdp->display_data_list[get_display_data_list_index(k)].buf_name == _mdi.p_child.p_DocumentName))
            ctidleft._lbadd_item(skey,20,pic_index_col1_active_file_mod);
         else
            ctidleft._lbadd_item(skey,20,_pic_index_col1_file_mod);
      } else if ((fdp->display_data_list[get_display_data_list_index(k)].buf_name == _mdi.p_child.p_buf_name) ||
                 (fdp->display_data_list[get_display_data_list_index(k)].buf_name == _mdi.p_child.p_DocumentName)) {
         ctidleft._lbadd_item(skey,20,pic_index_col1_active_file); 
      } else if ( fdp->display_data_list[get_display_data_list_index(k)].pinned ) {
         ctidleft._lbadd_item(skey,20,pic_index_col1_pin);
      } else {
         ctidleft._lbadd_item(skey,20,pic_index_col1_blank);
      }
   }
}


static void populate_shortcut_list_item( int k, int form_id, int ctidleft, int ctidm1 )
{
   //ctidm1._lbadd_item( strip_filename(listman_get_active_list_item_name(k),'DP') );
   //ctidleft._lbadd_item(listman_get_active_list_item_key(k),20,pic_index_col1_blank);

    
   //ctidm1._lbadd_item( strip_filename(active_shortcuts_list[k].name,'DP') );
   ctidm1._lbadd_item( form_id._ShrinkFilename( active_shortcuts_list[k].name,
                            pix2scale(ctidm1.p_client_width-15, form_id)) );
   ctidleft._lbadd_item(active_shortcuts_list[k].key,20,pic_index_col1_blank);
}

/*
static void populate_goback_history_item( int k, int form_id, int ctidleft, int ctidm1 )
{
   goback_item * gob = dlist_getp(fdp->goback_iterator2);
   dlist_prev(fdp->goback_iterator2);

   //ctllist_view1_col1.p_picture = 0;
   ctidleft._lbadd_item(gob->last_line, 20, pic_index_col1_blank);

   ctidm1._lbadd_item( strip_filename(gob->buf_name,'P'));
   //:+ '  ' :+ strip_filename(fdp->goback_list_ptr->list[y].buf_name,'N') );
}
 
*/ 


/*=================================================================================================

   The following functions switch on form_display_mode to decode the type of
   data that is being displayed in the listview.  These functions must all be
   updated when a new type of data is added.

   Currently the display modes are
      1. DISPLAY_MODE_OPEN_BUFFERS
      2. DISPLAY_MODE_GOBACK_HISTORY
      3. DISPLAY_MODE_SHORTCUT_LIST

   static void generate_display_list_data()
   static int get_display_data_list_length()
   static int get_display_data_list_index(int display_index, 
   static void process_listview_col2_lbutton_down(int data_index)
   static void process_listview_col2_mbutton_down(int data_index)
   static void populate_display_data_item(int k, int form_id, int ctidleft, int ctidm1 )
   static _str get_toolbar_caption()
   static boolean check_if_display_list_data_changed()
   _command GFM_toggle_display_mode()
   static void get_file_info_string(_str & res, int index)
   static void process_listviewx_right_mouse_click()

==================================================================================================*/

static void generate_display_list_data()
{
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         generate_buffer_list_and_indexes();
         return;
         /*
      case DISPLAY_MODE_GOBACK_HISTORY :
         fdp->goback_list_ptr = get_goback_list_address(0);
         fdp->goback_selected_listnum = 0;
         fdp->goback_iterator = fdp->goback_iterator2 = dlist_end(*fdp->goback_list_ptr);

         //goback_history_view_start_index2 =
           //  goback_history_view_start_index = fdp->goback_list_ptr->start_index;

         //if (--goback_history_view_start_index < 0) 
            //goback_history_view_start_index = fdp->goback_list_ptr->max_entries - 1;

         goback_history_view_length = calculate_goback_history_length(fdp->goback_selected_listnum);
         //goback_history_view_start_line = 
           // fdp->goback_list_ptr->list[goback_history_view_start_index].last_line;
         goback_project_changed = false;
         return; 
         */
          
      case DISPLAY_MODE_SHORTCUT_LIST :
         if (fdp->show_shortcuts_now) {
            listman_generate_active_shortcuts_list(active_shortcuts_list, true);
         } else {
            listman_generate_active_shortcuts_list(active_shortcuts_list, false);
         }
         return;
   }
}

static int get_display_data_list_length()
{
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         switch (fdp->GFM_file_order_mode) {
            case GFM_SORT_RECENT_ACCESS :
               return fdp->recent_access_sorted_buf_indexes._length();
            case GFM_SORT_DIRECTORY_FILENAME :
               return fdp->alpha_directory_sorted_buf_indexes._length();
            case GFM_SORT_FILESPEC :
               return fdp->alpha_directory_sorted_buf_indexes._length();
            case GFM_SORT_FILENAME :
               return fdp->filename_alpha_sorted_buf_indexes._length();
            case GFM_SORT_EXTENSION_FILENAME :
               return fdp->file_extension_alpha_sorted_buf_indexes._length();
            case GFM_SORT_DIRECTORY_EXTENSION_FILENAME :
               return fdp->alpha_directory_ext_sorted_buf_indexes._length();
         }
         return 0;
         /*
      case DISPLAY_MODE_GOBACK_HISTORY :
         return goback_history_view_length; 
         */ 
      case DISPLAY_MODE_SHORTCUT_LIST :
         return active_shortcuts_list._length();
   }
   return 0;
}


static int get_display_data_list_index(int display_index, 
                                       int start = fdp->buffer_list_view_start_index)
{
   int index = display_index + start;
   if (index >= get_display_data_list_length()) {
      return 0;
   }
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         switch (fdp->GFM_file_order_mode) {
            case GFM_SORT_RECENT_ACCESS :
               return fdp->recent_access_sorted_buf_indexes[index];
            case GFM_SORT_DIRECTORY_FILENAME :
               return fdp->alpha_directory_sorted_buf_indexes[index];
            case GFM_SORT_FILESPEC :
               return fdp->alpha_directory_sorted_buf_indexes[index];
            case GFM_SORT_FILENAME :
               return fdp->filename_alpha_sorted_buf_indexes[index];
            case GFM_SORT_EXTENSION_FILENAME :
               return fdp->file_extension_alpha_sorted_buf_indexes[index];
            case GFM_SORT_DIRECTORY_EXTENSION_FILENAME :
               return fdp->alpha_directory_ext_sorted_buf_indexes[index];
         }
         return 0;
      case DISPLAY_MODE_GOBACK_HISTORY :
         //return index;
         // fall through
      case DISPLAY_MODE_SHORTCUT_LIST :
         return index;
   }
   return 0;
}


static void process_listview_col2_lbutton_down(int data_index)
{
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         if (fdp->display_data_list[data_index].directory_flag) {
            shell( get_env('SystemRoot') :+ '\explorer.exe /n,/e,/select,' :+
                              fdp->display_data_list[data_index].buf_name, 'A' );
         }
         else if ( _mdi.p_child.p_buf_id != fdp->display_data_list[data_index].buf_id ) {
            maybe_holdoff_listview_update();
            mouse_move_holdoff_counter = 3;
            clear_listview_list_line_selection();
            hide_file_info();

            #ifdef debug1
            int k = fdp->display_data_list._length();
            say("-----");
            say(data_index);
            say("  ");
            int h;
            for (h = 0; h < k; ++h) {
               say(fdp->display_data_list[h].buf_name);
               if (h == data_index) {
                  say("    +++++++++++    ");
               }
            }
            say(data_index);
            #endif

            //if (_IsKeyDown(CTRL))
            //{
            //   return;
            //}



            if (fdp->display_data_list[data_index].fileman_buffer) {
               edit('+Q +BI ' :+ fdp->display_data_list[data_index].buf_id);
            }
            else
               edit('+B ' fdp->display_data_list[data_index].buf_name);
         }
         return;

         /*
      case DISPLAY_MODE_GOBACK_HISTORY :
         goback_item * dp = dlist_get_at(fdp->goback_iterator, -data_index);
         if ( _mdi.p_child.p_buf_name != dp->buf_name ) {
            maybe_holdoff_listview_update();
            mouse_move_holdoff_counter = 3;
            clear_listview_list_line_selection();
            hide_file_info();
            edit(maybe_quote_filename(dp->buf_name));
         }
         _mdi.p_child.p_line = dp->last_line;
         _mdi.p_child.p_col = dp->col;
         return;
   */

      case DISPLAY_MODE_SHORTCUT_LIST :
         _str fn = active_shortcuts_list[data_index].name;
         if ( _mdi.p_child.p_buf_name != fn) {
            maybe_holdoff_listview_update();
            mouse_move_holdoff_counter = 3;
            clear_listview_list_line_selection();
            hide_file_info();
            edit(maybe_quote_filename(fn));
         }
         return;

      default : return;
   }
}


static void process_listview_col2_mbutton_down(int data_index)
{
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         if (fdp->display_data_list[data_index].directory_flag)
            close_dir(fdp->display_data_list[data_index].buf_name);
         else if (!fdp->display_data_list[data_index].fileman_buffer) {
            //if (pos('.search',fdp->display_data_list[data_index].buf_name) == 0) {
               _save_non_active(fdp->display_data_list[data_index].buf_name,1);
            //}
         }
         break;

         /*
      case DISPLAY_MODE_GOBACK_HISTORY :
         goback_item * dp = dlist_get_at(fdp->goback_iterator, -data_index);
         _save_non_active(dp->buf_name, 1);
         break; 
         */
          
      case DISPLAY_MODE_SHORTCUT_LIST :
         //_str fn = listman_get_active_list_item_name(data_index);
         _str fn = active_shortcuts_list[data_index].name;
         _save_non_active(fn);
         break;
      default : return;
   }

   if (_mdi.p_child._no_child_windows()==0) {
      _mdi.p_child._set_focus();
   }
}


static void populate_display_data_item(int k, int form_id, int ctidleft, int ctidm1 )
{
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         populate_open_buffer_item(k,form_id,ctidleft,ctidm1);
         return;
         /*
      case DISPLAY_MODE_GOBACK_HISTORY :
         populate_goback_history_item(k,form_id,ctidleft,ctidm1);
         return; 
         */ 
      case DISPLAY_MODE_SHORTCUT_LIST :
         populate_shortcut_list_item(k,form_id,ctidleft,ctidm1);
         return;
   }
}


static _str get_toolbar_caption()
{
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         if (fdp->GFM_file_order_mode == GFM_SORT_RECENT_ACCESS) 
            return 'Recent buffers';
         else
            return 'Open buffers';
      case DISPLAY_MODE_GOBACK_HISTORY :
         return 'Goback history';
      case DISPLAY_MODE_SHORTCUT_LIST :
         return 'List ' :+ listman_get_active_list_name(); 
   }
   return 'What am I?'; 
}


static boolean check_if_display_list_data_changed()
{
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         return check_if_buffer_list_has_changed();
         /*
      case DISPLAY_MODE_GOBACK_HISTORY :
         return goback_project_changed ||
                     (fdp->goback_iterator != dlist_end(*fdp->goback_list_ptr));
                     */

      case DISPLAY_MODE_SHORTCUT_LIST :
         return false;
   }
   return false;
}


_command GFM_toggle_display_mode()
{
   fdp->buffer_list_view_start_index = 0;

   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :

         fdp->goback_list_ptr = get_goback_list_address(0);
         fdp->goback_selected_listnum = 0;
         fdp->goback_iterator = fdp->goback_iterator2 = dlist_end(*fdp->goback_list_ptr);
         fdp->requested_display_mode = DISPLAY_MODE_GOBACK_HISTORY;
         break;
      case DISPLAY_MODE_GOBACK_HISTORY :
         fdp->requested_display_mode = DISPLAY_MODE_SHORTCUT_LIST;
         break;
      case DISPLAY_MODE_SHORTCUT_LIST :
         fdp->requested_display_mode = DISPLAY_MODE_OPEN_BUFFERS;
         break;
   }
   fdp->redo_listview_list_counter = 2;
}


static void get_file_info_string(_str & res, int index)
{
   int y = get_display_data_list_index(index);
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         res = _file_date(fdp->display_data_list[y].buf_name, 'L') :+ "  " :+
               file_time(fdp->display_data_list[y].buf_name) :+ "  " :+ 
               fdp->display_data_list[y].buf_name;
         return;

         /*
      case DISPLAY_MODE_GOBACK_HISTORY :
         res = ((goback_item*)dlist_get_at(fdp->goback_iterator, -y))->buf_name;
         return; 
         */
          
      case DISPLAY_MODE_SHORTCUT_LIST :
         res = /* 'List: ' :+ listman_get_active_list_name() \n :+ */
               active_shortcuts_list[y].key :+ '  ' :+ active_shortcuts_list[y].name;
         //res = listman_get_active_list_item_key(index) :+ ' ' :+ 
           //                          listman_get_active_list_item_name(index);
         return;
   }
   res = '';
}


static void process_listviewx_right_mouse_click()
{
   hide_file_info();
   switch (fdp->form_display_mode) {
      case DISPLAY_MODE_OPEN_BUFFERS :
         process_listviewx_right_mouse_click_open_buffers();
         return;
      case DISPLAY_MODE_GOBACK_HISTORY :
         return;  // what ?
   }
}


/*=================================================================================================

   Above here are the functions that switch on form_display_mode to decode the
   type of data that is being displayed in the listview.  These functions must
   all be updated when a new type of display information is added.

   Currently the display modes are
      1. DISPLAY_MODE_OPEN_BUFFERS
      2. DISPLAY_MODE_GOBACK_HISTORY

   static void generate_display_list_data()
   static int get_display_data_list_length()
   static int get_display_data_list_index(int display_index, 
   static void process_listview_col2_lbutton_down(int data_index)
   static void process_listview_col2_mbutton_down(int data_index)
   static void populate_display_data_item(int k, int form_id, int ctidleft, int ctidm1 )
   static _str get_toolbar_caption()
   static boolean check_if_display_list_data_changed()
   _command GFM_toggle_display_mode()
   static void get_file_info_string(_str & res, int index)
   static void process_listviewx_right_mouse_click()

==================================================================================================*/


int pix2scale(int pix,int form_id)
{
   return _dx2lx(form_id.p_xyscale_mode,pix);
}


int scale2pix(int scale,int form_id)
{
   return _lx2dx(form_id.p_xyscale_mode,scale);
}


static void set_text_info1( int form_id,  int st ,_str tx)
{
   form_id.ctltext1.p_text = tx;
   fdp->text_info1_state = st;
}


static void set_text_info1_show_active_file(int form_id)
{
   int buf_list_length = get_display_data_list_length();
   int last_item_index;
   last_item_index = (fdp->buffer_list_view_start_index +
      (fdp->listview_num_lists*fdp->listview_lines_per_list));

   if (last_item_index > buf_list_length)
      last_item_index = buf_list_length;

   _str txfn = strip_filename(_mdi.p_child.p_buf_name,'DP');
   _str tx = (fdp->buffer_list_view_start_index+1) :+
      '-' :+ last_item_index :+ '/ ' :+ buf_list_length :+ ':   ' :+ txfn;

   if (form_id.ctltext1._text_width(tx) + pix2scale(5,form_id) > form_id.ctltext1.p_width) {
      set_text_info1(form_id,TEXT_INFO1_STATE_ACTIVE_FILE, txfn );
   } else {
      set_text_info1(form_id,TEXT_INFO1_STATE_ACTIVE_FILE, tx );
   }
}


static void set_text_info1_show_index(int form_id)
{
   int buf_list_length = get_display_data_list_length();
   int last_item_index;
   last_item_index = (fdp->buffer_list_view_start_index +
      (fdp->listview_num_lists*fdp->listview_lines_per_list));

   if (last_item_index > buf_list_length)
      last_item_index = buf_list_length;

   _str tx = (fdp->buffer_list_view_start_index+1) :+
      '-' :+ last_item_index :+ '/ ' :+ buf_list_length;

   set_text_info1(form_id,TEXT_INFO1_STATE_ACTIVE_FILE, tx );
}


static void calculate_info_window_position(popup_window_pos_data * dp )
{
   int scr_ht = _screen_height();  // pixels
   int scr_wid = _screen_width();
   dp->mouse_x = mou_last_x('D');  // pixels
   dp->mouse_y = mou_last_y('D');

   if (dp->mouse_y > scr_ht/2) {
      dp->ref_y = dp->mouse_y - dp->dist_top;
      dp->ref_y_is_top = false;  // ref_y is lower edge for popup window
   } else {
      dp->ref_y = dp->mouse_y + dp->dist_top;
      dp->ref_y_is_top = true;  // ref_y is top edge for popup window
   }

   if (dp->mouse_x > scr_wid/2) {
      dp->ref_x = dp->mouse_x - dp->dist_left;
      dp->ref_x_is_left = false;  // ref_x is right edge for popup window
   } else {
      dp->ref_x = dp->mouse_x + dp->dist_right;
      dp->ref_x_is_left = true;  // ref_x is top edge for popup window
   }
}


static void check_show_file_info(_str tx[] = null)
{
   /**************************************************************************** 
    
   This thing makes slick steal the focus and pop up its toolbar windows which 
   is very annoying so it is disabled 
    
   if (fdp->GFileman_file_info_showing && (last_file_info_text == tx[0])) {
      return;
   }
   if (!fdp->GFileman_file_info_showing &&
      (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC)) {
      fdp->GFileman_might_switch_focus = true;
   }
   fdp->GFileman_file_info_showing = true;
   GFileman_show_file_info2( &fdp->win_pos_data, tx);
   //fdp->GFileman_might_switch_focus = false;
   last_file_info_text = tx[0]; 
    
   *****************************************************************************/ 
}


static void hide_file_info()
{
   // fdp->GFileman_file_info_showing = false;
   // GFileman_hide_file_info2(special_x, special_y);
}


static void check_for_new_ctrl_key_down()
{
   if (_IsKeyDown(CTRL)) {
      if (!fdp->last_ctrl_key_down_state) {
         fdp->viewx_col2_move_mode = !fdp->viewx_col2_move_mode;
         fdp->last_ctrl_key_down_state = true;
      }
   } else {
      fdp->last_ctrl_key_down_state = false;
   }
}



// todo - any fix for this ??
// it's a nuisance to have to create _commands that are only used from a menu
_command GFM_collapse_all_directories() name_info(',')
{
   int k = 0;
   while (k < get_display_data_list_length()) {
      if (fdp->display_data_list[get_display_data_list_index(k)].directory_flag)
         fdp->display_data_list[get_display_data_list_index(k)].hide = true;
      ++k;
   }
   generate_display_list_data();
   resize_listview(p_active_form);
}

_command GFM_expand_all_directories()
{
   int k = 0;
   while (k < get_display_data_list_length()) {
      if (fdp->display_data_list[get_display_data_list_index(k)].directory_flag)
         fdp->display_data_list[get_display_data_list_index(k)].hide = false;
      ++k;
   }
   generate_display_list_data();
   resize_listview(p_active_form);
}

_command GFM_open_from_here()
{
   chdir(strip_filename(right_mouse_buf_name,'N'),1);
   gui_open();
}

_command GFM_right_mouse_menu_edit()
{
   edit('+b ' right_mouse_buf_name );
}



// pinned_filenames array is sorted with _sort('F'_fpos_case)
_command GFM_right_mouse_menu_pin()
{
   int x,y;
   _str copy_list[];
   int list_index = get_display_data_list_index(right_mouse_item_index);

   _str bname = fdp->display_data_list[list_index].buf_name;
   //fdp->pinned_filenames._sort('F'_fpos_case);
   if (fdp->display_data_list[list_index].pinned) {
      fdp->display_data_list[list_index].pinned = false;

      // if the filename is in the pinned_filenames list then remove it
      copy_list = fdp->pinned_filenames;
      fdp->pinned_filenames._makeempty();
      y = 0;
      for (x=0; x < copy_list._length(); ++x) {
         if ( bname != copy_list[x] ) {
            fdp->pinned_filenames[y++] = copy_list[x];
         }
      }

   } else {
      // add (insert?) the pinned filename into the list if it's not there
      fdp->display_data_list[list_index].pinned = true;
      for (x=0; x < fdp->pinned_filenames._length(); ++x) {
         if (bname == fdp->pinned_filenames[x]) {
            return 0;
         }
         /*******
         switch (stricmp(bname,fdp->pinned_filenames[x])) {
         case 0 :
            return 0;  // already in the list??
         case -1 :
            // insert before entry x
            for (y = fdp->pinned_filenames._length(); y > x; --y) {
               fdp->pinned_filenames[y] = fdp->pinned_filenames[y-1];
            }
            fdp->pinned_filenames[x] = bname;
            return 0;
         default : 
            break;  // keep looking
         }
         ***********/
      }
      // add to the end, then sort
      fdp->pinned_filenames[fdp->pinned_filenames._length()] = bname;
      fdp->pinned_filenames._sort('F'_fpos_case);
   }
}

// todo - works in Windows only
_command GFMPopupExploreFile()
{
   shell( get_env('SystemRoot') :+ '\explorer.exe /n,/e,/select,' :+
                                              right_mouse_buf_name, 'A' );
}


static void close_dir(_str dir_name)
{
   fdp->file_names_from_dir_close._makeempty();
   int k = 0;
   while (k < get_display_data_list_length()) {
      if (!fdp->display_data_list[get_display_data_list_index(k)].directory_flag)
      {
         if (strip_filename(fdp->display_data_list[get_display_data_list_index(k)].buf_name,'NE') == dir_name) {
            fdp->file_names_from_dir_close[fdp->file_names_from_dir_close._length()] = 
               fdp->display_data_list[get_display_data_list_index(k)].buf_name;
         }
      }
      ++k;
   }
   for (k = 0; k < fdp->file_names_from_dir_close._length(); ++k) {
      _save_non_active(fdp->file_names_from_dir_close[k],1);
   }
   generate_display_list_data();
   resize_listview(p_active_form);
}


_command void GFM_right_mouse_menu_close_dir() name_info(',')
{
   _str dir_name;
   if (fdp->display_data_list[get_display_data_list_index(right_mouse_item_index)].directory_flag) 
      dir_name = right_mouse_buf_name;
   else
      dir_name = strip_filename(right_mouse_buf_name,"NE");

   close_dir(dir_name);
}


_command GFM_right_mouse_menu_close() name_info(',')
{
   int status=_save_non_active(right_mouse_buf_name,1);
   return(status);
}

_command GFM_right_mouse_menu_copy_path() name_info(',')
{
   push_clipboard_itype('CHAR','',1,true);
   append_clipboard_text(strip_filename(right_mouse_buf_name,"NE"));
}


_command void GFM_project_add_file() name_info(',')
{
   if (_message_box('Add to project?  : ' :+ _project_name :+ \r :+ 
                    'File : ' :+ right_mouse_buf_name, "GFileman", MB_YESNO) == IDYES)
   {
      project_add_file(right_mouse_buf_name);
   }
}


// This function handles right click on a filename for all "4 columns"
static void process_listviewx_right_mouse_click_open_buffers()
{
   GFM_form_data * save_fxp = fdp;
   hide_file_info();
   right_mouse_buf_name = 
      fdp->display_data_list[get_display_data_list_index(right_mouse_item_index)].buf_name;

   int index=find_index("GFilemanViewXMid1RightClickMenu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');

   // build the menu
   if (!fdp->display_data_list[get_display_data_list_index(right_mouse_item_index)].directory_flag) {

      _menu_insert(menu_handle,0,MF_ENABLED,
                   "&Edit "strip_filename(right_mouse_buf_name,'P'),
                   "GFM_right_mouse_menu_edit","","",'Edit 'right_mouse_buf_name);

      if (fdp->display_data_list[get_display_data_list_index(right_mouse_item_index)].pinned) {
         _menu_insert(menu_handle,-1,MF_ENABLED,
                      "&Unpin "strip_filename(right_mouse_buf_name,'P'),
                      "GFM_right_mouse_menu_pin","","",'Unpin 'right_mouse_buf_name);
      } else {
         _menu_insert(menu_handle,-1,MF_ENABLED,
                      "&Pin "strip_filename(right_mouse_buf_name,'P'),
                      "GFM_right_mouse_menu_pin","","",'Pin 'right_mouse_buf_name);
      }

      _menu_insert(menu_handle,-1,MF_ENABLED,
         "&Close "strip_filename(right_mouse_buf_name,'P'),
         "GFM_right_mouse_menu_close","","",'Close 'right_mouse_buf_name);

   }

   _menu_insert(menu_handle,-1,MF_ENABLED,
      "&Explore "strip_filename(right_mouse_buf_name,'P'),
      "GFMPopupExploreFile","","",'Explore 'right_mouse_buf_name);

   _menu_insert(menu_handle,-1,MF_ENABLED,
      "Copy &path to ClipBd",
      "GFM_right_mouse_menu_copy_path","","",
      'Copy to ClipBd : ' strip_filename(right_mouse_buf_name,'EN'));

   _menu_insert(menu_handle,-1,MF_ENABLED,
      "Collapse directories",
      "GFM_collapse_all_directories","","",
      'Collapse all directories ');

   _menu_insert(menu_handle,-1,MF_ENABLED,
      "Expand directories",
      "GFM_expand_all_directories","","",
      'Expand all directories ');

   _menu_insert(menu_handle,-1,MF_ENABLED,
      "Open from here",
      "GFM_open_from_here","","",
      'Open from here ');

   _menu_insert(menu_handle,-1,MF_ENABLED,
      "Close directory",
      "GFM_right_mouse_menu_close_dir","","",
      'Close all in directory ' :+ right_mouse_buf_name);

   _menu_insert(menu_handle, -1, MF_ENABLED, "&Configure",
      "GFileman_form_configure_command","","", 
      'Configure ' :+ p_active_form.p_name);

   _menu_insert(menu_handle, -1, MF_ENABLED, "&Add to project",
      "GFM_project_add_file","","", 
      'Add to project  : ' :+ right_mouse_buf_name);


   // Show the menu.
   int x =100;
   int y=100;
   x=mou_last_x('M')-x;y=mou_last_y('M')-y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status=_menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);
   fdp = save_fxp;
   fdp->redo_listview_list_counter = 2;
   fdp->listview_force_line_reselect = true;
   clear_listview_list_line_selection();

   // set the focus back

   if (_mdi.p_child._no_child_windows()==0) {
      _mdi.p_child._set_focus();
   }
}


#ifdef nothing123
// do_draw_box draws a rectangle around a filename - an alternative to the
// "builtin" list box highlighting method - it currently overwrites one column
// of pixels in the filename that it shouldn't but you hardly notice...
// - and it goesn't get redrawn by any repaint so it's prone to disappearing...
static int x1_box; 
static int y1_box; 
static int y2_box; 
static int x2_box;

static void do_draw_box(int ctlid, int line_num, boolean erase = false)
{
   typeless dsetup;
   ctlid._save_draw_setup(dsetup);
   ctlid.p_draw_mode = PSDM_COPYPEN;
   ctlid.p_draw_style = PSDS_SOLID;

   x1_box = pix2scale(2,ctlid);
   y1_box = ctlid._text_height() * line_num; // + pix2scale(1,ctlid);
   y2_box = y1_box + ctlid._text_height(); // - pix2scale(2,ctlid);

   ctlid.p_line = line_num+1;
   x2_box = ctlid._text_width( ctlid._lbget_text() ) + pix2scale(10,ctlid);

   int x2 = ctlid.p_width - pix2scale(1,ctlid);

   if (x2_box > x2) {
      x2_box = x2;
   }

   if (erase) {
      ctlid._draw_rect(x1_box,y1_box,x2_box,y2_box, col2_backcolor );
   } else {
      ctlid._draw_rect(x1_box,y1_box,x2_box,y2_box, _rgb(183,0,183)); 
   }
   ctlid._restore_draw_setup(dsetup);
}

static void clear_listview_list_line_selection_v1(boolean force_refresh = false) 
{
   if (!fdp->listview_line_is_selected)
      return;
   do_draw_box(fdp->listview_col2_control_list[
      fdp->listview_selected_list_num],fdp->listview_selected_line_num, true);
   fdp->listview_line_is_selected = false;
}

#endif

static void clear_listview_list_line_selection_v2(boolean force_refresh = false) 
{
   if (!fdp->listview_line_is_selected)
      return;

   int k;
   for (k = 0; k < fdp->listview_col2_control_list._length(); ++k) {
      int w = fdp->listview_col2_control_list[k].p_Nofselected;
      fdp->listview_col2_control_list[k]._lbdeselect_line();
      if (force_refresh && w > 0) {
         // this call to refresh is needed because the control isn't
         // always getting repainted when needed, resulting in a line
         // being left highlighted/selected longer than wanted
         fdp->listview_col2_control_list[k].refresh();
      }
   }
   fdp->listview_line_is_selected = false;
}

static void clear_listview_list_line_selection(boolean force_refresh = false) 
{
   //if (fdp->setup_data.gfconfig.selection_indication_solid)
      clear_listview_list_line_selection_v2(force_refresh);
   //else
      //clear_listview_list_line_selection_v1(force_refresh);
}

static void set_listview_list_line_selection_v2(int list_num, int line_num, boolean redo = false )
{
   if ( !redo && fdp->listview_line_is_selected && 
      (fdp->listview_selected_list_num == list_num) &&
      (fdp->listview_selected_line_num == line_num) )
      return;


   int k;
   for (k = 0; k < fdp->listview_col2_control_list._length(); ++k) {
      fdp->listview_col1_control_list[k]._lbdeselect_all();
      fdp->listview_col2_control_list[k]._lbdeselect_all();
   }
   fdp->listview_selected_list_num = list_num;
   fdp->listview_selected_line_num = line_num;
   if (line_num < fdp->listview_num_lines_in_list[list_num]) {
      fdp->listview_line_is_selected = true;
      fdp->listview_col2_control_list[list_num].p_line = line_num + 1;
      fdp->listview_col2_control_list[list_num]._lbselect_line();
   }
}

#ifdef nothing123
static void set_listview_list_line_selection_v1(int list_num, int line_num, boolean redo = false )
{
   if ( !redo && fdp->listview_line_is_selected && 
      (fdp->listview_selected_list_num == list_num) &&
      (fdp->listview_selected_line_num == line_num) )
      return;

   // erase
   if (fdp->listview_line_is_selected) {
      if (fdp->listview_selected_line_num < 
            fdp->listview_num_lines_in_list[fdp->listview_selected_list_num]) {
         do_draw_box(fdp->listview_col2_control_list[
            fdp->listview_selected_list_num],fdp->listview_selected_line_num, true);
      }
   }
   fdp->listview_selected_list_num = list_num;
   fdp->listview_selected_line_num = line_num;
   if (line_num < fdp->listview_num_lines_in_list[list_num]) {
      fdp->listview_line_is_selected = true;
      do_draw_box(fdp->listview_col2_control_list[list_num],line_num, false);
   }
}

#endif


static void set_listview_list_line_selection(int list_num, int line_num, boolean redo = false )
{
   //if (fdp->setup_data.gfconfig.selection_indication_solid)
      set_listview_list_line_selection_v2(list_num,line_num,redo);
   //else
     // set_listview_list_line_selection_v1(list_num,line_num,redo);
}


static void maybe_holdoff_listview_update()
{
   if (holdoff_listview_update_mode) {
      holdoff_file_view_list_update = true;
      goback_set_buffer_history_pending_mode();
   }
}

static void ctllist_file_viewx_col2_mouse_move( int list_num)
{
   int linenum, ctlid, index_offset, lines_in_list;
   int form_id = p_active_form;
   int k;
   boolean right_mouse_flag = false;
   boolean left_mouse_flag = false;
   static int mouse_move_holdoff_mou_x, mouse_move_holdoff_mou_y;

   set_form_data_ptr(p_active_form);
   if (list_num >= fdp->listview_num_lists )
      return;

   // but only show file info if the cursor is within X%
   // of the right hand edge of the "list view"
   int TooltipPercent = fdp->setup_data.gfconfig.TooltipPercent;
   ctlid = fdp->listview_col2_control_list[list_num];
   index_offset = 0;
   for (k = 0; k < list_num; ++k) {
      index_offset += fdp->listview_num_lines_in_list[k];
   }
   lines_in_list = fdp->listview_num_lines_in_list[list_num];
   linenum = mou_last_y() intdiv (_ly2dy(ctlid.p_xyscale_mode,ctlid._text_height()) + 2);

   if (linenum >= lines_in_list) {
      clear_listview_list_line_selection();
      hide_file_info();
      return;
   } 

   // mouse_move_holdoff_counter is set to 3 when left or right click occurs on
   // a filename.  This is used to get an early exit from this function until 
   // the mouse has moved 5 or more pixels from where the mouse click occurred
   if ( mouse_move_holdoff_counter > 1 ) {
      --mouse_move_holdoff_counter;
      mouse_move_holdoff_mou_x = ctlid.mou_last_x();
      mouse_move_holdoff_mou_y = ctlid.mou_last_y();
      //say( mouse_move_holdoff_mou_x :+ ' ' :+ mouse_move_holdoff_mou_y :+
      //   ' ' :+ ctlid.mou_last_x() :+ ' ' :+ ctlid.mou_last_y() );
      return;
   } else if (mouse_move_holdoff_counter > 0) {
      if ( (abs(ctlid.mou_last_y() - mouse_move_holdoff_mou_y) < 5 )  &&
         (abs(ctlid.mou_last_x() - mouse_move_holdoff_mou_x) < 5 ) ) {
         return;
      }
      mouse_move_holdoff_counter = 0;
   }

   fdp->win_pos_data.dist_top = scale2pix(ctlid._text_height(),form_id)*3;
   fdp->win_pos_data.dist_bottom = scale2pix(ctlid._text_height(),form_id)*3;
   fdp->win_pos_data.dist_left = 50;  // pixels
   fdp->win_pos_data.dist_right = 50;  // pixels

   _str a1[];
   get_file_info_string(a1[0], linenum + index_offset);

   // TODO - the calls to check_for_new_ctrl_key_down() are commented for the
   // moment, so the following comment doesn't apply - I might re-enable this
   // feature sometime. ("goback history mode" has viewx_col2_move_mode set true.)

   // when viewx_col2_move_mode is true, the current buffer changes as the
   // mouse moves up and down the file list without the mouse being clicked.
   // viewx_col2_move_mode is toggled when the ctrl key is pressed while moving
   // the mouse

   //check_for_new_ctrl_key_down();

   if ( !fdp->viewx_col2_move_mode ) {

      // if file info (file date/time/size etc) is already showing then update it if necessary
      if (fdp->GFileman_file_info_showing) {
         if (fdp->listview_line_is_selected && 
            (fdp->listview_selected_list_num == list_num) &&
            (fdp->listview_selected_line_num == linenum)) {

            // The selected line hasn't changed so no need to update file info
            // Set the timer to a fast rate so that when the mouse moves
            // off the form, the line selection and file info form are 
            // cleared quickly.  The fast rate will be immediately changed back 
            // to the normal rate when the next timer_callback occurs.

            _kill_timer(GFM_timer_handle);
            GFM_timer_handle = _set_timer(400,GFileman_timer_callback);
            if (ctlid.mou_last_x() < (ctlid.p_client_width * TooltipPercent / 100) ) {
               hide_file_info();
            }
            return;
         }
         set_listview_list_line_selection( list_num, linenum);
         if (ctlid.mou_last_x() < (ctlid.p_client_width * TooltipPercent / 100) ) {
            // file info is shown only when the cursor is within XX percent
            // of the right hand edge of the "list view"
            hide_file_info();
            message(a1[0]);
            return;
         }
         message(a1[0]);
         calculate_info_window_position( &fdp->win_pos_data );
         check_show_file_info(a1);
         return;
      }

      // highlight the line the cursor is on
      set_listview_list_line_selection( list_num, linenum);

      // but only show file info if the cursor is within X%
      // of the right hand edge of the "list view"
      if (ctlid.mou_last_x() < (ctlid.p_client_width * TooltipPercent / 100) ) {
         message(a1[0]);
         return;
      }
      // wait 400 millisecs before showing file info
      mou_mode(1);
      mou_capture();
      _set_timer(400);
      boolean exit_event_loop = false;
      while (!exit_event_loop) {
         _str event=get_event();
         set_form_data_ptr(form_id);
         switch (event) {
            case ON_TIMER :
               get_file_info_string(a1[0], linenum + index_offset);
               calculate_info_window_position( &fdp->win_pos_data );
               check_show_file_info(a1);
               fdp->GFileman_file_info_showing = true;
               exit_event_loop = true;
               break;

            case MOUSE_MOVE:
               int x = ctlid.mou_last_x();   // pixels
               int y = ctlid.mou_last_y();
               int xline = y intdiv (_ly2dy( ctlid.p_xyscale_mode, ctlid._text_height()) + 2);
               if ( x < 0 || x > ctlid.p_client_width ||
                    y < 0 || y > ctlid.p_client_height  ||
                    xline >= lines_in_list) {
                  clear_listview_list_line_selection();
                  hide_file_info();
                  exit_event_loop = true;
                  break;
               }
               if ( linenum != xline ) {
                  linenum = xline;
                  set_listview_list_line_selection( list_num, linenum);
                  _kill_timer();
                  _set_timer(400);
               }
               // Only show file info if the cursor is within XX percent
               // of the right hand edge of the "list view"
               if (ctlid.mou_last_x() < (ctlid.p_client_width * TooltipPercent / 100) ) {
                  hide_file_info();
                  exit_event_loop = true;
               }
               break;

            case LBUTTON_DOWN :
               // todo - buf_id is not always meaningful
               //if ( _mdi.p_child.p_buf_id != fdp->display_data_list[
                 //   get_display_data_list_index(linenum + index_offset)].buf_id ) {
                  mouse_move_holdoff_counter = 3;
                  left_mouse_flag = true;
               //}
               exit_event_loop = true;
               break;

            case RBUTTON_UP :
               right_mouse_item_index = linenum + index_offset;
               right_mouse_flag = true;
               mouse_move_holdoff_counter = 3;
               exit_event_loop = true;
               break;

            case ON_KEYSTATECHANGE :
               if (_IsKeyDown(CTRL)) {
                  exit_event_loop = true;
               }
               break;
            default:
               exit_event_loop = true;
               break;

         }
      }   // while (!exit_event_loop)

      //clear_listview_list_line_selection();
      //hide_file_info();
      mou_mode(0);
      _kill_timer();
      mou_release();
      if (left_mouse_flag) {
         process_listview_col2_lbutton_down(get_display_data_list_index(linenum + index_offset));
      } else if (right_mouse_flag) {
         //holdoff_file_view_list_update = true;
         process_listviewx_right_mouse_click();
      }
      return;
   } else {
      // fdp->viewx_col2_move_mode is true
      
      // when viewx_col2_move_mode is true, the current buffer changes as the
      // mouse moves up and down the file list without the mouse being clicked.

      boolean flag = false;
      int data_index = get_display_data_list_index(linenum + index_offset);

      /*
      if (is_display_mode_goback_history()) {
         goback_item * dp = dlist_get_at(fdp->goback_iterator, -data_index);
         if ( (_mdi.p_child.p_buf_name != dp->buf_name) || 
              (_mdi.p_child.p_line != dp->last_line) ) {
            flag = true;
         }
      }
      else 
      */
       
      if (_mdi.p_child.p_buf_id != 
               fdp->display_data_list[get_display_data_list_index(linenum+index_offset)].buf_id) {
         flag = true;
      }
      if (flag) {
         set_listview_list_line_selection( list_num, linenum);
         hide_file_info();
         mou_mode(1);
         mou_capture();
         if (is_display_mode_goback_history()) 
            _set_timer(200);
         else
            _set_timer(400);

         boolean done_switch = false;
         boolean exit_event_loop = false;
         while (!exit_event_loop) {
            _str event=get_event();
            set_form_data_ptr(form_id);
            switch (event) {
               case ON_TIMER :
                  if (done_switch) {
                     exit_event_loop = true;
                  } else {
                     // ignore keys for one second after switching
                     _kill_timer();
                     goback_set_buffer_history_pending_mode();
                     holdoff_file_view_list_update = true;

                     /*
                     if (is_display_mode_goback_history()) {
                        goback_item * dp = dlist_get_at(fdp->goback_iterator, -data_index);
                        if (_mdi.p_child.p_buf_name != dp->buf_name)
                           edit(maybe_quote_filename(dp->buf_name));
                        _mdi.p_child.p_line = dp->last_line;
                     }
                     else  
                     */ 
                     {
                        edit('+b ' fdp->display_data_list[data_index].buf_name);
                     }
                     _set_timer(1000);
                     done_switch = true;
                  }
                  break;

               case ON_KEYSTATECHANGE :
                  //check_for_new_ctrl_key_down();
                  if ( !fdp->viewx_col2_move_mode ) {
                     exit_event_loop = true;
                  }
                  break;

               case MOUSE_MOVE:
                  int xline = mou_last_y() intdiv 
                     (_ly2dy(ctlid.p_xyscale_mode, ctlid._text_height()) + 2);
                  boolean hover = (mou_last_x() > 0)\
                     && (mou_last_x() < ctlid.p_client_width);
                  if ( linenum != xline || !hover ) {
                     exit_event_loop = true;
                  }
                  break;
            } // switch
         }  // while (!exit_event_loop)
         mou_mode(0);
         _kill_timer();
         mou_release();
      }
   }
}

void ctllist_view1_col2.mouse_move()
{
   set_form_data_ptr(p_active_form);
   ctllist_file_viewx_col2_mouse_move(p_user);
}


static void ctllist_file_viewx_col2_lbutton_down(int list_num)
{
   int linenum, ctlid, index_offset, lines_in_list, k;
   int form_id = p_active_form;
   set_form_data_ptr(p_active_form);
   if (list_num >= fdp->listview_num_lists )
      return;

   ctlid = fdp->listview_col2_control_list[list_num];
   index_offset = 0;
   for (k = 0; k < list_num; ++k) {
      index_offset += fdp->listview_num_lines_in_list[k];
   }
   lines_in_list = fdp->listview_num_lines_in_list[list_num];
   linenum = mou_last_y() intdiv (_ly2dy(ctlid.p_xyscale_mode,ctlid._text_height()) + 2);

   //say('Mou2 ' :+ mou_last_y() :+ ' ' :+ _ly2dy(ctlid.p_xyscale_mode,ctlid._text_height()));

   if (linenum >= lines_in_list)
      return;

   process_listview_col2_lbutton_down(get_display_data_list_index(linenum + index_offset));
}


void ctllist_view1_col2.lbutton_down()
{
   ctllist_file_viewx_col2_lbutton_down(p_user);
}



static void ctllist_file_viewx_col2_mbutton_down(int list_num)
{
   int linenum, ctlid, index_offset, lines_in_list, k;
   int form_id = p_active_form;

   set_form_data_ptr(p_active_form);
   if (list_num >= fdp->listview_num_lists )
      return;
   ctlid = fdp->listview_col2_control_list[list_num];
   index_offset = 0;
   for (k = 0; k < list_num; ++k) {
      index_offset += fdp->listview_num_lines_in_list[k];
   }
   lines_in_list = fdp->listview_num_lines_in_list[list_num];
   linenum = mou_last_y() intdiv (_ly2dy(ctlid.p_xyscale_mode,ctlid._text_height()) + 2);
   if (linenum >= lines_in_list)
      return;

   process_listview_col2_mbutton_down(get_display_data_list_index(linenum + index_offset));
}


void ctllist_view1_col2.mbutton_down()
{
   ctllist_file_viewx_col2_mbutton_down(p_user);
}


static void ctllist_file_viewx_col2_rbutton_up( int list_num )
{
   int linenum, ctlid, index_offset, lines_in_list, k;
   int form_id = p_active_form;

   set_form_data_ptr(p_active_form);
   if (list_num >= fdp->listview_num_lists )
      return;
   ctlid = fdp->listview_col2_control_list[list_num];
   index_offset = 0;
   for (k = 0; k < list_num; ++k) {
      index_offset += fdp->listview_num_lines_in_list[k];       
   }
   lines_in_list = fdp->listview_num_lines_in_list[list_num];
   linenum = mou_last_y() intdiv (_ly2dy(ctlid.p_xyscale_mode,ctlid._text_height()) + 2);
   if (linenum >= lines_in_list)
      return;
   right_mouse_item_index = linenum + index_offset;
   mouse_move_holdoff_counter = 3;
   hide_file_info();
   process_listviewx_right_mouse_click();
}



static void ctllist_file_viewx_col1_left_lbutton_down(
            int ctlid_col1,int ctlid_col2, int index_offset, int lines_in_list)
{
   int linenum;
   linenum = ctlid_col1.mou_last_y() intdiv
      (_ly2dy( ctlid_col2.p_xyscale_mode,ctlid_col2._text_height()) + 2);

   if (linenum < lines_in_list) 
   {
      //if (_IsKeyDown(CTRL))
      //{
      //   return;
      //}


      if (fdp->display_data_list[get_display_data_list_index(linenum+index_offset)].directory_flag) 
      {
         fdp->display_data_list[get_display_data_list_index(linenum+index_offset)].hide =
            ! fdp->display_data_list[get_display_data_list_index(linenum+index_offset)].hide;
         generate_display_list_data();
         resize_listview(p_active_form);
      } 
      else 
      {
         _save_non_active(fdp->display_data_list[get_display_data_list_index(linenum+index_offset)].buf_name,1);
      }

      if (_mdi.p_child._no_child_windows()==0) {
         _mdi.p_child._set_focus();
      }
   }
}


void ctllist_view1_col2.rbutton_up()
{
   set_form_data_ptr(p_active_form);
   ctllist_file_viewx_col2_rbutton_up(p_user);
}



void ctllist_view1_col1.lbutton_down()
{
   set_form_data_ptr(p_active_form);

   int index_offset = 0;
   int k;    
   for (k = 0; k < p_user; ++k) {
      index_offset += fdp->listview_num_lines_in_list[k];
   }

   ctllist_file_viewx_col1_left_lbutton_down(
      fdp->listview_col1_control_list[p_user],
      fdp->listview_col2_control_list[p_user],
      index_offset, 
      fdp->listview_num_lines_in_list[p_user] );
}


void view1_ctlimage1.lbutton_down()
{
   set_form_data_ptr(p_active_form);
   int mx = mou_last_x("M");
   if (mx > fdp->listview_col1_control_list[p_user].p_width) {
      ctllist_file_viewx_col2_lbutton_down(p_user);
   }
   else
   {
      int index_offset = 0;
      int k;    
      for (k = 0; k < p_user; ++k) {
         index_offset += fdp->listview_num_lines_in_list[k];
      }

      ctllist_file_viewx_col1_left_lbutton_down(
         fdp->listview_col1_control_list[p_user],
         fdp->listview_col2_control_list[p_user],
         index_offset, 
         fdp->listview_num_lines_in_list[p_user] );
   }


}


void view1_ctlimage1.rbutton_up()
{
   set_form_data_ptr(p_active_form);
   int mx = mou_last_x("M");
   if (mx > fdp->listview_col1_control_list[p_user].p_width) {
      ctllist_file_viewx_col2_rbutton_up(p_user);
   }

}



void view1_ctlimage1.mouse_move()
{
   int num_vis, num_not_vis_at_end;
   set_form_data_ptr(p_active_form);
   int num_rows = fdp->listview_num_lists * fdp->listview_lines_per_list;
   calc_num_visible_items(num_vis, num_not_vis_at_end);
   if (!_IsKeyDown(CTRL) || num_vis >= get_display_data_list_length())
   {
      ctllist_file_viewx_col2_mouse_move(p_user);
         return;
   }

   int form_id = p_active_form;

   // At x <= x1, scroll slowest, one line every few y pixels
   // at x >= x2, scroll fastest, one "list" every few pixels
   // x1 = 30, x2 = 80, ytrigger = 8

   //mou_set_xy(jmp_xxx,jmp_yyy);

   int xlast = form_id.mou_last_x();
   int ylast = form_id.mou_last_y();
   int xnow, ynow;
   int ytrigger = 8;
   int xleft = 65;
   int xright = 130;
   int rows_to_scroll = 1;
   int max_rows_to_scroll = num_rows - 1;

   if (form_id.p_width < 130) {
      xleft = form_id.p_width/2;
      xright = form_id.p_width;
   }

   hide_file_info();
   set_scrollbar_slider_pos(form_id);
   mou_mode(1);
   mou_capture();
   boolean exit_event_loop = false;

   form_id.scrollbar_horizontal_indicator_image.p_height = pix2scale(3, form_id);
   form_id.scrollbar_horizontal_indicator_image.p_width = pix2scale(xright - xleft, form_id);

   form_id.scrollbar_horizontal_indicator_image.p_x = pix2scale(xleft, form_id);
   form_id.scrollbar_horizontal_indicator_image.p_visible = true;
   form_id.scrollbar_horizontal_indicator_image.p_y = pix2scale(ylast + 6, form_id);

   while (!exit_event_loop) {
      _str event=get_event();
      //_str key = get_event('N');   // refresh screen and get a key
      _str keyt = event2name(event);
      //message('event ' :+ keyt :+ '  ' :+ event);
      set_form_data_ptr(form_id);  // dunno why we do this
      switch (keyt) {

         case 'MOUSE-MOVE':
            xnow = form_id.mou_last_x();
            ynow = form_id.mou_last_y();
            form_id.scrollbar_horizontal_indicator_image.p_y = pix2scale(ynow + 6, form_id);
            if (xnow < 0 || xnow > scale2pix(form_id.p_width, form_id)) {
               exit_event_loop = true;
               break;
            }
            if (ynow < 0 || ynow > scale2pix(form_id.p_height, form_id)) {
               exit_event_loop = true;
               break;
            }

            if (xnow <= xleft) {
               rows_to_scroll = 1;
            }
            else if (xnow >= xright) {
               rows_to_scroll = max_rows_to_scroll;
            }
            else {
               rows_to_scroll = (((xnow - xleft) * max_rows_to_scroll) / (xright - xleft)) + 1;
            }

            if (ynow > ylast) {
               if (ynow - ylast > ytrigger) {
                  ylast += ytrigger;
                  calc_num_visible_items(num_vis, num_not_vis_at_end);
                  if (num_not_vis_at_end > 0) {
                     if (rows_to_scroll > num_not_vis_at_end) {
                        rows_to_scroll = num_not_vis_at_end;
                     }
                     fdp->buffer_list_view_start_index += rows_to_scroll;
                     redisplay_list_data(form_id);
                     set_scrollbar_slider_pos(form_id);
                     set_text_info1_show_index(form_id);
                  }
               }
               break;
            } 
            else {
               if (ylast - ynow > ytrigger) {
                  ylast -= ytrigger;
                  if (fdp->buffer_list_view_start_index > 0) {
                     if (rows_to_scroll > fdp->buffer_list_view_start_index) {
                        rows_to_scroll = fdp->buffer_list_view_start_index;
                     }
                     fdp->buffer_list_view_start_index -= rows_to_scroll;
                     redisplay_list_data(form_id);
                     set_scrollbar_slider_pos(form_id);
                     set_text_info1_show_index(form_id);
                  }
               }
               break;
            }
            break;

         case 'LBUTTON-DOWN' :
            exit_event_loop = true;
            break;

         case 'LBUTTON-UP' :
            break;

         //case ON_KEYSTATECHANGE :
            // check_for_new_ctrl_key_down();
            //break;

         case 'ESC' :
            exit_event_loop = true;
            break;

      }
   }   while(!exit_event_loop);
   //clear_listview_list_line_selection();
   //hide_file_info();
   //scrollbar_slider_image.p_picture = scrollbar_move_pic;
   form_id.scrollbar_horizontal_indicator_image.p_visible = false;
   mou_mode(0);
   mou_release();
}






/***************
void ctllist_view1_col1.mouse_move()
{
   //hide_file_info();
}
***************/


// If ctltext1_scrolls_list_on_mouseover is true and the filename editbox (ctltext1)
// is not being used to enter a filename, then moving the mouse along the editbox
// produces scrolling of the displayed list of files - for each notch that the mouse
// moves along, the next "page" of files is displayed.
// Right click in the editbox toggles ctltext1_scrolls_list_on_mouseover.
void ctltext1.mouse_move()
{
   // this margin is in pixels and sets an area at the ends of the
   // edit box window that allows the start or end of the list to be
   // easily positioned to
   #define CTLTEXT1_SLIDER_MARGIN 6

   set_form_data_ptr(p_active_form);

   // when the ctltext1 contains a partially entered filename matching pattern
   // this scroll mechanism is disabled
   if (!fdp->ctltext1_scrolls_list_on_mouseover ||
       (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC) )
      return;

   // NOTE - update show_editbox_scroll_markers() if the following calculations
   // are changed because it has duplicates
   int buf_list_length = get_display_data_list_length();
   int num_visible_positions = (fdp->listview_num_lists * fdp->listview_lines_per_list);

   int num_pixels = scale2pix(p_active_form.ctltext1.p_width, p_active_form) - (CTLTEXT1_SLIDER_MARGIN * 2);

   int num_pages = ((buf_list_length-1) intdiv num_visible_positions) + 1;

   int buffers_per_page = num_visible_positions;

   int mx = p_active_form.ctltext1.mou_last_x();
   hide_file_info();
   // say('steps ' :+ num_pages :+ ' ' :+ buffers_per_page :+ ' ' 
   //    :+ fdp->listview_lines_per_list :+ ' ' :+ buf_list_length);

   if (mx < CTLTEXT1_SLIDER_MARGIN) {
      fdp->buffer_list_view_start_index = 0;
   } 
   else if (mx > (scale2pix(p_active_form.ctltext1.p_width, p_active_form))- 
                                                      CTLTEXT1_SLIDER_MARGIN) {
      fdp->buffer_list_view_start_index = (num_pages - 1) * buffers_per_page;
   } 
   else if (num_pages > num_pixels) {
      fdp->buffer_list_view_start_index = ((mx-CTLTEXT1_SLIDER_MARGIN) *
                             (num_pages intdiv num_pixels)) * buffers_per_page;
   } else {
      int pixels_per_step = num_pixels intdiv num_pages;
      if (pixels_per_step > 40) {
         pixels_per_step = 40;
      }
      int step_number = ((mx - CTLTEXT1_SLIDER_MARGIN) intdiv pixels_per_step);
      if (step_number >= num_pages) {
         step_number = step_number % num_pages;
      }
      fdp->buffer_list_view_start_index = step_number * buffers_per_page;
   }

   if (buf_list_length <= num_visible_positions) {
      fdp->buffer_list_view_start_index = 0;
   } else if (fdp->buffer_list_view_start_index >= buf_list_length) {
      fdp->buffer_list_view_start_index = buf_list_length - num_visible_positions;
   } else if ((buf_list_length - fdp->buffer_list_view_start_index) < num_visible_positions) {
      fdp->buffer_list_view_start_index = buf_list_length - num_visible_positions;
   }

   populate_lists(p_active_form);

   int last_item_index = (fdp->buffer_list_view_start_index +
                     (fdp->listview_num_lists * fdp->listview_lines_per_list));

   if (last_item_index > buf_list_length)
      last_item_index = buf_list_length;

   set_text_info1(p_active_form, TEXT_INFO1_STATE_ITEM_NUMBERS,
                  (fdp->buffer_list_view_start_index + 1) :+
                          '-' :+ last_item_index :+ '/ ' :+ buf_list_length);
}


static void set_line_selection_for_highlighted_item(int xx)
{
   hide_file_info();
   int buf_list_length = get_display_data_list_length();
   if (buf_list_length == 0) {
      clear_listview_list_line_selection();
      return;
   }
   int num_visible_positions = (fdp->listview_num_lists * fdp->listview_lines_per_list);
   int last_item_index = buf_list_length - 1;

   switch (xx) {
      case 0 :
         fdp->highlighted_item_index = fdp->buffer_list_view_start_index = 0;
         break;
      case 1 :
         // up one
         if (fdp->highlighted_item_index < last_item_index) {
            if (++fdp->highlighted_item_index >= 
                (fdp->buffer_list_view_start_index + num_visible_positions)) {
               ++fdp->buffer_list_view_start_index;
               //resize_listview(p_active_form);
               populate_lists(p_active_form);
            }
         }
         break;
      case -1 :
         // down one
         if (fdp->highlighted_item_index > fdp->buffer_list_view_start_index) {
            --fdp->highlighted_item_index;
         } else {
            if (fdp->buffer_list_view_start_index > 0) {
               --fdp->highlighted_item_index;
               --fdp->buffer_list_view_start_index;
               //resize_listview(p_active_form);
               populate_lists(p_active_form);
            }
         }
         break;
      case 2 :
         // page up
         if (fdp->highlighted_item_index > fdp->buffer_list_view_start_index) {
            // highlight first visible item 
            fdp->highlighted_item_index = fdp->buffer_list_view_start_index;
         } else {
            // already on the first item
            if (fdp->buffer_list_view_start_index >= num_visible_positions) {
               fdp->buffer_list_view_start_index -= num_visible_positions;
               fdp->highlighted_item_index = fdp->buffer_list_view_start_index;
            } else {
               fdp->highlighted_item_index = fdp->buffer_list_view_start_index = 0;
            }
            populate_lists(p_active_form);
         }
         break;
      case -2 :
         // page down
         if (fdp->highlighted_item_index < 
             (fdp->buffer_list_view_start_index + num_visible_positions - 1)) {
            // highlight last visible item
            fdp->highlighted_item_index =
             (fdp->buffer_list_view_start_index + num_visible_positions - 1);
            if (fdp->highlighted_item_index > (buf_list_length-1)) {
               fdp->highlighted_item_index = (buf_list_length-1);
            }
         } else {
            // already on last visible item
            if (fdp->highlighted_item_index < (buf_list_length-1)) {
               fdp->buffer_list_view_start_index += num_visible_positions;
               fdp->highlighted_item_index =
                (fdp->buffer_list_view_start_index + num_visible_positions - 1);
               if (fdp->highlighted_item_index > (buf_list_length-1)) {
                  fdp->highlighted_item_index = (buf_list_length-1);
               }
               populate_lists(p_active_form);
            }
         }
         break;
      // the compiler didn't like having "default" before the case items for some reason
      default :
         return;
   }

   int listnum = (fdp->highlighted_item_index - fdp->buffer_list_view_start_index) intdiv
      fdp->listview_lines_per_list;
   int linenum = (fdp->highlighted_item_index - fdp->buffer_list_view_start_index) - 
                           (listnum * fdp->listview_lines_per_list);
   set_listview_list_line_selection(listnum, linenum,true);

   _str xy;
   get_file_info_string(xy, fdp->highlighted_item_index);
   message(xy);
}


static void ctltext1_begin_filename_entry(int form_id)
{
   fdp->GFM_save_file_order_mode = fdp->GFM_file_order_mode;
   fdp->text_info1_state = TEXT_INFO1_STATE_FILESPEC;
   fdp->GFM_file_order_mode = GFM_SORT_FILESPEC;
   form_id.ctltext1.p_text = '';
   form_id.ctltext1.begin_line();
   last_filespec = '';
   generate_display_list_data();
   fdp->buffer_list_view_start_index = 0;
   resize_listview(form_id);
   fdp->redo_listview_list_counter = 2;
   set_listview_list_line_selection(0,0,false);
   fdp->highlighted_item_index = 0;
   message('Prefix "/" character to select reg. expr. mode');
}

void ctltext1.lbutton_down()
{
   set_form_data_ptr(p_active_form);
   if (fdp->GFM_file_order_mode != GFM_SORT_FILESPEC) {
      ctltext1_begin_filename_entry(p_active_form);
      p_active_form.ctltext1._set_focus();
   }
}

// this do nothing rbutton up event is needed to prevent generic toolbar context 
// menu from appearing.
void ctltext1.rbutton_up()
{
}

void ctltext1.rbutton_down()
{
   set_form_data_ptr(p_active_form);
   fdp->ctltext1_scrolls_list_on_mouseover = !fdp->ctltext1_scrolls_list_on_mouseover;
}

void ctltext1.on_got_focus()
{
   set_form_data_ptr(p_active_form);
   if (fdp->text_info1_state != TEXT_INFO1_STATE_FILESPEC) {
      ctltext1_begin_filename_entry(p_active_form);
   }
}

// this command shows the GFileman form and puts focus on the filename editbox
// so a filename can be entered or so arrow up/down keys and page up/down keys
// can be used to select a file for editing
/*
_command void GFM_filename_entry_mode_old() name_info(',')
{
   if (name_of_last_form_with_filename_editbox_target == '') {
      name_of_last_form_with_filename_editbox_target = 'GFilemanForm1';
   }
   int form_id = _find_formobj(name_of_last_form_with_filename_editbox_target);
   if (form_id) {
      int wid = _tbIsVisible(name_of_last_form_with_filename_editbox_target);
      if (wid) {
         tbShow(name_of_last_form_with_filename_editbox_target);
      } else {
         // First check for auto hidden tool window
         // third parameter true means killDockChanMouseEvents - whatever they are!
         wid=_tbMaybeAutoShow(name_of_last_form_with_filename_editbox_target,'',true);
         if( wid==0 ) {
            tbShow(name_of_last_form_with_filename_editbox_target);
            wid=activate_toolbar(name_of_last_form_with_filename_editbox_target,"");
         }
      }
   } else {
      //tbShow(name_of_last_form_with_filename_editbox_target);
      int wid = activate_toolbar(name_of_last_form_with_filename_editbox_target,'');
      form_id = _find_formobj(name_of_last_form_with_filename_editbox_target);
      if (wid <= 0 || form_id <= 0) {
         form_id = show('-xy ' :+ name_of_last_form_with_filename_editbox_target);
         if (form_id < 0) {
            message('Form not found - ' :+ name_of_last_form_with_filename_editbox_target);
            return;
         }
      }
      find_or_create_GFM_form_data_array_entry(name_of_last_form_with_filename_editbox_target);
      //return;
   }
   set_form_data_ptr(form_id);
   if (fdp->text_info1_state != TEXT_INFO1_STATE_FILESPEC) {
      form_id.ctltext1.p_enabled = true;
      ctltext1_begin_filename_entry(form_id);
      form_id.ctltext1._set_focus();
   }
}
*/


_command void GFM_filename_entry_mode() name_info(',')
{
   if (name_of_last_form_with_filename_editbox_target == '') {
      name_of_last_form_with_filename_editbox_target = 'GFilemanForm1';
   }
   int wid = activate_tool_window(name_of_last_form_with_filename_editbox_target);
   int form_id = _find_formobj(name_of_last_form_with_filename_editbox_target);
   if (wid <= 0 || form_id <= 0) {
      _message_box("An error may have occurred if the form"\n"being opened is not a toolbar", 'GFileman' );
      form_id = show('-xy ' :+ name_of_last_form_with_filename_editbox_target);
      if (form_id <= 0) {
         message('Form not found - ' :+ name_of_last_form_with_filename_editbox_target);
         return;
      }
   }
   find_or_create_GFM_form_data_array_entry(name_of_last_form_with_filename_editbox_target);
   set_form_data_ptr(form_id);
   if (fdp->text_info1_state != TEXT_INFO1_STATE_FILESPEC) {
      form_id.ctltext1.p_enabled = true;
      ctltext1_begin_filename_entry(form_id);
      form_id.ctltext1._set_focus();
   }
}


/*********
void ctltext1.on_lost_focus()
{
}
**********/


// move the highlight index down by one
// TODO skip directory names, since you can't edit directories
void ctltext1.'DOWN'()
{
   set_form_data_ptr(p_active_form);
   if (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC) 
      set_line_selection_for_highlighted_item(1);
}

void ctltext1.'UP'()
{
   set_form_data_ptr(p_active_form);
   if (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC) 
      set_line_selection_for_highlighted_item(-1);
}

void ctltext1.'PGUP'()
{
   set_form_data_ptr(p_active_form);
   if (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC) 
      set_line_selection_for_highlighted_item(2);
}

void ctltext1.'PGDN'()
{
   set_form_data_ptr(p_active_form);
   if (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC) 
      set_line_selection_for_highlighted_item(-2);
}

void ctltext1.'ENTER'()
{
   set_form_data_ptr(p_active_form);
   if (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC) {
      int buf_list_length = get_display_data_list_length();
      int data_index = get_display_data_list_index(fdp->highlighted_item_index,0);
      if (fdp->highlighted_item_index >= buf_list_length) {
         clear_listview_list_line_selection();
         return;
      }
      if (fdp->display_data_list[data_index].directory_flag) {
         shell( get_env('SystemRoot') :+ '\explorer.exe /n,/e,/select,' :+
                           fdp->display_data_list[data_index].buf_name, 'A' );
      } else {
         fdp->GFM_file_order_mode = fdp->GFM_save_file_order_mode;
         fdp->redo_listview_list_counter = 2;
         fdp->buffer_list_view_start_index = 0;
         edit('+b ' fdp->display_data_list[data_index].buf_name);
         _kill_timer(GFM_timer_handle);
         GFM_timer_handle = _set_timer(400,GFileman_timer_callback);
      }
   }
}


void ctltext1.on_change()
{
   set_form_data_ptr(p_active_form);
   if (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC) {
      last_filespec = p_text;
      // generate_display_list_data is called for each keypress - with lots of
      // files open, this may be too slow, coz it sorts and copies etc
      generate_display_list_data();
      fdp->buffer_list_view_start_index = 0;
      resize_listview(p_active_form);
      fdp->redo_listview_list_counter = 2;
      set_line_selection_for_highlighted_item(0);
   }
}

void ctltext1.on_create()
{
   set_form_data_ptr(p_active_form);
   if (fdp->setup_data.gfconfig.filename_editbox_is_target) {
      id_of_last_form_with_filename_editbox_target = p_active_form;
      name_of_last_form_with_filename_editbox_target = fdp->form_name;
   }
   fdp->ctltext1_window_id = p_window_id;
   ctltext1.p_height = pix2scale(10,p_active_form);
}


static void calc_lines_per_list(int form_id)
{
   fdp->listview_lines_per_list = form_id.ctllist_view1_col2.p_client_height intdiv
      (_ly2dy( form_id.p_xyscale_mode,form_id.ctllist_view1_col2._text_height()) + 2);

}


/************************
static int find_nth_match(_str mtx, int count)
{
   int k = 0;
   while ( k < get_display_data_list_length() ) {
      if (fdp->display_data_list[get_display_data_list_index(k,0)].directory_flag) {
      } else {
         _str fname = strip_filename(
            fdp->display_data_list[get_display_data_list_index(k,0)].buf_name,'DP');
         if (pos(mtx,fname,1, 'I') == 1) {
            if (--count == 0) {
               return k;
            }
         }
      }
      ++k;
   }
   return -1;
}
*************************/


// generate_display_list_data() must be called before populate_lists() is called
static void populate_lists(int form_id)
{
   int k = fdp->buffer_list_view_start_index;
   int listnum = 0;
   int list_len = get_display_data_list_length();

   if (is_display_mode_goback_history()) {
      fdp->goback_iterator = 
         fdp->goback_iterator2 = dlist_end(*fdp->goback_list_ptr);
      dlist_prev(fdp->goback_iterator2, k);
   }

   for (;listnum < fdp->listview_num_lists; ++listnum) {
      int y = 0;

      fdp->listview_col1_control_list[listnum]._lbclear();
      fdp->listview_col2_control_list[listnum]._lbclear();
      fdp->listview_col3_control_list[listnum]._lbclear();

      fileman_id = 0;
      while ((k < list_len) && (y < fdp->listview_lines_per_list)) {
         populate_display_data_item(k,form_id,
            fdp->listview_col1_control_list[listnum],
            fdp->listview_col2_control_list[listnum] );
         ++k; ++y;
      }
      fdp->listview_num_lines_in_list[listnum] = y;
      // when the end of the list is reached this loop continues so as
      // to clear the listboxes that are empty (if any visible)
   }
   set_scrollbar_slider_pos(form_id);
}




//=============================================================================
//
// The amazing scrollbar handling code follows.
// 
//=============================================================================


static void calc_num_visible_items(int & num_visible, int & num_not_visible_at_end)
{
   int buf_list_length = get_display_data_list_length();
   num_visible = (fdp->listview_num_lists * fdp->listview_lines_per_list);

   if ( (fdp->buffer_list_view_start_index + num_visible) >= buf_list_length )
      num_not_visible_at_end = 0;
   else
      num_not_visible_at_end = buf_list_length - (fdp->buffer_list_view_start_index + num_visible);
}


static int calc_scrollbar_slider_pos(int maxpos)
{
   int buf_list_length = get_display_data_list_length();
   int num_visible = (fdp->listview_num_lists * fdp->listview_lines_per_list);
   int nnvis;

   if ((fdp->buffer_list_view_start_index == 0) || (num_visible >= buf_list_length) )
      return 0;

   nnvis = buf_list_length - num_visible;  // number not visible
   if ( fdp->buffer_list_view_start_index >= nnvis)
      return maxpos;

   // make sure no overflow in val*maxpos.  If maxpos is say 1000 pixels,
   // if fdp->buffer_list_view_start_index is greater than 10000 then val
   // is limited to 10000  - that's a lot of files ...
   int val;
   int check = 10000000 intdiv maxpos;
   if (fdp->buffer_list_view_start_index > check)
      val = check;
   else
      val = fdp->buffer_list_view_start_index;
   return(val * maxpos) intdiv nnvis;
}




static void set_scrollbar_slider_pos(int form_id)
{
   int offset = calc_scrollbar_slider_pos(
      scale2pix(form_id.ctllist_view1_col1.p_height, form_id) - 
                scale2pix(form_id.scrollbar_slider_image.p_height,form_id) - 2 );

   form_id.scrollbar_slider_image.p_y = form_id.ctllist_view1_col1.p_y + pix2scale(offset, form_id);

   form_id.scrollbar_slider_image.p_height = pix2scale(40, form_id);
   form_id.scrollbar_slider_image.p_width = pix2scale(4, form_id);
}
 
 
static void process_scrollbar_mouse_move2(int form_id, int & y_now, int & y_last, int pixels_per_unit = 6)
{
   int num_not_visible_at_end, num_visible, num;
   if (y_now > y_last) {
      if (y_now - y_last > pixels_per_unit) {
         calc_num_visible_items(num_visible, num_not_visible_at_end);
         num = (y_now - y_last) intdiv pixels_per_unit;
         y_last = y_last + num * pixels_per_unit;
         if (scrollbar_speed_mode != 0) {
            num = num * scrollbar_speed;
         }
         if (num_not_visible_at_end > 0) {
            if (num > num_not_visible_at_end)
               num = num_not_visible_at_end;
            fdp->buffer_list_view_start_index += num;
            redisplay_list_data(form_id);
            set_scrollbar_slider_pos(form_id);
            set_text_info1_show_index(form_id);
         }
      }
   } else {
      if (y_last - y_now > pixels_per_unit) {
         calc_num_visible_items(num_visible, num_not_visible_at_end);
         num = (y_last - y_now) intdiv pixels_per_unit;
         y_last = y_last - num * pixels_per_unit;
         if (scrollbar_speed_mode != 0) {
            num = num * scrollbar_speed;
         }
         if (fdp->buffer_list_view_start_index > 0) {
            if (num > fdp->buffer_list_view_start_index)
               num = fdp->buffer_list_view_start_index;
            fdp->buffer_list_view_start_index -= num;
            redisplay_list_data(form_id);
            set_scrollbar_slider_pos(form_id);
            set_text_info1_show_index(form_id);
         }
      }

   }
}
 
 
 
static void process_scrollbar2(int form_id)
{
   boolean first_time = true;

   set_scrollbar_slider_pos(form_id);
   int x_on_entry = form_id.mou_last_x();

   //int offset_y = calc_scrollbar_slider_pos(form_id.ctllist_view1_col1.p_height);
   //
   //int jmp_xxx = scale2pix(form_id.scrollbar_image.p_x + 
   //   form_id.scrollbar_image.p_width, form_id);
   //int jmp_yyy = offset_y + scale2pix(form_id.scrollbar_image.p_y, form_id);
   //
   //int mid_x = jmp_xxx;
   //int mid_y = scale2pix(form_id.scrollbar_image.p_y, form_id) + 
   //   scale2pix(form_id.scrollbar_image.p_height intdiv 2,form_id);
   //
   //_map_xy(form_id,0,mid_x,mid_y);
   //
   //_map_xy(form_id,0,jmp_xxx,jmp_yyy);
   //mou_set_xy(jmp_xxx,jmp_yyy);

   int y_last, y_now, num;
   int x_last, x_now, proc_count;
   boolean prev_y_greater_x;



   mou_mode(1);
   mou_capture();
   boolean exit_event_loop = false;

   //scrollbar_slider_image.p_picture = scrollbar_move_alive_pic;
   while (!exit_event_loop) {
      _str event=get_event();
      //_str key = get_event('N');   // refresh screen and get a key
      _str keyt = event2name(event);
      //message('event ' :+ keyt :+ '  ' :+ event);
      set_form_data_ptr(form_id);
      switch (keyt) {
      //switch (event) {

         //case 'TAB' :
         //   mou_set_xy(jmp_xxx, mid_y);
         //   break;
         //case ' ' :
         //   // space key
         //   if (scrollbar_speed_mode==0) {
         //      //scrollbar_fast_speed = scrollbar_slow_speed = scrollbar_speed = 1;
         //      scrollbar_speed_mode = 1;
         //      show_speed();
         //      mou_set_xy(jmp_xxx, mid_y);
         //   } else {
         //      scrollbar_speed_mode = 0;
         //   }
         //   break;


         case 'F1' :
            scrollbar_speed = scrollbar_slow_speed;
            show_speed();
            break;

         case 'F2' :
            scrollbar_speed = scrollbar_fast_speed;
            show_speed();
            break;

         case 'F3' :
            // slower
            if (scrollbar_speed > 0) {
               --scrollbar_speed;
            }
            show_speed();
            break;

         case 'F4' :
            // faster
            ++scrollbar_speed;
            show_speed();
            break;

         case 'F5' :
            scrollbar_slow_speed = scrollbar_speed;
            show_speed();
            break;
         case 'F6' :
            scrollbar_fast_speed = scrollbar_speed;
            show_speed();
            break;
         case 'F9' :
            scrollbar_fast_speed = scrollbar_slow_speed = 1;
            show_speed();
            break;

         case 'MOUSE-MOVE':
            if (first_time) {
               y_last = y_now = form_id.mou_last_y();
               x_last = x_now = form_id.mou_last_x();
               prev_y_greater_x = first_time = false;
               proc_count = 0;
            }
            else if (++proc_count < 5) {
               //y_now = form_id.mou_last_y();   // pixels
               //x_now = form_id.mou_last_x();
               //say("Less5 " :+ x_last :+ " " :+ x_now :+ " " :+ y_last :+ " " :+ y_now);
            }
            else {
               proc_count = 0;
               y_now = form_id.mou_last_y();   // pixels
               x_now = form_id.mou_last_x();
               if (abs(x_on_entry - x_now) > 40) {
                  exit_event_loop = true;
                  break;
               }
               int diff = abs(y_last - y_now) - abs(x_last - x_now);
               if (diff > 2) {
                  //say("diff " :+ diff :+ " " :+ x_last :+ " " :+ x_now :+ " " :+ y_last :+ " " :+ y_now);
                  process_scrollbar_mouse_move(form_id, y_now, y_last);

               }
               /**********
               else if (diff > 0 && prev_y_greater_x) {
                  process_scrollbar_mouse_move(form_id, y_now, y_last);
               }
               prev_y_greater_x = (diff > 0);
               *************/
               x_last = x_now;
               y_last = y_now;
            }
            break;

         case 'LBUTTON-DOWN' :
            exit_event_loop = true;
            break;

         case 'LBUTTON-UP' :
            break;

         //case ON_KEYSTATECHANGE :
            // check_for_new_ctrl_key_down();
            //break;

         case 'ESC' :
            exit_event_loop = true;
            break;

      }
   }   // while(!exit_event_loop)
   //clear_listview_list_line_selection();
   //hide_file_info();
   //scrollbar_slider_image.p_picture = scrollbar_move_pic;
   mou_mode(0);
   _kill_timer();
   mou_release();

}
 
 

// move the scrollbar slider according to the change in the y coordinate
// of the mouse location
static void process_scrollbar_mouse_move(int form_id, int & y_now, int & y_last, int pixels_per_unit = 6)
{
   int num_not_visible_at_end, num_visible, num;
   if (y_now > y_last) {
      if (y_now - y_last > pixels_per_unit) {
         calc_num_visible_items(num_visible, num_not_visible_at_end);
         num = (y_now - y_last) intdiv pixels_per_unit;
         y_last = y_last + num * pixels_per_unit;
         if (scrollbar_speed_mode != 0) {
            num = num * scrollbar_speed;
         }
         if (num_not_visible_at_end > 0) {
            if (num > num_not_visible_at_end)
               num = num_not_visible_at_end;
            fdp->buffer_list_view_start_index += num;
            redisplay_list_data(form_id);
            set_scrollbar_slider_pos(form_id);
            set_text_info1_show_index(form_id);
         }
      }
   } else {
      if (y_last - y_now > pixels_per_unit) {
         calc_num_visible_items(num_visible, num_not_visible_at_end);
         num = (y_last - y_now) intdiv pixels_per_unit;
         y_last = y_last - num * pixels_per_unit;
         if (scrollbar_speed_mode != 0) {
            num = num * scrollbar_speed;
         }
         if (fdp->buffer_list_view_start_index > 0) {
            if (num > fdp->buffer_list_view_start_index)
               num = fdp->buffer_list_view_start_index;
            fdp->buffer_list_view_start_index -= num;
            redisplay_list_data(form_id);
            set_scrollbar_slider_pos(form_id);
            set_text_info1_show_index(form_id);
         }
      }

   }
}





static void show_speed()
{
   message('Speed=' :+ scrollbar_speed :+ ' Slow speed=' :+ scrollbar_slow_speed :+ ' Fast speed=' :+ scrollbar_fast_speed);
}

static void process_scrollbar(int form_id)
{
   boolean first_time = true;

   set_scrollbar_slider_pos(form_id);
   int x_on_entry = form_id.mou_last_x();

   //int offset_y = calc_scrollbar_slider_pos(form_id.ctllist_view1_col1.p_height);
   //
   //int jmp_xxx = scale2pix(form_id.scrollbar_image.p_x + 
   //   form_id.scrollbar_image.p_width, form_id);
   //int jmp_yyy = offset_y + scale2pix(form_id.scrollbar_image.p_y, form_id);
   //
   //int mid_x = jmp_xxx;
   //int mid_y = scale2pix(form_id.scrollbar_image.p_y, form_id) + 
   //   scale2pix(form_id.scrollbar_image.p_height intdiv 2,form_id);
   //
   //_map_xy(form_id,0,mid_x,mid_y);
   //
   //_map_xy(form_id,0,jmp_xxx,jmp_yyy);
   //mou_set_xy(jmp_xxx,jmp_yyy);

   int y_last, y_now, num;
   int x_last, x_now, proc_count;
   boolean prev_y_greater_x;


   mou_mode(1);
   mou_capture();
   boolean exit_event_loop = false;

   //scrollbar_slider_image.p_picture = scrollbar_move_alive_pic;
   while (!exit_event_loop) {
      _str event=get_event();
      //_str key = get_event('N');   // refresh screen and get a key
      _str keyt = event2name(event);
      //message('event ' :+ keyt :+ '  ' :+ event);
      set_form_data_ptr(form_id);
      switch (keyt) {
      //switch (event) {

         //case 'TAB' :
         //   mou_set_xy(jmp_xxx, mid_y);
         //   break;
         //case ' ' :
         //   // space key
         //   if (scrollbar_speed_mode==0) {
         //      //scrollbar_fast_speed = scrollbar_slow_speed = scrollbar_speed = 1;
         //      scrollbar_speed_mode = 1;
         //      show_speed();
         //      mou_set_xy(jmp_xxx, mid_y);
         //   } else {
         //      scrollbar_speed_mode = 0;
         //   }
         //   break;


         case 'F1' :
            scrollbar_speed = scrollbar_slow_speed;
            show_speed();
            break;

         case 'F2' :
            scrollbar_speed = scrollbar_fast_speed;
            show_speed();
            break;

         case 'F3' :
            // slower
            if (scrollbar_speed > 0) {
               --scrollbar_speed;
            }
            show_speed();
            break;

         case 'F4' :
            // faster
            ++scrollbar_speed;
            show_speed();
            break;

         case 'F5' :
            scrollbar_slow_speed = scrollbar_speed;
            show_speed();
            break;
         case 'F6' :
            scrollbar_fast_speed = scrollbar_speed;
            show_speed();
            break;
         case 'F9' :
            scrollbar_fast_speed = scrollbar_slow_speed = 1;
            show_speed();
            break;

         case 'MOUSE-MOVE':
            if (first_time) {
               y_last = y_now = form_id.mou_last_y();
               x_last = x_now = form_id.mou_last_x();
               prev_y_greater_x = first_time = false;
               proc_count = 0;
            }
            else if (++proc_count < 5) {
               //y_now = form_id.mou_last_y();   // pixels
               //x_now = form_id.mou_last_x();
               //say("Less5 " :+ x_last :+ " " :+ x_now :+ " " :+ y_last :+ " " :+ y_now);
            }
            else {
               proc_count = 0;
               y_now = form_id.mou_last_y();   // pixels
               x_now = form_id.mou_last_x();
               if (abs(x_on_entry - x_now) > 40) {
                  exit_event_loop = true;
                  break;
               }
               int diff = abs(y_last - y_now) - abs(x_last - x_now);
               if (diff > 2) {
                  //say("diff " :+ diff :+ " " :+ x_last :+ " " :+ x_now :+ " " :+ y_last :+ " " :+ y_now);
                  process_scrollbar_mouse_move(form_id, y_now, y_last);

               }
               /**********
               else if (diff > 0 && prev_y_greater_x) {
                  process_scrollbar_mouse_move(form_id, y_now, y_last);
               }
               prev_y_greater_x = (diff > 0);
               *************/
               x_last = x_now;
               y_last = y_now;
            }
            break;

         case 'LBUTTON-DOWN' :
            exit_event_loop = true;
            break;

         case 'LBUTTON-UP' :
            break;

         //case ON_KEYSTATECHANGE :
            // check_for_new_ctrl_key_down();
            //break;

         case 'ESC' :
            exit_event_loop = true;
            break;

      }
   }   // while(!exit_event_loop)
   //clear_listview_list_line_selection();
   //hide_file_info();
   //scrollbar_slider_image.p_picture = scrollbar_move_pic;
   mou_mode(0);
   _kill_timer();
   mou_release();

}


int ynow;
int ylast;

void view1_ctlimage1.wheel_up()
{
   set_form_data_ptr(p_active_form);
   if (fdp->scrollbar_needed) {
      ynow -= 5;
      process_scrollbar_mouse_move(p_active_form, ynow, ylast, 12);
   }
}


void view1_ctlimage1.wheel_down()
{
   set_form_data_ptr(p_active_form);
   if (fdp->scrollbar_needed) {
      ynow += 5;
      process_scrollbar_mouse_move(p_active_form, ynow, ylast, 12);
   }
}




#if 0
void scrollbar_image.mouse_move()
{
   set_form_data_ptr(p_active_form);
   if (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC)
      return;
   int xnow = scrollbar_image.mou_last_x();   // pixels
   int ynow = scrollbar_image.mou_last_y();
   if (++fdp->scrollbar_mousemove_counter > 5) {
      int xdist = abs(xnow - scrollbar_mousemove_last_x);
      int ydist = abs(ynow - scrollbar_mousemove_last_y);
      //say('smvxy ' :+ xdist :+ ' ' :+ ydist);
      if (ydist > (xdist+5)) {
         process_scrollbar(p_active_form);
         fdp->scrollbar_mousemove_counter = 0;
      }
   }
   else
   {
      scrollbar_mousemove_last_y = ynow;
      scrollbar_mousemove_last_x = xnow;
   }
}

#endif


//=============================================================================
// End of the scrollbar handling code 
//=============================================================================



// generate_the_listview() calculates the width, height, x, y etc values for all
// the listboxes and images etc that make up the listview.  This code determines
// how many columns will be shown and hence how many items can be displayed.
static void generate_the_listview(int form_id,int max_cols)
{
   int one_pixel_x = _lx2lx(SM_PIXEL,form_id.p_xyscale_mode,1);
   int one_pixel_y = _ly2ly(SM_PIXEL,form_id.p_xyscale_mode,1);

   // avail_width is the width in pixels available to the listview including its borders
   int avail_width = form_id.p_client_width -
      fdp->setup_data.gfconfig.listview_list_left_margin -
      fdp->setup_data.gfconfig.listview_list_right_margin;

   int left_listbox_width = 14;
   if (is_display_mode_goback_history()) {
      left_listbox_width = fdp->setup_data.gfconfig.listview_left_col_width;
   }
   else if (fdp->setup_data.gfconfig.show_shortcuts_in_col1 || fdp->show_shortcuts_now) {
      left_listbox_width = fdp->setup_data.gfconfig.shortcut_key_col1_width;
   }

   form_id.ctllist_view1_col1.p_width = pix2scale(left_listbox_width,form_id);
   form_id.ctllist_view1_col3.p_width = one_pixel_x*5;

   form_id.ctlimage_listview_left_vert_bar1.p_width = one_pixel_x*2;
   form_id.ctlimage_listview_right_vert_bar1.p_width = one_pixel_x*2;

   int border_overhead = scale2pix( form_id.ctlimage_listview_left_vert_bar1.p_width +
      form_id.ctlimage_listview_right_vert_bar1.p_width,form_id);
   int vert_sep_overhead = scale2pix(form_id.ctlimage_listview_vert_sep_bar1.p_width,form_id);

   // col_width_pix is the width of one column of the listview - each column has 3 listboxes
   int col_width_pix;  // pixels

   if ( (max_cols==1) || (avail_width < 0) || (fdp->num_listview_columns_available < 2) ||
        ( avail_width < (border_overhead + vert_sep_overhead + 
                         (fdp->setup_data.gfconfig.listview_min_width * 2)) ) ) 
   {
      fdp->listview_num_lists = 1;
      if (avail_width > fdp->setup_data.gfconfig.listview_min_width + border_overhead)
         col_width_pix = avail_width - border_overhead;
      else
         col_width_pix = fdp->setup_data.gfconfig.listview_min_width;
   } else {
      // assign number of listview columns according to number of items to be shown
      // but subject to minimum column width

      int k = 2;
      while ((k * fdp->listview_lines_per_list) < get_display_data_list_length()) {
         if (k >= fdp->num_listview_columns_available)
            break;
         else if ( avail_width < (border_overhead + (vert_sep_overhead*k) + 
                             (fdp->setup_data.gfconfig.listview_min_width*(k+1))) ) 
            break;
         else
            ++k;
      }

      col_width_pix = (int)((avail_width - border_overhead - vert_sep_overhead*(k-1))/k);
      fdp->listview_num_lists = k;
   }

   int col_width_scale = pix2scale(col_width_pix,form_id);

   form_id.ctllist_view1_col2.p_width = 
      col_width_scale - form_id.ctllist_view1_col1.p_width - form_id.ctllist_view1_col3.p_width;

   form_id.ctllist_view1_col2.p_height =
      form_id.ctllist_view1_col3.p_height =
      form_id.ctllist_view1_col1.p_height;

   int scroll_bar_space = 0;
   int min_scroll_height = pix2scale(40,form_id);

   if ((fdp->listview_num_lists * fdp->listview_lines_per_list) >= get_display_data_list_length())
   {
      fdp->buffer_list_view_start_index = 0;
      fdp->scrollbar_needed = false;
      form_id.scrollbar_button.p_visible = false;
      fdp->scrollbar_is_visible = false;
   }
   else
   {
      fdp->scrollbar_needed = true;
      fdp->scrollbar_is_visible = true;
      //if (fdp->setup_data.gfconfig.button_row1_visible) 
      //   form_id.scrollbar_button.p_visible = true;
      //else
      //   form_id.scrollbar_button.p_visible = false;

      form_id.scrollbar_button.p_visible = false;
   }

   if ( ((fdp->listview_num_lists * fdp->listview_lines_per_list) < get_display_data_list_length()) &&
        (min_scroll_height < form_id.ctllist_view1_col1.p_height) && fdp->scrollbar_is_visible  ) 
   {
      scroll_bar_space = 0;
      //form_id.scrollbar_image.p_visible = true;
      //form_id.scrollbar_top_image.p_visible = true;
      //form_id.scrollbar_bottom_image.p_visible = true;
      form_id.scrollbar_slider_image.p_visible = true;
      set_scrollbar_slider_pos(form_id);
   } else {
      //form_id.scrollbar_image.p_visible = false;
      //form_id.scrollbar_top_image.p_visible = false;
      //form_id.scrollbar_bottom_image.p_visible = false;
      form_id.scrollbar_slider_image.p_visible = false;
   }

   form_id.ctllist_view1_col1.p_x =
      pix2scale(fdp->setup_data.gfconfig.listview_list_left_margin,form_id) + 
      form_id.ctlimage_listview_left_vert_bar1.p_width + scroll_bar_space;

   form_id.ctllist_view1_col2.p_x = form_id.ctllist_view1_col1.p_x +
      form_id.ctllist_view1_col1.p_width;
   form_id.ctllist_view1_col3.p_x = form_id.ctllist_view1_col2.p_x +
      form_id.ctllist_view1_col2.p_width;
   form_id.ctllist_view1_col1.p_y = pix2scale(fdp->listview_p_y,form_id);
   form_id.ctllist_view1_col2.p_y = form_id.ctllist_view1_col1.p_y;
   form_id.ctllist_view1_col3.p_y = form_id.ctllist_view1_col1.p_y;

   // this image overlays all 3 listboxes for this column
   form_id.view1_ctlimage1.p_x = form_id.ctllist_view1_col1.p_x;
   form_id.view1_ctlimage1.p_y = form_id.ctllist_view1_col1.p_y;
   form_id.view1_ctlimage1.p_width = col_width_scale;
   form_id.view1_ctlimage1.p_height = form_id.ctllist_view1_col1.p_height;

   int total_width_scale = col_width_scale * fdp->listview_num_lists +
      pix2scale(border_overhead,form_id) +
      form_id.ctlimage_listview_vert_sep_bar1.p_width*(fdp->listview_num_lists-1);

   //_rgb(92,103,228);  _rgb(131,138,235);  _rgb(48,52,205);

   form_id.ctlimage_listview_top_horiz_bar1.p_x = form_id.ctllist_view1_col1.p_x -
      form_id.ctlimage_listview_left_vert_bar1.p_width;
   form_id.ctlimage_listview_top_horiz_bar1.p_width = total_width_scale;
   form_id.ctlimage_listview_top_horiz_bar1.p_height = one_pixel_y;
   form_id.ctlimage_listview_top_horiz_bar1.p_y = form_id.ctllist_view1_col1.p_y -
      one_pixel_y*2;

   form_id.ctlimage_listview_left_vert_bar1.p_width = one_pixel_x;
   form_id.ctlimage_listview_left_vert_bar1.p_x = form_id.ctllist_view1_col1.p_x -
      form_id.ctlimage_listview_left_vert_bar1.p_width;
   form_id.ctlimage_listview_left_vert_bar1.p_height =
      form_id.ctllist_view1_col1.p_height;
   form_id.ctlimage_listview_left_vert_bar1.p_y = form_id.ctllist_view1_col1.p_y;

   form_id.ctlimage_listview_bottom_horiz_bar1.p_x = form_id.ctlimage_listview_top_horiz_bar1.p_x;
   form_id.ctlimage_listview_bottom_horiz_bar1.p_width =
      form_id.ctlimage_listview_top_horiz_bar1.p_width;
   form_id.ctlimage_listview_bottom_horiz_bar1.p_height =
      form_id.ctlimage_listview_top_horiz_bar1.p_height;
   form_id.ctlimage_listview_bottom_horiz_bar1.p_y =
      form_id.ctllist_view1_col1.p_y + form_id.ctllist_view1_col1.p_height;

   form_id.ctlimage_listview_right_vert_bar1.p_width = form_id.ctlimage_listview_left_vert_bar1.p_width;
   form_id.ctlimage_listview_right_vert_bar1.p_x = form_id.ctlimage_listview_left_vert_bar1.p_x +
      total_width_scale - form_id.ctlimage_listview_right_vert_bar1.p_width;

   form_id.ctlimage_listview_right_vert_bar1.p_height =
      form_id.ctlimage_listview_left_vert_bar1.p_height;
   form_id.ctlimage_listview_right_vert_bar1.p_y = form_id.ctlimage_listview_left_vert_bar1.p_y;

   // scrollbar_image (track) p_x, p_y and p_height
   //form_id.scrollbar_image.p_x = form_id.ctlimage_listview_left_vert_bar1.p_x - 
   //   form_id.scrollbar_image.p_width - pix2scale(1,form_id);
   //
   //form_id.scrollbar_image.p_y = form_id.ctllist_view1_col1.p_y + 
   //   form_id.scrollbar_top_image.p_height - pix2scale(1,form_id);
   //
   //form_id.scrollbar_image.p_height = form_id.ctllist_view1_col1.p_height - 
   //   form_id.scrollbar_top_image.p_height - form_id.scrollbar_bottom_image.p_height + pix2scale(2,form_id);
   //
   //// scrollbar top/bottom image p_x, p_y
   //form_id.scrollbar_top_image.p_y = form_id.ctllist_view1_col1.p_y - pix2scale(1,form_id);
   //form_id.scrollbar_top_image.p_x = 
   //   form_id.scrollbar_bottom_image.p_x = form_id.scrollbar_image.p_x;
   //
   //form_id.scrollbar_bottom_image.p_y = form_id.ctllist_view1_col1.p_y + pix2scale(1,form_id) +
   //   form_id.ctllist_view1_col1.p_height - form_id.scrollbar_bottom_image.p_height;


   //form_id.scrollbar_slider_image.p_y = form_id.scrollbar_image.p_y + pix2scale(2,form_id);
   form_id.scrollbar_slider_image.p_x =  form_id.ctlimage_listview_left_vert_bar1.p_x;



   int k;
   for (k = 1; k < fdp->num_listview_columns_available; ++k) {
      if (k >= fdp->listview_num_lists) {
         fdp->listview_col1_control_list[k].p_visible = false;
         fdp->listview_col2_control_list[k].p_visible = false;
         fdp->listview_col3_control_list[k].p_visible = false;
         fdp->listview_vert_sep_bar_image_list[k-1].p_visible = false;
         fdp->listview_image_overlay_control_list[k].p_visible = false;
      } else {
         fdp->listview_vert_sep_bar_image_list[k-1].p_visible = true;

         fdp->listview_vert_sep_bar_image_list[k-1].p_x = 
            fdp->listview_col3_control_list[k-1].p_x + fdp->listview_col3_control_list[k-1].p_width;

         fdp->listview_vert_sep_bar_image_list[k-1].p_height =
            fdp->listview_col1_control_list[k-1].p_height;

         fdp->listview_vert_sep_bar_image_list[k-1].p_y =
            fdp->listview_col1_control_list[k-1].p_y;

         fdp->listview_col1_control_list[k].p_width = fdp->listview_col1_control_list[0].p_width;
         fdp->listview_col3_control_list[k].p_width = fdp->listview_col3_control_list[0].p_width;

         fdp->listview_col2_control_list[k].p_width = pix2scale(col_width_pix,form_id) -
            fdp->listview_col1_control_list[k].p_width - fdp->listview_col3_control_list[k].p_width;

         fdp->listview_col1_control_list[k].p_x = fdp->listview_col1_control_list[k-1].p_x +
            col_width_scale + pix2scale(vert_sep_overhead,form_id);

         fdp->listview_col2_control_list[k].p_x = fdp->listview_col1_control_list[k].p_x +
            fdp->listview_col1_control_list[k].p_width;

         fdp->listview_col3_control_list[k].p_x = fdp->listview_col2_control_list[k].p_x +
            fdp->listview_col2_control_list[k].p_width;

         fdp->listview_col1_control_list[k].p_y = fdp->listview_col1_control_list[0].p_y;
         fdp->listview_col2_control_list[k].p_y = fdp->listview_col1_control_list[0].p_y;
         fdp->listview_col3_control_list[k].p_y = fdp->listview_col1_control_list[0].p_y;

         fdp->listview_col1_control_list[k].p_height = fdp->listview_col1_control_list[0].p_height;
         fdp->listview_col2_control_list[k].p_height = fdp->listview_col1_control_list[0].p_height;
         fdp->listview_col3_control_list[k].p_height = fdp->listview_col1_control_list[0].p_height;

         fdp->listview_col1_control_list[k].p_visible = true;
         fdp->listview_col2_control_list[k].p_visible = true;
         fdp->listview_col3_control_list[k].p_visible = true;

         fdp->listview_image_overlay_control_list[k].p_y = fdp->listview_col1_control_list[0].p_y;
         fdp->listview_image_overlay_control_list[k].p_x = fdp->listview_col1_control_list[k].p_x;
         fdp->listview_image_overlay_control_list[k].p_width = col_width_scale;
         fdp->listview_image_overlay_control_list[k].p_height = fdp->listview_col1_control_list[0].p_height;
         fdp->listview_image_overlay_control_list[k].p_visible = true;

      }
   }
}


// The slickedit V9 blackbox generator - this is not currently supported. but
// it used to work
static void resize_title_label(int form_id)
{
   form_id.blackbox1_title_label.p_x = pix2scale(12,form_id);
   form_id.blackbox1_title_label.p_y = pix2scale(fdp->vse_v9_title_label_p_y,form_id);
   form_id.blackbox1_title_label.p_width = pix2scale(80,form_id);
   //pix2scale(form_id.p_client_width,form_id)-pix2scale(8,form_id);
   form_id.blackbox1_title_label.p_auto_size = false;
   form_id.blackbox1_title_label.p_height = pix2scale(13,form_id);
   if (is_display_mode_open_buffers()) {
      form_id.blackbox1_title_label.p_caption = 'Open buffers';
   } else if (is_display_mode_goback_history()) {
      form_id.blackbox1_title_label.p_caption = 'Goback history';
   }

   int blackbox_x = pix2scale(0,form_id);
   int blackbox_y = pix2scale(3,form_id);
   int blackbox_width = pix2scale(form_id.p_client_width,form_id) -
      pix2scale(1,form_id);
   int blackbox_height = form_id.blackbox1_title_label.p_height + pix2scale(2,form_id);

   form_id.ctlimage_blackbox1_top_horiz_bar.p_x =
      form_id.ctlimage_blackbox1_bottom_horiz_bar.p_x =
      form_id.ctlimage_blackbox1_left_vert_bar.p_x = blackbox_x;
   form_id.ctlimage_blackbox1_right_vert_bar.p_x = blackbox_x + blackbox_width;

   form_id.ctlimage_blackbox1_top_horiz_bar.p_y =
      form_id.ctlimage_blackbox1_right_vert_bar.p_y =
      form_id.ctlimage_blackbox1_left_vert_bar.p_y = blackbox_y;
   form_id.ctlimage_blackbox1_bottom_horiz_bar.p_y =  blackbox_y + blackbox_height;

   //form_id.ctlimage_blackbox1_bottom_horiz_bar_shadow.p_x = blackbox_x + pix2scale(1,form_id);
   //form_id.ctlimage_blackbox1_bottom_horiz_bar_shadow.p_y = blackbox_y +
   //   blackbox_height + pix2scale(1,form_id);


   form_id.ctlimage_blackbox1_right_vert_bar.p_width =
      form_id.ctlimage_blackbox1_left_vert_bar.p_width = pix2scale(1,form_id);
   form_id.ctlimage_blackbox1_right_vert_bar.p_height =
      form_id.ctlimage_blackbox1_left_vert_bar.p_height = blackbox_height;

   //form_id.ctlimage_blackbox1_bottom_horiz_bar_shadow.p_height =
   form_id.ctlimage_blackbox1_bottom_horiz_bar.p_height =
      form_id.ctlimage_blackbox1_top_horiz_bar.p_height = pix2scale(1,form_id);

   form_id.ctlimage_blackbox1_left_vert_bar.p_backcolor =
      form_id.ctlimage_blackbox1_right_vert_bar.p_backcolor =
      form_id.ctlimage_blackbox1_top_horiz_bar.p_backcolor =
   //form_id.ctlimage_blackbox1_bottom_horiz_bar.p_backcolor = _rgb(100,100,100);
      form_id.ctlimage_blackbox1_bottom_horiz_bar.p_backcolor = _rgb(0,0,0);

   //form_id.ctlimage_blackbox1_bottom_horiz_bar_shadow.p_width =
   form_id.ctlimage_blackbox1_bottom_horiz_bar.p_width =
      form_id.ctlimage_blackbox1_top_horiz_bar.p_width = blackbox_width;
   //form_id.ctlimage_blackbox1_bottom_horiz_bar_shadow.p_backcolor = _rgb(140,140,140);

}


// set_form_components_y_offsets calculates the y offset for the editbox, the toolbuttons and
// the listview
static void set_form_components_y_offsets(int form_id)
{
   // ensure ctltext1.p_height is correct first
   form_id.ctltext1.p_font_name = fdp->setup_data.gfconfig.active_file_editbox_font;
   form_id.ctltext1.p_font_size = fdp->setup_data.gfconfig.active_file_editbox_font_size;

   form_id.ctltext1.p_height = form_id.ctltext1._text_height();// + pix2scale(2,form_id);

   if (fdp->setup_data.gfconfig.filename_editbox_y_offset != 0) 
      form_id.ctltext1.p_y = pix2scale(fdp->setup_data.gfconfig.filename_editbox_y_offset,form_id);
   else
      form_id.ctltext1.p_y = pix2scale(2,form_id);

   int buttons_p_y = scale2pix(form_id.ctltext1.p_height,form_id) + 4;
   form_id.ctltext1.p_visible = fdp->setup_data.gfconfig.filename_editbox_visible != 0;

   if (!form_id.ctltext1.p_visible) 
      buttons_p_y = 2;

   if (fdp->setup_data.gfconfig.button_row1_y_offset != 0) 
      buttons_p_y = fdp->setup_data.gfconfig.button_row1_y_offset;

   form_id.scrollbar_button.p_y = 
      form_id.options1_button.p_y = 
      form_id.goback_button.p_y = pix2scale(buttons_p_y,form_id);

   form_id.scrollbar_button.p_visible =
      form_id.options1_button.p_visible =
      form_id.goback_button.p_visible = fdp->setup_data.gfconfig.button_row1_visible != 0;

   if (fdp->setup_data.gfconfig.button_row1_visible && form_id.ctltext1.p_visible) {
      if (fdp->setup_data.gfconfig.button_row1_y_offset > fdp->setup_data.gfconfig.filename_editbox_y_offset) {
         fdp->listview_p_y = buttons_p_y + 29;
      } else {
         fdp->listview_p_y = 6 + scale2pix(form_id.ctltext1.p_y + form_id.ctltext1.p_height,form_id);
      }
   }
   else if (fdp->setup_data.gfconfig.button_row1_visible) 
      fdp->listview_p_y = buttons_p_y + 29;
   else if (form_id.ctltext1.p_visible) {
      fdp->listview_p_y = 6 + scale2pix(form_id.ctltext1.p_y + form_id.ctltext1.p_height,form_id);
   }
   else
      fdp->listview_p_y = 4;
}


// the filename editbox on the form expands to fill the available width
static void resize_editbox1(int form_id)
{
   form_id.ctltext1.p_x = pix2scale(2,form_id);
   form_id.ctltext1.p_width =
      pix2scale(form_id.p_client_width,form_id)-pix2scale(4,form_id);
   //form_id.ctltext1.p_auto_size = true;
   form_id.ctltext1.p_height = form_id.ctltext1._text_height();// + pix2scale(2,form_id);

   form_id.ctlimage_editbox1_top_horiz_bar.p_x =
      form_id.ctlimage_editbox1_bottom_horiz_bar.p_x =
      form_id.ctlimage_editbox1_left_vert_bar.p_x =
      form_id.ctltext1.p_x - pix2scale(1,form_id);
   form_id.ctlimage_editbox1_top_horiz_bar.p_y =
      form_id.ctlimage_editbox1_left_vert_bar.p_y =
      form_id.ctltext1.p_y - pix2scale(1,form_id);
   form_id.ctlimage_editbox1_right_vert_bar.p_width =
      form_id.ctlimage_editbox1_left_vert_bar.p_width = pix2scale(1,form_id);
   form_id.ctlimage_editbox1_right_vert_bar.p_height =
      form_id.ctlimage_editbox1_left_vert_bar.p_height =
      form_id.ctltext1.p_height + pix2scale(2,form_id);

   form_id.ctlimage_editbox1_left_vert_bar.p_backcolor =
      form_id.ctlimage_editbox1_right_vert_bar.p_backcolor =
      form_id.ctlimage_editbox1_top_horiz_bar.p_backcolor =
      form_id.ctlimage_editbox1_bottom_horiz_bar.p_backcolor = _rgb(127,157,185);

   form_id.ctlimage_editbox1_right_vert_bar.p_x =
      form_id.ctltext1.p_x + form_id.ctltext1.p_width;
   form_id.ctlimage_editbox1_right_vert_bar.p_y =
      form_id.ctltext1.p_y - pix2scale(1,form_id);

   form_id.ctlimage_editbox1_bottom_horiz_bar.p_y =
      form_id.ctltext1.p_y + form_id.ctltext1.p_height;
   form_id.ctlimage_editbox1_top_horiz_bar.p_width =
      form_id.ctltext1.p_width + pix2scale(2,form_id);
   form_id.ctlimage_editbox1_bottom_horiz_bar.p_height =
      form_id.ctlimage_editbox1_top_horiz_bar.p_height = pix2scale(1,form_id);
   form_id.ctlimage_editbox1_bottom_horiz_bar.p_width =
      form_id.ctlimage_editbox1_top_horiz_bar.p_width =
      form_id.ctltext1.p_width + pix2scale(2,form_id);

   form_id.ctlimage_editbox1_bottom_horiz_bar.p_visible =
      form_id.ctlimage_editbox1_top_horiz_bar.p_visible =
      form_id.ctlimage_editbox1_left_vert_bar.p_visible =
      form_id.ctlimage_editbox1_right_vert_bar.p_visible = form_id.ctltext1.p_visible;
}


#ifdef nothing123
// todo - the scroll markers don't always turn up...
static void show_editbox_scroll_markers()
{
   if (!fdp->ctltext1_scrolls_list_on_mouseover ||
       (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC) )
      return;

   int buf_list_length = get_display_data_list_length();
   int num_visible_positions = (fdp->listview_num_lists * fdp->listview_lines_per_list);
   int num_pixels = scale2pix(fdp->form_id.ctltext1.p_width, fdp->form_id) - (CTLTEXT1_SLIDER_MARGIN * 2);
   int num_pages = ((buf_list_length - 1) intdiv num_visible_positions) + 1;

   int pixels_per_step;

   if ((num_pages <= 1) || (num_pages > num_pixels)) {
      return;
   } else {
      pixels_per_step = num_pixels intdiv num_pages;
      if (pixels_per_step > 40) {
         pixels_per_step = 40;
      }
   }

   typeless dsetup;
   fdp->form_id._save_draw_setup(dsetup);
   fdp->form_id.p_draw_mode = PSDM_COPYPEN;
   fdp->form_id.p_draw_style = PSDS_SOLID;
   fdp->form_id.p_draw_width = 2;   // pixels

   int k;
   for (k = 0; k < num_pages; ++k) {

      fdp->form_id._draw_rect(
         fdp->form_id.ctlimage_editbox1_bottom_horiz_bar.p_x + 
                      pix2scale(CTLTEXT1_SLIDER_MARGIN + (k * pixels_per_step),fdp->form_id),
         fdp->form_id.ctlimage_editbox1_bottom_horiz_bar.p_y, // - pix2scale(3,fdp->form_id),
         fdp->form_id.ctlimage_editbox1_bottom_horiz_bar.p_x + 
                      pix2scale(CTLTEXT1_SLIDER_MARGIN + 2 + (k * pixels_per_step),fdp->form_id),
         fdp->form_id.ctlimage_editbox1_bottom_horiz_bar.p_y + pix2scale(2,fdp->form_id),
         _rgb(115,109,99));
   }
   fdp->form_id._restore_draw_setup(dsetup);
}

#endif


// resize_listview sets the number of columns and their width, according to
// how much information there is to show
static void resize_listview(int form_id)
{
   // TODO - caption doesn't always appear correctly when the form is docked
   form_id.p_caption = get_toolbar_caption();
   int listnum = 0;
   for (;listnum < fdp->listview_num_lists; ++listnum) {

      if (form_id.p_client_height > 80) {
         int xyz = pix2scale(form_id.p_client_height - // 2 - 
                scale2pix(form_id.ctllist_view1_col1.p_y,form_id),form_id);

         fdp->listview_col1_control_list[listnum].p_height = xyz;
            fdp->listview_col2_control_list[listnum].p_height = xyz;
            fdp->listview_col3_control_list[listnum].p_height =  xyz;
                  //pix2scale(form_id.p_client_height - // 2 - 
                    //  scale2pix(form_id.ctllist_view1_col1.p_y,form_id),form_id);
      } else {
         fdp->listview_col1_control_list[listnum].p_height = 
            fdp->listview_col2_control_list[listnum].p_height =
            fdp->listview_col3_control_list[listnum].p_height = pix2scale(50,form_id);
      }

      fdp->listview_col2_control_list[listnum].p_font_name = fdp->setup_data.gfconfig.listview_font;       
      fdp->listview_col2_control_list[listnum].p_font_size = fdp->setup_data.gfconfig.listview_font_size;  
      fdp->listview_col1_control_list[listnum].p_font_name = fdp->setup_data.gfconfig.listview_font;       
      fdp->listview_col1_control_list[listnum].p_font_size = fdp->setup_data.gfconfig.listview_font_size;  
      fdp->listview_col1_control_list[listnum].p_pic_space_y = 0;                                        
      fdp->listview_col1_control_list[listnum].p_pic_point_scale = 0;                                    
   }

   calc_lines_per_list(form_id);

   int num_lists = ((get_display_data_list_length()-1) intdiv fdp->listview_lines_per_list) + 1;

   if (num_lists > fdp->num_listview_columns_available)
      num_lists = fdp->num_listview_columns_available;  
   
   if (fdp->listview_lines_per_list >= get_display_data_list_length())
      generate_the_listview(form_id,1);
   else
      generate_the_listview(form_id,num_lists);

   populate_lists(form_id);
   if (fdp->listview_line_is_selected) {
      set_listview_list_line_selection(
         fdp->listview_selected_list_num, fdp->listview_selected_line_num,true);
   }
   //show_editbox_scroll_markers();
}

static void redisplay_list_data(int form_id)
{
   populate_lists(form_id);
   if (fdp->listview_line_is_selected) {
      set_listview_list_line_selection(
         fdp->listview_selected_list_num, fdp->listview_selected_line_num,true);
   }
   //show_editbox_scroll_markers();
}


static void GFilemanForm_on_resize(int form_id)
{
   set_form_data_ptr(form_id);
   set_form_components_y_offsets(form_id);
   resize_listview(form_id);
   resize_editbox1(form_id);
   // vse_v9_mode is currently never enabled
   if (vse_v9_mode) {
      resize_title_label(form_id);
   }

   fdp->redo_form = false;
   fdp->redo_listview_list_counter = 2;

   // TODO - what happens on platforms other than Windows ?
   // special_x/y were the first attempt at hiding the file info form
   // without disabling it - if it's disabled, then re-enabling it causes it
   // to get the focus - which is bad because the focus needs to stay on the
   // mdi edit window (switching the focus around causes the display to be
   // undesirably "busy") 
   // - this is now redundant because the "tooltip" window is hidden by setting
   // its width/ height to zero - which currently works (on Windows).
   special_x = form_id.p_x + 60;
   special_y = form_id.p_y + 8;
}

void GFilemanForm1.on_resize()
{
   // set_form_data_ptr is called in GFilemanForm_on_resize.
   GFilemanForm_on_resize(p_active_form);
}


void scrollbar_button.lbutton_down()
{
   set_form_data_ptr(p_active_form);

   if (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC)
      return;

   // if all items are already visible then ignore scrollbar button
   if ((fdp->listview_num_lists * fdp->listview_lines_per_list) >= get_display_data_list_length()) 
      return;

   if (fdp->scrollbar_mode == SCROLLBAR_MODE_CAN_HIDE) {
      if (fdp->scrollbar_is_visible) {
         fdp->scrollbar_is_visible = false;
         resize_listview(p_active_form);
      } else {
         fdp->scrollbar_is_visible = true;
         resize_listview(p_active_form);
         process_scrollbar(p_active_form);
      }
   }
   else if (fdp->scrollbar_mode == SCROLLBAR_MODE_NO_SHOW) {
      fdp->scrollbar_is_visible = false;
      process_scrollbar(p_active_form);
   }
}


void scrollbar_button.rbutton_up()
{
   set_form_data_ptr(p_active_form);
   switch (fdp->scrollbar_mode) {

      //default :
      case SCROLLBAR_MODE_NO_SHOW :
         fdp->scrollbar_mode = SCROLLBAR_MODE_CAN_HIDE;
         fdp->scrollbar_is_visible = true;
         resize_listview(p_active_form);
         return;
      case SCROLLBAR_MODE_CAN_HIDE :
         fdp->scrollbar_mode = SCROLLBAR_MODE_NO_SHOW;
         fdp->scrollbar_is_visible = false;
         resize_listview(p_active_form);
         return;
   }
}


// if the name of the current buffer hasn't changed, the buffer list is checked
// only when force_buffer_list_check is true (every 4 seconds)
static boolean check_if_buffer_list_has_changed()
{
   static _str last_bufname;
   static boolean last_modified;
   boolean redo = false;

   if (!force_buffer_list_check && !_no_child_windows() && (last_bufname == _mdi.p_child.p_buf_name)) {
      if (_mdi.p_child.p_modify == last_modified) 
         return false;
   }
   last_bufname = _mdi.p_child.p_buf_name;
   last_modified = _mdi.p_child.p_modify;

   fdp->num_buffers2 = 0;
   fdp->buffer_list2._makeempty();
   _mdi.p_child.for_each_buffer( 'GFM_add_to_buf_list2' );
   if (fdp->num_buffers2 == fdp->num_buffers) {
      int k;
      for (k=0; k < fdp->num_buffers; ++k) {
         if ((fdp->display_data_list[k].buf_id != fdp->buffer_list2[k].buf_id ) ||
            (fdp->display_data_list[k].buf_name != fdp->buffer_list2[k].buf_name ) ||
            (fdp->display_data_list[k].buf_modified != fdp->buffer_list2[k].buf_modified )) {
            redo = true;
            break;
         }
      }
      if (!redo) {
         return false;
      }
   }
   return true;
}


void GFilemanForm1.on_destroy()
{
   set_form_data_ptr(p_active_form);
   fdp->form_is_alive = false;
   fdp->form_name = "";
   call_event(p_window_id,ON_DESTROY,'2');
}


//=============================================================================
// 
// >>>>>>>>>>>>>>>>>>>   WARNING   <<<<<<<<<<<<<<<<<<<<<
// 
// kill_gfileman_timer is an important _command that must be called before
// rebuilding GFileman.e so that the timer is stopped, otherwise you are
// likely to get an "invalid function pointer error" (which is more annoying than
// catastrophic).
_command kill_gfileman_timer()
{
   _kill_timer(GFM_timer_handle);
}



static void GFilemanMaintainForm(GFM_form_data * fp)
{
   int form_id = _find_object(fp->form_name);
   if (form_id != 0) {
      set_form_data_ptr(form_id);
   } else {
      //fp->viewx_col2_move_mode = false;
      fp->form_is_alive = false;
      return;
   }

   // every second
   fdp->scrollbar_mousemove_counter = 0;

   if ( (fdp->text_info1_state != TEXT_INFO1_STATE_ACTIVE_FILE) ||
      holdoff_file_view_list_update || fdp->viewx_col2_move_mode ||
      fdp->GFileman_file_info_showing || fdp->listview_line_is_selected) {
      // when a new buffer is switched to using this (GFileman) form, the buffer
      // history list is left temporarily unchanged so that the list of files
      // doesn't change - and also to allow multiple files to be switched to
      // without any except the last switch affecting the buffer history list.

      // when the mouse moves out of the window, the pending buffer history
      // is processed and the list is updated

      int x = form_id.mou_last_x('m');
      int y = form_id.mou_last_y('m');
      if (x<0 || x>form_id.p_width || y<0 || y>form_id.p_height) {

         if (fdp->listview_line_is_selected && (fdp->GFM_file_order_mode != GFM_SORT_FILESPEC)) {
            // parameter true forces a repaint
            clear_listview_list_line_selection(true);
         }
         if ( (fdp->GFM_file_order_mode == GFM_SORT_FILESPEC) &&
              (fdp->ctltext1_window_id != _get_focus()) &&
              !fdp->GFileman_might_switch_focus ) {
            fdp->GFM_file_order_mode = fdp->GFM_save_file_order_mode;
            fdp->redo_listview_list_counter = 2;
            fdp->buffer_list_view_start_index = 0;
         }

         if (fdp->GFM_file_order_mode != GFM_SORT_FILESPEC) {
            if (holdoff_file_view_list_update) {
               holdoff_file_view_list_update = false;
               goback_process_pending_buffer_history();
               fdp->redo_listview_list_counter += 1;
            }
            fdp->viewx_col2_move_mode = false;
            hide_file_info();
            if ( fdp->text_info1_state != TEXT_INFO1_STATE_ACTIVE_FILE ) {
               set_text_info1_show_active_file(form_id);
            }
         }
      }
   }
   fdp->GFileman_might_switch_focus = false;

   // when holdoff_file_view_list_update is true, it's ok to update the display
   // of files because holdoff_file_view_list_update prevents the list changing
   // if a different buffer is switched to and the display is in recent-access-order

   // check_if_display_list_data_changed() checks only once every 4 seconds if the
   // current buffer name hasn't changed
   if ((fdp->redo_listview_list_counter > 0) || check_if_display_list_data_changed()) {

      if (--fdp->redo_listview_list_counter != 1)
         fdp->redo_listview_list_counter = 0;
      
      fdp->form_id.p_caption = get_toolbar_caption();
      fdp->form_id.ctltext1.p_enabled = true;
      goback_enable_buffer_list_history();
      fdp->form_display_mode = fdp->requested_display_mode;
      if (fdp->redo_form) {
         GFilemanForm_on_resize(form_id);
         fdp->redo_form = false;
         fdp->redo_listview_list_counter = 0;
      }
      generate_display_list_data();
      resize_listview(form_id);
      if ( fdp->text_info1_state == TEXT_INFO1_STATE_ACTIVE_FILE ) {
         set_text_info1_show_active_file(form_id);
      }
      // listview_force_line_reselect is set true after right click is used
      // on a filename
      if (fdp->listview_force_line_reselect) {
         fdp->listview_force_line_reselect = false;
         // parameter true forces a repaint
         clear_listview_list_line_selection(true);
         hide_file_info();
      }
   }
}               


// this is called from GFilemanConfig.e when config dialog exits
void GFileman_update_all_forms()
{
   int k;
   for ( k = 0; k < GFM_form_data_array._length(); ++k ) {
      if (GFM_form_data_array[k].form_is_alive) {
         GFM_form_data_array[k].show_shortcuts_now = 0;
         if (GFM_form_data_array[k].kill_me) {
            GFM_form_data_array[k].kill_me = false;
            int form_id = _find_object(GFM_form_data_array[k].form_name);
            if (form_id != 0)
               form_id._delete_window('');
            continue;
         }
         GFileman_load_form_config( &GFM_form_data_array[k].setup_data, 
            GFM_form_data_array[k].form_name );
         GFM_form_data_array[k].redo_form = true;
         GFM_form_data_array[k].redo_listview_list_counter = 2;
         set_filename_sort_order_from_config(&GFM_form_data_array[k]);
      }
   }
}



static void GFileman_timer_callback()
{
   int k;
   boolean any_alive = false;
   static int buffer_list_check_count;
   //static int seq;

   if (_use_timers == 0) 
      return;
   
   // maintain_line_buffer_goback_history();

// if (++seq & 3) {
//    return;
// }
   // every fourth time
   // seq = 0;
   _kill_timer(GFM_timer_handle);

   for ( k = 0; k < GFM_form_data_array._length(); ++k ) {
      if (GFM_form_data_array[k].form_is_alive) {
         GFilemanMaintainForm(&GFM_form_data_array[k]);
         any_alive = true;
      }
   }
   if (!any_alive) {
      holdoff_file_view_list_update = false;
      goback_process_pending_buffer_history();
      GFileman_destroy_file_info_form_if_any();
   }

   // units of 100 milliseconds
   #define GFileman_timer_callback_rate_selector 2

   // ensure the timer rate is fast (it's sometimes slower)
   GFM_timer_handle = _set_timer(GFileman_timer_callback_rate_selector * 100, GFileman_timer_callback);
   
   // rate is in units 100ms, so 10/rate gives seconds - so 2 seconds is selected here
   force_buffer_list_check = false;
   if (++buffer_list_check_count > ((10*2)/GFileman_timer_callback_rate_selector)) {
      buffer_list_check_count = 0;
      force_buffer_list_check = true;
   }
}
  


// GFilemanForm_create is called from other files for other forms
void GFilemanForm_create(_str form_name)
{
   find_or_create_GFM_form_data_array_entry(form_name, false);
   // p_user is firstly set to -1 to force set_form_data_ptr to assign it to
   // the index into GFM_form_data_array for this form
   p_active_form.p_user = -1;
   set_form_data_ptr(p_active_form);

   // load the latest config info
   GFileman_load_form_config( &fdp->setup_data, p_active_form.p_name ); 

   fdp->listview_col1_control_list[0] = p_active_form.ctllist_view1_col1; 
   fdp->listview_col2_control_list[0] = p_active_form.ctllist_view1_col2; 
   fdp->listview_col3_control_list[0] = p_active_form.ctllist_view1_col3; 

   fdp->listview_col1_control_list[1] = p_active_form.ctllist_view2_col1; 
   fdp->listview_col2_control_list[1] = p_active_form.ctllist_view2_col2; 
   fdp->listview_col3_control_list[1] = p_active_form.ctllist_view2_col3; 

   fdp->listview_col1_control_list[2] = p_active_form.ctllist_view3_col1; 
   fdp->listview_col2_control_list[2] = p_active_form.ctllist_view3_col2; 
   fdp->listview_col3_control_list[2] = p_active_form.ctllist_view3_col3; 

   fdp->listview_col1_control_list[3] = p_active_form.ctllist_view4_col1; 
   fdp->listview_col2_control_list[3] = p_active_form.ctllist_view4_col2; 
   fdp->listview_col3_control_list[3] = p_active_form.ctllist_view4_col3; 

   fdp->listview_image_overlay_control_list[0] = p_active_form.view1_ctlimage1;
   fdp->listview_image_overlay_control_list[1] = p_active_form.view2_ctlimage1;
   fdp->listview_image_overlay_control_list[2] = p_active_form.view3_ctlimage1;
   fdp->listview_image_overlay_control_list[3] = p_active_form.view4_ctlimage1;

   fdp->listview_vert_sep_bar_image_list[0] = p_active_form.ctlimage_listview_vert_sep_bar1;
   fdp->listview_vert_sep_bar_image_list[1] = p_active_form.ctlimage_listview_vert_sep_bar2;
   fdp->listview_vert_sep_bar_image_list[2] = p_active_form.ctlimage_listview_vert_sep_bar3;


   _pic_index_col1_file_mod = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_fileview_col1_file_mod.png@native'); 
   //pic_index_col1_blank = _find_or_add_picture(GFM_BITMAP_PATH :+ '_f_d2.svg');
   pic_index_col1_blank = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_fileview_col1_blank.png@native');
   pic_index_col1_dir_collapsed = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_fileview_col1_dir_collapsed.png@native');
   pic_index_col1_dir_expanded = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_fileview_col1_dir_expanded.png@native');
   pic_index_col1_pin = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_fileview_col1_pin.png@native');
   pic_index_col1_active_file = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_fileview_col1_active_file.png@native');
   //pic_index_col1_active_file = _find_or_add_picture(GFM_BITMAP_PATH :+ 'image2vector.svg');
   pic_index_col1_active_file_mod = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_fileview_col1_active_file_mod.png@native');

   pic_index_checkbox_ticked = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_checkbox-ticked.png@native');
   pic_index_checkbox_unticked = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_checkbox-unticked.png@native');

   col2_backcolor = _rgb(250,250,250);

   int k;
   for (k = 0; k < MAX_LISTVIEW_COLS ; ++k) {
      fdp->listview_col1_control_list[k].p_user = k; 
      fdp->listview_col2_control_list[k].p_user = k; 
      fdp->listview_col3_control_list[k].p_user = k; 
      fdp->listview_image_overlay_control_list[k].p_user = k; 

      fdp->listview_col1_control_list[k].p_backcolor = _rgb(255,255,255);
      fdp->listview_col2_control_list[k].p_backcolor = col2_backcolor;
      fdp->listview_col3_control_list[k].p_backcolor = col2_backcolor;

      fdp->listview_col1_control_list[k].p_border_style = BDS_SIZABLE;
      fdp->listview_col2_control_list[k].p_border_style = BDS_SIZABLE;
      fdp->listview_col3_control_list[k].p_border_style = BDS_SIZABLE;

      fdp->listview_col1_control_list[k].p_pic_point_scale = 0;   
      fdp->listview_col1_control_list[k].p_picture = pic_index_col1_blank;
      fdp->listview_col1_control_list[k].p_stretch = 0;
      fdp->listview_col1_control_list[k].p_auto_size = false;
   }

   fdp->buffer_list_view_start_index = 0;    

   int one_pixel_x = _lx2lx(SM_PIXEL,p_xyscale_mode,1);
   int one_pixel_y = _ly2ly(SM_PIXEL,p_xyscale_mode,1);

   ctlimage_listview_left_vert_bar1.p_backcolor =
   ctlimage_listview_right_vert_bar1.p_backcolor =
   ctlimage_listview_bottom_horiz_bar1.p_backcolor =
      ctlimage_listview_top_horiz_bar1.p_backcolor = 0x00B99D7F;
   ctlimage_listview_vert_sep_bar1.p_width = one_pixel_x;
   ctlimage_listview_vert_sep_bar1.p_backcolor = _rgb(200,200,200);
   ctlimage_listview_vert_sep_bar2.p_width = one_pixel_x;
   ctlimage_listview_vert_sep_bar2.p_backcolor = _rgb(200,200,200);

   ctlimage_listview_vert_sep_bar3.p_width = one_pixel_x;
   ctlimage_listview_vert_sep_bar3.p_backcolor = _rgb(200,200,200);

   ctlimage_editbox1_top_horiz_bar.p_visible = true;
   ctlimage_editbox1_left_vert_bar.p_visible = true;
   ctlimage_editbox1_bottom_horiz_bar.p_visible = true;
   ctlimage_editbox1_right_vert_bar.p_visible = true;

   ctlimage_blackbox1_top_horiz_bar.p_visible = vse_v9_mode;
   ctlimage_blackbox1_right_vert_bar.p_visible = vse_v9_mode;
   ctlimage_blackbox1_left_vert_bar.p_visible = vse_v9_mode;
   ctlimage_blackbox1_bottom_horiz_bar.p_visible = vse_v9_mode;
   blackbox1_title_label.p_visible = vse_v9_mode;

   scrollbar_move_alive_pic = 
      scrollbar_move_pic = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_scrollbar_slider_image.bmp@native');
   //scrollbar_move_alive_pic = gp_find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_scrollbar-move-alive.bmp');
   //
   //scrollbar_image.p_picture = gp_find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_scrollbar-fixed.bmp');
   //scrollbar_image.p_stretch = 1;
   //scrollbar_slider_image.p_picture = scrollbar_move_pic;
   //
   //scrollbar_top_image.p_picture = gp_find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_scrollbar-top.bmp');
   //scrollbar_bottom_image.p_picture = gp_find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_scrollbar-bottom.bmp');

   scrollbar_horizontal_indicator_image.p_backcolor = _rgb(62, 148, 253);
   scrollbar_slider_image.p_backcolor = _rgb(62, 148, 253);

   scrollbar_button.p_y = pix2scale(fdp->buttons_row1_p_y,p_active_form);
   scrollbar_button.p_x = pix2scale(SCROLLBAR_BUTTON_P_X,p_active_form);
   scrollbar_button.p_width = pix2scale(16,p_active_form);
   scrollbar_button.p_auto_size = true;
   options1_button.p_y = pix2scale(fdp->buttons_row1_p_y,p_active_form);
   options1_button.p_x = pix2scale(OPTIONS_BUTTON_P_X,p_active_form);

   scrollbar_button.p_picture = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_scrollbar-button.png@native');

   options1_button.p_picture = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_options_button.png@native');

   goback_button.p_picture = _find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_goback_button.png@native');
   goback_button.p_y = pix2scale(fdp->buttons_row1_p_y,p_active_form);
   goback_button.p_x = pix2scale(GOBACK_BUTTON_P_X,p_active_form);

   ctltext1.p_enabled = false;
   ctltext1.p_text = form_name;
   set_filename_sort_order_from_config(fdp);
   //fdp->GFM_file_order_mode = GFM_SORT_DIRECTORY_EXTENSION_FILENAME;
   fdp->display_data_list._makeempty();
   generate_display_list_data();
   fdp->form_is_alive = true;
   _kill_timer(GFM_timer_handle);
   GFM_timer_handle = _set_timer(1000,GFileman_timer_callback);
   goback_enable_buffer_list_history();
}


// todo - how to avoid creating _commands just for a menu
_command GFileman_form_configure_command()
{
   //_message_box( p_active_form.p_name );
   _str fm = p_active_form.p_name;
   //GFM_form_data * save_fxp = fdp;
   int info_form_id = _find_object('GFilemanSetupForm');
   if (info_form_id == 0) {
      show( '-xy -modal GFilemanSetupForm',fm );
      //GFileman_load_form_config( &save_fxp->setup_data, fm );
      //save_fxp->redo_listview_list_counter = 2;
   }
}

static void set_filename_sort_order_from_config(GFM_form_data * fdp)
{
   switch (fdp->setup_data.gfconfig.filename_display_order) {
      case 'Recently accessed' :
         fdp->GFM_file_order_mode = GFM_SORT_RECENT_ACCESS; return;
      case 'Directory then Filename' :
         fdp->GFM_file_order_mode = GFM_SORT_DIRECTORY_FILENAME; return;
      case 'Filename' :
         fdp->GFM_file_order_mode = GFM_SORT_FILENAME; return;
      case 'Extension then Filename' :
         fdp->GFM_file_order_mode = GFM_SORT_EXTENSION_FILENAME; return;
      case 'Directory Extension Filename' :
      default :
         fdp->GFM_file_order_mode = GFM_SORT_DIRECTORY_EXTENSION_FILENAME; return;
   }
}


_command GFileman_listview_sort_by_directory_filename()
{
   fdp->GFM_file_order_mode = GFM_SORT_DIRECTORY_FILENAME;
   fdp->redo_listview_list_counter = 2;
}

_command GFileman_listview_sort_by_recent_access()
{
   fdp->GFM_file_order_mode = GFM_SORT_RECENT_ACCESS;
   fdp->redo_listview_list_counter = 2;
}

_command GFileman_listview_sort_by_filename()
{
   fdp->GFM_file_order_mode = GFM_SORT_FILENAME;
   fdp->redo_listview_list_counter = 2;
}

_command GFileman_listview_sort_by_extension_filename()
{
   fdp->GFM_file_order_mode = GFM_SORT_EXTENSION_FILENAME;
   fdp->redo_listview_list_counter = 2;
}

_command GFileman_listview_sort_by_directory_extension_filename()
{
   fdp->GFM_file_order_mode = GFM_SORT_DIRECTORY_EXTENSION_FILENAME;
   fdp->redo_listview_list_counter = 2;
}

static _str get_sort_order_string(int order)
{
   switch (order) {
      case GFM_SORT_RECENT_ACCESS :
         return 'recent access order';
      case GFM_SORT_DIRECTORY_FILENAME :
         return 'directory group: filename order';
      case GFM_SORT_FILESPEC :
         return 'filename pattern match';
      case GFM_SORT_FILENAME :
         return 'filename order';
      case GFM_SORT_EXTENSION_FILENAME :
         return 'extension group: filename order';
      case GFM_SORT_DIRECTORY_EXTENSION_FILENAME :
         return 'directory group: extension group: filename order';
   }
   return 'filename order';
}

static _str get_current_sort_order_string()
{
   return get_sort_order_string(fdp->GFM_file_order_mode);
}


void options1_button.lbutton_up()
{
   set_form_data_ptr(p_active_form);

   GFM_form_data * save_fxp = fdp;

   int index=find_index("GFilemanButtonMenu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');

   // build the menu
   _menu_insert(menu_handle, -1, MF_ENABLED, "&Configure",
      "GFileman_form_configure_command","","", 
      'Configure ' :+ p_active_form.p_name);

   int checked = (fdp->GFM_file_order_mode == GFM_SORT_RECENT_ACCESS) ?
      MF_CHECKED : 0;
   _menu_insert(menu_handle, -1, MF_ENABLED|checked, "Sort &Recently accessed",
      "GFileman_listview_sort_by_recent_access","","", 
      get_sort_order_string(GFM_SORT_RECENT_ACCESS));

   checked = (fdp->GFM_file_order_mode == GFM_SORT_DIRECTORY_FILENAME) ?
      MF_CHECKED : 0;
   _menu_insert(menu_handle, -1, MF_ENABLED|checked, "Sort &Directory",
      "GFileman_listview_sort_by_directory_filename","","", 
      get_sort_order_string(GFM_SORT_DIRECTORY_FILENAME));

   checked = (fdp->GFM_file_order_mode == GFM_SORT_FILENAME) ?
      MF_CHECKED : 0;
   _menu_insert(menu_handle, -1, MF_ENABLED|checked, "Sort &Filename",
      "GFileman_listview_sort_by_filename","","", 
      get_sort_order_string(GFM_SORT_FILENAME));

   checked = (fdp->GFM_file_order_mode == GFM_SORT_EXTENSION_FILENAME) ?
      MF_CHECKED : 0;
   _menu_insert(menu_handle, -1, MF_ENABLED|checked, "Sort &Extension/filename",
      "GFileman_listview_sort_by_extension_filename","","", 
      get_sort_order_string(GFM_SORT_EXTENSION_FILENAME));

   checked = (fdp->GFM_file_order_mode == GFM_SORT_DIRECTORY_EXTENSION_FILENAME) ?
      MF_CHECKED : 0;
   _menu_insert(menu_handle, -1, MF_ENABLED|checked, "Sort Directory/e&xtension",
      "GFileman_listview_sort_by_directory_extension_filename","","", 
      get_sort_order_string(GFM_SORT_DIRECTORY_EXTENSION_FILENAME));

   _menu_insert(menu_handle, -1, MF_ENABLED, "Toggle display mode",
      "GFM_toggle_display_mode","","", '');

   // Show the menu.
   int x =100;
   int y=100;
   x=mou_last_x('M')-x;y=mou_last_y('M')-y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status=_menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);
   save_fxp->redo_form = true;
   //save_fxp->redo_listview_list_counter = 2;

   // set the focus back
   /*****
   if (_mdi.p_child._no_child_windows()==0) {
      _mdi.p_child._set_focus();
   }********/

}


void goback_button.lbutton_down()
{
   set_form_data_ptr(p_active_form);
   GFM_toggle_display_mode();
   generate_display_list_data();
   resize_listview(p_active_form);

   if (fdp->requested_display_mode == DISPLAY_MODE_GOBACK_HISTORY) 
      fdp->viewx_col2_move_mode = true;
   else
      fdp->viewx_col2_move_mode = false;
}


void GFilemanForm1.on_create()
{
   GFilemanForm_create(p_active_form.p_name);
}


void _listman_key1_GFileman()
{
   _str form_name = '';
   int form_index = -1;
   // find an alive form that has show_shortcuts_on_demand enabled
   int k;
   for ( k = 0; k < GFM_form_data_array._length(); ++k ) {
      if (GFM_form_data_array[k].form_is_alive && GFM_form_data_array[k].setup_data.gfconfig.show_shortcuts_on_demand) {
         form_name = GFM_form_data_array[k].form_name;
         form_index = k;
         break;
      }
   }

   if (form_name == '') {
      // no live forms with on demand enabled, check if any non live
      form_name = GFileman_find_form_with_shortcuts_on_demand_enabled();
      if (form_name == '') 
         return;
   }

   // now see if the form exists 
   int form_id = _find_formobj(form_name);
   if (form_id == 0) {
      form_index = find_or_create_GFM_form_data_array_entry(form_name);
      GFM_form_data_array[form_index].show_shortcuts_now = 1;
      GFM_form_data_array[form_index].kill_me = true;
      GFM_form_data_array[form_index].form_display_mode = DISPLAY_MODE_SHORTCUT_LIST;
      show('-xy ' :+ form_name);
   }
   else {
      set_form_data_ptr(form_id);
      if (fdp->setup_data.gfconfig.show_shortcuts_on_demand) {
         fdp->show_shortcuts_now = 1;
      }
      else {
         return;
      }

      int wid = _tbIsVisible(form_name);
      if (wid) {
         tbShow(form_name);
      } else {
         // First check for auto hidden tool window
         // third parameter true means killDockChanMouseEvents - whatever they are!
         wid=_tbMaybeAutoShow(form_name,'',true);
         if( wid==0 ) {
            tbShow(form_name);
            wid=activate_tool_window(form_name);
         }
      }
      fdp->show_shortcuts_now = 1;
      fdp->form_display_mode = DISPLAY_MODE_SHORTCUT_LIST;
      generate_display_list_data();
      resize_listview(form_id);
      hide_file_info();
   }
}


void _listman_key2_GFileman(_str event_name)
{
   int k;
   for ( k = 0; k < GFM_form_data_array._length(); ++k ) {
      if (GFM_form_data_array[k].form_is_alive) {
         GFM_form_data_array[k].show_shortcuts_now = 0;
         if (GFM_form_data_array[k].kill_me) {
            GFM_form_data_array[k].kill_me = false;
            if (event_name != 'LBUTTON-DOWN') {
               int form_id = _find_object(GFM_form_data_array[k].form_name);
               if (form_id != 0)
                  form_id._delete_window('');
               continue;
            }
         }
         GFM_form_data_array[k].redo_listview_list_counter = 2;
         set_filename_sort_order_from_config(&GFM_form_data_array[k]);
      }
   }
}


void GFileman_show_form(_str form_name)
{
   int form_index;
   // see if the form exists 
   int form_id = _find_formobj(form_name);
   if (form_id == 0) {
      form_index = find_or_create_GFM_form_data_array_entry(form_name);
      show('-xy ' :+ form_name);
   }
   else {
      set_form_data_ptr(form_id);
      int wid = _tbIsVisible(form_name);
      if (wid) {
         tbShow(form_name);
      } else {
         // First check for auto hidden tool window
         // third parameter true means killDockChanMouseEvents.
         wid=_tbMaybeAutoShow(form_name,'',true);
         if( wid==0 ) {
            tbShow(form_name);
            wid=activate_tool_window(form_name);
         }
      }
      generate_display_list_data();
      resize_listview(form_id);
      hide_file_info();
   }
}


void _on_load_module_GFileman(_str module_name)
{
   _str sm = strip(module_name, "B", "\'\"");
   if (strip_filename(sm, 'PD') == 'GFileman.e') {
      kill_gfileman_timer();
   }
}


definit()   
{
   // destroy all form data
   GFM_form_data_array._makeempty();
   find_or_create_GFM_form_data_array_entry("GFilemanForm1", true);
   find_or_create_GFM_form_data_array_entry("GFilemanForm2", true);
   find_or_create_GFM_form_data_array_entry("GFilemanForm3", true);

   if (arg(1)=="L") {
      _kill_timer(GFM_timer_handle);
      tw_register_form('GFilemanForm1', 0, DOCKAREAPOS_NONE);
      tw_register_form('GFilemanForm2', 0, DOCKAREAPOS_NONE);
      tw_register_form('GFilemanForm3', 0, DOCKAREAPOS_NONE);

      //_tbAddForm('GFilemanForm1',TBFLAG_ALWAYS_ON_TOP|TBFLAG_SIZEBARS,false,0,true);
      //_tbAddForm('GFilemanForm2',TBFLAG_ALWAYS_ON_TOP|TBFLAG_SIZEBARS,false,0,true);
      //_tbAddForm('GFilemanForm3',TBFLAG_ALWAYS_ON_TOP|TBFLAG_SIZEBARS,false,0,true);
   }
   GFM_timer_handle = _set_timer(4000,GFileman_timer_callback);

   // int k = _find_formobj('GFilemanForm1');
   // if (k > 0) {
   //    say('hhh ' :+ k);
   //    k.p_user = -1;
   // }
   // if this is an editor invocation, init goback
   if (arg(1)!="L") {
      //init_goback_history();
   }
}



_command void xfm1() name_info(',')
{
   execute('tbSmartShow GFilemanForm1');
}

_command void xfm2() name_info(',')
{
   execute('tbSmartShow GFilemanForm2');
}

_command void xfm3() name_info(',')
{
   execute('tbSmartShow GFilemanForm3');
}






/*
defeventtab GFilemanForm2;

void GFilemanForm2.on_create()
{
   GFilemanForm_create(p_active_form.p_name);
}

void GFilemanForm2.on_resize()
{
   // set_form_data_ptr is called in GFilemanForm_on_resize.
   GFilemanForm_on_resize(p_active_form);
}

void GFilemanForm2.on_destroy()
{
   set_form_data_ptr(p_active_form);
   fdp->form_is_alive = false;
   fdp->form_name = "";
   call_event(p_window_id,ON_DESTROY,'2');
}

*/

