


int trace_id;

_str trace_cross_ref[];

_command add_trace() name_info(','VSARG2_MACRO|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   top();
   int line1;
   _str filen = strip_filename(p_buf_name,'DP');
   while (next_tag('Y') == 0)
   {
      find('{','I?');
      _deselect();
      end_line();
      c_enter();
      begin_line();
      _insert_text("XTRACE(" :+ (_str)++trace_id :+ ');');
      line1 = p_line;
      find('{','I-?');
      _deselect();
      find_matching_paren(true);
      keyin_enter();
      cursor_up();
      _insert_text("XTRACE_EXIT(" :+ (_str)trace_id :+ ');');

      _str cur_proc = '', cur_class = '';

      cur_proc = current_proc(false);
      cur_class = current_class(false);
      if ( length(cur_class))
         cur_proc = cur_class :+ '::' :+ cur_proc;

      trace_cross_ref[trace_cross_ref._length()] =
         (_str)trace_id :+ ' lines: ' :+ field(line1,5) :+ ' ' :+ field(p_line,5) :+
             ' ' :+ field(cur_proc,35) :+ '  ' :+ field('"' :+ filen :+ '"', 16) :+  '  "' :+ p_buf_name :+ '"';
   }
}

_str trace_files[];


int add_to_trace_list()
{
   if (p_extension == 'c') {
      trace_files[trace_files._length()] = p_buf_name;
   }
   return 0;
}

_command void add_trace_all() name_info(','VSARG2_MACRO|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   trace_id = 10000;
   trace_files._makeempty();
   trace_cross_ref._makeempty();
   for_each_buffer('add_to_trace_list');
   trace_files._sort('F');
   int k;
   for (k = 0; k < trace_files._length(); ++k) {
      _str ext = get_extension(trace_files[k]);
      if ( ext == 'c' || ext == 'cpp') {
         message('Trace ' :+ field(trace_id,5) :+ ' ' :+ strip_filename(p_buf_name,'DP'));
         edit(maybe_quote_filename(trace_files[k]));
         add_trace();
      }
   }
   edit('trace_cross_ref.txt');
   bottom();
   for (k = 0; k < trace_cross_ref._length(); ++k) {
      keyin_enter();
      _insert_text(trace_cross_ref[k]);
   }
   keyin_enter();
   keyin_enter();
   _insert_text('End cross reference');
   keyin_enter();
}


#if 0
// clipboard_type == 'CHAR' , 'LINE' or 'BLOCK'
_command int text_to_clipboard (_str text = '', _str clipboard_type = 'CHAR', _str clipboard_name = '')
{
   if ( length ( text ) )
   {
      push_clipboard_itype (clipboard_type,clipboard_name,1,true);
      append_clipboard_text (text);
      return(0);
   }
   else
      return(TEXT_NOT_SELECTED_RC);
}

_command void ccb,copy_current_buffer () name_info (','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   text_to_clipboard (strip_filename (p_buf_name,'DP'));
   message ( "'" strip_filename (p_buf_name,'DP') "' copied to clipboard")
}
_command void ccbf_copy_current_buffer_full () name_info (','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   hs2_text_to_clipboard (p_buf_name);
   message ( "'" p_buf_name "' copied to clipboard")
}

_command void ccp,copy_current_proc () name_info (','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _str cur_proc = '', cur_class = '';

   cur_proc = current_proc ( false );
   cur_class = current_class ( false );

   if ( length ( cur_class ) )
      cur_proc = cur_class :+ '::' :+ cur_proc;

   text_to_clipboard ( cur_proc );
   message ( "'" cur_proc "' copied to clipboard")
}

#endif

