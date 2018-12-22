

#include "slick.sh"

#pragma option(strictsemicolons,on)
//#pragma option(strict,on)
//#pragma option(autodecl,off)
#pragma option(strictparens,on)
#region Imports
#endregion


_str my_current_layout_import_settings_part1(int view_id)
{
   error := '';
   typeless count = 0;
   typeless line = "";
   _str type = "";
   top();
   for (;;) {
      // get the line - it will tell us what this section is for
      get_line(line);
      parse line with type line;

      name := '_sr_' :+ strip(lowcase(type), '', ':');
      index := find_index(name, PROC_TYPE);
      if (index_callable(index)) {
         status := call_index('R', line, index);
         if (status) {
            error = 'Error applying layout type 'type'.  Error code = 'status'.';
            break;
         }
      } else {
         error = 'No callback to apply layout type 'type'.' :+ OPTIONS_ERROR_DELIMITER;
         // we can't process these lines, so skip them
         parse line with count .;
         if (isnumber(count) && count > 1) {
            down(count-1);
         }
      }
      activate_window(view_id);
      if ( down()) {
         break;
      }
   }

   /********************************************************************************* 
    
   The following is done by the call to the real _current_layout_import_settings 
    
   if ( _tbFullScreenQMode() ) {
      if ( _tbDebugQMode() ) {
         if ( _tbDebugQSlickCMode() ) {
            _autorestore_from_view(_fullscreen_slickc_debug_layout_view_id, true);
         } else {
            _autorestore_from_view(_fullscreen_debug_layout_view_id, true);
         }
      } else {
         _autorestore_from_view(_fullscreen_layout_view_id, true);
      }
   } else {
      if ( _tbDebugQMode() ) {
         if ( _tbDebugQSlickCMode() ) {
            _autorestore_from_view(_slickc_debug_layout_view_id, true);
         } else {
            _autorestore_from_view(_debug_layout_view_id, true);
         }
      } else {
         _autorestore_from_view(_standard_layout_view_id, true);
      }
   } 
   p_window_id = view_id;
   ***********************************************************************************/

   return error;
}


int _sr_nothing()
{
   return 0;
}



// handle deletion of a layout from either the save or load dialog
static _str _load_named_twlayout_callback(int reason, var result, _str key)
{
   _nocheck _control _sellist;
   _nocheck _control _sellistok;
   if (key == 4) {
      item := _sellist._lbget_text();
      filename := _ConfigPath():+'xtoolwindow-layouts.ini';
      status := _ini_delete_section(filename,item);
      if ( !status ) {
         _sellist._lbdelete_item();
      }
   }
   return "";
}


_command void xload_named_toolwindow_layout(_str sectionName="") name_info(',')
{
   filename := _ConfigPath():+'xtoolwindow-layouts.ini';
   if ( sectionName=="" ) {
      _ini_get_sections_list(filename,auto sectionList);
      result := show('-modal _sellist_form',
                     "Load Named Layout",
                     SL_SELECTCLINE,
                     sectionList,
                     "Load,&Delete",     // Buttons
                     "Load Named Layout", // Help Item
                     "",                 // Font
                     _load_named_twlayout_callback
                     );
      if ( result=="" ) {
         return;
      }
      sectionName = result;
   }
   status := _ini_get_section(filename, sectionName, auto tempWID);
   if (status)
   {
      _message_box('Error reading file : ' :+ filename);
      return;
   }

   origWID := p_window_id;
   p_window_id = tempWID;

   _str err = my_current_layout_import_settings_part1(tempWID);
   if ( err != '' ) {
      _message_box(err);
   }

   filename = _ConfigPath() :+ 'xtemp' :+ FILESEP :+ 'nothing.slk';

   // pass a dummy file containing one line only so that the calls to _autorestore_from_view get done
   _current_layout_import_settings(filename);

   if ( _iswindow_valid(tempWID) ) {
      _delete_temp_view(tempWID);
   }

   if ( _iswindow_valid(origWID) ) {
      p_window_id = origWID;
   }
}


_command void xsave_named_toolwindow_layout(_str sectionName="") name_info(',')
{
   filename := _ConfigPath():+'xtoolwindow-layouts.ini';
   if ( sectionName=="" ) {
      _ini_get_sections_list(filename,auto sectionList);
      result := "";
      if ( sectionList==null ) {
         // if there are no section names stored already, prompt for a name.
         result = textBoxDialog("Save Named Layout",
                                0,
                                0,
                                "Save Named Layout",
                                "",
                                "",
                                "Save Named Layout");
         if ( result==COMMAND_CANCELLED_RC ) {
            return;
         }
         result = _param1;
      } else {
         // if there are names, show the list with a combobox so they can pick or type a new name.
         result = show('-modal _sellist_form',
                       "Save Named Layout",
                       SL_SELECTCLINE|SL_COMBO,
                       sectionList,
                       "Save,&Delete",     // Buttons
                       "Save Named Layout", // Help Item
                       "",                 // Font
                       _load_named_twlayout_callback
                       );
      }
      if ( result=="" ) return;
      sectionName = result;
   }
   int orig_view_id = _create_temp_view(auto temp_view_id);
   _sr_app_layout();
   _sr_standard_layout();
   _sr_fullscreen_layout();
   _sr_debug_layout();
   _sr_fullscreen_debug_layout();
   _sr_slickc_debug_layout();
   _sr_fullscreen_slickc_debug_layout();

   p_window_id = orig_view_id;
   int status = _ini_put_section(filename, sectionName, temp_view_id);
   if (status) {
      _message_box('Error writing file : ' :+ filename);
   }
}



