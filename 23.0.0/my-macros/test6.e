

#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)


_command void xf1() name_info(',')
{
   // Get handle to active selection
   int current_mark_id = _duplicate_selection('');
   // Allocate another mark.
   int mark_id = _alloc_selection();
   _select_line(mark_id);
   _show_selection(mark_id);
   get_event();
   _show_selection(current_mark_id);
   _free_selection(mark_id);
}


void xrestore_selection(typeless mark)
{
   typeless cur_mark=_duplicate_selection('');
   say(cur_mark);
   _show_selection(mark);
   _free_selection(cur_mark);

}

int xx1;

_command void xf2() name_info(',')
{
   save_selection(xx1);
   say(xx1);
}

int xx2;
_command void xf3() name_info(',')
{
   xrestore_selection(xx1);
}
