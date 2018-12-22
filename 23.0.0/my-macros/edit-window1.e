#include "slick.sh"

defeventtab form3;
void ctlcommand1.lbutton_up()
{
   _control ctlframe1;
   _control ctlsstab1;
   _control ctledit1;

   edit('C:\GP\DEV\SlickConfig\Vnn\V21-0-1-A\21.0.1\xtemporary_files\NoKeep-000145.gcs');
   select_all();
   copy_to_clipboard();
   deselect();
   int wid = show('form3');
   wid.ctlframe1.ctlsstab1.ctledit1.paste();
   top();
   //wid.ctlframe1.ctlsstab1.ctledit1.p_buf_name = ".search0";
   highlight_all_occurrences("qbus_test_states", "", 0)

}
