#include "slick.sh"
#import "se/ui/toolwindow.sh"

#import "DLinkList.e"
#import "xretrace.e"

defeventtab xretrace_scrollbar_form;

 
struct xbar_form_data {
   int wid;
   int curr_line;
   int nof_lines;
   int buf_id;
   boolean modified;
   int edit_buf_wid;
   int num_marker_rows;
   boolean no_markup;
   boolean close_me;
   int listbox_row_bitmap_id[];
   int listbox_row_associated_line_number[];
};
 
int pic_visited_line;
int pic_changed_line;
int pic_old_changed_line;
int pic_bookmark_line;
int pic_blank_line;
int pic_scrollbar_image;
int pic_changed_and_bookmarked_line;

boolean xbar_update_needed;  // global for all xbar forms

xbar_form_data xbar_forms[];

#define GRAY 0X00A8A8A8
#define INACTIVE_SCROLLBAR_HANDLE_COLOUR 0X00EE62BD
#define RED_MINUS1 0x000000FE

// void xbar1.rbutton_down()
// {
//    //p_active_form._delete_window();
// }



static int pix2scale(int pix,int wid)
{
   return _dx2lx(wid.p_xyscale_mode, pix);
}


static int scale2pix(int scale,int wid)
{
   return _lx2dx(wid.p_xyscale_mode, scale);
}


static int right_mouse_xbar_form_id;

_command xretrace_scrollbar_form_close()
{
   xbar_forms[right_mouse_xbar_form_id].close_me = true;
   xbar_update_needed = true;
}


_command void xretrace_set_bookmark_for_buffer() name_info(',')
{
   xretrace_add_bookmark_for_buffer(_mdi.p_child.p_buf_name, _mdi.p_child, _mdi.p_child.p_line, _mdi.p_child.p_col); 
   xbar_forms[right_mouse_xbar_form_id].no_markup = true;
}

_command void xretrace_clear_bookmark_for_buffer() name_info(',')
{
   xretrace_remove_bookmark_for_buffer(_mdi.p_child.p_buf_name, _mdi.p_child.p_line); 
   xbar_forms[right_mouse_xbar_form_id].no_markup = true;
}


static void process_right_mouse_click(int wid, int edwin, int formid)
{
   int wid2 = p_window_id;

   right_mouse_xbar_form_id = formid;

   #if 1
   int index = find_index("xretrace_scrollbar_popup_menu",oi2type(OI_MENU));
   if (!index) {
      //say("not index");
      return;
   }
   //say("yes index");

   int menu_handle=p_active_form._menu_load(index,'P');

   // build the menu

   _menu_insert(menu_handle,-1,MF_ENABLED,
                "&Close ",
                "xretrace_scrollbar_form_close","","",'');

   _menu_insert(menu_handle,-1,MF_ENABLED,
                "&Bookmark line " :+ edwin.p_line,
                "xretrace_set_bookmark_for_buffer", "", "",'');

   _menu_insert(menu_handle,-1,MF_ENABLED,
                "&Clear bookmark at line " :+ edwin.p_line,
                "xretrace_clear_bookmark_for_buffer", "", "",'');

   _menu_insert(menu_handle,-1,MF_ENABLED,
                "&xretrace options",
                "xretrace_show_control_panel", "", "",'');

   // Show the menu.
   int x =100;
   int y=100;
   x=mou_last_x('M')-x;y=mou_last_y('M')-y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status=_menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);

   //say("mmmm");
   // set the focus back
   // 
   //if (_mdi.p_child._no_child_windows()==0) {
   //   _mdi.p_child._set_focus();
   //}
   p_window_id = wid2;
   #endif
}


void set_scrollbar_handle_location_from_curr_line(int wid, int editor_wid)
{
   _control scrollbar_image;
   _control scrollbar_handle_image;
   _control current_line_image;

   int nlines = editor_wid.p_Noflines;
   if ( nlines == 0 ) {
      nlines = 1;
   }
   int distance_100K = (editor_wid.p_line * 100000) / nlines;
   wid.current_line_image.p_y = wid.scrollbar_image.p_height * distance_100K / 100000;

   int lines_per_screen = editor_wid.p_client_height / editor_wid.p_font_height;
   int ratio100k = lines_per_screen * 100000 / nlines;
   int ht = ratio100k * wid.scrollbar_image.p_height / 100000;
   if ( ht < pix2scale(20, wid) ) {
      ht = pix2scale(20, wid);
   }
   wid.scrollbar_handle_image.p_height = ht;
   wid.scrollbar_handle_image.p_y = wid.current_line_image.p_y - (wid.scrollbar_handle_image.p_height / 2);
}


#define PIXELS_PER_LISTBOX_LINE 5

