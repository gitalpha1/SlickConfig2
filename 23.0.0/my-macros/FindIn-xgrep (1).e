/**
 * FindIn.e
 *
 * $Id: FindIn.e#6 2008/07/03 16:31:04 chrisant $
 *
 *    Makes it easier to search common directories by choosing them from a
 *    table.  The table can be configured by editing this macro source.
 *
 * Commands in this macro file:
 *
 *    - FindIn                   Show the Find In dialog and initiate search.
 *    - FindInFunction           Search in the current function.
 *    - FindInThisFile           Search in the current buffer.
 *    - FindInOpenBuffers        Search in the open buffers.
 *    - FindInFileDirectory      Search in current file's directory.
 *    - FindInProjectFiles       Search all project files.
 *    - FindInWorkspaceFiles     Search all workspace files.
 *    - OpenFileAtCursor         Opens the filename under the cursor.
 *    - EditAssociatedFile       Opens file associated with current file (e.g.
 *                               matching header file).
 */

#include "slick.sh"
#pragma option( strict, on )

#define WHERE_PROMPT "<Prompt>"

// Use a custom tree search function since the built in _TreeSearch function
// seems to be pretty broken.
#define USE_CUSTOM_TREESEARCH

/**
 * Set this to 1 to speed up showing the tree list by not checking whether the
 * paths in the tree list actually exist.
 */
int def_findin_no_path_check = 0;

/*
 * Find In form.
 */

static _str s_sOptions = '';
static _str s_sWhere = '';
static _str s_sWildcards = '';
static _str s_sTreeMode = '';
static _str s_sIncr = '';

struct WILDCARDRECORD
{
   _str        keyword;    // Wildcard keyword to be replaced (full string match).
   _str        replaceWith;// Wildcard string to replace the keyword with.
};

struct FINDINRECORD
{
   _str        caption;    // Caption that appears in the tree list control.
   _str        where;      // Path(s) to search.
   _str        wildcards;  // Wildcards for files to search in.
   _str        tree_mode;  // Can be "-t" to disable recursive tree search.
};

/**
 * Table of wildcard keywords that expand to longer lists of wildcards.
 */
static WILDCARDRECORD s_arrayWildcardKeywords[] =
{
   { '<slick>',            '*.e;*.sh' },

   { '<sources>',          '*.c;*.cc;*.cpp;*.cxx;':+
                           '*.h;*.hpp;*.hxx;*.inl;':+
                           '*.cs;':+
                           '*.rc;*.rc2;*.rcp;*.pp;*.csv;*.dlg;':+
                           '*.idl;*.odl;':+
                           '*.bat;*.cmd;*.btm;':+
                           '*.pl;*.pm;':+
                           '*.asm;*.inc;':+
                           '*.bas;*.cls;':+
                           '*.rcp;':+
                           '*.lua;':+
                           '*.htm;*.xml;':+
                           '*.def;*.ini;':+
                           'makefile.*;*.mak;sources.*;dirs;':+
                           'jamfile;jamrules;':+
                           '' },

   { '<headers>',          '*.h;*.hpp;*.hxx;*.inl;':+
                           '*.idl;*.odl;':+
                           '*.asm;*.inc;':+
                           '*.htm;*.xml;':+
                           '*.def;*.ini;':+
                           'makefile.*;*.mak;sources.*;dirs;':+
                           'jamfile;jamrules;':+
                           '' },
};

/**
 * <dl>
 *    <dt>caption</dt>
 *    <dd>Caption to be displayed in the tree view.  If the node has children,
 *    the first character must be "-" to default to collapsed (unless the
 *    current working directory matches a directory under this node) or "+" to
 *    always expand the tree node.  Begin the list of children for a node by
 *    making the next entry caption be ">", and end the list of children by
 *    making the next entry caption be "<".  The ">" and "<" are nestable to
 *    define any shape of tree that is desired.
 *    </dd>
 *    <dt>where</dt>
 *    <dd>The path to search.  Can be multiple paths, space delimited.
 *    Use quotes if a path contains spaces.  By default if the path is not
 *    accessible, it is not listed in the tree view; set
 *    <i>def_findin_no_path_check</i>=1 to skip the path checks and speed
 *    up building the tree list (useful if one or more paths are
 *    network paths).</dd>
 *    <dt>wildcards</dt>
 *    <dd>Wildcards for files to search in the <i>where</i> path(s).  If
 *    the wildcard string matches an entry from the s_arrayWildcardKeywords
 *    table, then the corresponding list of wildcards is used from the
 *    table.</dd>
 *    <dt>treemode</dt>
 *    <dd>Can be "-t" to disable recursive tree search (on by default).</dd>
 * </dl>
 *
 * @see FINDINRECORD
 * @see s_arrayWildcardKeywords
 */
