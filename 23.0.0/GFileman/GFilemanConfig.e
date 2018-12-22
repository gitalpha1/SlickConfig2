


#include "slick.sh"
#include "GFilemanHdr.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)

defeventtab GFilemanSetupForm;

// don't need this right now
#define GFILEMAN_CONFIG_VERSION 'V1_10'

_control top_separator_image;
_control fileview_font_editbox;
_control ctlcombo_select_dialog;
_control fileview_fontsize_editbox;
_control TooltipPercentEditbox;
_control left_col_width_ctltext;
_control selection_indicator_checkbox;
_control min_col_width_ctltext;

_control button_row1_visible_ctlcheck;
_control button_row1_y_offset_ctltext;
_control filename_editbox_visible_ctlcheck;
_control filename_editbox_y_offset_ctltext;
_control ctlcheck_filename_editbox_is_target;

_control active_file_font_name_editbox;
_control active_file_font_size_editbox;
_control ctlcombo_filename_display_order;
_control ctlcheck_show_shortcuts_in_col1;
_control shortcut_key_col1_width_editbox;
_control ctlcheck_show_shortcuts_on_demand;

_control ShowFormButton;
_control UpdateFormsButton;



// the following items are substitutes for a widget property because these items
// don't have a widget i.e. they are not user changeable yet
int listview_list_left_margin_property;
int listview_list_right_margin_property;
int ctltext1_slider_default_enable_property;


GFileman_persistent_setup_data GFileman_global_persistent_data[];

_str GFileman_form_names[];

// GFileman_current_form_config_index is index into GFileman_global_persistent_data
// for the form whose config info is currently displayed in the config dialog
int GFileman_current_form_config_index;

static int setup_current_form_config_index(_str form_name)
{
    int k;
    for ( k = 0; k < GFileman_form_names._length(); ++k ) {
        if (GFileman_form_names[k] == form_name) {
            GFileman_current_form_config_index = k;
            return k;
        }
    }
    GFileman_form_names[k] = form_name;
    GFileman_current_form_config_index = k;
    GFileman_load_form_config(&(GFileman_global_persistent_data[k].gfconfig), form_name);
    return k;
}



#define CFG_FUNC_SET_DEFAULT 1
#define CFG_FUNC_SET_ITV_TO_PPV 2
#define CFG_FUNC_INSERT_ITEM 3
#define CFG_FUNC_SET_ITV_TO_VAL 4
#define CFG_FUNC_SET_PPV_TO_ITV 5

