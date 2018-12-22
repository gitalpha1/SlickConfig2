

#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)

#include "tagsdb.sh"




static int x_do_list_members(boolean OperatorTyped,
                      boolean DisplayImmediate,
                      _str (&syntaxExpansionWords)[]=null,
                      _str expected_type=null,
                      VS_TAG_RETURN_TYPE &rt=null,
                      _str expected_name=null,
                      boolean prefixMatch=false,
                      boolean selectMatchingItem=false,
                      boolean doListParameters=false)
{
   
   
   int orig_col=p_col;
   left();
   p_col=orig_col;
   //boolean inJavadocSeeTag=_inJavadocSeeTag();
   struct VS_TAG_RETURN_TYPE visited:[];

   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   _str lang=p_LangId;
   int status=0;
   // set up info flags to be seen by get_expression_info
   if (expected_type!=null && expected_type!='') {
      //say("_do_list_members: expected_type="expected_type);
      idexp_info.info_flags=VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS;
   }
   // parse out the context expression for the current language

   status=_Embeddedget_expression_info(OperatorTyped, lang, idexp_info, visited);
   if (status && OperatorTyped && rt!=null) {
      status=_Embeddedget_expression_info(false, lang, idexp_info, visited);
   }

   // override expression info if overloaded operator syntax
   if (OperatorTyped && status < 0 && (idexp_info.info_flags & VSAUTOCODEINFO_CPP_OPERATOR )) {
      tag_idexp_info_init(idexp_info);
      idexp_info.lastid='';
      idexp_info.prefixexp='';
      idexp_info.lastidstart_col=p_col;
      idexp_info.lastidstart_offset=(int)_QROffset();
      idexp_info.prefixexpstart_offset=(int)_QROffset();
      idexp_info.info_flags=VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS;
      status=0;
   }

   if (status) {
      if (!OperatorTyped && expected_type==null) {
         _str msg=_CodeHelpRC(status,idexp_info.errorArgs);
         if (msg!='') {
            //_message_box(msg);
            message(msg);
         }
      }
      return -1;
   }
   // if we were not given an expected type, try to find one
   if (idexp_info.prefixexpstart_offset>0 && expected_type==null && rt!=null) {
      tag_return_type_init(rt);
      status=find_expected_type_from_expression(idexp_info.errorArgs,idexp_info.prefixexpstart_offset,rt);
      if (status) {
         _str msg=_CodeHelpRC(status,idexp_info.errorArgs);
         if (msg!='' && !OperatorTyped) {
            //_message_box(msg);
            message(msg);
         }
         return -1;
      } else {
         expected_type = rt.return_type;
      }
   }
   if (OperatorTyped) {
      idexp_info.info_flags |= VSAUTOCODEINFO_OPERATOR_TYPED;
   }
   if (expected_type!=null) {
      idexp_info.info_flags |= VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS;
   } else {
      rt = null;
   }
   if (_chdebug) {
      tag_idexp_info_dump(idexp_info,"_do_list_members");
   }

   // if auto-complete is already active, then just update the info.
   if (AutoCompleteActive() && AutoCompleteRunCommand()) {
      return -1;
   }

   // turn things over the auto-complete to handle the display of list-symbols

   retryCount := 0;
   orig_wid := p_window_id;
   _str errorArgs[];
   do {
      status = AutoCompleteUpdateInfo(true,
                                      DisplayImmediate,   /* force update */
                                      false,              /* insert longest match */
                                      OperatorTyped,
                                      prefixMatch,
                                      idexp_info,
                                      expected_type,
                                      rt,
                                      expected_name,
                                      selectMatchingItem,
                                      doListParameters,
                                      errorArgs
                                      );
      if (status < 0) {
         msg := _CodeHelpRC(status, errorArgs);
         if (msg != '' && !OperatorTyped) {
            message(msg);
         }
         if (DisplayImmediate && retryCount==0) {
            if (_MaybeRetryTaggingWhenFinished()) {
               if (_iswindow_valid(orig_wid)) {
                  activate_window(orig_wid);
                  retryCount++;
                  continue;
               }
            }
         }
      }
      else
         return 0;

   } while (false);

   return 1;
}


static boolean is_wordchar(_str s1)
{
   //return isalnum(s1) || (s1=='_');
   return pos('['p_word_chars']',s1,1,'R') > 0;
}


static boolean is_whitespace(_str s1)
{
   return (s1==' ') || (s1==\n) || (s1==\t) || (s1==\r) ;
}


_command void xlist_symbols() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if (p_col <= 1 || _in_comment() || _in_string() || select_active()) 
      return;

   left();
   if ( is_wordchar(get_text(1))) {
      right();
      _insert_text('->');
      if (x_do_list_members(false,true,null,null,null,null,false,true) == 0) {
         return;
      }
      rubout(1);
      rubout(1);
      _insert_text('.');
      if (x_do_list_members(false,true,null,null,null,null,false,true) == 0) {
         return;
      }
      rubout(1);
      list_symbols();
      return;
   }
   right();
   list_symbols();
}