static FINDINRECORD s_arrayTreeData[] =
{
   { '-Sample Nodes' },
   { '>' },
   { '-Project A' },
   { '>' },
   { 'Sources', 'c:\temp', '<sources>' },
   { 'Headers', 'c:\temp', '<headers>' },
   { '<' },
   { 'Project B', 'c:\temp', '<sources>' },
   { '<' },
   { 'Current Function', 'f' },
   { 'Current Buffer', 'b' },
   { 'All Open Buffers', 'o' },
   { 'Directory of Current File', 'd' },
   { 'All Project Files', 'p' },
   { 'All Workspace Files', 'w' },
};

defeventtab events_FindIn_What;

_form form_FindIn_What {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='Find In';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=1035;
   p_help="?Ctrl-C toggles case sensitivity.\nCtrl-X toggles UNIX regular expressions.\nCtrl-W toggles matching whole words.";
   p_width=4200;
   p_x=9600;
   p_y=4650;
   p_eventtab=events_FindIn_What;
   _label ctllabelLabel {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Enter text to search for';
      p_forecolor=0x80000008;
      p_height=240;
      p_tab_index=1;
      p_width=3960;
      p_word_wrap=false;
      p_x=120;
      p_y=60;
   }
   _text_box ctltextText {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=NONE_ARG;
      p_font_bold=true;
      p_font_size=10;
      p_forecolor=0x80000008;
      p_height=315;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=4080;
      p_x=60;
      p_y=300;
      p_eventtab2=_ul2_textbox;
   }
   _check_box ctlcheckCase {
      p_alignment=AL_LEFT;
      p_backcolor=0x80000005;
      p_caption='&Ignore case';
      p_forecolor=0x80000008;
      p_height=240;
      p_style=PSCH_AUTO2STATE;
      p_tab_index=3;
      p_tab_stop=true;
      p_value=0;
      p_width=1260;
      p_x=120;
      p_y=720;
   }
   _check_box ctlcheckRegex {
      p_alignment=AL_LEFT;
      p_backcolor=0x80000005;
      p_caption='Regular e&xp.';
      p_forecolor=0x80000008;
      p_height=240;
      p_style=PSCH_AUTO2STATE;
      p_tab_index=4;
      p_tab_stop=true;
      p_value=0;
      p_width=1260;
      p_x=1500;
      p_y=720;
   }
   _check_box ctlcheckWord {
      p_alignment=AL_LEFT;
      p_backcolor=0x80000005;
      p_caption='Whole &word';
      p_forecolor=0x80000008;
      p_height=240;
      p_style=PSCH_AUTO2STATE;
      p_tab_index=5;
      p_tab_stop=true;
      p_value=0;
      p_width=1260;
      p_x=2880;
      p_y=720;
   }
}

void events_FindIn_What.'C-I','C-C'()
{
   ctlcheckCase.p_value = ctlcheckCase.p_value ? 0 : 1;
}
void events_FindIn_What.'C-X'()
{
   ctlcheckRegex.p_value = ctlcheckRegex.p_value ? 0 : 1;
}
void events_FindIn_What.'C-W'()
{
   ctlcheckWord.p_value = ctlcheckWord.p_value ? 0 : 1;
}
void events_FindIn_What.ESC()
{
   p_active_form._delete_window();
}
void events_FindIn_What.ENTER()
{
   s_sOptions = '';
   if ( ctlcheckCase.p_value )
      s_sOptions :+= 'I';
   if ( ctlcheckRegex.p_value )
      s_sOptions :+= 'U';
   if ( ctlcheckWord.p_value )
      s_sOptions :+= 'W';
   p_active_form._delete_window( ctltextText.p_text );
}
void events_FindIn_What.on_create()
{
   typeless arg1 = arg( 1 );
   ctllabelLabel.p_caption = ctllabelLabel.p_caption :+ arg1 :+ ':';
   ctlcheckCase.p_value = pos( 'I', s_sOptions, 1, 'I' ) ? 1 : 0;
   ctlcheckRegex.p_value = pos( 'U', s_sOptions, 1, 'I' ) ? 1 : 0;
   ctlcheckWord.p_value = pos( 'W', s_sOptions, 1, 'I' ) ? 1 : 0;
}

