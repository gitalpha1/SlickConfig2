

#include "slick.sh"



_form GFilemanBorderForm {
   p_backcolor=0x00000000;
   p_border_style=BDS_NONE;
   p_caption='GFilemanBorderForm';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=5520;
   p_width=5910;
   p_x=7215;
   p_y=2520;
}




// For the first form
#define GFILEMAN_FORM_NAME GFilemanForm1
#define GFILEMAN_FORM_CAPTION 'GFileman1'
#define P_EVENTTAB(x) 

#include 'GFilemanFormsInclude.sh'

//#undef P_EVENTTAB
//#define P_EVENTTAB(x) p_eventtab=x;
//
//
//
//
//// For the second form etc
//#undef GFILEMAN_FORM_NAME 
//#define GFILEMAN_FORM_NAME GFilemanForm2
//#undef GFILEMAN_FORM_CAPTION
//#define GFILEMAN_FORM_CAPTION 'GFileman2'
//
//#include 'GFilemanFormsInclude.sh'
//
//
//#undef GFILEMAN_FORM_NAME 
//#define GFILEMAN_FORM_NAME GFilemanForm3
//#undef GFILEMAN_FORM_CAPTION
//#define GFILEMAN_FORM_CAPTION 'GFileman3'
//
//#include 'GFilemanFormsInclude.sh'