void set_control_sizes(int wid, int k)
{
   _control ctllist1;
   _control scrollbar_image;
   _control scrollbar_handle_image;
   _control current_line_image;

   wid.ctllist1.p_height = wid.p_height;
   wid.ctllist1.p_width = wid.p_width;
   wid.ctllist1.p_x = 0;

   wid.scrollbar_handle_image.p_width = pix2scale(4, wid);
   wid.scrollbar_handle_image.p_x = wid.ctllist1.p_x;

   wid.scrollbar_image.p_height = wid.p_height;
   wid.scrollbar_image.p_width = wid.p_width;
   wid.scrollbar_image.p_x = wid.ctllist1.p_x;
   wid.scrollbar_image.p_y = wid.ctllist1.p_y;

   wid.current_line_image.p_width = wid.p_width;
   wid.current_line_image.p_height = pix2scale(2,wid);
   wid.current_line_image.p_x = wid.ctllist1.p_x;

   // using text_height works only when the text height is greater than the bitmap height
   // xbar_forms[k].num_marker_rows = wid.ctllist1.p_client_height intdiv
   //                                  (_ly2dy( wid.p_xyscale_mode,wid.ctllist1._text_height()) + 2);

   // bitmap height is 2 pixels with 2 pix between bitmaps  -  2 + 2 = 4
   xbar_forms[k].num_marker_rows = wid.ctllist1.p_client_height intdiv PIXELS_PER_LISTBOX_LINE; 
}


static int GetEditorCtlWid(int wid)
{
   int editorctl_wid = wid._MDIGetActiveMDIChild();
   if ( editorctl_wid != null && _iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
      return editorctl_wid;
   }
   if (_no_child_windows()) 
      return -1;

   return _mdi.p_child;
}


void set_edwin_current_line_from_cursor_y(int wid, int edwin)
{
   _control scrollbar_image;
   int nlines = edwin.p_Noflines;
   if ( nlines == 0 ) {
      nlines = 1;
   }

   int xl = (wid.scrollbar_image.mou_last_y() * 100000 / 
               scale2pix(wid.scrollbar_image.p_height, wid)) * nlines / 100000;
   if ( xl <= 0 ) {
      xl = 1;
   }
   if ( xl > edwin.p_Noflines ) {
      xl = edwin.p_Noflines;
   }
   edwin.p_line = xl;
   edwin.center_line();
}



// scrollbar_image.wheel_up()
// {
//    int edwin = GetEditorCtlWid(p_active_form);
//    edwin.up(1);
// }
// 
// scrollbar_image.wheel_down()
// {
//    int edwin = GetEditorCtlWid(p_active_form);
//    edwin.down(1);
// }

//

static void set_scrollbar_handle_colour(int colour, int edwin)
{
   _control scrollbar_handle_image;
   _control current_line_image;

   if ( colour == INACTIVE_SCROLLBAR_HANDLE_COLOUR && edwin.p_modify ) 
      p_active_form.scrollbar_handle_image.p_backcolor = RED_MINUS1;  // red minus one
   else
      p_active_form.scrollbar_handle_image.p_backcolor = colour;

   p_active_form.current_line_image.p_backcolor = colour;
}

// return positive value if there is a marker within three positions of the mouse cursor
static int find_nearest_marker(int formid, int wid)
{
   _control scrollbar_image;

   if ( xbar_forms[formid].no_markup ) {
      //say('no markup');
      return -1;
   }
   int max_rows = xbar_forms[formid].num_marker_rows;
   if ( max_rows > xbar_forms[formid].listbox_row_associated_line_number._length() ) {
      max_rows = xbar_forms[formid].listbox_row_associated_line_number._length();
   }
   int fred = wid.scrollbar_image.mou_last_y();
   int listbox_row = (fred / PIXELS_PER_LISTBOX_LINE) + 2;
   if ( listbox_row >= max_rows ) {
      listbox_row = max_rows - 1;
   }
   else if ( fred < 0 ) {
      fred = 0;
   }
   // find the nearest marker
   int k1 = 0, k2 = 0;
   while ( k1 < 2 && listbox_row >= k1 ) {
      if ( xbar_forms[formid].listbox_row_associated_line_number[listbox_row - k1] > 0 ) {
         break;
      }
      ++k1;
   }
   while ( (k2 < 2) && (listbox_row + k2 < max_rows) ) {
      if ( xbar_forms[formid].listbox_row_associated_line_number[listbox_row + k2] > 0 ) {
         break;
      }
      ++k2
   }
   //mysay( 'F4 ' :+ fred :+ ' ' :+ max_rows :+ ' ' :+ listbox_row :+ ' ' :+ k1 :+ ' ' k2);
   if ( k1 < k2 ) {
      fred = listbox_row - k1;
   }
   else if (k2 < k1) {
      fred = listbox_row + k2;
   }
   else if ( k1 < 2 ) {
      fred = listbox_row - k1;
   }
   else
      fred = -1;

   if ( fred >= max_rows ) {
      fred = -1;
   }
   //mysay("fred " fred);
   return fred;
}



// _IsKeyDown(CTRL)