defeventtab events_FindIn;

_form form_FindIn {
   p_backcolor=0x80000005;
   p_border_style=BDS_SIZABLE;
   p_caption='Find In';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=4800;
   p_width=4440;
   p_x=9600;
   p_y=4650;
   p_eventtab=events_FindIn;
   _tree_view ctlTree {
      p_after_pic_indent_x=50;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_clip_controls=false;
      p_CheckListBox=false;
      p_CollapsePicture='_lbminus.bmp';
      p_ColorEntireLine=false;
      p_EditInPlace=false;
      p_delay=0;
      p_ExpandPicture='_lbplus.bmp';
      p_forecolor=0x80000008;
      p_Gridlines=TREE_GRID_NONE;
      p_height=4380;
      p_LevelIndent=50;
      p_LineStyle=TREE_SOLID_LINES;
      p_multi_select=MS_NONE;
      p_NeverColorCurrent=false;
      p_ShowRoot=false;
      p_AlwaysColorCurrent=false;
      p_SpaceY=50;
      p_scroll_bars=SB_VERTICAL;
      p_tab_index=1;
      p_tab_stop=true;
      p_width=3060;
      p_x=60;
      p_y=60;
      p_eventtab=events_FindIn.ctlTree;
      p_eventtab2=_ul2_tree;
   }
   _command_button ctlcommandOk {
      p_cancel=false;
      p_caption='OK';
      p_default=true;
      p_height=420;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=1200;
      p_x=3180;
      p_y=60;
      p_eventtab=events_FindIn.ctlcommandOk;
   }
   _command_button ctlcommandCancel {
      p_cancel=true;
      p_caption='Cancel';
      p_default=false;
      p_height=420;
      p_tab_index=3;
      p_tab_stop=true;
      p_width=1200;
      p_x=3180;
      p_y=540;
   }
   _label ctllabelWhere {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='';
      p_forecolor=0x80000008;
      p_height=240;
      p_tab_index=4;
      p_width=4200;
      p_word_wrap=false;
      p_x=0;
      p_y=4560;
   }
   _label ctllabelDivider {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_SUNKEN;
      p_caption='';
      p_forecolor=0x80000008;
      p_height=40;
      p_tab_index=5;
      p_width=840;
      p_word_wrap=false;
      p_x=3360;
      p_y=4500;
   }
}

void ctlTree.' '()
{
   IncrSearchTree( ' ');
}
void ctlTree.\33-\255()
{
   IncrSearchTree( last_event() );
}
void ctlTree.backspace()
{
   if ( length( s_sIncr ) )
   {
      s_sIncr = substr( s_sIncr, 1, length( s_sIncr ) - 1 );
      IncrSearchTree( '' );
   }
}
void ctlTree.ENTER()
{
   ctlcommandOk.call_event( ctlcommandOk, lbutton_up, 'W' );
}

void ctlTree.on_change(int reason, int index = 0)
{
   s_sIncr = '';

   if (reason != CHANGE_SELECTED) {
      return;
   }
   _str where = '';
   int nodeIndex = _TreeCurIndex();
   if ( nodeIndex >= 0 )
   {
      int ii = _TreeGetUserInfo( nodeIndex );
      where = ExpandEnvVars( TransformWhere( 0, s_arrayTreeData[ii].where ) );
   }
   if ( where != '' )
   {
      ctllabelWhere.p_caption = where;
      ctlcommandOk.p_enabled = true;
   }
   else
   {
      ctllabelWhere.p_caption = '';
      ctlcommandOk.p_enabled = false;
   }
}

//void ctlTree.on_change()
//{
//   s_sIncr = '';
//
//   _str where = '';
//   int nodeIndex = _TreeCurIndex();
//   if ( nodeIndex >= 0 )
//   {
//      int ii = _TreeGetUserInfo( nodeIndex );
//      where = ExpandEnvVars( TransformWhere( 0, s_arrayTreeData[ii].where ) );
//   }
//   if ( where != '' )
//   {
//      ctllabelWhere.p_caption = where;
//      ctlcommandOk.p_enabled = true;
//   }
//   else
//   {
//      ctllabelWhere.p_caption = '';
//      ctlcommandOk.p_enabled = false;
//   }
//}

static void EscapeWindow()
{
   if ( _tbIsAutoShownWid( p_active_form ) )
      _tbAutoHide( p_active_form );    // Auto-hide windows auto-hide instead of closing.
   else if ( !_tbIsAutoHidden( p_active_form.p_name ) && !tbIsDocked( p_active_form.p_name ) )
      p_active_form._delete_window();  // Floating windows close.
}

