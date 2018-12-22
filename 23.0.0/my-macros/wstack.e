
#include "slick.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)


struct stack_s {
   int s_top;
   int s_bottom;
   int max_len;
   boolean wrap;
   typeless stack[];
};


void init_stack(stack_s & stk, int smax, boolean swrap, typeless val)
{
   stk.stack._makeempty();
   stk.s_top = stk.s_bottom = 0;
   stk.max_len = smax;
   stk.wrap = swrap;
   stk.stack[0] = val;  // set the stack item type
}


void reset_stack(stack_s & stk, typeless val)
{
   init_stack(stk, stk.max_len, stk.wrap,val);
}


// nothing

boolean push_stack(stack_s & stk, typeless & val)
{
   // the stack is allowed to increase in size until it reaches max len
   // stack.top always points at the latest item
   // stack.bottom points at the item PRECEDING the oldest item
   int temp = stk.s_top + 1;
   if (temp >= stk.stack._length()) {
      if (stk.stack._length() >= stk.max_len) {
         temp = 0;
      }
   }
   if (temp == stk.s_bottom) {
      // the stack is full, see if we can remove the oldest
      if (!stk.wrap) {
         return false;
      }
      if (++stk.s_bottom >= stk.stack._length()) {
         stk.s_bottom = 0;
      }
   }
   stk.stack[temp] = val;
   stk.s_top = temp;
   return true;
}


boolean pop_stack(stack_s & stk, typeless & val)
{
   if (stk.s_top == stk.s_bottom) {
      return false;
   }
   val = stk.stack[stk.s_top];
   if (stk.s_top == 0) {
      stk.s_top = stk.stack._length() - 1;
   }
   else {
      --stk.s_top;
   }
   return true;
}


int get_stack_entry_distance(stack_s & stk, int sx)
{
   if (sx <= stk.s_top) {
      return stk.s_top - sx + 1;
   } else {
      return stk.s_top + stk.stack._length() - sx;
   }
   
}
int get_prev_stack_entry_index(stack_s & stk, int now)
{
   if (now == 0) {
      now = stk.stack._length() - 1;
   } else {
      --now;
   }
   if (now == stk.s_bottom) {
      // the s_bottom entry is always empty and there might be more than one
      // empty entry
      return stk.s_top;
   }
   return now;
}


int get_next_stack_entry_index(stack_s & stk, int now)
{
   if (now == stk.s_top) {
      now = stk.s_bottom;
   }
   if (++now >= stk.stack._length()) {
      return 0;
   }
   return now;
}

#define STACK_CALLBACK_SHOW_ITEM 0
#define STACK_CALLBACK_ERROR 1
#define STACK_CALLBACK_RESET 2


/**
 *  
 *  
 * 
 * @author Administrator (20/04/2008)
 * 
 * @param stk 
 */
void cycle_stack(stack_s & stk, _str callback_name)
{
   int lpos,k,sx;
   int start_line = _mdi.p_child.p_line;
   int start_buf_id = _mdi.p_child.p_buf_id;
   int start_col = _mdi.p_child.p_col;
   boolean restart = true;

   int nx = find_index(callback_name, COMMAND_TYPE);
   if (nx == 0) {
      message('Call back function "' :+ callback_name :+ '" not found');
      return;
   }

   while (true) {
      if (restart) {
         restart = false;
         sx = stk.s_top;
         if (sx == stk.s_bottom) {
            message('Stack empty');
            return;
         }
      }

      lpos = get_stack_entry_distance(stk, sx);
      // if there is one item on the stack, bottom is a "distance" of 2 from top
      if (lpos >= get_stack_entry_distance(stk, stk.s_bottom)) {
         // something is wrong, tell the caller
         call_index(STACK_CALLBACK_ERROR, stk, sx,'', nx);
         return;
      }

      _str ms = 'Stack item ' :+ lpos :+ '/' :+ stk.stack._length()-1 :+ ' ';
      //call_index(nx, STACK_CALLBACK_SHOW_ITEM, stk, sx, ms);
      if (call_index(STACK_CALLBACK_SHOW_ITEM, stk, sx, ms, nx) != 0)
         return;

      _str key = get_event('N');   // refresh screen and get a key
      _str keyt = event2name(key);

      switch (keyt) {
         case 'UP' :
         case 'RIGHT' :
         case 'C-F5' :
            sx = get_next_stack_entry_index(stk, sx);
            break;

         case 'DOWN' :
         case 'LEFT' :
         case 'F5' :
            sx = get_prev_stack_entry_index(stk, sx);
            break;

         case 'C-S-END' :
            // user requested stack reset
            call_index( STACK_CALLBACK_RESET, stk, 0, '', nx);
            // fall through
         case 'ESC' :
            edit('+Q +BI ' :+ start_buf_id);
            _mdi.p_child.p_line = start_line;
            _mdi.p_child.p_col = start_col;
            return;
         default:
            return;
      }
   }
}

// nothing 2