int run_xrs_event_loop(boolean lbutton = false)
{
   _control scrollbar_handle_image;
   _control current_line_image;
   _control scrollbar_image;

   //boolean first_time = true;

   //int x_on_entry = wid.mou_last_x();
   //int y_on_entry = wid.mou_last_y();

   //int y_last, y_now, num;
   //int x_last, x_now, proc_count;
   //boolean prev_y_greater_x;

   int edwin = GetEditorCtlWid(p_active_form);
   int xbar_wid = p_active_form;
   int formid = find_xbar_form_from_wid(xbar_wid);
   int listbox_row;
   int max_rows;

   int start_line  = edwin.p_line;
   int exit_line = edwin.p_line;
   int start_col = edwin.p_col;
   boolean lock_line = false;
   boolean spacebar_lock = false;
   boolean spacebar_direction = true;  // true is down
   boolean first_time = true;

   int my1 = xbar_wid.scrollbar_image.mou_last_y();
   int mx1 = xbar_wid.scrollbar_image.mou_last_x();

   if ( _get_focus() != edwin ) {
      return 0;
   }
   //mysay("start");
   close_me = 0;
   _set_timer(3000);
   mou_mode(2);
   mou_capture();
   boolean exit_event_loop = false;
   _str event;
   while (!exit_event_loop) {
      if ( lbutton ) {
         event = LBUTTON_DOWN; 
         lbutton = false;
      }
      else {
         event = get_event();
      }
      //mysay(event2name(event));
      int mxnow = xbar_wid.scrollbar_image.mou_last_x();
      int mynow = xbar_wid.scrollbar_image.mou_last_y();

      switch (event) {

      case ON_TIMER :
         exit_event_loop = true;
         edwin._set_focus();
         break;

      case WHEEL_UP:
         exit_event_loop = true;
         edwin.up(4);
         break;
        
      case WHEEL_DOWN:
         exit_event_loop = true;
         edwin.down(4);
         break;

      case MOUSE_MOVE:
         if ( (mxnow > (scale2pix(xbar_wid.scrollbar_image.p_width, xbar_wid))) || (mxnow < 0) )  {
            // the mouse cursor left the area before 3 seconds was up
            _kill_timer();
            mou_mode(0);
            mou_release();
            set_scrollbar_handle_colour(INACTIVE_SCROLLBAR_HANDLE_COLOUR, edwin);  
            edwin._set_focus();
            return 0;
         }
         int xd = abs(mxnow - mx1);
         int yd = abs(mynow - my1);
         if ( xd > 10 || yd > 10 ) {
            // if we move more in the y axis than the x, then assume scrolling is wanted
            // and drop out of this 3 second event loop and start the next
            if ( (yd > xd) && (mxnow > 15) ) {
               exit_event_loop = true;
               edwin._set_focus();
               break;
            }
            mx1 = mxnow;
            my1 = mynow;
         }
         break;
      case LBUTTON_DOWN:
         int lr = find_nearest_marker(formid, xbar_wid);
         //mysay("F1 " lr);
         if ( (lr > 0) && (xbar_forms[formid].listbox_row_associated_line_number[lr] > 0) ) {
            edwin.p_line = xbar_forms[formid].listbox_row_associated_line_number[lr];
            edwin.center_line();
            lock_line = true;
            exit_line = edwin.p_line;
            set_scrollbar_handle_colour(0x00277FFF, edwin);   // orange
            set_scrollbar_handle_location_from_curr_line(xbar_wid, edwin);
            edwin._set_focus();
            exit_event_loop = true;
            // exit this event loop and enter the next
            //message('click');
            break;
         }

         if ( first_time ) {
            first_time = false;
            // if the edit window has been scrolled with the mouse-wheel, setting p_line to
            // set the visible line number in the edit window doesn't work but the following
            // code makes it start working again.
            if (edwin.p_scroll_left_edge >= 0) 
                edwin.p_scroll_left_edge = -1;
            //edit(edwin.p_buf_name);       // - this is an alternative solution for the above problem
            //p_window_id = xbar_wid;
            edwin._set_focus();
         }
         set_edwin_current_line_from_cursor_y(xbar_wid, edwin); 
         if ( lock_line ) {
            lock_line = false;
            exit_line = start_line;
            set_scrollbar_handle_colour(0X000dd252, edwin);
         }
         else
         {
            lock_line = true;
            exit_line = edwin.p_line;
            set_scrollbar_handle_colour(0x000000C0, edwin);      // red
         }
         set_scrollbar_handle_location_from_curr_line(xbar_wid, edwin);
         break;

      case RBUTTON_DOWN:
      case RBUTTON_UP:
         mou_mode(0);
         mou_release();
         //mysay('this one');
         set_scrollbar_handle_colour(INACTIVE_SCROLLBAR_HANDLE_COLOUR, edwin);  
         edwin.p_line = exit_line;
         edwin.center_line();
         edwin._set_focus();  // so that _mdi.p_child is correct
         process_right_mouse_click(xbar_wid, edwin, formid);
         return 0;
      }
   }

   _kill_timer();
   // if the edit window has been scrolled with the mouse-wheel, setting p_line to
   // set the visible line number in the edit window doesn't work but the following
   // code makes it start working again.
   if (edwin.p_scroll_left_edge >= 0) 
       edwin.p_scroll_left_edge = -1;

   //edit(edwin.p_buf_name);  // - this is an alternative solution for the above problem
   //p_window_id = xbar_wid;
   edwin._set_focus();
   if ( !lock_line ) {
      set_scrollbar_handle_colour(0X000dd252, edwin);
      set_edwin_current_line_from_cursor_y(xbar_wid, edwin); 
   }
   //mysay("halfway");
   exit_event_loop = false;
   update_xbar_forms(true);

   while (!exit_event_loop) {
      _str event = get_event();
      //mysay(event2name(event));

      if ( xbar_forms[formid].close_me ) {
         mou_mode(0);
         mou_release();
         set_scrollbar_handle_colour(INACTIVE_SCROLLBAR_HANDLE_COLOUR, edwin);  
         edwin.p_line = exit_line;
         edwin.center_line();
         return 0;
      }
      int mx = xbar_wid.scrollbar_image.mou_last_x();
      int mynow = xbar_wid.scrollbar_image.mou_last_y();
      update_xbar_forms(true);
      switch (event) {
      default:
         mou_mode(0);
         mou_release();
         set_scrollbar_handle_colour(INACTIVE_SCROLLBAR_HANDLE_COLOUR, edwin);  
         edwin.p_line = exit_line;
         edwin.center_line();
         return 0;

      case WHEEL_UP:
         edwin.up(4);
         break;
        
      case WHEEL_DOWN:
         edwin.down(4);
         break;

      case 'ESC' :
         set_scrollbar_handle_colour(INACTIVE_SCROLLBAR_HANDLE_COLOUR, edwin);  
         edwin.p_line = start_line;
         edwin.center_line();
         mou_mode(0);
         mou_release();
         return 0;   

      case 'c':  // the keys just above the spacebar
      case 'C':
      case 'v':
      case 'V':
      case 'b':
      case 'B':
      case 'n':
      case 'N':
      case 'm':
      case 'M':
         if ( !spacebar_lock ) 
            break;
         spacebar_direction = !spacebar_direction;
         // fall through
      case ' ':
         if ( xbar_forms[formid].no_markup ) break;
         int max_rows = xbar_forms[formid].num_marker_rows;
         if ( max_rows > xbar_forms[formid].listbox_row_associated_line_number._length() ) {
            max_rows = xbar_forms[formid].listbox_row_associated_line_number._length();
         }

         if ( !spacebar_lock ) {
            listbox_row = xbar_wid.scrollbar_image.mou_last_y() / PIXELS_PER_LISTBOX_LINE;
            if ( listbox_row >= max_rows ) {
               listbox_row = max_rows - 1;
            }
         }
         else  {
            if ( spacebar_direction ) {
               if ( ++listbox_row >= max_rows ) {
                  listbox_row = 0;
               }
            } 
            else if ( --listbox_row < 0 ) {
               listbox_row = max_rows - 1;
            }
         }

         while ( 1 ) {
            if ( xbar_forms[formid].listbox_row_associated_line_number[listbox_row] > 0 ) {
               edwin.p_line = xbar_forms[formid].listbox_row_associated_line_number[listbox_row];
               edwin.center_line();
               exit_line = edwin.p_line;
               lock_line = true;
               spacebar_lock = true;
               set_scrollbar_handle_colour(0x000000C0, edwin);
               set_scrollbar_handle_location_from_curr_line(xbar_wid, edwin);
               break;
            }
            if ( spacebar_direction ) {
               if ( ++listbox_row >= max_rows ) {
                   listbox_row = 0;
               }
            } 
            else if ( --listbox_row < 0 ) {
               listbox_row = max_rows - 1;
            }
         }
         break;

      case MOUSE_MOVE:
         if ( !spacebar_lock ) {
            spacebar_direction = xbar_wid.scrollbar_image.mou_last_y() > my1;
            my1 = xbar_wid.scrollbar_image.mou_last_y();

            // don't exit if locked with spacebar
            if ( (mx > (scale2pix(xbar_wid.scrollbar_image.p_width, xbar_wid) + 15)) 
                 || (mx < -15) || (xbar_wid.scrollbar_image.mou_last_y() <= 0)
                 || (xbar_wid.scrollbar_image.mou_last_y('M') >= xbar_wid.scrollbar_image.p_height )  )  
            {
               mou_mode(0);
               mou_release();
               set_scrollbar_handle_colour(INACTIVE_SCROLLBAR_HANDLE_COLOUR, edwin);   
               edwin.p_line = exit_line;
               edwin.center_line();
               return 0;
            }
         }
         if ( !lock_line ) {
            set_edwin_current_line_from_cursor_y(xbar_wid, edwin); 
         }
         break;

      case LBUTTON_UP:
         break;

      case LBUTTON_DOWN:
         if ( mx < 16 ) {
            int lr = find_nearest_marker(formid, xbar_wid);
            //mysay("F2 " lr);
            if ( (lr > 0) && (xbar_forms[formid].listbox_row_associated_line_number[lr] > 0) ) {
               edwin.p_line = xbar_forms[formid].listbox_row_associated_line_number[lr];
               edwin.center_line();
               lock_line = true;
               exit_line = edwin.p_line;
               set_scrollbar_handle_colour(0x00277FFF, edwin);   // orange
               set_scrollbar_handle_location_from_curr_line(xbar_wid, edwin);
               edwin._set_focus();
               break;
            }
         }
         set_edwin_current_line_from_cursor_y(xbar_wid, edwin); 
         spacebar_lock = false;
         if ( lock_line ) {
            lock_line = false;
            exit_line = start_line;
            set_scrollbar_handle_colour(0X000dd252, edwin);
         }
         else
         {
            lock_line = true;
            exit_line = edwin.p_line;
            set_scrollbar_handle_colour(0x000000C0, edwin);
         }
         break;

      case RBUTTON_DOWN:
      case RBUTTON_UP:
         mou_mode(0);
         mou_release();
         //mysay('saw it');
         set_scrollbar_handle_colour(INACTIVE_SCROLLBAR_HANDLE_COLOUR, edwin);  
         edwin.p_line = exit_line;
         edwin.center_line();
         edwin._set_focus();  // so that _mdi.p_child is correct
         process_right_mouse_click(xbar_wid, edwin, formid);
         return 0;
      }
   }
   return 0;
}


