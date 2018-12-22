/**
 * Written by: Rafi Cohen
 * Date      : 2005-05-20
 * Desc      :
 *
 * [UN]Higlight the word under the cursor:
 *    - if word under cursor isn't already highlighted - it will become highlighted for cur buffer only;
 *    - otherwise (i.e. if word under cursor is highlighted already) - it will become UNhighlighted for cur buffer only;
 *    both are done by using the same API/_command: 'hlWord'
 *
 * additional features:
 *    - supports multiple words (i.e. user can [UN]highlight diff. words);
 *      e.g. user can highlight 'wordA', then highlight 'wordB', then highlight 'wordC', then UNhighlight 'wordB';
 *           (so that at this point 'wordA' and 'wordC' are still highlighted), and so on.
 *
 *    - supports multiple buffers (i.e. user can [UN]highlight words in diff. buffers,
 *      and their state will not lost when user switches buffers)
 *
 *    - message displays number of times the given word has been [UN]highlighted
 *
 *    - if user asks to highlight a word, and word only found once - word will NOT become highlighted,
 *      and user will be informed.
 *
 *    - does not interfere with selected text AT ALL: user can still select/unselect text freely
 *
 *    - Current scope is the whole buffer
 *
 *    - word-match is for whole-word
 *
 * TODO (if need be):
 *    - add unhilightAllWords which will unhighlight all highlighted words in cur. buffer
 *
 *    - add unhilightAllWordsAllBufs which will unhighlight all highlighted words in all buffers
 *
 *    - restrict search to selected text (if selection exists), or scope (if no selection)
 *
 *    - pop up a list of current highlighted words, and their buffer name
 *      (if so - remember to monitor close-buffer events in order to remove from list)
 *
 *    - when called in highlight mode - pop up a list will all line-numbers where word has been found (p_RLine of each hit)
 *
 * Known issues:
 *    - highlighted words do NOT show up as highlighted ones if they are selected/inside a selected block;
 *      as a (temporary ?) solution, in order to still be able to distinguish selected words from select-highlighted words
 *      the highlight-color is set to also underscore the highlighted words.
 *
 *    - highlight is lost when VSE shuts down, or when buffer is closed & then re-loaded
 *
 *    - when restoring orig ColorIndex for a given word, the ColorIndex used is the one belongs to the first-char of that word
 *      (however - I could only think of one scenario where this might be an issue: select the first char of a word,
 *       highlight word, then UNhighlight; however - it worked fine, so no need to worry about this one).
 *
 *    - if this module is RE-loaded while there are highlighted words - user will not be able to UNhighlight then by calling 'hlWord':
 *      the reason is the fact that when this module is loaded, the array of cur. highlighted words (SHighlightInfo.m_sttarrHWI)
 *      gets reset/emptied;
 *      and from that moment on - from this module point of view - the current ColorIndex of these words
 *      (which is actually the highlight-ColorIndex) becomes their ORIGINAL color;
 *      and so - when user toggels highlight/UNhighlight word ColorIndex remains the same
 *      (i.e. 'changes' from highlight-ColorIndex to highlight-ColorIndex)
 *      ! maybe add a call to unhilightAllWordsAllBufs in 'definit' ... depends on execution order that VSE uses
 *        (i.e. first init vars (my guess, and if true -> will not work), or first execute 'definit'
 *
 *    - no-big-deal bug: if user highlights a given word, then modifies text of all highlight occurrences,
 *                       then the original word is still treated as an existing entry in the list of already-highlighted-word
 *                       (i.e. SHighlightInfo.m_sttarrHWI will still have an entry for the original word);
 *                       since it causes no harm I don't see a reason to do anything about it.
 *
 *    - users which have any their VSE colors set to use the same colors as the highligh-color used in this module
 *      will need to change the highligh-color to something else (this should be done in 'definit')
 *
 */