_form GFilemanSetupForm {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='GFileman Options';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=6870;
   p_width=6975;
   p_x=8955;
   p_y=2160;
   p_eventtab=GFilemanSetupForm;
   _command_button ok_button {
      p_cancel=false;
      p_caption='OK';
      p_default=false;
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_height=330;
      p_tab_index=1;
      p_tab_stop=true;
      p_width=930;
      p_x=60;
      p_y=6270;
   }
   _command_button cancel_button {
      p_cancel=false;
      p_caption='Cancel';
      p_default=false;
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_height=315;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=825;
      p_x=4920;
      p_y=6270;
   }
   _command_button help_button {
      p_cancel=false;
      p_caption='Help';
      p_default=false;
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_height=315;
      p_tab_index=3;
      p_tab_stop=true;
      p_width=825;
      p_x=2880;
      p_y=6270;
   }
   _sstab ctlsstab1 {
      p_FirstActiveTab=0;
      p_backcolor=0x80000005;
      p_clip_controls=false;
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_forecolor=0x80000008;
      p_Grabbar=false;
      p_GrabbarLocation=SSTAB_GRABBARLOCATION_TOP;
      p_height=4920;
      p_MultiRow=SSTAB_MULTIROW_NONE;
      p_NofTabs=2;
      p_Orientation=SSTAB_OTOP;
      p_PaddingX=4;
      p_PaddingY=4;
      p_PictureOnly=false;
      p_tab_index=4;
      p_tab_stop=true;
      p_TabsPerRow=5;
      p_width=6990;
      p_x=0;
      p_y=780;
      p_eventtab2=_ul2_sstabb;
      _sstab_container  {
         p_ActiveCaption='General';
         p_ActiveEnabled=true;
         p_ActiveOrder=0;
         p_ActiveColor=0x80000008;
         p_ActiveToolTip='';
         _frame font_frame {
            p_backcolor=0x80000005;
            p_caption='File list';
            p_clip_controls=true;
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=1080;
            p_tab_index=1;
            p_width=2940;
            p_x=240;
            p_y=240;
            _text_box fileview_font_editbox {
               p_auto_size=true;
               p_backcolor=0x80000005;
               p_border_style=BDS_FIXED_SINGLE;
               p_completion=NONE_ARG;
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_forecolor=0x80000008;
               p_height=255;
               p_tab_index=1;
               p_tab_stop=true;
               p_width=2205;
               p_x=600;
               p_y=255;
               p_eventtab2=_ul2_textbox;
            }
            _text_box fileview_fontsize_editbox {
               p_auto_size=true;
               p_backcolor=0x80000005;
               p_border_style=BDS_FIXED_SINGLE;
               p_completion=NONE_ARG;
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_forecolor=0x80000008;
               p_height=255;
               p_tab_index=2;
               p_tab_stop=true;
               p_width=630;
               p_x=945;
               p_y=660;
               p_eventtab2=_ul2_textbox;
            }
            _label ctllabel3 {
               p_alignment=AL_LEFT;
               p_auto_size=false;
               p_backcolor=0x80000005;
               p_border_style=BDS_NONE;
               p_caption='Font :';
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_forecolor=0x80000008;
               p_height=240;
               p_tab_index=3;
               p_width=450;
               p_word_wrap=false;
               p_x=135;
               p_y=285;
            }
            _label ctllabel4 {
               p_alignment=AL_LEFT;
               p_auto_size=false;
               p_backcolor=0x80000005;
               p_border_style=BDS_NONE;
               p_caption='Font size :';
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_forecolor=0x80000008;
               p_height=240;
               p_tab_index=4;
               p_width=765;
               p_word_wrap=false;
               p_x=135;
               p_y=675;
            }
            _command_button Fileview_font_change_button {
               p_cancel=false;
               p_caption='Change';
               p_default=false;
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_height=285;
               p_tab_index=5;
               p_tab_stop=true;
               p_width=765;
               p_x=2055;
               p_y=645;
            }
         }
         _frame ctlframe1 {
            p_backcolor=0x80000005;
            p_caption='Active file edit box';
            p_clip_controls=true;
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=1080;
            p_tab_index=5;
            p_width=2940;
            p_x=240;
            p_y=1530;
            _text_box active_file_font_name_editbox {
               p_auto_size=true;
               p_backcolor=0x80000005;
               p_border_style=BDS_FIXED_SINGLE;
               p_completion=NONE_ARG;
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_forecolor=0x80000008;
               p_height=255;
               p_tab_index=1;
               p_tab_stop=true;
               p_width=2205;
               p_x=600;
               p_y=255;
               p_eventtab2=_ul2_textbox;
            }
            _text_box active_file_font_size_editbox {
               p_auto_size=true;
               p_backcolor=0x80000005;
               p_border_style=BDS_FIXED_SINGLE;
               p_completion=NONE_ARG;
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_forecolor=0x80000008;
               p_height=255;
               p_tab_index=2;
               p_tab_stop=true;
               p_width=720;
               p_x=600;
               p_y=675;
               p_eventtab2=_ul2_textbox;
            }
            _label ctllabel14 {
               p_alignment=AL_LEFT;
               p_auto_size=false;
               p_backcolor=0x80000005;
               p_border_style=BDS_NONE;
               p_caption='Font :';
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_forecolor=0x80000008;
               p_height=240;
               p_tab_index=3;
               p_width=450;
               p_word_wrap=false;
               p_x=135;
               p_y=285;
            }
            _label ctllabel15 {
               p_alignment=AL_LEFT;
               p_auto_size=false;
               p_backcolor=0x80000005;
               p_border_style=BDS_NONE;
               p_caption='Size :';
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_forecolor=0x80000008;
               p_height=240;
               p_tab_index=4;
               p_width=420;
               p_word_wrap=false;
               p_x=135;
               p_y=675;
            }
            _command_button active_file_editbox_font_change_button {
               p_cancel=false;
               p_caption='Change';
               p_default=false;
               p_font_bold=false;
               p_font_italic=false;
               p_font_name='MS Sans Serif';
               p_font_size=8;
               p_font_underline=false;
               p_height=285;
               p_tab_index=5;
               p_tab_stop=true;
               p_width=765;
               p_x=2055;
               p_y=675;
            }
         }
         _combo_box ctlcombo_filename_display_order {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_case_sensitive=false;
            p_completion=NONE_ARG;
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=285;
            p_style=PSCBO_EDIT;
            p_tab_index=6;
            p_tab_stop=true;
            p_width=2775;
            p_x=240;
            p_y=3630;
            p_eventtab2=_ul2_combobx;
         }
         _label ctllabel17 {
            p_alignment=AL_LEFT;
            p_auto_size=false;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption='Filename display order';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=240;
            p_tab_index=7;
            p_width=1590;
            p_word_wrap=false;
            p_x=255;
            p_y=3375;
         }
         _check_box ctlcheck_show_shortcuts_in_col1 {
            p_alignment=AL_LEFT;
            p_backcolor=0x80000005;
            p_caption='Show shortcut keys';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=240;
            p_style=PSCH_AUTO2STATE;
            p_tab_index=8;
            p_tab_stop=true;
            p_value=0;
            p_width=2310;
            p_x=4095;
            p_y=315;
         }
         _text_box shortcut_key_col1_width_editbox {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=255;
            p_tab_index=16;
            p_tab_stop=true;
            p_width=480;
            p_x=4095;
            p_y=1020;
            p_eventtab2=_ul2_textbox;
         }
         _label ctllabel18 {
            p_alignment=AL_LEFT;
            p_auto_size=false;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption='Shortcut key column width';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=255;
            p_tab_index=17;
            p_width=2025;
            p_word_wrap=false;
            p_x=4695;
            p_y=1050;
         }
         _check_box selection_indicator_checkbox {
            p_alignment=AL_LEFT;
            p_backcolor=0x80000005;
            p_caption='Highlight with block';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=300;
            p_style=PSCH_AUTO2STATE;
            p_tab_index=18;
            p_tab_stop=true;
            p_value=0;
            p_width=1710;
            p_x=240;
            p_y=2880;
         }
         _check_box ctlcheck_show_shortcuts_on_demand {
            p_alignment=AL_LEFT;
            p_backcolor=0x80000005;
            p_caption='Show shortcuts on demand';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=240;
            p_style=PSCH_AUTO2STATE;
            p_tab_index=19;
            p_tab_stop=true;
            p_value=0;
            p_width=2220;
            p_x=4095;
            p_y=660;
         }
      }
      _sstab_container  {
         p_ActiveCaption='Layout';
         p_ActiveEnabled=true;
         p_ActiveOrder=1;
         p_ActiveColor=0x80000008;
         p_ActiveToolTip='';
         _text_box TooltipPercentEditbox {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=255;
            p_tab_index=1;
            p_tab_stop=true;
            p_text='50';
            p_width=495;
            p_x=225;
            p_y=585;
            p_eventtab2=_ul2_textbox;
         }
         _label ctllabel5 {
            p_alignment=AL_LEFT;
            p_auto_size=false;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption='Info Tooltip Activation Point';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=300;
            p_tab_index=2;
            p_width=2040;
            p_word_wrap=false;
            p_x=225;
            p_y=315;
         }
         _label ctllabel6 {
            p_alignment=AL_LEFT;
            p_auto_size=false;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption='Percent';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=240;
            p_tab_index=3;
            p_width=780;
            p_word_wrap=false;
            p_x=795;
            p_y=615;
         }
         _text_box left_col_width_ctltext {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=255;
            p_tab_index=4;
            p_tab_stop=true;
            p_width=480;
            p_x=225;
            p_y=1110;
            p_eventtab2=_ul2_textbox;
         }
         _label ctllabel10 {
            p_alignment=AL_LEFT;
            p_auto_size=false;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption='Goback line# col width : ';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=300;
            p_tab_index=5;
            p_width=1740;
            p_word_wrap=false;
            p_x=825;
            p_y=1110;
         }
         _text_box min_col_width_ctltext {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=255;
            p_tab_index=6;
            p_tab_stop=true;
            p_width=480;
            p_x=225;
            p_y=1470;
            p_eventtab2=_ul2_textbox;
         }
         _label ctllabel11 {
            p_alignment=AL_LEFT;
            p_auto_size=false;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption='Filename col min width : ';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=315;
            p_tab_index=7;
            p_width=1740;
            p_word_wrap=false;
            p_x=825;
            p_y=1470;
         }
         _text_box button_row1_y_offset_ctltext {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=255;
            p_tab_index=8;
            p_tab_stop=true;
            p_width=480;
            p_x=225;
            p_y=2445;
            p_eventtab2=_ul2_textbox;
         }
         _label ctllabel12 {
            p_alignment=AL_LEFT;
            p_auto_size=false;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption='Button row1 y offset :';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=300;
            p_tab_index=9;
            p_width=1740;
            p_word_wrap=false;
            p_x=825;
            p_y=2445;
         }
         _text_box filename_editbox_y_offset_ctltext {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=255;
            p_tab_index=10;
            p_tab_stop=true;
            p_width=480;
            p_x=225;
            p_y=3615;
            p_eventtab2=_ul2_textbox;
         }
         _label ctllabel13 {
            p_alignment=AL_LEFT;
            p_auto_size=false;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption='Filename edit box y offset :';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=300;
            p_tab_index=11;
            p_width=1980;
            p_word_wrap=false;
            p_x=825;
            p_y=3630;
         }
         _check_box button_row1_visible_ctlcheck {
            p_alignment=AL_LEFT;
            p_backcolor=0x80000005;
            p_caption='Button row1 visible';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=240;
            p_style=PSCH_AUTO2STATE;
            p_tab_index=12;
            p_tab_stop=true;
            p_value=0;
            p_width=1800;
            p_x=225;
            p_y=2145;
         }
         _check_box filename_editbox_visible_ctlcheck {
            p_alignment=AL_LEFT;
            p_backcolor=0x80000005;
            p_caption='Filename editbox visible';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=225;
            p_style=PSCH_AUTO2STATE;
            p_tab_index=13;
            p_tab_stop=true;
            p_value=0;
            p_width=2160;
            p_x=225;
            p_y=3270;
         }
         _check_box ctlcheck_filename_editbox_is_target {
            p_alignment=AL_LEFT;
            p_backcolor=0x80000005;
            p_caption='Filename editbox is target';
            p_font_bold=false;
            p_font_italic=false;
            p_font_name='MS Sans Serif';
            p_font_size=8;
            p_font_underline=false;
            p_forecolor=0x80000008;
            p_height=360;
            p_style=PSCH_AUTO2STATE;
            p_tab_index=14;
            p_tab_stop=true;
            p_value=0;
            p_width=2220;
            p_x=225;
            p_y=2880;
         }
      }
   }
   _combo_box ctlcombo_select_dialog {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_case_sensitive=false;
      p_completion=NONE_ARG;
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_forecolor=0x80000008;
      p_height=285;
      p_style=PSCBO_NOEDIT;
      p_tab_index=5;
      p_tab_stop=true;
      p_width=2100;
      p_x=1260;
      p_y=180;
      p_eventtab2=_ul2_combobx;
   }
   _label DialogSelectorLabel {
      p_alignment=AL_RIGHT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Form name :';
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_forecolor=0x80000008;
      p_height=240;
      p_tab_index=6;
      p_width=1140;
      p_word_wrap=false;
      p_x=60;
      p_y=240;
   }
   _command_button ShowFormButton {
      p_cancel=false;
      p_caption='Show form';
      p_default=false;
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_height=360;
      p_tab_index=7;
      p_tab_stop=true;
      p_width=915;
      p_x=3720;
      p_y=180;
   }
   _image top_separator_image {
      p_auto_size=false;
      p_backcolor=0x000000FF;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=120;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=8;
      p_value=0;
      p_width=495;
      p_x=180;
      p_y=5970;
      p_eventtab2=_ul2_imageb;
   }
   _command_button save_button {
      p_cancel=false;
      p_caption='Save';
      p_default=false;
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_height=330;
      p_tab_index=9;
      p_tab_stop=true;
      p_width=885;
      p_x=1200;
      p_y=6270;
   }
   _command_button exit_button {
      p_cancel=false;
      p_caption='Close';
      p_default=false;
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_height=315;
      p_tab_index=10;
      p_tab_stop=true;
      p_width=825;
      p_x=3930;
      p_y=6270;
   }
   _command_button UpdateFormsButton {
      p_cancel=false;
      p_caption='Update all forms';
      p_default=false;
      p_font_bold=false;
      p_font_italic=false;
      p_font_name='MS Sans Serif';
      p_font_size=8;
      p_font_underline=false;
      p_height=360;
      p_tab_index=11;
      p_tab_stop=true;
      p_width=1305;
      p_x=4830;
      p_y=180;
   }
}