scrollbar_image.wheel_up()
{
   if ( _no_child_windows() ) {
      return 0;
   }
   //mysay('in');
   run_xrs_event_loop();
}

scrollbar_image.wheel_down()
{
   if ( _no_child_windows() ) {
      return 0;
   }
   //mysay('in');
   run_xrs_event_loop();
}

//scrollbar_image.mouse_move()
//{
//   if ( _no_child_windows() ) {
//      return 0;
//   }
//   run_xrs_event_loop();
//}


scrollbar_image.rbutton_down()
{
   if ( _no_child_windows() ) {
      return 0;
   }
   int xbar_wid = p_active_form;
   int edwin = GetEditorCtlWid(p_active_form);
   int formid = find_xbar_form_from_wid(xbar_wid);
   process_right_mouse_click(xbar_wid, edwin, formid);
}


scrollbar_image.lbutton_down()
{
   if ( _no_child_windows() ) {
      return 0;
   }
   int xbar_wid = p_active_form;
   int edwin = GetEditorCtlWid(p_active_form);
   int formid = find_xbar_form_from_wid(xbar_wid);
   edwin._set_focus();
   run_xrs_event_loop(true);
}


int find_xbar_form_from_wid(int wid)
{
   int k;
   for ( k = 0; k < xbar_forms._length(); ++k  ) {
      if ( xbar_forms[k].wid == wid ) {
         return k;
      }
   }
   return -1;
}