#include 'slick.sh'
#pragma option(strictreturn,on)
#pragma option(autodeclvars,off)
#pragma option(strictsemicolons,on)
#pragma option(strictparens,on)

/**
 * Holds properties for a given already-highlighted word
 */
static struct SHighlightWordInfo{
   /**
    * the word being highlighted
    */
   _str m_strWord;
   /**
    * the original ColorIndex of the highlighted word (i.e. before it has been changed to the highlighted ColorIndex)
    */
   int  m_nColorIndexOrig;
   /**
    * the buf-id (p_buf_id) of the highlighted word (so that user could switch buffers & then restore/unhighlight words correctly)
    */
   int  m_np_buf_id;
};

/**
 * Creates an instance of a SHighlightWordInfo struct, loads it with app. data & returns it to caller
 *
 * @param strWord         word to be highlighted
 *
 * @param nColorIndexOrig original/current word ColorIndex
 *
 * @return an instance of a SHighlightWordInfo struct as desc. above
 */
SHighlightWordInfo createHighlightWordInfoStt(_str strWord, int nColorIndexOrig)
{
   SHighlightWordInfo sttHWI;

         sttHWI.m_strWord         = strWord;
         sttHWI.m_nColorIndexOrig = nColorIndexOrig;
         sttHWI.m_np_buf_id       = p_buf_id;

   return(sttHWI);
}

/**
 * Struct to hold info req. by this module
 */
static struct SHighlightInfo{
  /**
   * array of words currenly highlighted
   */
   SHighlightWordInfo m_sttarrHWI[];

  /**
   * ColorIndex of the Color used to highlight words;
   * per Slick-C doc. there are only 255 Colors avail., so don't waste more than you need.
   */
   int                m_nColorIndexHighlight;
};

/**
 * An instance of the struct used to hold info req. by this module
 */
static SHighlightInfo G_sttHighlightInfo;


/**
 * Scans the array of already-highlighted words, looking for a match;
 * if match found - its index is returned; otherwise -1 is returned.
 *
 * @param strWord   one of the keys to look for when performing a match search;
 *                  contains the word itself.
 *
 * @param np_buf_id another one of the keys to look for when performing a match search;
 *                  contains the buf-id (p_buf_id).
 *
 * @return          if match found - its index is returned; otherwise -1 is returned.
 */
int getIndexInHighlightedWordsList(_str strWord, int np_buf_id = p_buf_id)
{
   int nIndex = -1, i=0;
   for (i = 0; i < G_sttHighlightInfo.m_sttarrHWI._length(); i ++) {
      if ( ! strcmp(G_sttHighlightInfo.m_sttarrHWI[i].m_strWord, strWord)
          &&
          G_sttHighlightInfo.m_sttarrHWI[i].m_np_buf_id == np_buf_id) {
         //G_sttHighlightInfo.m_sttarrHWI._deleteel(i);
         nIndex = i;
         break;
      }
   }
   return(nIndex);
}


/**
 * Used to make sure highlighted-color is only allocated once
 *
 * @return
 */
definit()
{
   // When definit is called, the expression arg(1) indicates whether the module was loaded with the load command
   // or when the editor initialized.
   //    - When a module is loaded, arg(1) returns 'L';
   //    - When the editor initialized, arg(1) returns a null string ("").
     if (true/*arg(1) == 'L'*/){
//say('Allocating highlighting ColorIndex');
        G_sttHighlightInfo.m_nColorIndexHighlight = _AllocColor();
        //_default_color(G_sttHighlightInfo.m_nColorIndexHighlight, _rgb(255, 255, 255)/*i.e. white*/, _rgb(0, 0, 0)/*i.e. black*/, F_STRIKE_THRU);
        _default_color(G_sttHighlightInfo.m_nColorIndexHighlight, _rgb(255, 255, 255)/*i.e. white*/, _rgb(0, 0, 0)/*i.e. black*/, F_UNDERLINE);
        //_default_color(G_sttHighlightInfo.m_nColorIndexHighlight, _rgb(255, 255, 255)/*i.e. white*/, _rgb(0, 0, 0)/*i.e. black*/);
        //_default_color(G_sttHighlightInfo.m_nColorIndexHighlight, 0xffffff, 0xFF0000);
        //_default_color(G_sttHighlightInfo.m_nColorIndexHighlight, 0xffffff, 0xFF0000, F_BOLD);
     }
}

