

#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)


#import "tagform.e"



#define UNDO_BACKUP_FOLDER 'C:/temp'

// zero for X_UNDO_HOLDOFF_TIME means no holdoff and a delta backup is made
// every time x_undo is used.
// non-zero sets a value in seconds that must elapse between uses of x_undo
// before another delta backup is saved
#define X_UNDO_HOLDOFF_TIME 0

// non static allows inspection with set-var
_str my_normal_backup_folder;

static int x_redo_timer_handle;
static int x_undo_timer_handle;
static int x_undo_holdoff_counter;
static int x_redo_holdoff_counter;



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
 * Copied from saveload.e and modified to handle x_redo switching the backup path
 */
_str save_file(_str filename,_str options)
{
   boolean was_undo = false;
   _str vb = get_env('VSLICKBACKUP');
   if (vb == UNDO_BACKUP_FOLDER) {
      // need to have correct backup path set for file save
      set_env('VSLICKBACKUP', my_normal_backup_folder );
      was_undo = true;
   }
   //say(vb);

   // Following code is from original save_file
   typeless status=_save_file(options " "filename);
   if (!status && file_eq(strip(filename,'B','"'),p_buf_name)) {
      call_list('_cbsave_');
      if (def_autotag_flags2&AUTOTAG_ON_SAVE) {
         TagFileOnSave();
      }
   }
   // end of original code

   if (was_undo && _tbIsVisible('_tbdeltasave_form')) {
      set_env('VSLICKBACKUP', UNDO_BACKUP_FOLDER );
   }
   return(status);
}


// if x_redo has switched VSLICKCONFIG to the undo backup folder, this
// timer call will restore VSLICKCONFIG if the backup history toolbar
// is no longer visible.
// x_undo also calls this to force VSLICKCONFIG to be restored.
static void x_redo_timer_callback(boolean force_normal = false)
{
   if (!force_normal && x_redo_holdoff_counter > 0) {
      //say(' kk4 ' :+ x_redo_holdoff_counter);
      --x_redo_holdoff_counter;
      return;
   }
   _str vb = get_env('VSLICKBACKUP');
   if (vb != UNDO_BACKUP_FOLDER) {
      _kill_timer(x_redo_timer_handle);
      _cbsave_BackupHistory();  // force refresh
      return;
   }
   if (!_tbIsVisible('_tbdeltasave_form') || force_normal) {
      //say(' kk5 ' :+ x_undo_holdoff_counter);
      set_env('VSLICKBACKUP', my_normal_backup_folder );
      _kill_timer(x_redo_timer_handle);
      _cbsave_BackupHistory();  // force refresh
      return;
   }
}


// decrement x_undo_holdoff_counter once a second
static void x_undo_timer_callback()
{
   //say(' kk1 ' :+ x_undo_holdoff_counter);
   if (--x_undo_holdoff_counter <= 0) {
      _kill_timer(x_undo_timer_handle);
   }
}


/**
 * 
 * <p>x_undo is an alternative to undo.
 * If the last undo command was more than X_UNDO_HOLDOFF_TIME seconds ago, it makes a 
 * delta save of the current file so that redo can bring up the undo delta history when 
 * there is nothing to redo.
 * 
 * @see undo
 * @see redo
 * @see undo_steps
 * @see undo_cursor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 ********************************************************************************/
_command void x_undo() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX/*|VSARG2_NOEXIT_SCROLL*/)
{
   if (x_undo_holdoff_counter > 0) {
      x_undo_holdoff_counter = X_UNDO_HOLDOFF_TIME; // seconds
      undo();
      x_redo_timer_callback(true);
      //say(' kk2 ' :+ x_undo_holdoff_counter);
      return;
   }
   x_undo_holdoff_counter = X_UNDO_HOLDOFF_TIME; // seconds
   //say(' kk3 ' :+ x_undo_holdoff_counter);
   set_env('VSLICKBACKUP', UNDO_BACKUP_FOLDER );
   _save_file(p_buf_name :+ ' -O +DD -Z -ZR -E -S -L ');
   set_env('VSLICKBACKUP', my_normal_backup_folder );
   undo();
   undo();
   if (X_UNDO_HOLDOFF_TIME > 0) 
      x_undo_timer_handle = _set_timer(1000,x_undo_timer_callback);
   x_redo_timer_callback(true);
}


/**
 * 
 * <p>x_redo is an alternative to redo.
 * If there is nothing to redo, the undo backup history is invoked.
 * 
 * @see x_undo
 * @see redo
 * @see undo_steps
 * @see undo_cursor
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 ********************************************************************************/
_command void x_redo() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   _control ctl_BH_comment_note2;
   x_redo_holdoff_counter = 2;
   if (redo() == NOTHING_TO_REDO_RC) {
      set_env('VSLICKBACKUP', UNDO_BACKUP_FOLDER );
      activate_deltasave();
      _cbsave_BackupHistory();  // force refresh
      x_redo_timer_handle = _set_timer(500,x_redo_timer_callback);
      int wid = _find_formobj("_tbdeltasave_form", 'n');
      if (wid) {
         wid.ctl_BH_comment_note2.p_text = 
            '<FONT face="Helvetica" size="2"><b>$$$ UNDO HISTORY $$$</b><br>PATH: ' :+ UNDO_BACKUP_FOLDER ;
      }
   }
}


definit ()
{
   if (arg(1)!="L") {
      my_normal_backup_folder = get_env('VSLICKBACKUP');
   }
   x_undo_holdoff_counter = 0;
   x_redo_holdoff_counter = 0;
}


defeventtab _tbdeltasave_form;

// swap backup history between undo backup and normal backup when mouse left
// click in the comment window on the backup history toolbar
void ctl_BH_comment_note2.lbutton_down()
{
   _str vb = get_env('VSLICKBACKUP');
   if (vb != UNDO_BACKUP_FOLDER) {
      set_env('VSLICKBACKUP', UNDO_BACKUP_FOLDER );
      _cbsave_BackupHistory();  // force refresh
      int wid = _find_formobj("_tbdeltasave_form", 'n');
      if (wid) {
         wid.ctl_BH_comment_note2.p_text = 
            '<FONT face="Helvetica" size="2"><b>$$$ UNDO HISTORY $$$</b><br>PATH: ' :+ 
            UNDO_BACKUP_FOLDER :+ '<br>Left click here to swap' ;
      }
   }
   else
   {
      set_env('VSLICKBACKUP', my_normal_backup_folder );
      _cbsave_BackupHistory();  // force refresh
   }
}