// 

int register_xbar_form(int wid)
{
   int k = find_xbar_form_from_wid(wid);
   if ( k < 0 ) {
      for ( k = 0; k < xbar_forms._length(); ++k ) {
         if ( xbar_forms[k].wid == -1 ) {
            // found a free one
            break;
         }
      }
      xbar_forms[k].wid = wid;
   }
   return k;
}


//scrollbar_image.rbutton_down()
//{
//   say("hhh m");
//   int k = find_xbar_form_from_wid(p_window_id);
//   if ( k < 0 ) {
//      return 0;
//   }
//   int edwin = GetEditorCtlWid(p_window_id);
//   if ( edwin <= 0 ) {
//      return 0;
//   }
//   process_right_mouse_click(p_window_id, edwin, k );
//   return 0;
//}


void xretrace_scrollbar_form.on_create()
{
   scrollbar_image.p_picture = pic_scrollbar_image;
   int k = register_xbar_form(p_window_id);
   set_control_sizes(p_window_id, k); 

   if ( k >= 0 ) {
      if ( ! _no_child_windows() ) {
         int edwin = GetEditorCtlWid(p_window_id);
         xbar_forms[k].curr_line = edwin.p_line;
         xbar_forms[k].nof_lines = edwin.p_Noflines;
         xbar_forms[k].buf_id = edwin.p_buf_id;
         xbar_forms[k].modified = edwin.p_modify;
         xbar_forms[k].edit_buf_wid = edwin;
         set_scrollbar_handle_location_from_curr_line(p_window_id, edwin);
         xbar_forms[k].no_markup = true;
         xbar_forms[k].close_me = false;
         xbar_update_needed = true;
      }
      else
      {
         xbar_forms[k].edit_buf_wid = -1;
      }
   }
}


void xretrace_scrollbar_form.on_destroy()
{
   int k = find_xbar_form_from_wid(p_window_id);
   if ( k >= 0 ) {
      xbar_forms[k].wid = -1;
   }
}


void xretrace_scrollbar_form.on_resize()
{
   int k = find_xbar_form_from_wid(p_window_id);
   set_control_sizes(p_window_id, k);
   if ( _no_child_windows() || k < 0 ) {
      return;
   }
   int edit_wid = GetEditorCtlWid(p_window_id);
   xbar_forms[k].curr_line = edit_wid.p_line;
   xbar_forms[k].nof_lines = edit_wid.p_Noflines;
   xbar_forms[k].buf_id = edit_wid.p_buf_id;
   xbar_forms[k].modified = edit_wid.p_modify;
   xbar_forms[k].edit_buf_wid = edit_wid;
   xbar_forms[k].no_markup = true;  // regenerate
   set_scrollbar_handle_location_from_curr_line(p_window_id, edit_wid);
   xbar_update_needed = true;
}

