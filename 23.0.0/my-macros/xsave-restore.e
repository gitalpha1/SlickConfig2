
#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)

  

#if 0

#define SESSION_FOLDER_NAME 'SlickEditSessions'

static int workspace_save_session(_str filename, boolean proj_only)
{
   if (filename == '') 
      return 1;


   // toolbarSaveExpansion();   // another day
   int state_view_id = 0;
   int orig_view_id = _create_temp_view(state_view_id);
   p_window_id = orig_view_id;
   save_window_config(proj_only, state_view_id, false, strip_filename(filename, 'N'));
   p_window_id = orig_view_id;
   int status = _ini_put_section(filename, "State", state_view_id);
   if (status) {
      clear_message();
   }
   return status;
}


static void set_paths(_str &filename, _str &path)
{
   if (filename == '' && _workspace_filename == '') {
      path = _config_path() :+ SESSION_FOLDER_NAME :+ FILESEP;
      filename = path :+ 'default.ses';
   }
   else if (filename == '') {
      path = strip_filename(_workspace_filename,'N') :+ SESSION_FOLDER_NAME :+ FILESEP;
      filename = path :+ 'default.ses';
   }
   else {
      path = strip_filename(filename,'N');
   }
}

_command void xsave_session(_str filename = '', boolean proj_only = true) name_info(',')
{
   _str path;
   set_paths(filename, path);
   if (path == '') {
      _message_box('Path not specified');
      return;
   }
   if (!path_exists(path)) {
      if (make_path(path)) {
         _message_box("Unable to create path :  \n" :+ path);
         return;
      }
   }
   _str fn = _OpenDialog('', 'Save session to :','','', OFN_SAVEAS,'', strip_filename(filename,'P'), 
                               path, 'RetrieveXSaveSession');
   if (fn == '') 
      return;
   if (workspace_save_session(fn, proj_only))
      return;
   _message_box("Session has been saved to:\n" :+ fn, "Session saved");
}


_command void xsave_session_plus_toolbars(_str filename = '') name_info(',')
{
   xsave_session(filename, false);
}


_command void xrestore_session(_str filename = '') name_info(',')
{
   _str path;
   set_paths(filename, path);

   _str fn = _OpenDialog('', 'Restore session from :','','','','', strip_filename(filename,'P'), 
                               path, 'RetrieveXSaveSession');
   if (fn == '') 
      return;

   int view_id;
   get_window_id(view_id);
   int ini_view_id;
   int status = _ini_get_section(fn, "State", ini_view_id);
   activate_window(view_id);
   if (!status) {
      if (close_all())
         return;
      int old_restore_flags=def_restore_flags;
      //if (ProjectWorkingDirectory!='') {
      //}
      def_restore_flags &= ~RF_CWD;
      //was_recording=_macro();
      restore('',ini_view_id, path, true, true);
      //_macro('m',was_recording);
      def_restore_flags = old_restore_flags;
      _delete_temp_view(ini_view_id);
   }
   else {
      _message_box("Unable to read session data in :\n" :+ fn);
   }
}

#endif

