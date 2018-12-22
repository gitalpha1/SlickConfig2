#include "slick.sh"

defeventtab form1;
void ctlcommand2.lbutton_up()
{
   static boolean b;
   b = !b;
   p_active_form.p_border_style = b ? BDS_NONE : BDS_DIALOG_BOX;
}
void ctlcommand1.lbutton_up()
{
   p_active_form._delete_window();
}