//   
/*******************************************************************************
 * FUNCTION NAME : void add_markup_from_list(dlist &alist, int bitmap, int edwin, int formid, int bitmap2=0)
 * 
 * DESCRIPTION : 
 *     
 *
 * INPUTS : 
 *     @param alist 
 *     @param bitmap 
 *     @param edwin 
 *     @param formid 
 *     @param bitmap2 
 *
 *
 ******************************************************************************/
static void add_markup_from_list(dlist & alist, int bitmap, int edwin, int formid, int bitmap2 = 0)
{
   xretrace_item * ip;
   VSLINEMARKERINFO info1;
   int nlines = edwin.p_Noflines;
   if ( nlines == 0 ) {
      nlines = 1;
   }
   
   dlist_iterator iter = dlist_begin(alist);
   for( ; dlist_iter_valid(iter); dlist_next(iter)) {
      ip = dlist_getp(iter);
      if (ip->marker_id_valid && (_LineMarkerGet(ip->line_marker_id, info1) == 0)) {
         ip->last_line = info1.LineNum;
      }
      if ( ip->last_line > 0 ) {
         int index = (int)((double)(xbar_forms[formid].num_marker_rows * ip->last_line) / nlines + 0.5) + 1;
         if ( index >= xbar_forms[formid].num_marker_rows ) {
            index = xbar_forms[formid].num_marker_rows - 1;
         }
         if ( (bitmap2 > 0) && (ip->flags & MARKER_WAS_ALREADY_HERE_ON_OPENING) ) 
         {
            xbar_forms[formid].listbox_row_bitmap_id[index] = bitmap2;
         }
         else
         {
            if ( xbar_forms[formid].listbox_row_bitmap_id[index] == pic_changed_line && bitmap == pic_bookmark_line ) {
               xbar_forms[formid].listbox_row_bitmap_id[index] = pic_changed_and_bookmarked_line;
            }
            else
               xbar_forms[formid].listbox_row_bitmap_id[index] = bitmap;
         }

         xbar_forms[formid].listbox_row_associated_line_number[index] = ip->last_line;
         //("aa2 " :+ index :+ " " :+ ip->last_line);
      }
   }
}


// add_markup_to_xbar_for_edwin is called from xretrace timer callback when an xretrace 
// list changes and at startup.  It re-generates the markup for the specified edit window.
void add_markup_to_xbar_for_edwin(int edwin, dlist & visited_list, dlist & changed_list, dlist & bookmark_list)
{
   _control ctllist1;

   if ( _no_child_windows() ) {
      return;
   }

   // dlist_iterator iter = dlist_begin(visited_list);
   // if ( !dlist_iter_valid(iter) ) {
   //    return;
   // }
   // iter = dlist_begin(changed_list);
   // if ( !dlist_iter_valid(iter) ) {
   //    return;
   // }
   
   int wid = p_window_id;
   int formid;
   for ( formid = 0; formid < xbar_forms._length(); ++formid ) {
      if ( xbar_forms[formid].wid > 0 ) {
         int edit_wid = GetEditorCtlWid(xbar_forms[formid].wid);
         if ( edit_wid == edwin ) {
            int h;
            xbar_forms[formid].listbox_row_bitmap_id._makeempty();
            for ( h = 0; h < xbar_forms[formid].num_marker_rows; ++h ) {
               xbar_forms[formid].listbox_row_bitmap_id[h] = pic_blank_line;
               xbar_forms[formid].listbox_row_associated_line_number[h] = -1;
            }
            add_markup_from_list(visited_list, pic_visited_line, edwin, formid);
            add_markup_from_list(changed_list, pic_changed_line, edwin, formid, pic_old_changed_line);
            add_markup_from_list(bookmark_list, pic_bookmark_line, edwin, formid);

            xbar_forms[formid].wid.ctllist1._lbclear();

            for ( h = 0; h < (xbar_forms[formid].listbox_row_bitmap_id._length() - 2); ++h ) {
               xbar_forms[formid].wid.ctllist1._lbadd_item("", 0, xbar_forms[formid].listbox_row_bitmap_id[h+2]);
            }
            // xretrace will keep trying to add markup until no_markup goes false
            xbar_forms[formid].no_markup = false;
         }
      }
   }
   p_window_id = wid;
}


void check_update_xretrace_scrollbar()
{
   if ( _no_child_windows()  ) 
      return;

   // update_xbar_forms returns a non zero value if there is an xretrace scrollbar that doesn't have markup yet
   int edwin = update_xbar_forms();
}