// in MAKE_CONFIG_FUNC macro, item_name becomes the name of a function used to
// perform operations for this item and is also the name of the item in the
// ini file and the member name of GFileman_persistent_config_data.  
// For the CFG_FUNC_SET_ITV_TO_VAL operation, only the item whose
// name matches is affected.  ptype is used to typecast a value before it is
// assigned to the item.
#define MAKE_CONFIG_FUNC(item_name, property_name, default_val, ptype)    \
static void item_name(int wid, int what, GFileman_persistent_config_data * config_ptr, typeless val, _str field_name)\
{\
   switch (what) {\
      case CFG_FUNC_SET_DEFAULT : config_ptr->##item_name = (ptype)default_val; return;\
      case CFG_FUNC_SET_ITV_TO_PPV : config_ptr->##item_name = (ptype)property_name; return;\
      case CFG_FUNC_INSERT_ITEM : insert_line( #item_name '=' :+ config_ptr->##item_name); return;\
      case CFG_FUNC_SET_ITV_TO_VAL : \
         if (strcmp(field_name,#item_name) == 0) config_ptr->##item_name = (ptype)val;\
         return;\
      case CFG_FUNC_SET_PPV_TO_ITV : property_name = config_ptr->##item_name; return;\
      default : return;\
   }\
}


   // generate all the config functions
   MAKE_CONFIG_FUNC(TooltipPercent,             wid.TooltipPercentEditbox.p_text, '50', int)
   MAKE_CONFIG_FUNC(listview_font,              wid.fileview_font_editbox.p_text, 'Microsoft Sans Serif', _str)
   MAKE_CONFIG_FUNC(listview_font_size,         wid.fileview_fontsize_editbox.p_text, 8, _str)
   MAKE_CONFIG_FUNC(active_file_editbox_font,   wid.active_file_font_name_editbox.p_text, 'Microsoft Sans Serif', _str)
   MAKE_CONFIG_FUNC(active_file_editbox_font_size, wid.active_file_font_size_editbox.p_text, 8, _str)
   MAKE_CONFIG_FUNC(listview_left_col_width,    wid.left_col_width_ctltext.p_text, 48, int)  // pixels
   MAKE_CONFIG_FUNC(listview_min_width,         wid.min_col_width_ctltext.p_text, 130, int)  // pixels
   MAKE_CONFIG_FUNC(selection_indication_solid, wid.selection_indicator_checkbox.p_value, 1, int)
   MAKE_CONFIG_FUNC(button_row1_visible,        wid.button_row1_visible_ctlcheck.p_value, 1, int)
   MAKE_CONFIG_FUNC(button_row1_y_offset,       wid.button_row1_y_offset_ctltext.p_text, 25, int)
   MAKE_CONFIG_FUNC(filename_editbox_visible,   wid.filename_editbox_visible_ctlcheck.p_value, 1, int)
   MAKE_CONFIG_FUNC(filename_editbox_y_offset,  wid.filename_editbox_y_offset_ctltext.p_text, 2, int)
   MAKE_CONFIG_FUNC(filename_editbox_is_target, wid.ctlcheck_filename_editbox_is_target.p_value, 1, int)
   MAKE_CONFIG_FUNC(listview_list_left_margin, listview_list_left_margin_property, 1, int)
   MAKE_CONFIG_FUNC(listview_list_right_margin, listview_list_right_margin_property, 1, int)
   MAKE_CONFIG_FUNC(ctltext1_slider_default_enable, ctltext1_slider_default_enable_property, 1, int)
   MAKE_CONFIG_FUNC(filename_display_order,         wid.ctlcombo_filename_display_order.p_cb_text_box.p_text, 
                                                                  'Directory Extension Filename', _str)

   MAKE_CONFIG_FUNC(show_shortcuts_in_col1, wid.ctlcheck_show_shortcuts_in_col1.p_value, 0, int)
   MAKE_CONFIG_FUNC(shortcut_key_col1_width, wid.shortcut_key_col1_width_editbox.p_text, 48, int)
   MAKE_CONFIG_FUNC(show_shortcuts_on_demand, wid.ctlcheck_show_shortcuts_on_demand.p_value, 1, int)



   // items added to this list should also be added to call_config_funcs below


#define CALL(item_name,val) item_name(wid, what, config_ptr, val, field_name)

static call_config_funcs(int wid, int what, GFileman_persistent_config_data * config_ptr, typeless val = 0, _str field_name = '')
{
    CALL(TooltipPercent, val);
    CALL(listview_font, val);
    CALL(listview_font_size, val);
    CALL(active_file_editbox_font, val);
    CALL(active_file_editbox_font_size, val);
    CALL(listview_left_col_width, val);
    CALL(listview_min_width, val);
    CALL(selection_indication_solid, val);
    CALL(button_row1_visible, val != 0);
    CALL(button_row1_y_offset, val);
    CALL(filename_editbox_visible, val != 0);
    CALL(filename_editbox_y_offset, val);
    CALL(filename_editbox_is_target, val != 0);
    CALL(listview_list_left_margin, val);
    CALL(listview_list_right_margin, val);
    CALL(ctltext1_slider_default_enable, val);
    CALL(filename_display_order, val);
    CALL(show_shortcuts_in_col1, val != 0);
    CALL(shortcut_key_col1_width, val);
    CALL(show_shortcuts_on_demand, val != 0);
}

#undef CALL


static void GFileman_save_config( GFileman_persistent_setup_data * dptr, _str form_name, int wid )
{
   // copy widget property values into item values
   call_config_funcs(wid, CFG_FUNC_SET_ITV_TO_PPV, &dptr->gfconfig);

   int section_view, current_view;
   current_view = _create_temp_view(section_view);
   if (current_view == '') {
       return;
   }
   activate_view(section_view);
   top();

   insert_line('GFileman_config_version=' :+ GFILEMAN_CONFIG_VERSION);
   // write all item values to the active view
   call_config_funcs(wid, CFG_FUNC_INSERT_ITEM, &dptr->gfconfig, 0);
   insert_line('');
   int res = _ini_replace_section(_config_path() :+ 'GFilemanConfig.ini', form_name :+ '_General',section_view);
}



void GFileman_load_form_config( GFileman_persistent_setup_data * dptr, _str form_name)
{
    // set default values for all items
    call_config_funcs(-1, CFG_FUNC_SET_DEFAULT, &dptr->gfconfig);

    int section_view, current_view;
    get_view_id(current_view);
    int res;
    res = _ini_get_section(_config_path() :+ 'GFilemanConfig.ini',form_name :+ '_General',section_view);
    if (res) {
        return;
    }
    activate_view(section_view);
    top();
    _insert_text(' '\r\n);  // _ini_parse_line does a down() first
    top();
    activate_view(current_view);
    _str field_name,value;
    int k = 0, maxl = 0;
    while ( k==0 ) {
        if (++maxl > 4000) {
            break;
        }
        k = _ini_parse_line(section_view,field_name,value);
        if (k==0) {
           // Set item value whose name matches the field name, to the parsed value
           // This was previously a switch statement with case options being the
           // item names - which might be faster if it uses binary search style match.
           call_config_funcs(-1, CFG_FUNC_SET_ITV_TO_VAL, &dptr->gfconfig, value, field_name);
        }
    }
}


void Fileview_font_change_button.lbutton_up()
{
   _str font = _font_param( p_active_form.fileview_font_editbox.p_text,
                      p_active_form.fileview_fontsize_editbox.p_text, 0);
   int result = show('-modal _font_form',
               '',      // Display fixed fonts only
                font
              );
   if (result == '') {
    return;
   }
   _str font_name, font_size, font_flags;
   parse result with font_name','font_size','font_flags',';
   p_active_form.fileview_font_editbox.p_text = font_name;
   p_active_form.fileview_fontsize_editbox.p_text = font_size;
}


void active_file_editbox_font_change_button.lbutton_up()
{
    _str font = _font_param( p_active_form.active_file_font_name_editbox.p_text,
                        p_active_form.active_file_font_size_editbox.p_text, 0);
   int result = show('-modal _font_form',
                 '',      // Display fixed fonts only
                  font
                );
   if (result == '') {
      return;
   }
   _str font_name, font_size, font_flags;
   parse result with font_name','font_size','font_flags',';
   p_active_form.active_file_font_name_editbox.p_text = font_name;
   p_active_form.active_file_font_size_editbox.p_text = font_size;
}



static void set_ctlcombo_select_dialog(int wid)
{
   wid.p_cb_list_box._lbclear();
   GFileman_form_names._sort();
   int k;
   for ( k = 0; k < GFileman_form_names._length(); ++k) {
       wid.p_cb_list_box._lbadd_item(GFileman_form_names[k]);
   }
   wid.p_cb_text_box.p_text = GFileman_form_names[GFileman_current_form_config_index];
}


void ctlcombo_select_dialog.on_change(reason)
{
   int wid = p_window_id;
   GFileman_save_config(
      &GFileman_global_persistent_data[GFileman_current_form_config_index],
      GFileman_form_names[GFileman_current_form_config_index], p_active_form);

   setup_current_form_config_index(wid.ctlcombo_select_dialog.p_text);
   call_config_funcs(wid, CFG_FUNC_SET_PPV_TO_ITV, 
                     &GFileman_global_persistent_data[GFileman_current_form_config_index].gfconfig);
   //set_ctlcombo_select_dialog(wid);
}


void ctlcombo_select_dialog.on_create()
{
   int wid = p_window_id;
   if (GFileman_form_names._length()==0) {
      setup_current_form_config_index('GFilemanForm1');
   }
   set_ctlcombo_select_dialog(wid);
}


void ctlcombo_filename_display_order.on_create()
{
   p_cb_list_box._lbclear();
   // these strings must match those in set_filename_sort_order_from_config()
   p_cb_list_box._lbadd_item('Recently accessed');
   p_cb_list_box._lbadd_item('Directory then Filename');
   p_cb_list_box._lbadd_item('Filename');
   p_cb_list_box._lbadd_item('Extension then Filename');
   p_cb_list_box._lbadd_item('Directory Extension Filename');
}




void GFilemanSetupForm.on_create(_str arg1)
{
   int wid = p_active_form;
   // todo - use macro for separator
   int pic1 = gp_find_or_add_picture(GFM_BITMAP_PATH :+ '_GFM_separator1.bmp');
   
   top_separator_image.p_picture = pic1;
   top_separator_image.p_stretch = true;
   top_separator_image.p_auto_size = true;
   top_separator_image.p_x = 0;
   //top_separator_image.p_y = pix2scale(50,p_active_form);
   
   top_separator_image.p_height = pix2scale(2,p_active_form);         
   top_separator_image.p_width = pix2scale(p_active_form.p_client_width,p_active_form);
   
   int k;
   for ( k = 0; k < GFileman_form_names._length(); ++k) {
      GFileman_load_form_config(&GFileman_global_persistent_data[k], GFileman_form_names[k]);
   }
   setup_current_form_config_index(arg1);
   call_config_funcs(wid, CFG_FUNC_SET_PPV_TO_ITV, 
      &GFileman_global_persistent_data[GFileman_current_form_config_index].gfconfig);
}


_str GFileman_find_form_with_shortcuts_on_demand_enabled()
{
   int k;
   for ( k = 0; k < GFileman_form_names._length(); ++k) {
      if (GFileman_global_persistent_data[k].gfconfig.show_shortcuts_on_demand) 
         return GFileman_form_names[k];
   }
   return '';
}


void save_button.lbutton_up()
{
    GFileman_save_config(
       &GFileman_global_persistent_data[GFileman_current_form_config_index],
       GFileman_form_names[GFileman_current_form_config_index], p_active_form);
}


void ok_button.lbutton_up()
{
   GFileman_save_config(
      &GFileman_global_persistent_data[GFileman_current_form_config_index],
      GFileman_form_names[GFileman_current_form_config_index], p_active_form);

   int form_id = _find_object('GFilemanSetupForm');
   if (form_id != 0) 
      form_id._delete_window('');
   GFileman_update_all_forms();
}


void ShowFormButton.lbutton_up()
{
   GFileman_show_form(GFileman_form_names[GFileman_current_form_config_index]);
}


void UpdateFormsButton.lbutton_up()
{
   GFileman_save_config(
      &GFileman_global_persistent_data[GFileman_current_form_config_index],
      GFileman_form_names[GFileman_current_form_config_index], p_active_form);
   GFileman_update_all_forms();
}


definit()
{
   GFileman_form_names._makeempty();
   GFileman_form_names[0] = 'GFilemanForm1';
   GFileman_form_names[1] = 'GFilemanForm2';
   GFileman_form_names[2] = 'GFilemanForm3';
   GFileman_form_names[3] = 'GFilemanForm4';
}