static _str MaybeAppendPathSep( _str p )
{
   if ( p == '' )
      return '';
   if ( last_char( p ) != '\' )
      return p'\';
   return p;
}

static _str ExpandEnvVars( _str s )
{
   _str new_s = '';

   while ( pos( '(%([A-Za-z_0-9]+)%)', s, 1, 'U' ) )
   {
      int cchBefore = pos( 'S1' ) - 1;
      int cchAfter = length( s ) - ( pos( 'S1' ) + pos( '1' ) - 1 );
      new_s = '';
      if ( cchBefore )
         new_s = new_s :+ substr( s, 1, cchBefore );
      new_s = new_s :+ get_env( substr( s, pos( 'S2' ), pos( '2' ) ) );
      if ( cchAfter )
         new_s = new_s :+ substr( s, length( s ) - ( cchAfter - 1 ), cchAfter );
      s = new_s;
   }

   return s;
}

#ifdef USE_CUSTOM_TREESEARCH
static int s_arrayIndexList[];
static int TreeSearch( _str needle, boolean fIncludeHidden = false )
{
   int iPass;
   int ii;
   _str caption;
   int moreFlags, junk;

   for ( iPass = 0; iPass < ( fIncludeHidden ? 2 : 1 ); iPass++ )
   {
      for ( ii = 0; ii < s_arrayIndexList._length(); ii++ )
      {
         caption = ctlTree._TreeGetCaption( s_arrayIndexList[ii] );
         ctlTree._TreeGetInfo( s_arrayIndexList[ii], junk, junk, junk, moreFlags, junk );

         if ( !( moreFlags & TREENODE_HIDDEN ) || iPass > 0 )
            if ( pos( needle, caption, 1, 'I' ) )
               return s_arrayIndexList[ii];
      }
   }

   return -1;
}
#endif

static void IncrSearchTree( _str ch )
{
   _str old_incr = s_sIncr; // Save the value because the on_change handler will clear it in a moment.
   _str new_incr = old_incr :+ ch;

//say('newincr='new_incr);
#ifdef USE_CUSTOM_TREESEARCH
   int index = TreeSearch( new_incr, true );
#else
   int index = ctlTree._TreeSearch( TREE_ROOT_INDEX, new_incr, 'ITH' );
#endif

   if ( index >= 0 )
   {
//say('matched');
      ctlTree._TreeSetCurIndex( index );
      s_sIncr = new_incr;
   }
}

static boolean any_path_exists( _str list, _str sep = ' ' )
{
   _str p;

   //say('checking list "'list'"');
   while ( length( list ) )
   {
      pos( '^((?:(?:"[^"]*")?(?:[^\'sep'"]+)?)*)', list, 1, 'U' );
      p = substr( list, pos( 'S' ), pos( '' ) );
      if ( path_exists( p ) )
      {
         //say('  YES path "'p'" exists');
         return true;
      }
      //say('  no  path "'p'" does not exist');
      list = substr( list, length( p ) + 1 );
      if ( pos( '^([\'sep']*)', list, 1, 'U' ) )
         list = substr( list, pos( 'S' ) + 1 );
   }

   return false;
}

void events_FindIn.on_load()
{
   int ii;
   int nodeIndex = 0;
   int nodeDepth = 0;
   int nodeStack[];
   boolean fSkipNodes = false;
   int cSkipDepth = 0;
   _str caption;
   _str expandedWhere;
   _str matchedPath = '';
   _str cwd = lowcase( strip_filename( _mdi._edit_window().p_buf_name, 'NE' ) );
//say( 'cwd='cwd );

   s_sWhere = '';
   s_sWildcards = '';
   s_sTreeMode = '';
   s_sIncr = '';

#ifdef USE_CUSTOM_TREESEARCH
   s_arrayIndexList._makeempty();
#endif

   ctlTree._TreeBeginUpdate( TREE_ROOT_INDEX );
   for ( ii = 0; ii < s_arrayTreeData._length(); ii++ )
   {
      caption = s_arrayTreeData[ii].caption;
      if ( caption == '>' )
      {
         if ( fSkipNodes )
            cSkipDepth++;
         nodeStack[nodeDepth] = nodeIndex;
         nodeDepth++;
      }
      else if ( caption == '<' )
      {
         if ( fSkipNodes )
         {
            cSkipDepth--;
            if ( cSkipDepth <= 0 )
               fSkipNodes = false;
         }
         nodeDepth--;
      }
      else if ( !fSkipNodes )
      {
         int showChildren = -1;
         if ( substr( caption, 1, 1 ) == '-' )
            showChildren = 0;
         else if ( substr( caption, 1, 1 ) == '+' )
            showChildren = 1;
         if ( showChildren >= 0 )
            caption = substr( caption, 2 );
         expandedWhere = MaybeAppendPathSep( ExpandEnvVars( s_arrayTreeData[ii].where ) );

         if ( expandedWhere == '' ||
              ( !def_findin_no_path_check &&
                ( ( substr( expandedWhere, 1, 1 ) == '<' && substr( expandedWhere, length( expandedWhere ) - 1, 2 ) == '>\' ) ||
                  any_path_exists( expandedWhere ) ) ) )
         {
            nodeIndex = ctlTree._TreeAddItem( nodeDepth ? nodeStack[nodeDepth - 1] : TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, showChildren, 0 );
            ctlTree._TreeSetUserInfo( nodeIndex, ii );

#ifdef USE_CUSTOM_TREESEARCH
            s_arrayIndexList[s_arrayIndexList._length()] = nodeIndex;
#endif

//say( 'where='expandedWhere );
            if ( pos( expandedWhere, cwd, 1, 'I' ) == 1 )
            {
               int expandIndex = nodeIndex;
               loop
               {
                  expandIndex = ctlTree._TreeGetParentIndex( expandIndex );
                  if ( expandIndex == TREE_ROOT_INDEX )
                     break;
//say( 'expanding 'caption );
                  ctlTree._TreeSetInfo( expandIndex, 1 );
               }

               if ( length( matchedPath ) < length( expandedWhere ) )
               {
                  matchedPath = expandedWhere;
                  ctlTree._TreeSetCurIndex( nodeIndex );
               }
            }
         }
         else
         {
            if ( showChildren >= 0 )
            {
               fSkipNodes = true;
               cSkipDepth = 0;
            }
         }
      }
   }
   ctlTree._TreeEndUpdate( TREE_ROOT_INDEX );
}

void events_FindIn.on_resize()
{
   int containerW = _dx2lx( SM_TWIP, p_active_form.p_client_width );
   int containerH = _dy2ly( SM_TWIP, p_active_form.p_client_height );
   int border = ctlTree.p_x;

   ctlTree.p_height = max( 1200, containerH - ( border * 3 ) - ctllabelWhere.p_height );
   ctlTree.p_width = max( 1200, containerW - ( border * 3 + ctlcommandOk.p_width ) );

   ctlcommandOk.p_x = border + ctlTree.p_width + border;
   ctlcommandCancel.p_x = ctlcommandOk.p_x;

   ctllabelDivider.p_x = 0 - border;
   ctllabelDivider.p_y = ctlTree.p_y + ctlTree.p_height + border;
   ctllabelDivider.p_width = border + containerW + border;

   ctllabelWhere.p_x = ctlTree.p_x;
   ctllabelWhere.p_y = ctlTree.p_y + ctlTree.p_height + ( border * 2 );
   ctllabelWhere.p_width = containerW - ( ctllabelWhere.p_x + 240 );
}

void ctlcommandOk.lbutton_up()
{
   int iSel = ctlTree._TreeCurIndex();
   if ( iSel >= 0 )
   {
      int ii = ctlTree._TreeGetUserInfo( iSel );
      _str where = ExpandEnvVars( s_arrayTreeData[ii].where );

      if ( where != '' )
      {
         s_sWhere = where;
         s_sWildcards = s_arrayTreeData[ii].wildcards;
         s_sTreeMode = s_arrayTreeData[ii].tree_mode;
         if ( s_sTreeMode == '' )
            s_sTreeMode = '+t';
         if ( s_sTreeMode != '' )
            s_sTreeMode = s_sTreeMode' ';
         EscapeWindow();
      }
   }
}

/**
 * @return _str   Returns the first line of selected text as a string.
 */
static _str GetSelectedText()
{
   if ( _isnull_selection() )
      return '';

   _str str;
   int mark_locked = 0;
   if ( _select_type( '', 'S' ) == 'C' )
   {
      mark_locked = 1;
      _select_type( '', 'S', 'E' );
   }
   filter_init();
   filter_get_string( str );
   filter_restore_pos();
   if ( mark_locked )
   {
      _select_type( '', 'S', 'C' );
   }
   return str;
}

/**
 * @return _str   Returns the word under the cursor.
 */
_str WordUnderCursor()
{
   typeless old_pos, old_mark;
   save_pos( old_pos );
   save_selection( old_mark );
   _str ch = get_text( -1 );
   if ( _isSpaceChar( ch ) )
      left();
   select_whole_word();
   _str str = GetSelectedText();
   restore_selection( old_mark );
   restore_pos( old_pos );
   if ( !pos( '^[A-Za-z_0-9~$]', str, 1, 'U' ) ) str = ''; // If the first character isn't a word character, that's not a 'word' for our purposes here.
   return str;
}

/**
 * @return _str   Returns the file name under the cursor.
 */
static _str FileUnderCursor()
{
   _str regex_filename_nospaces = '([^ \t;<>"]+)';
   _str regex_filename_quoted = '"([^"*?<>]+)"';

   int iCursor = _text_colc( p_col, 'P' );
   _str regex;
   _str line;
   get_line( line );

   int iAttempt;
   for ( iAttempt = 0; iAttempt < 2; iAttempt++ )
   {
      switch ( iAttempt )
      {
      case 0:  regex = regex_filename_quoted; break;
      case 1:  regex = regex_filename_nospaces; break;
      default: break;
      }

      int ii;
      for ( ii = 1; ii <= length( line ); )
      {
         int iMatch = pos( regex, line, ii, 'U' );
         if ( !iMatch )
            break;
         if ( iCursor >= iMatch && iCursor <= iMatch + pos( '' ) )
            return substr( line, iMatch, pos( '' ) );
         ii = iMatch + pos( '' );
      }
   }

   return '';
}

/**
 * Gets text to search for.  If text is selected, the first line of selected
 * text is used.  Otherwise the word under the cursor is used.  Otherwise if
 * <i>fMaybePrompt</i> is true it prompts for text to search for.
 *
 * @param fMaybePrompt        When true and search text could not be
 *                            determined, this prompts the user to enter text
 *                            to search for.
 * @param options             In/out parameter, options to use for the search.
 * @param whereDescription    String to show in the prompt, so the user has
 *                            some idea where will be searched.
 *
 * @return _str               Returns text to search for, or ''.
 */
static _str TextToFind( boolean fMaybePrompt, _str& options, _str whereDescription = '' )
{
   _str str = '';

   if ( !_isnull_selection() )
      str = GetSelectedText();
   else
   {
      //str = WordUnderCursor();
      int x1;
      str = cur_word(x1);
   }

   if ( fMaybePrompt && str :== '' )
   {
      if ( whereDescription == '' )
         whereDescription = '';
      else
         whereDescription = ' in 'whereDescription;

      str = show( "-modal -mdi -xy form_FindIn_What", whereDescription );
      options = s_sOptions;
   }

   return str;
}

/**
 * Shows a dialog with a tree list of the paths from the s_arrayTreeData
 * table.  The closest match to the current working directory is initially
 * selected.
 *
 * <p>This is also responsible for translating the various special wildcards
 * from the s_arrayWildcardKeywords table.
 *
 * @param where         [out] Where to search.
 * @param wildcards     [out] File name wildcards to use.
 * @param treemode      [out] Recursive prefix string (+t or -t).
 */
static void GetCustomSearchLocation( _str& where, _str& wildcards, _str& treemode )
{
   show( "-modal -mdi -xy form_FindIn" );

   where = s_sWhere;
   wildcards = s_sWildcards;
   treemode = s_sTreeMode;

   if ( lowcase( where ) == '<prompt>' )
   {
      where = '';
      get_string( where, 'Enter directory to search in:', FILE_ARG );
      where = maybe_quote_filename( where );
   }

   int ii;
   for ( ii = 0; ii < s_arrayWildcardKeywords._length(); ii++ )
   {
      if ( lowcase( wildcards ) == s_arrayWildcardKeywords[ii].keyword )
      {
         wildcards = s_arrayWildcardKeywords[ii].replaceWith;
         break;
      }
   }
}

static _str TransformWhere( int mode, _str where, _str treemode = '', int indexWhere = -1 )
{
   if ( indexWhere < 0 )
   {
      indexWhere = 0;
      if ( substr( where, 1, 1 ) == '@' )
         indexWhere = find_index( substr( where, 2 ), PROC_TYPE|COMMAND_TYPE );
   }

   switch ( lowcase( where ) )
   {
   case 'b':   where = '"'MFFIND_BUFFER'"'; break;
   case 'd':   where = '"'MFFIND_BUFFER_DIR'"'; break;
   case 'f':   where = '"<Current Function>"'; break;
   case 'o':   where = '"'MFFIND_BUFFERS'"'; break;
   case 'p':   where = '"'MFFIND_PROJECT_FILES'"'; break;
   case 'w':   where = '"'MFFIND_WORKSPACE_FILES'"'; break;

   default:
      if ( indexWhere )
         where = call_index( mode, indexWhere );
      if ( mode == 1 )
         where = treemode :+ where;
   }

   if ( mode == 0 && pos( '^"(<.*>)"$', where, 1, 'U' ) )
      where = substr( where, pos( 'S1' ), pos( '1' ) );

   return where;
}

/**
 * FindIn - Lists all occurences of text in the specific place(s).
 *
 * @param where      Indicates where to search:
 * <dl>
 * <dt>'f'</dt><dd>In the current function.</dd>
 * <dt>'b'</dt><dd>In the current buffer.</dd>
 * <dt>'d'</dt><dd>In the current buffer's directory.</dd>
 * <dt>'o'</dt><dd>In the open buffers.</dd>
 * <dt>'p'</dt><dd>In the project files.</dd>
 * <dt>'w'</dt><dd>In the workspace files.</dd>
 * <dt>'@function'</dt><dd>Invokes 'function(1)' to get string indicating
 * where to search, and invokes 'function(0)' to get display string
 * desribing where to search (which is shown in the "Enter text to search for"
 * dialog). For example GetCheckedOutFileList(1) might return a list of
 * checked out files, and GetCheckedOutFileList(0) might return "checked out
 * files".</dd>
 * <dt>Otherwise</dt><dd>In the specified files/directories (space
 * delimited).</dd>
 * </dl>
 * @param what       Text to search for, or empty string to prompt for text.
 * @param options    Optional additional search options.
 * @param wildcards  Optional wildcards (space delimited) to search for if
 *                   <i>where</i> includes directories.
 */
_command void FindIn( _str where = '', _str what = '', _str options = 'E', _str wildcards = '' ) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   int indexWhere = 0;
   _str treemode = '';

   if ( !_isEditorCtl( false ) )
   {
      message( 'Requires editor control.' );
      return;
   }

   if ( substr( where, 1, 1 ) == '@' )
   {
      indexWhere = find_index( substr( where, 2 ), PROC_TYPE|COMMAND_TYPE );
      if ( !indexWhere )
      {
         _message_box( nls( 'Unable to find function "%s".', substr( where, 2 ) ) );
         return;
      }
   }
   else if ( where == '' || where == WHERE_PROMPT )
   {
      GetCustomSearchLocation( where, wildcards, treemode );
      if ( where == '' )
      {
         message( 'Nowhere to search.' );
         return;
      }
   }

   if ( what :== '' )
   {
      _str whereDescription = '';
      switch ( lowcase( where ) )
      {
      case 'b':   whereDescription = 'current buffer'; break;
      case 'd':   whereDescription = "current buffer's directory"; break;
      case 'f':   whereDescription = 'current function'; break;
      case 'o':   whereDescription = 'all buffers'; break;
      case 'p':   whereDescription = 'project files'; break;
      case 'w':   whereDescription = 'workspace files'; break;

      default:
         if ( indexWhere )
            whereDescription = call_index( 0, indexWhere );
         else if ( length( where ) < 32 )
            whereDescription = where;
         break;
      }

      what = TextToFind( true, options, whereDescription );
      if ( what :== '' )
      {
         message( 'Nothing to find.' );
         return;
      }
   }

   clear_highlights();

   where = TransformWhere( 1, where, treemode, indexWhere );

   typeless old_pos, old_mark;
   _save_pos2( old_pos );
   save_selection( old_mark );

   boolean fOk = false;
   boolean fHighlight = false;

   switch ( where )
   {
   case '"<Current Function>"':
      if ( select_proc() == 0 )
      {
         list_all_occurrences( what, 'M'options, 0, auto_increment_grep_buffer() );
         highlight_all_occurrences( what, 'M'options );
      }
      else
      {
         message( 'Not in a function.' );
      }
      break;
   case '"'MFFIND_BUFFER'"':
      list_all_occurrences( what, options, 0, auto_increment_grep_buffer() );
      highlight_all_occurrences( what, options );
      break;
   default:
      _mffind( what, options, where,
               '', /*notused*/
               MFFIND_GLOBAL|MFFIND_THREADED, /*mfflags*/
               false, /*searchProjectFiles*/
               false, /*searchWorkspaceFiles*/
               wildcards, /*wildcards*/
               '', /*file_exclude*/
               false, /*files_delimited_with_pathsep*/
               auto_increment_grep_buffer() /*grep_id*/
               );
      break;
   }

   restore_selection( old_mark );
   _restore_pos2( old_pos );
}

/**
 * Finds text in the current function.
 * @see FindIn
 */
_command void FindInFunction() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   FindIn( 'f' );
}

/**
 * Finds text in the current file.
 * @see FindIn
 */
_command void FindInThisFile() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   FindIn( 'b' );
}

