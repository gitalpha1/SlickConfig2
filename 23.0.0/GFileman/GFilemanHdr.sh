

/*****************************************************************************
*  COPYRIGHT : This code is written by, and copyright to Graeme F Prentice.
*              You may not distribute this code in whole or in part or use it
*              in a commercial product without permission from the author in
*              writing.   
*****************************************************************************/



/******************************************************************************
*  $Revision: 1.3 $
******************************************************************************/


#define GFM_BITMAP_PATH _config_path() :+ "GFileman\\bitmaps\\"

struct GFileman_persistent_state_data
{
    int form_width;
    int form_height;
};

struct GFileman_persistent_config_data
{
   int listview_list_left_margin;
   int listview_list_right_margin;
   int listview_min_width;
   int listview_left_col_width;
   //
   int ctltext1_slider_default_enable;
   _str listview_font;
   _str listview_font_size;
   int TooltipPercent;
   int selection_indication_solid;

   int button_row1_visible;
   int button_row1_y_offset;

   int filename_editbox_visible;
   int filename_editbox_y_offset;

   _str active_file_editbox_font;
   _str active_file_editbox_font_size;
   int filename_editbox_is_target;
   _str filename_display_order;
   int show_shortcuts_in_col1;
   int shortcut_key_col1_width;
   int show_shortcuts_on_demand;
};

struct GFileman_persistent_setup_data
{
    GFileman_persistent_config_data gfconfig;
    GFileman_persistent_state_data state;
};

struct popup_window_pos_data {
    int calc_x;
    int calc_y;
    int mouse_x;
    int mouse_y;
    int ref_y;
    boolean ref_y_is_top;
    int ref_x;
    boolean ref_x_is_left;
    int dist_top;
    int dist_right;
    int dist_bottom;
    int dist_left;
};