_form GFilemanInfoForm2 {
   p_backcolor=0x00FF00FF;
   p_border_style=BDS_NONE;
   p_caption='File Infomation';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=5520;
   p_tool_window=true;
   p_width=5910;
   p_x=8220;
   p_y=2415;
   p_eventtab=GFilemanInfoForm2;
   _picture_box ctlpicture1 {
      p_auto_size=true;
      p_backcolor=0x000000FF;
      p_border_style=BDS_NONE;
      p_clip_controls=false;
      p_forecolor=0x000000FF;
      p_height=1620;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=5;
      p_value=0;
      p_width=3240;
      p_x=1020;
      p_y=2280;
      p_eventtab2=_ul2_picture;
      _label TitleLabel {
         p_alignment=AL_LEFT;
         p_auto_size=false;
         p_backcolor=0x0000FF00;
         p_border_style=BDS_NONE;
         p_caption='  File :';
         p_font_bold=false;
         p_font_italic=false;
         p_font_name='MS Sans Serif';
         p_font_size=8;
         p_font_underline=false;
         p_forecolor=0x00800080;
         p_height=360;
         p_tab_index=1;
         p_width=555;
         p_word_wrap=false;
         p_x=180;
         p_y=720;
      }
      _label FilenameLabel {
         p_alignment=AL_LEFT;
         p_auto_size=false;
         p_backcolor=0x0000FFFF;
         p_border_style=BDS_NONE;
         p_caption='ctllabel1';
         p_font_bold=false;
         p_font_italic=false;
         p_font_name='MS Sans Serif';
         p_font_size=8;
         p_font_underline=false;
         p_forecolor=0x00800080;
         p_height=420;
         p_tab_index=2;
         p_width=1740;
         p_word_wrap=false;
         p_x=1020;
         p_y=780;
      }
   }
}


_menu GFilemanButtonMenu {
}


_menu GFilemanViewXMid1RightClickMenu {
}