/**
 * Finds text in the currently open file buffers.
 * @see FindIn
 */
_command void FindInOpenBuffers() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   FindIn( 'o' );
}

/**
 * Finds text in files that are in the same directory as the current file.
 * @see FindIn
 */
_command void FindInFileDirectory() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   FindIn( 'd' );
}

/**
 * Finds text in files in the current project.
 * @see FindIn
 */
_command void FindInProjectFiles() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   FindIn( 'p' );
}

/**
 * Finds text in files in the current workspace.
 * @see FindIn
 */
_command void FindInWorkspaceFiles() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   FindIn( 'w' );
}

/**
 * Opens the file under the cursor:
 * <ul>
 *    <li>Tries to load the file as stated.
 *    <li>Tries to find the file in the current project.
 *    <li>Tries to find the file in the current workspace.
 *    <li>Tries to find the file along the workspace's include paths.
 * </ul>
 */
_command void OpenFileAtCursor() name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY)
{
   // Get file name under cursor.
   _str ln = '';
   _str toOpen = FileUnderCursor();
   toOpen = strip( stranslate( toOpen, '', '"' ), 'T' );
   if ( length( toOpen ) )
   {
      // Try to parse out a line number.
      if ( pos( '(:?[ \t]*(?:\((\:i)\))?)$', toOpen, 1, 'U' ) )
      {
         if ( pos( 'S2' ) )
            ln = substr( toOpen, pos( 'S2' ), pos( '2' ) );
         toOpen = substr( toOpen, 1, pos( 'S' ) - 1 );
      }
   }
   if ( !length( toOpen ) )
   {
      message( 'No file name at cursor.' );
      return;
   }

   // If the file doesn't exist as named, try to find it in the workspace.
   message( 'Checking for file "'toOpen'"...' );
   boolean isFound = file_exists( absolute( toOpen, _file_path( p_buf_name ) ) );
   if ( !isFound )
   {
      _str notFound = toOpen;
      if ( _workspace_filename != '' )
      {
         message( 'Searching project/workspace for file "'toOpen'"...' );
         toOpen = _ProjectWorkspaceFindFile( toOpen );
         isFound = ( toOpen != '' );
      }

      if ( !isFound )
      {
         message( 'File "'notFound'" does not exist.' );
         return;
      }
   }

   // Try to open the file.
   push_bookmark();
   message( 'Opening file "'toOpen'"...' );
   int status = edit( maybe_quote_filename( toOpen ) );
   if ( status )
   {
      pop_bookmark();
      _message_box( get_message( status ) );
      message( '' );
      return;
   }
   message( '' );

   // If there was a line number, go to that line.
   if ( ln != '' )
   {
      p_line = (int)ln;
      set_scroll_pos( 0, p_height * 2 / 5 );
   }
}

static int s_timerClearHighlights = -1;
static void TimerCallback_ClearHighlights()
{
   if ( s_timerClearHighlights >= 0 )
   {
      _kill_timer( s_timerClearHighlights );
      s_timerClearHighlights = -1;
   }
   clear_highlights();
}

/**
 * Find the header or source file associated with the current file in the
 * editor and open it.
 *
 * @param fFindWordUnderCursor   Optionally finds the word under the cursor
 *                               after opening the file.
 *
 * @see edit_associated_file
 */
_command void EditAssociatedFile( boolean fFindWordUnderCursor = true ) name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY)
{
   _str word = WordUnderCursor();
   _str buf_name = p_buf_name;
   edit_associated_file();
   if ( fFindWordUnderCursor && word != '' && buf_name != p_buf_name )
   {
      top();
      search( word, "E#" );
      s_timerClearHighlights = _set_timer( 1000, TimerCallback_ClearHighlights );
   }
}



_command void runsg() name_info(',')
{
   _str s1 = TextToFind(true, '');
   if (s1 != '') {
      concur_command("sgrep " :+ s1 :+ " *.e");
   }
}

