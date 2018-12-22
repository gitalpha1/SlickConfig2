#include "slick.sh"
defmain()

 
{
   //messageNwait("Hello World");
     //messageNwait("Hello World2");
   messageNwait("Arguments given: "arg(1));
   parse arg(1) with word1 word2 .;
   messageNwait("word1="word1" word2="word2);
   return(0);

}


