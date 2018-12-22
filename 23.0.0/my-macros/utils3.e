

// #define PRE_VERSION_13

#ifdef PRE_VERSION_13

#include "slick.sh"
#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)

#else

#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#import "tagform.e"
#import "mprompt.e"
#import "main.e"
#import "util.e"
#import "stdprocs.e"
#import "files.e"
#import "backtag.e"
#endregion

#endif


#if 0
static struct cobol_modified_line_prefix_result {
   _str prefix;
   boolean reset_line_modify_flags;
   boolean add_prefix_without_save;
   boolean abandon_save;
   boolean save_without_prefix;
};

static cobol_modified_line_prefix_result get_cobol_modified_line_prefix()
{
   cobol_modified_line_prefix_result answer;

   answer.prefix = '';
   answer.abandon_save = false;
   answer.save_without_prefix = false;
   answer.reset_line_modify_flags = false;
   answer.add_prefix_without_save = false;

   int result = textBoxDialog("Enter modified line prefix", // Form caption
                              TB_RETRIEVE,      // Flags
                              0,                // Use default textbox width
                              "",               // Help item
                              "",
                              "CobolModifiedLinePrefixFormRetrieve",  // Retrieve Name
                              "Enter prefix:",                        // _param1
                              "-CHECKBOX Reset line modify flags:"0,
                              "-CHECKBOX Add prefix but don't save:"0,
                              "-CHECKBOX Make all upper case"0,      // _param4
                              "-CHECKBOX Abandon save:"0);
   if (result != COMMAND_CANCELLED_RC) {
      answer.prefix = substr(_param1,1,6,' ');
      if (_param4) {
         answer.prefix = upcase(answer.prefix);
      }
      if (_param2) {
         answer.reset_line_modify_flags = true;
      }
      if (_param3) {
         answer.add_prefix_without_save = true;
      }
      if (_param5) {
         answer.abandon_save = true;
      }
      return answer;
   }
   answer.save_without_prefix = true;
   return answer;
}


// This macro replaces the save_file function from slick saveload.e
// It will need reloading if the installation saveload.e ever gets reloaded
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
   // Add user prefix to modified lines except during auto-saves.
   _str as_dir=def_as_directory;
   if (as_dir=='') {
      as_dir=_ConfigPath():+'autosave':+FILESEP;
   }
   if (pos(as_dir,filename,1,'I')!=1) {
      // not auto save
      cobol_modified_line_prefix_result answer = get_cobol_modified_line_prefix();
      if (answer.abandon_save) {
         return 0;
      }
      if (!answer.save_without_prefix) {
         typeless p;
         _save_pos2(p);
         top();
         do {
            if (_lineflags()&(MODIFY_LF|INSERTED_LINE_LF)) {
               _str line;
               get_line(line);
               replace_line(answer.prefix :+ substr(line,7));
            }
         } while (down()==0);
         _restore_pos2(p);
      }
      if (answer.add_prefix_without_save) {
         return 0;
      }
      if (answer.reset_line_modify_flags) {
         options = options :+ '+L';
      }
   }

   typeless status=_save_file(options " "filename);
   if (!status && file_eq(strip(filename,'B','"'),p_buf_name)) {
      call_list('_cbsave_');
      //10:51am 7/3/1997
      // Dan modified for auto-tagging
      if (def_autotag_flags2&AUTOTAG_ON_SAVE) {
         //messageNwait(nls('got here'));
         TagFileOnSave();
      }
   }
   return(status);
}

#endif

