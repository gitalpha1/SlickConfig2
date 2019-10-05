/*
 * FontOverrides - Override fonts in various toolbars.
 *
 * $Id: FontOverrides.e#9 2009/06/25 23:45:27 chrisant $
 *
 * This macro should work with SlickEdit 12 and higher.
 *
 * Set the following editor variables to override fonts.  You can set them to
 * any of the CFG_SBCS_DBCS_SOURCE_WINDOW font indices, or you can set them to
 * a string "font name,font size,font flags" in the same format as used by
 * _default_font.
 *
 *    - def_tbfname_build
 *    - def_tbfname_output
 *    - def_tbfname_preview
 *    - def_tbfname_preview_bottom
 *    - def_tbfname_references
 *    - def_tbfname_search
 *
 * Set the following editor variables to override font sizes.  Set these to 0
 * to use the same font size as defined in the def_tbfname_* variables.  Or
 * set these to some other value to fine tune the size.  Personally, I have my
 * normal fonts set to 11pt, and I override the TB fonts to be 9pt.
 *
 *    - def_tbfsize_build
 *    - def_tbfsize_output
 *    - def_tbfsize_preview
 *    - def_tbfsize_preview_bottom
 *    - def_tbfsize_references
 *    - def_tbfsize_search
 *
 * Set the following editor variables to override special characters, line
 * numbers, and the line-modify flag settings for the toolbars.  The format
 * for these is a string containing any of the following keywords, separated
 * by commas:  "tabs, spaces, newlines, linenumbers, linemodify, curline".  To
 * forcibly disable any of them, put a minus sign in front:  for example
 * "-tabs".  "tabs" shows tab characters, "spaces" shows space characters,
 * "newlines" shows newline characters, "linenumbers" shows line numbers for
 * each line in the window, "linemodify" shows a color in the margin for
 * modified lines, "curline" highlights the current line.
 *
 *    - def_tbflags_build
 *    - def_tbflags_output
 *    - def_tbflags_preview
 *    - def_tbflags_preview_bottom
 *    - def_tbflags_references
 *    - def_tbflags_search
 *
 * NOTE:  If you have the def_tagwin_use_bottom_style patch from here
 * http://community.slickedit.com/index.php?topic=2396.msg9973#msg9973 then
 * def_tbfname_preview_bottom and def_tbfsize_preview_bottom override the font
 * used when the Preview toolbar bottom style is active.
 */

#include "slick.sh"
#region Imports
#import "config.e"
#import "output.e"
#import "tagrefs.e"
#import "tagwin.e"
#import "tbsearch.e"
#import "tbshell.e"
#endregion
#pragma option( strict, on )

_str def_tbfname_build;
_str def_tbfname_output;
_str def_tbfname_preview;
_str def_tbfname_preview_bottom;
_str def_tbfname_references;
_str def_tbfname_search;

int def_tbfsize_build;
int def_tbfsize_output;
int def_tbfsize_preview;
int def_tbfsize_preview_bottom;
int def_tbfsize_references;
int def_tbfsize_search;

_str def_tbflags_build;
_str def_tbflags_output;
_str def_tbflags_preview;
_str def_tbflags_preview_bottom;
_str def_tbflags_references;
_str def_tbflags_search;

static void MaybeInitFontSetting( _str& namevar, int& sizevar, _str fname, int fsize )
{
   if ( namevar == "" )
   {
      namevar = fname;
      sizevar = fsize;
   }
}

definit()
{
   if ( arg( 1 ) == 'L' )
   {
      MaybeInitFontSetting( def_tbfname_build, def_tbfsize_build, CFG_SBCS_DBCS_SOURCE_WINDOW, 9 );
      MaybeInitFontSetting( def_tbfname_output, def_tbfsize_output, CFG_SBCS_DBCS_SOURCE_WINDOW, 9 );
      MaybeInitFontSetting( def_tbfname_preview, def_tbfsize_preview, CFG_SBCS_DBCS_SOURCE_WINDOW, 9 );
      MaybeInitFontSetting( def_tbfname_preview_bottom, def_tbfsize_preview_bottom, CFG_SBCS_DBCS_SOURCE_WINDOW, 9 );
      MaybeInitFontSetting( def_tbfname_references, def_tbfsize_references, CFG_SBCS_DBCS_SOURCE_WINDOW, 9 );
      MaybeInitFontSetting( def_tbfname_search, def_tbfsize_search, CFG_SBCS_DBCS_SOURCE_WINDOW, 9 );
   }
}

/**
 * Set edit control font.
 * @param control          Control whose font to set.
 * @param font_str         Font string (e.g. from _default_font(index)).
 * @param override_size    Optional: if passed, this overrides any size from
 *                         <i>font_str</i>.
 * @author Chris Antos
 * @author Ding Zhaojie
 */
