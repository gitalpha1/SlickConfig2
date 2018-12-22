highlight
/******************************************************************************
*  $Revision: 1.1 $
******************************************************************************/

#include "slick.sh"

#import 'dlinklist.e'

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)





//=============================================================================
//  Data structures for recording file activity
//=============================================================================


struct file_activity_data
{
   _str  filename;
   int   base_view_counter;
   int   period_1;
   int   periods_2_3;
   int   periods_4_7;
   int   periods_8_14;
   int   periods_15_28;
   int   periods_29_56;
   int   current_view_counter;
};


// file_activity_ten_seconds_counter is used to treat all files mods that occur
// within a single ten second period as one modification
static int     file_activity_ten_seconds_counter;



static _str current_projname;

static _str current_stats_filename;

static file_activity_data *   current_file_activity_data_ptr;


file_activity_data   file_activity_list:[];


//=============================================================================






struct 
{
}





#define XML_LIST_INDENT_STRING      "\x20\x20\x20"
#define XML_LIST_INDENT_STRING2     XML_LIST_INDENT_STRING :+ XML_LIST_INDENT_STRING
#define XML_LIST_INDENT_STRING3     XML_LIST_INDENT_STRING2 :+ XML_LIST_INDENT_STRING
#define XML_LIST_INDENT_STRING4     XML_LIST_INDENT_STRING3 :+ XML_LIST_INDENT_STRING



static _str encode_xml_special_chars(_str str1)
{
   // convert <>& to sequence
   str1 = stranslate(str1, "&amp;", "&");
   str1 = stranslate(str1, "&gt;", ">");
   str1 = stranslate(str1, "&lt;", "<");
   str1 = stranslate(str1, "&quot;", "\"");
   str1 = stranslate(str1, "&apos;", "'");
   return str1;
}



static void insert_xml_lists(int format = 1, boolean global_lists = false)
{
   int k;
   for (k = 0; k < the_lists._length(); ++k) {
      if (the_lists[k].list_name == '') {
         continue;
      }
      boolean gf = false;
      if (the_lists[k].list_name == FAVORITES_LIST_NAME || 
          the_lists[k].list_name == EXTERNAL_LIST_NAME ||
          the_lists[k].list_flags & LFMASK_LIST_IS_GLOBAL) {
         gf = true;
      }
      // are we saving global or non-global lists?
      if (global_lists && !gf || !global_lists && gf) 
         continue;

      insert_line(XML_LIST_INDENT_STRING2 :+ '<List Name="' :+ encode_xml_special_chars(the_lists[k].list_name) '">');
      int j = 0;
      while (j < the_lists[k].list_items._length()) {
         _str keyn = the_lists[k].list_items[j].key;
         if (keyn == '') {
            keyn = '--';
         }
         _str options = convert_flags_to_string_for_file(the_lists[k].list_items[j].flags);
         if (the_lists[k].list_items[j].name != '')
         {
            if (format == 2) {
               insert_line(XML_LIST_INDENT_STRING3 :+ '<Item Key="' :+ encode_xml_special_chars(keyn) :+ 
                           '" Options="' :+ encode_xml_special_chars(options) :+ '">' );
               insert_line(XML_LIST_INDENT_STRING4 :+ '<Target>' :+ 
                           encode_xml_special_chars(the_lists[k].list_items[j].name) );
               insert_line(XML_LIST_INDENT_STRING4 :+ '</Target>' ); 
               insert_line(XML_LIST_INDENT_STRING3 :+ '</Item>' );
            }
            else 
            {
               insert_line(XML_LIST_INDENT_STRING3 :+ '<Item  Key="' :+ encode_xml_special_chars(keyn) :+ 
                           '"  Options="' :+ encode_xml_special_chars(options) :+
                           '"  Target="'  :+ encode_xml_special_chars(the_lists[k].list_items[j].name) :+ '" />');
            }
         }
         ++j;
      }
      insert_line(XML_LIST_INDENT_STRING2 :+ '</List>');
   }

}


void save_xml_list_data_to_file(_str filename, boolean global_lists = false)
{
   int section_view, current_view;
   current_view = _create_temp_view(section_view);
   if (current_view == '') {
       return;
   }
   activate_view(section_view);
   top();
   // insert_line('<!DOCTYPE ListManData SYSTEM "http://www.slickedit.com/dtd/vse/Graeme/ListManData.dtd">');
   insert_line('<ListManData Date="' :+ _date('L') :+ '" Format="1" ListmanVersion="' :+ LISTMAN_VERSION :+ '" >');
   insert_line(XML_LIST_INDENT_STRING :+ '<ListSet Name="ListSet1">');    // name unused for now
   insert_xml_lists(1,global_lists);
   insert_line(XML_LIST_INDENT_STRING :+ '</ListSet>');
   insert_line('</ListManData>');

   _save_file('-Z -ZR -E -S -L +DD -O ' :+ filename);
   _delete_temp_view(section_view);
   activate_view(current_view);
}




