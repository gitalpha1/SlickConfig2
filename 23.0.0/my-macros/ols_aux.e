#include "slick.sh"
/*
  These functions can be added to your library or loaded from this file.
  Check for name collisions first if doing either of those options.
  They can also be added as static methods to open_local_symbol.e and open_project_file.e,
  but remember to prefix the functions with static.

  open_local_symbol.e, for version v4.0.8.1, other versions you are on your own.
  1) in open_local_symbol.e find the function:
    static void _update_tree ( boolean on_init_tree = false )
  2) In that function, in the while loop, look for a line:
    hidden = ( found == count ) ? 0 : TREENODE_HIDDEN;
  3) After that line insert this code:
         //m.c.r+
         {//dont step on locals
            if (count==1) {
               _str n2=name;
               if (pos(name,'::')!=0) {
                  _str junk;
                  parse name with junk'::'n2;
               }
               //_str caps=opf_str_caps_of(n2);
               _str acode=str_abbr_code(str_item(n2,0,'('));
               //say('acode:'acode);
               if (str_abbr_code_match(pattern,lowcase(acode),4)) {
                  hidden =0;
               }
            }
         }
         //m.c.r-
  4) Recompile and load module
  5) Try new pattern matching, examples:
    a) given target 'abc_def', 'ad' will match
    a) given target 'abcDef', 'ad' will match
    a) given target 'AbcDefGhi', 'ag' or 'dg' will match
    a) given target 'AbcDEFghi', 'ag' or 'dg' or 'def' will match
    a) given target 'AbcDefghi', 'ae' will not match

*/


/**
 * Creates a string of abbr code characters to use for fast find
 * purposes. It will capture:
 * <ul>
 * <li> All numbers 0-9
 * <li> All capitals A-Z
 * <li> All alpha transitions; where this char is alpha, but previous is not
 * <li> All transitions to lower, provided previous 2 or more chars are upper
 * <li> The first char, if alpha
 * <ul>
 *
 * Example:<br>
 * <code> str_abbr_code('abcDefGHIjkl-m_1a2b') // returns
 * 'aDGHIjm1a2b'
 * </code>
 *
 * @param s_     The subject string
 *
 * @return abbr code chars
 */
_str str_abbr_code(_str s_){
   //
   // when lower to upper
   // abcDef = D
   //
   // when non-abc to abc
   // .abc = a
   // 12a  = a
   //
   // when number
   // 12a  =12
   //
   // when upper
   // abcDEF = DEF
   //
   // when multiupper to lower
   // abcDEFghi = g
   //
   // when first and alpha or num
   //
   _str r='';
   int x=0;
   _str abc='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
   _str n='1234567890';
   int prev_case=-1;
   int prev_abc=-1;
   int mult_up=-1;
   for (x=0;x<length(s_);x++) {
      _str i=substr(s_,x+1,1);
      boolean is_abc=pos(upcase(i),abc)!=0;
      boolean is_num=pos(i,n)!=0;
      boolean is_low=pos(i,lowcase(abc))!=0;
      boolean is_up=pos(i,abc)!=0;
      if (
          pos(i,abc)!=0 //all uppers
          ||pos(i,n)!=0 //all nums
          ||(prev_abc!=1&&is_abc) //abc trans
          ||(mult_up==1&&is_low) //mult upper lower
          ||(x==0&&(is_abc||is_num))
          ) {
         if (pos(i,abc)!=0&&prev_case==1) {
         }else{
            r=r i;
         }
      }else{
      }
      if (is_up&&prev_case==1) {
         mult_up=1;
      }else{
         mult_up=0;
      }
      if (is_up) {
         prev_case=1;
      }else{
         prev_case=0;
      }
      if (is_abc) {
         prev_abc=1;
      }else{
         prev_abc=0;
      }
   }
   return r;
}

/**
 * Given source and target strings which are abbr codes, if souce characters are in target in same order we return a gap count, otherwise return -1
 * <br>
 * Example of gap count:<br>
 * <code> s_='acf'; t_='abcdef';// gap count of 2, first
 * representing b, second representing de
 * </code>
 *
 * @param s_     The souce, can be shorter than target
 * @param t_     the target, if shorter than source, return -1
 *
 * @return 0 if perfect match, -1 if failed to match, gap count otherwize
 */