static void SetControlFont( typeless control, typeless font, int override_size = 0 )
{
   if ( isnumber( font ) )
      font = _default_font( font );

   _str font_name;
   _str font_size;
   typeless font_flags;

   parse font with font_name ',' font_size ',' font_flags ',' .;

   if ( override_size )
      font_size = override_size;

   int font_bold = font_flags & F_BOLD;
   int font_italic = font_flags & F_ITALIC;
   int font_strike_thru = font_flags & F_STRIKE_THRU;
   int font_underline = font_flags & F_UNDERLINE;

   control.p_redraw = false;  // Turn off redraw to avoid excessive recalcs.
   control.p_font_name = font_name;
   control.p_font_size = font_size;
   control.p_font_bold = ( font_bold != 0 );
   control.p_font_italic = ( font_italic != 0 );
   control.p_font_strike_thru = ( font_strike_thru != 0 );
   control.p_font_underline = ( font_underline != 0 );
   control.p_redraw = true;
}

/**
 * Set edit control flags.
 * @param control          Control whose font to set.
 * @param flags_str        Flags to set/clear, separated by commas.  Prefix
 *                         with a minus sign to clear flag.  Recognized flags
 *                         are "tabs, spaces, newlines, linenumbers,
 *                         linemodify, curline".
 * @author Chris Antos
 */
static void SetControlFlags( typeless control, _str flags = '' )
{
   do
   {
      typeless flag;

      if ( pos( ',', flags ) )
      {
         parse flags with flag ',' flags;
      }
      else
      {
         flag = flags;
         flags = '';
      }
      flag = strip( flag );

      boolean fClear = ( pos( '-', flag ) == 1 );
      if ( fClear )
         flag = substr( flags, 2 );

      switch ( flag )
      {
         case 'tabs':
            control.p_ShowSpecialChars &= ~SHOWSPECIALCHARS_TABS;
            if ( !fClear )
               control.p_ShowSpecialChars |= SHOWSPECIALCHARS_TABS;
            break;
         case 'spaces':
            control.p_ShowSpecialChars &= ~SHOWSPECIALCHARS_SPACES;
            if ( !fClear )
               control.p_ShowSpecialChars |= SHOWSPECIALCHARS_SPACES;
            break;
         case 'newlines':
            control.p_ShowSpecialChars &= ~SHOWSPECIALCHARS_NLCHARS;
            if ( !fClear )
               control.p_ShowSpecialChars |= SHOWSPECIALCHARS_NLCHARS;
            break;
         case 'linenumbers':
            control.p_LCBufFlags &= ~(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
            if ( !fClear )
               control.p_LCBufFlags |= (VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
            break;
         case 'linemodify':
            control.p_color_flags &= ~MODIFY_COLOR_FLAG;
            if ( !fClear )
               control.p_color_flags |= MODIFY_COLOR_FLAG;
            break;
         case 'curline':
            control.p_color_flags &= ~CLINE_COLOR_FLAG;
            if ( !fClear )
               control.p_color_flags |= CLINE_COLOR_FLAG;
            break;
      }
   }
   while ( flags._length() );
}

/*
 * Override fonts for various editor windows.
 */

// Override Preview TB font.
defeventtab _tbtagwin_form;
void edit1.on_create2,on_got_focus()
{
   //say( 'override Preview font' );
   int index = find_index( "def_tagwin_use_bottom_style", VAR_TYPE );
   if ( !index || !_get_var( index ) )
   {
      SetControlFont( edit1, def_tbfname_preview, def_tbfsize_preview );
      SetControlFlags( edit1, def_tbflags_preview );
   }
   else
   {
      SetControlFont( edit1, def_tbfname_preview_bottom, def_tbfsize_preview_bottom );
      SetControlFlags( edit1, def_tbflags_preview_bottom );
   }
}

// Override References TB font.
defeventtab _tbtagrefs_form;
void ctlrefedit.on_create2,on_got_focus()
{
   //say( 'override References font' );
   SetControlFont( ctlrefedit, def_tbfname_references, def_tbfsize_references );
   SetControlFlags( ctlrefedit, def_tbflags_references );

   // There is no way to Tab out of the ctlrefedit, so it's better not to
   // allow tabbing into it.
   ctlrefedit.p_tab_stop = false;
}

// Override Build TB font.
defeventtab _tbshell_form;
void _shellEditor.on_create2,on_got_focus()
{
   //say( 'override Build font' );
   SetControlFont( _shellEditor, def_tbfname_build, def_tbfsize_build );
   SetControlFlags( _shellEditor, def_tbflags_build );
}

// Override Output TB font.
static void DeferredOutputFont( typeless control )
{
   //say('override Output font');
   SetControlFont( control, def_tbfname_output, def_tbfsize_output );
   SetControlFlags( control, def_tbflags_output );
}
defeventtab _tboutputwin_form;
void ctloutput.on_create2,on_got_focus()
{
   _post_call( DeferredOutputFont, ctloutput );
}

// Override Search TB font.
static void DeferredSearchFont( typeless control )
{
   // Only override the font in the Search toolbar; avoid overriding the font
   // when the user chooses "Open as Editor Window" from a Search window.
   if ( !control.p_mdi_child )
   {
      if ( _isGrepBuffer( control.p_buf_name ) )
      {
         //say('override Search font');
         SetControlFont( control, def_tbfname_search, def_tbfsize_search );
         SetControlFlags( control, def_tbflags_search );
      }
   }
}
_command void grep_mode() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   #if __VERSION__<13
   select_edit_mode( 'grep' );
   #else
   _SetEditorLanguage( 'grep' );
   #endif
   _post_call( DeferredSearchFont, p_window_id );
}