static void GFM_save_shortcut_lists(_str list_data_filename, boolean force_save = false)
{
   //GFM_save_shortcut_lists2(list_data_filename, false);
   //GFM_save_shortcut_lists2(GLOBAL_LIST_DATA_FILENAME, true);

   if (!force_save && !list_data_has_been_modified) {
      return;
   }
   save_xml_list_data_to_file(list_data_filename, false);
   save_xml_list_data_to_file(GLOBAL_LIST_DATA_FILENAME, true);
   list_data_has_been_modified = false;
}




static int load_xml_shortcut_list_data2(_str list_data_filename, boolean global)
{
   _str line,listname,rkey,rname, roptions;
   int list_index = the_lists._length();

   if (!file_exists(list_data_filename)) {
      message('ListMan error - data file not found ' :+ list_data_filename);
      return 0;
   }
   int xst;
   int xhandle = _xmlcfg_open(list_data_filename, xst);

   if (xhandle < 0) {
      message('ListMan error - xml load error ' :+ xhandle :+ ' File: ' :+ list_data_filename);
      return xhandle;
   }
   int ListSet_node = _xmlcfg_find_simple(xhandle, "/ListManData/ListSet");
   if (ListSet_node < 0) {
      message( 'ListMan error - xml tag not found ListManData/ListSet - File:' :+ list_data_filename );
      return -1;
   }

   int listset_child_node = _xmlcfg_get_first_child(xhandle, ListSet_node, VSXMLCFG_NODE_ELEMENT_START | VSXMLCFG_NODE_ELEMENT_START_END );

   // iterate through the lists, if any
   for ( ; ; listset_child_node = _xmlcfg_get_next_sibling(xhandle, listset_child_node)) {
      if (listset_child_node < 0) 
         break;
      
      if (_xmlcfg_get_name(xhandle, listset_child_node) == 'List') {
         _str list_name = _xmlcfg_get_attribute(xhandle, listset_child_node, 'Name' );
         if (list_name == '') {
            continue;
         }
         //say('list ' :+ list_name);
         the_lists[list_index].list_name = list_name;
         the_lists[list_index].list_flags = (global ? LFMASK_LIST_IS_GLOBAL : 0);
         the_lists[list_index].most_recent = 0;
         the_lists[list_index].list_items._makeempty();

         int list_child_node = _xmlcfg_get_first_child(xhandle, listset_child_node, VSXMLCFG_NODE_ELEMENT_START | VSXMLCFG_NODE_ELEMENT_START_END );
         if (list_child_node < 0) {
            ++list_index;  // keep empty list
            continue;
         }
         // iterate through list items
         int item_index = 0;
         while (true) {
            if (_xmlcfg_get_name(xhandle, list_child_node) == 'Item') {
               _str target = _xmlcfg_get_attribute(xhandle, list_child_node, 'Target' );
               _str key = _xmlcfg_get_attribute(xhandle, list_child_node, 'Key' );
               _str options = _xmlcfg_get_attribute(xhandle, list_child_node, 'Options' );
               the_lists[list_index].list_items[item_index].key = (key == '--' ? '' : key);
               the_lists[list_index].list_items[item_index].name = target;
               the_lists[list_index].list_items[item_index].flags = convert_string_to_flags_for_file(options);
               ++item_index;
               //say('Item ' :+ key :+ ' ' :+ options :+ ' ' :+ target);
            }
            list_child_node = _xmlcfg_get_next_sibling(xhandle, list_child_node);
            if (list_child_node < 0) {
               break;
            }
         }
         ++list_index;
      }
   }
   return 1;
}



void GFM_load_shortcut_list_data(_str list_data_filename)
{
   the_lists._makeempty();
   listman_datafile_name = list_data_filename;

   if (list_data_filename != '' && file_exists(list_data_filename)) {
      load_xml_shortcut_list_data2(list_data_filename, false);
   }
   if (file_exists(GLOBAL_LIST_DATA_FILENAME)) {
      load_xml_shortcut_list_data2(GLOBAL_LIST_DATA_FILENAME, true);
   }
}


void _prjopen_xfilestats()
{
   if (current_projname != '') {
      // save data
   }
   current_projname = _project_get_filename();
   current_stats_filename = strip_filename(current_projname, 'E') :+ '.stats.vfs';

   // load data

}



void inc_xfilestats_counter()
{

}


void maintain_xfilestats_buffer_modified()
{

}


void maintain_xfilestats_buffer_modified()
{

}


void maintain_xfilestats_same_buffer()
{
   if (current_file_activity_data_ptr && (*current_file_activity_data_ptr instanceof file_activity_data) {
      ++current_file_activity_data_ptr->base_view_counter;
      if (current_file_activity_data_ptr->base_view_counter >= 240) {
      }
   }
}


void maintain_xfilestats_buffer_switched()
{



   file_activity_list

}


