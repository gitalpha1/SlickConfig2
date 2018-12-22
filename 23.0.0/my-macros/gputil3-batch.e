
#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)


// void gputil3_check_path(_str p)
// {
//    if (p != __PATH__)
//       _message_box('Warning gputil3 path');
// }
// 
// #define GPUTIL3_CHECK_PATH(y) gputil3_check_path(y) 


int get3()
{
   return 3;
}

void defmain()
{
   message (get3());
}