int str_ordered_match(_str s_,_str t_){
   // returns -1 if no match, else return number of gaps
   // if t is abcdefghi
   // then def returns 0
   // then df returns 1
   // then adg returns 2
   // then z returns -1
   // then az returns -1
   //
   if (s_==t_) {
      return 0;
   }
   if (pos(s_,t_)!=0) {
      return 0;
   }
   //say('=============');
   //say('t_:'t_);
   //say('substr(t_,1,1):'substr(t_,1,1));
   int ct=0;
   boolean pg=false;
   _str s=s_;
   for (x=0;x<length(t_);x++) {
      _str i=substr(t_,x+1,1);
      //say('x:'x 'i:'i ' s:'s)
      if (i==substr(s,1,1)) {
         //say('i==substr(s,1,1)');
         if (length(s)==1) {
            return ct;
         }
         s=substr(s,2);
         pg=false;
      }else{
         //say('i!=substr(s,1,1)');
         if (!pg) {
            if (length(s)!=length(s_)) {
               ct++;
            }
         }
         pg=true;
      }
   }
   return -1;
}

/**
 * Remove all characters in c_ from s_ and return the result
 *
 * @param s_     Source string
 * @param c_     characters to remove
 *
 * @return s_ without any of the characters in c_
 */
_str str_remove_chars(_str s_, _str c_){
   _str r='';
   for (x=0;x<length(s_);x++) {
      _str i=substr(s_,x+1,1);
      if (pos(i,c_)==0) {
         r=r i;
      }
   }
   return r;
}

/**
 * Determine if two abbr codes match sufficiently, where:
 * <ul>
 *    <li>if s_ and t_ are identical return true
 *    <li>if s_ and t_ are identical with numbers removed return
 *    true
 *    <li>if s_ and t_ ordered match gap count is zero return
 *    true (ie s_ is in t_)
 *    <li>if s_ and t_ with numbers removed, ordered match gap
 *    count is zero return true (ie s_ is in t_)
 *    <li>When min_ct_==-1 then:
 *    <ul>
 *      <li>if length s_ is more than one third the length of t_
 *      and gap count, with or without nums, is not -1, return
 *      true
 *    </ul>
 *    <li>When min_ct_!=-1 and length of s_ is more than or
 *    equal to min_ct_ then:
 *    <ul>
 *      <li>if gap count, with or without nums, is not -1,
 *      return true
 *    </ul>
 *    <li>Otherwize, when min_ct_!=-1 and length of s_ is less
 *    than min_ct_ then:
 *    <ul>
 *      <li>if gap count, with or without nums, is not -1 and
 *      less than or equal to one third of the length of s
 *      return true
 *    </ul>
 * </ul>
 *
 * @param s_      Souce abbr code
 * @param t_      Target abbr code
 * @param min_ct_ When source abbr code reaches this length, do not require a gap
 *
 * @return
 */
boolean str_abbr_code_match(_str s_,_str t_,int min_ct_=-1){
   // if identical = true
   // if strip nums identical = true
   // if ordered match and no gaps = true
   // if gaps and ordered match 50 pct or more = true
   if (s_==t_) {
      return true;
   }
   _str nums='0123456789';
   _str ss=str_remove_chars(s_,nums);
   _str tt=str_remove_chars(t_,nums);
   if (ss==tt) {
      return true;
   }
   int gc1=str_ordered_match(s_,t_);
   if (gc1==0) {
      return true;
   }
   if (min_ct_==-1&&length(s_)>=length(t_) intdiv 3) {
      if (gc1!=-1) {
         return true;
      }
      if (str_ordered_match(ss,tt)!=-1) {
         return true;
      }
      return false;
   }
   int gc2=str_ordered_match(ss,tt);
   if (length(s_)>=min_ct_) {
      if (gc1!=-1) {
         return true;
      }
      if (gc2!=-1) {
         return true;
      }
      return false;
   }else{
      if (gc1!=-1&&gc1<=length(s_) intdiv 3) {
         return true;
      }
      if (gc2!=-1&&gc2<=length(ss) intdiv 3) {
         return true;
      }
      return false;
   }
   return false;
}

