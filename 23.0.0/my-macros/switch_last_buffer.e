////////////////////////////////////////////////////////////////////////////////////////////////
// HS2 - 2007
// @see http://community.slickedit.com/index.php?topic=3229.0
//

#pragma option(strict,on)

#include 'slick.sh'

static _str old_buffer_name = '';

// called when Slick calls it's list of _switchbuf_ - callbacks
void _switchbuf_toggle_buffer (_str oldbuffname, _str flag)
{
   // toggle_buffer support
   if ( flag == 'Q' )
      old_buffer_name = '';  // quit buffer
   else  if ( (oldbuffname != '') && (oldbuffname != _mdi.p_child.p_buf_name) )
      old_buffer_name = oldbuffname;
}

static int get_num_buffers()
{
   if ( _no_child_windows() ) return 0;

   int ii = 0, start_buf_id = p_buf_id;
   typeless p;
   _save_pos2( p );
   do
   {
      ++ii;
      _next_buffer('NR');
   } while ( p_buf_id != start_buf_id );
   _restore_pos2( p );

   return ii;
}

/**
 * switch to the last (used) buffer
 *
 * @param doCenter   if 'true' the buffer is centered<br>
 *                   This could be useful when quick or visually comparing code snippets in 2 files.
 */
_command void switch_last_buffer ( boolean doCenter = false )
{
   int numbuf = get_num_buffers();
   // say ("hs2_toggle_buffer: old_buffer_name: '" old_buffer_name "' numbuf = " numbuf);
   if ( numbuf <= 1 ) return;

   int status = FILE_NOT_FOUND_RC;

   if ( old_buffer_name != '' )
   {
      // handle new <unnamed> buffers too
      _str old_buffer_name2 = ((_mdi.p_child.p_buf_name != '') ? _mdi.p_child.p_buf_name : "Untitled<"p_buf_id">");
      typeless buf_id=0;
      if ( _isno_name(old_buffer_name) )
      {
         parse old_buffer_name with '<' buf_id'>';
         _macro('m',_macro('s'));
         _macro_call('edit','+bi 'buf_id);
         status = edit('+bi 'buf_id);
         if ( ! status ) p_buf_flags=p_buf_flags & (~VSBUFFLAG_HIDDEN);
      }
      else if ( old_buffer_name != old_buffer_name2 )
      {
         _macro('m',_macro('s'));
         _macro_call('edit','+b 'old_buffer_name);
         status = edit('+b 'old_buffer_name);
         if ( ! status ) p_buf_flags=p_buf_flags & (~VSBUFFLAG_HIDDEN);
      }

      old_buffer_name = old_buffer_name2;
   }

   // use prev buffer as fallback
   if ( status ) prev_buffer ();

   // auto-center can be useful when 'quick comparing' 2 locations
   if ( doCenter ) center_line();
}