// update_xbar_forms is called from xretrace timer callback - maintain_cursor_retrace_history - on 
// every callback - default rate is every 250 ms.
// it deletes an xbar form when needed and updates the position of the scrollbar handle
// return value is positive window ID if an xbar form needs markup added
int update_xbar_forms(boolean event_loop = false)
{
   _control scrollbar_handle_image;
   int no_markup_wid = -1;
   if ( _no_child_windows() ) {
      return -1;
   }
   //if ( !xbar_update_needed ) {
   //   return -1;
   //}

   int wid = p_window_id;
   int k;
   for ( k = 0; k < xbar_forms._length(); ++k ) {
      if ( xbar_forms[k].wid > 0 ) {
         if ( !event_loop && xbar_forms[k].close_me ) {
            xbar_forms[k].wid._delete_window();
            continue;
         }

         int edit_wid = GetEditorCtlWid(xbar_forms[k].wid);

         if ( xbar_forms[k].edit_buf_wid == edit_wid ) {
            if ( xbar_forms[k].curr_line == edit_wid.p_line  &&
                 xbar_forms[k].nof_lines == edit_wid.p_Noflines  &&
                 xbar_forms[k].buf_id == edit_wid.p_buf_id  &&
                 xbar_forms[k].modified == edit_wid.p_modify   )   {
               continue;
            }
         }
         xbar_forms[k].curr_line = edit_wid.p_line;
         xbar_forms[k].nof_lines = edit_wid.p_Noflines;
         xbar_forms[k].buf_id = edit_wid.p_buf_id;
         xbar_forms[k].edit_buf_wid = edit_wid;
         xbar_forms[k].modified = edit_wid.p_modify;
         if ( (xbar_forms[k].wid.scrollbar_handle_image.p_backcolor == INACTIVE_SCROLLBAR_HANDLE_COLOUR) && edit_wid.p_modify ) {
            xbar_forms[k].wid.scrollbar_handle_image.p_backcolor = RED_MINUS1;
         }
         else if ( (xbar_forms[k].wid.scrollbar_handle_image.p_backcolor == RED_MINUS1) && !edit_wid.p_modify) {
                 xbar_forms[k].wid.scrollbar_handle_image.p_backcolor = INACTIVE_SCROLLBAR_HANDLE_COLOUR;
         }
         set_scrollbar_handle_location_from_curr_line(xbar_forms[k].wid, edit_wid);
         if ( xbar_forms[k].no_markup ) {
            no_markup_wid = edit_wid;
         }
      }
   }
   xbar_update_needed = false;
   p_window_id = wid;
   return no_markup_wid;
}


//void _on_load_module_xbar1(_str module_name)
//{
//   _str sm = strip(module_name, "B", "\'\"");
//   if (strip_filename(sm, 'PD') == 'xbar1.e') {
//      //xretrace_kill_timer();
//   }
//}


_command void delete_xbar_windows() name_info(',')
{
   for ( k = 0; k < xbar_forms._length(); ++k ) {
      if ( xbar_forms[k].wid > 0 ) {
            xbar_forms[k].wid._delete_window();
      }
   }
}



definit()   
{
   tw_register_form('xretrace_scrollbar_form', TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_NONE);  
   //if (arg(1) != "L") {
      // not a load command
   xbar_forms._makeempty();
   //}

   pic_scrollbar_image = _find_or_add_picture(_config_path() :+ "xretrace/bitmaps/_xretrace-scrollbar-image1.png@native");

   pic_bookmark_line = _find_or_add_picture(_config_path() :+ "xretrace/bitmaps/_xretrace-scrollbar-markup-bookmark.bmp@native");
   pic_changed_line = _find_or_add_picture(_config_path() :+ "xretrace/bitmaps/_xretrace-scrollbar-markup-changed-line.bmp@native");
   pic_changed_and_bookmarked_line = _find_or_add_picture(_config_path() :+ "xretrace/bitmaps/_xretrace-scrollbar-markup-changed-bookmark.bmp@native");
   pic_old_changed_line = _find_or_add_picture(_config_path() :+ "xretrace/bitmaps/_xretrace-scrollbar-markup-old-changed-line.bmp@native");
   pic_visited_line = _find_or_add_picture(_config_path() :+ "xretrace/bitmaps/_xretrace-scrollbar-markup-visited-line.bmp@native");
   pic_blank_line = _find_or_add_picture(_config_path() :+ "xretrace/bitmaps/_xretrace-scrollbar-markup-white.bmp@native");
}




