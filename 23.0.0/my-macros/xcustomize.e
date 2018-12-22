


#include "slick.sh"

#pragma option(strictsemicolons,on)
//#pragma option(strict,on)
//#pragma option(autodecl,off)
#pragma option(strictparens,on)



// proctree.e

defeventtab _tbproctree_form;

_proc_tree.lbutton_up()
{
   if (_IsKeyDown(CTRL)) {
      return 0;
   }

   // If there is a pending on-change, kill the timer
   if (gProcTreeFocusTimerId != -1) {
      _kill_timer(gProcTreeFocusTimerId);
      gProcTreeFocusTimerId=-1;
   }
   int index=_TreeCurIndex();
   call_event(CHANGE_LEAF_ENTER,index,p_window_id,ON_CHANGE,'w');
}