/**
 * [UN]Highlight the word under the cursor;
 * can be safely used on multiple words and/or in multiple buffers
 *
 * @return
 */
_command hlWord() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int nStartCol; _str strWord = cur_word(nStartCol);
   //say('['strWord '] ' nStartCol);

   int nWordLen = length(strWord);
   if (nWordLen == 0) {
      _message_box('No word at cursor - aborting [un]highlighting.');
      return(0);
   }

   int nColorIndexToUse = -1;
   int nWordIndexInHighlightedWordsList = getIndexInHighlightedWordsList(strWord);
   if (nWordIndexInHighlightedWordsList > -1) {
      // UNhighlight mode
      nColorIndexToUse = G_sttHighlightInfo.m_sttarrHWI[nWordIndexInHighlightedWordsList].m_nColorIndexOrig;
   }
   else {
      // highlight mode
      SHighlightWordInfo sttHWI = createHighlightWordInfoStt(strWord, _GetTextColor());
      G_sttHighlightInfo.m_sttarrHWI[G_sttHighlightInfo.m_sttarrHWI._length()] = sttHWI;
      nColorIndexToUse = G_sttHighlightInfo.m_nColorIndexHighlight;
   }

   typeless tlP; save_pos(tlP); // save orig. position as search will change it
   top();                       // place cursor at first line and first column of buffer
   /*
      '<' (Default) Place cursor at beginning of string found.
      '+' (Default) Forward search.
      'E' (Default) Case sensitive search.
      'M' Search within visible mark.
      'N' (Default) Do not interpret search string as a regular search string.
      '@' No error message.
      'W' Limits search to words. Used to search and replace variable names.
          The default word characters are [A-Za-z0-9_$].
          To change the word characters for a specificextension, use the Extension Options dialog box ("Tools", "Configuration", "FileExtension Setup...",
          select the Advanced tab).

      Returns 0 if the search specified is found.
      Common return codes are STRING_NOT_FOUND_RC, INVALID_OPTION_RC, and INVALID_REGULAR_EXPRESSION_RC. On error, message is displayed.
   */
   int nSearchResult = search(strWord, "<+EN@W");
   //int nSearchResult = search(strWord, ">NI@CC");
   int nNumOfHits = 0;

   if (nSearchResult != 0) {
      _message_box('IMPOSSIBLE scenario ! search failed to find the word under the cursor after position set to top of buffer! Aborting.');
      return(0);
   }
   while ( nSearchResult == 0 )
   {
      nNumOfHits ++;

      _SetTextColor(nColorIndexToUse, nWordLen);

      // keep searching for additional hits
      nSearchResult = repeat_search();
   }

   restore_pos(tlP); // restore orig. position

   if (nWordIndexInHighlightedWordsList > -1) {
      // UNhighlight mode - remove entry after word has been UNhighlighted
      G_sttHighlightInfo.m_sttarrHWI._deleteel(nWordIndexInHighlightedWordsList);
   }

   if (nWordIndexInHighlightedWordsList < 0
       &&
       nNumOfHits == 1) {
      // Highlight mode but word only found once - notify user & UNhighlight
      hlWord();
      _message_box('Searched word ['strWord'] found only once; Aborting highlighting for that word.');
   }
   else {
      _str strAction = ((nWordIndexInHighlightedWordsList > -1) ? 'UNhighlighted' : 'Highlighted');
      message('Word ['strWord'] 'strAction' ['nNumOfHits'] times.');
      //sticky_message('Word ['strWord'] 'strAction' ['nNumOfHits'] times.');
   }
}