_form xretrace_scrollbar_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_NONE;
   p_caption="xretrace scrollbar";
   p_forecolor=0x80000008;
   p_height=6000;
   p_tool_window=true;
   p_width=3825;
   p_x=14925;
   p_y=1890;
   p_eventtab=xretrace_scrollbar_form;
   _list_box ctllist1 {
      p_border_style=BDS_FIXED_SINGLE;
      p_font_size=1;
      p_height=5460;
      p_multi_select=MS_NONE;
      p_scroll_bars=SB_NONE;
      p_tab_index=1;
      p_tab_stop=true;
      p_width=900;
      p_x=0;
      p_y=0;
      p_eventtab2=_ul2_listbox;
   }
   _image scrollbar_image {
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=5040;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=2;
      p_tab_stop=false;
      p_value=0;
      p_width=780;
      p_x=600;
      p_y=360;
      p_eventtab2=_ul2_imageb;
   }

   _image current_line_image {
      p_auto_size=false;
      p_backcolor=0x00A8A8A8;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=120;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=4;
      p_tab_stop=false;
      p_value=0;
      p_width=780;
      p_x=300;
      p_y=5100;
      p_eventtab2=_ul2_imageb;
   }

   _image scrollbar_handle_image {
      p_auto_size=false;
      p_backcolor=0x00A8A8A8;
      p_border_style=BDS_NONE;
      p_forecolor=0x00D70625;
      p_height=960;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=3;
      p_tab_stop=false;
      p_value=0;
      p_width=840;
      p_x=180;
      p_y=4080;
      p_eventtab2=_ul2_imageb;
   }
}


_menu xretrace_scrollbar_popup_menu {
}
//
//



int def_scroll_up_with_cursor;
static int scroll_up_with_cursor_key_bindings;
bool block_scroll_flag;

void my_scroll_callback()
{
   block_scroll_flag = false;
}


void xscroll(bool is_up)
{
   bool xrs = false;
   bool try_call_key = false;
   _str ev;
   if ( block_scroll_flag ) {
      return;
   }

   if ( find_index('delete_xbar_windows', COMMAND_TYPE) != 0 ) {
      xrs = true;
   }

   if ( def_scroll_up_with_cursor && !_IsKeyDown(SHIFT) || _IsKeyDown(CTRL) ) {
      if ( p_window_id != null && _iswindow_valid(p_window_id) && p_window_id._isEditorCtl()) {

         if ( substr(p_window_id.p_buf_name, 1, 1) == "." ) {
            fast_scroll();
            return;
         }
         if ( p_window_id != _get_focus() ) {
            p_window_id._set_focus();
         }

         if (p_window_id.p_scroll_left_edge >= 0) 
             p_window_id.p_scroll_left_edge = -1;

         int p2;
         save_pos(p2);
         if ( _IsKeyDown(CTRL) ) 
         {
            if ( is_up ) 
               cursor_up(8);
            else
               cursor_down(8);
         }
         else
         {
            if ( is_up ) 
               cursor_up();
            else
               cursor_down();
         }

         mou_mode(2);
         mou_capture();

         while ( 1 ) {
            ev = get_event('k');
            //say(event2name(ev));
            if ( xrs ) 
               check_update_xretrace_scrollbar();
            switch( ev ) {
            default:
               try_call_key = true;
               break;
            case RBUTTON_DOWN :
               toggle_xscroll();
               break;
            case ESC :
               restore_pos(p2);
               break;
            case ON_KEYSTATECHANGE :
            case MOUSE_MOVE :
               continue;
            case WHEEL_UP :
               if ( _IsKeyDown(CTRL) ) 
                  cursor_up(8);
               else 
                  cursor_up();
               continue;

            case WHEEL_DOWN :
               if ( _IsKeyDown(CTRL) ) 
                  cursor_down(8);
               else 
                  cursor_down();
               continue;

            }
            mou_mode(0);
            mou_release();
            break;
         }
         //center_line();
         block_scroll_flag = true;
         _set_timer(500, my_scroll_callback);
         if ( try_call_key ) {
            call_key(ev);
         }
         return;
      }
   }
   fast_scroll();
}


_command void xscroll_up() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   xscroll(true);
}


_command void xscroll_down() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   xscroll(false);
}

// https://devdocs.io/cpp/

// http://www.google.com/search?q=memcmp&as_sitesearch=cplusplus.com&btnI



_command void toggle_xscroll(bool force_xscroll_off = false) name_info(',')
{
   if ( force_xscroll_off ) {
      execute('bind-to-key -r fast_scroll 'event2index(name2event('WHEEL-UP')),"");
      execute('bind-to-key -r fast_scroll 'event2index(name2event('WHEEL-DOWN')),"");
      return;
   }
   if ( def_scroll_up_with_cursor == 0 ) {
      if (_message_box('Enable scroll with cursor', "", MB_YESNO) != IDYES)  {
         message("Cursor scrolling is disabled");
         return;
      }
      def_scroll_up_with_cursor = 1;
      scroll_up_with_cursor_key_bindings = 1;
   }
   scroll_up_with_cursor_key_bindings = (int)!scroll_up_with_cursor_key_bindings;

   if ( scroll_up_with_cursor_key_bindings ) {
      execute('bind-to-key -r fast_scroll 'event2index(name2event('WHEEL-UP')),"");
      execute('bind-to-key -r fast_scroll 'event2index(name2event('WHEEL-DOWN')),"");
      message("Bind to fast-scroll");
   }
   else {
      execute('bind-to-key -r xscroll_up 'event2index(name2event('WHEEL-UP')),"");
      execute('bind-to-key -r xscroll_down 'event2index(name2event('WHEEL-DOWN')),"");
      message("Bind to xscroll");
   }
}


