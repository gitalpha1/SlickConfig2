

/*****************************************************************************
*  COPYRIGHT : This code is written by, and copyright to Graeme F Prentice.
*              You may not distribute this code in whole or in part or use it
*              in a commercial product without permission from the author in
*              writing.   
*****************************************************************************/


/******************************************************************************
*  $Revision: 1.3 $
******************************************************************************/


#include "slick.sh"
#include "GFilemanHdr.sh"

#pragma option(strictsemicolons,on)
#pragma option(strict,on)
#pragma option(autodecl,off)
#pragma option(strictparens,on)


defeventtab GFilemanInfoForm2;

_control TitleLabel;
_control FilenameLabel;
_control ctlpicture1;


static int find_longest_string_length( int ctlid, _str lines[] )
{
   int mx = 0;
   int k = lines._length();
   while (k--) {
      int j = ctlid._text_width(lines[k]);
      if ( j > mx) {
         mx = j;
      }
   }
   return mx;
}

static void set_text_window_size( popup_window_pos_data * dp, 
                                  int form_id,/*int border_form_id,*/_str data[]=null )
{
   _str lines[];
   lines[0] = data[0];
   int width = form_id.FilenameLabel._text_width( data[0] );
   int maxw = pix2scale(_screen_width()*2/3, form_id);
   if (width > maxw) {
      int chrs = length( data[0] );
      lines[0] = substr( data[0], 1, chrs/2 );
      lines[1] = substr( data[0], chrs/2+1, chrs - chrs/2 );

      width = find_longest_string_length( form_id.FilenameLabel, lines );
      if (width > maxw) {
         int blk = chrs/4;
         lines[0] = substr( data[0], 1, blk );
         lines[1] = substr( data[0], blk+1, blk );
         lines[2] = substr( data[0], blk*2+1, blk );
         lines[3] = substr( data[0], blk*3+1, chrs - blk*3 );
         width = find_longest_string_length( form_id.FilenameLabel, lines );
         if (width > maxw) {
            width = maxw;
            lines[3] = '......';
            lines[4] = substr( data[0], chrs - 39, 40 );
         }
      }
   }
   int k = 0;
   int num_lines = lines._length();

   form_id.FilenameLabel.p_caption = lines[0] :+ \r :+ \n;
   while (++k < num_lines) {
      form_id.FilenameLabel.p_caption =
      form_id.FilenameLabel.p_caption :+ lines[k] :+ \r :+ \n;
   }
   num_lines += 1;

   form_id.FilenameLabel.p_caption = form_id.FilenameLabel.p_caption :+
                                     file_date(data[0]) :+ ' ' :+ file_time(data[0]);

   width += pix2scale(4,form_id);
   form_id.p_width = width + form_id.TitleLabel.p_width + pix2scale(2,form_id);
   form_id.FilenameLabel.p_width = width;

   form_id.FilenameLabel.p_x = form_id.TitleLabel.p_width; //+ pix2scale(1,form_id);
   form_id.FilenameLabel.p_y = pix2scale(6,form_id);
   form_id.TitleLabel.p_x = 0;//pix2scale(1,form_id);
   form_id.TitleLabel.p_y = pix2scale(6,form_id);

   int ht = form_id.FilenameLabel._text_height() * num_lines;

   if (ht > pix2scale(300,form_id))
      ht = pix2scale(300,form_id);
   form_id.p_height = (ht+pix2scale(14,form_id));

   form_id.FilenameLabel.p_height = ht;
   form_id.TitleLabel.p_height = ht;

   if (dp->ref_x_is_left) {
      form_id.p_x = pix2scale(dp->ref_x,form_id);
   } else {
      form_id.p_x = pix2scale(dp->ref_x,form_id) - form_id.p_width;
   }

   if (dp->ref_y_is_top) {
      form_id.p_y = pix2scale(dp->ref_y,form_id);
   } else {
      form_id.p_y = pix2scale(dp->ref_y,form_id) - form_id.p_height;
   }

   form_id.ctlpicture1.p_x = pix2scale(1,form_id);
   form_id.ctlpicture1.p_y = pix2scale(1,form_id);
   form_id.ctlpicture1.p_height = form_id.p_height - pix2scale(2,form_id);
   form_id.ctlpicture1.p_width = form_id.p_width - pix2scale(2,form_id);;
}


void GFileman_show_file_info2(popup_window_pos_data * dp, _str data[]=null,boolean first_time = false)
{
   int orig_focus = _get_focus();
   int info_form_id = _find_object('GFilemanInfoForm2');
   if (info_form_id==0) {
      info_form_id = show('-xy GFilemanInfoForm2', 'file');
   }

   info_form_id.TitleLabel.p_font_name = "Microsoft Sans Serif";
   info_form_id.FilenameLabel.p_font_name = "Microsoft Sans Serif";
   info_form_id.TitleLabel.p_font_size = 8;
   info_form_id.FilenameLabel.p_font_size = 8;
   info_form_id.TitleLabel.p_backcolor = _rgb(255,230,242);
   info_form_id.FilenameLabel.p_backcolor = _rgb(255,230,242);
   info_form_id.ctlpicture1.p_backcolor = _rgb(255,230,242);

   if (!first_time) {
      set_text_window_size(dp, info_form_id, data);
   }
   info_form_id.p_visible = 1;
   if (orig_focus != 0)
      orig_focus._set_focus();
}


void GFileman_hide_file_info2(int x, int y)
{
   int info_form_id = _find_object('GFilemanInfoForm2');
   if (info_form_id!=0) {
      //info_form_id.p_visible = 0;
      info_form_id.p_width = 0;
      info_form_id.p_height = 0;
      info_form_id.p_x = x;
      info_form_id.p_y = y;
   }
}


void GFileman_destroy_file_info_form_if_any()
{
   int info_form_id = _find_object('GFilemanInfoForm2');
   if (info_form_id != 0) {
      info_form_id.p_visible = 0;
      info_form_id._delete_window();
   }
}



