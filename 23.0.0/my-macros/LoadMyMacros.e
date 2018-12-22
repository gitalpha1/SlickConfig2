
#include "slick.sh"
#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)



_command boolean load_my_module(_str module = "")
{
   _str sm = strip(module, "B", '"');
   say(sm);
   if (!file_exists(sm)) {
      _message_box('File not found ' \n :+ sm);
      return false;
   }
   int res = _message_box('Load module ?' \n :+ sm,'', MB_YESNO);
   if (res == IDNO) {
      return false;
   }
   return load(module) == 0;
}


static void load_my_module2(_str module)
{
   static boolean more;
   if (module == '') {
      more = true;
      return;
   }
   if (!more) {
      return;
   }
   more = load_my_module(module);
   return;
}

// nothing 3

_command void load_my_modules()
{
   if (find_index('kill_gfileman_timer', COMMAND_TYPE)) {
      kill_gfileman_timer();
   }
   _str path = _ChooseDirDialog("",_ConfigPath(),"",CDN_PATH_MUST_EXIST|CDN_ALLOW_CREATE_DIR);
   if (path == '') {
      return;
   }
   _maybe_append_filesep(path);
   load_my_module2('');
   load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'gputil1.e');
   load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'DLinkList.e');
   load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'GFilemanConfig.e');
   load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'GFilemanInfoWindow.e');
   load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'GFilemanGoback.e');
   load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'GFilemanForms.e');
   load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'GFilemanForms2.e');
   load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'GFilemanForms3.e');
   load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'GFileman.e');
   //load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'ListmanForms.e');
   //load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'ListmanConfig.e');
   //load_my_module2(path :+ 'GFileman' :+ FILESEP :+ 'Listman.e');

   load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'wstack.e');
   load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'HighlightParens.e');
   //load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'ParenMatch2.e');
   load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'gputil2.e');
   load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'gputil4.e');
   load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'xkeydefs.e');
   //load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'ProjectTBExtra.e');
   //load_my_module2(path :+ 'my-macros' :+ FILESEP :+ 'ProjectTBExtraMenus.e');

}


