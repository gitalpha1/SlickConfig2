
#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)
#import "tagform.e"


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
#if 0
   int renumber_flags=numbering_options();
   if (renumber_flags&VSRENUMBER_AUTO) {
      if (renumber_flags&VSRENUMBER_COBOL) {
         renumber_lines(1,6,'0',false,true);
      }
      if (renumber_flags&VSRENUMBER_STD) {
         renumber_lines(73,80,'0',false,true);
      }
   }
#endif


   //say("Save " :+ options :+ "  " :+ filename);
   //set_env("VSLICKBACKUP", "C:/GP/TEMP/backups"); 
   //set_env("VSLICKBACKUP", strip_filename(filename,'N') :+ "/BACK1" );
   //set_env("VSLICKBACKUP", strip_filename(_workspace_filename, 'N') :+ "/backup1" );

   typeless status=_save_file(options " "_maybe_quote_filename(filename));
   if (!status && file_eq(strip(filename,'B','"'),p_buf_name)) {
      if (p_modified_temp_name!='') {
         _as_removefilename(p_modified_temp_name,true);
         p_modified_temp_name='';
      }
      //_cbsave_filewatch();
#if 1
      call_list('_cbsave_');
      //10:51am 7/3/1997
      //Dan modified for auto-tagging
      if (def_autotag_flags2&AUTOTAG_ON_SAVE) {
         //messageNwait(nls('got here'));
         TagFileOnSave();
      }
#endif
   }

   if ( pos(filename, 'autosave') ) {
      return status;
   }
   if ( pos(filename, 'Google Drive') ) {
      return status;
   }
   if ( pos(filename, 'OneDrive') ) {
      return status;
   }


   _str pa = 'C:\Users\Graeme\Google Drive\slick\laptop\backups\' :+ strip_filename(filename,'DN');
   if (!path_exists(pa)) {
      int result = make_path(pa);
      if (result) {
         _message_box("slick gdrive backup make path failed : " :+ result :+ pa);
         return status;
      }
   }

   int result2 = copy_file(_maybe_quote_filename(filename), _maybe_quote_filename(pa :+ strip_filename(filename,'P')));

   if (result2 != 0) {
      _message_box("slick backup main google drive copy failed " :+ (_str)(result2));
   }

   pa = 'C:\Users\Graeme\OneDrive\slick\laptop\backups' :+ strip_filename(filename,'DN');
   if (!path_exists(pa)) {
      int result = make_path(pa);
      if (result) {
         _message_box("slick one-drive backup make path failed : " :+ result :+ pa);
         return status;
      }
   }

   int result = copy_file(_maybe_quote_filename(filename), _maybe_quote_filename(pa :+ strip_filename(filename,'P')));

   if (result != 0) {
      _message_box("slick backup main one drive copy failed " :+ (_str)(result));
   }

   return(status);
}


// temp



_command gui_save_config(_str save_immediate='') name_info(','VSARG2_EDITORCTL)
{
   int status=_promptSaveConfig();
   if (status!=1) {
      return(status);
   }
   status = (save_config(save_immediate));

   if ( status == 0 ) {
      result := _message_box("Export all options?", '', IDYES|IDNO|MB_ICONQUESTION,IDNO);
      if ( result != IDYES ) {
         return 0;
      }
      _str p1 = 'V23-' :+ stranslate(_date('I'),'-','/') :+ '-' :+ 
                                                                   stranslate(_time('M'), '-', ':') :+ '.zip';
      _str fn = 'C:/GP/slick-config/temp/' :+ p1;;

      _mdi.export_options('-a  ' :+ fn);
      copy_file(fn, "C:/Users/Graeme/Google Drive/slick/laptop/backup-config/" :+ p1);
      delete_file(fn);
   }
   return status;
}



_command void tsv() name_info(',')
{
   say(get_env("VSLICKBACKUP"));
}

