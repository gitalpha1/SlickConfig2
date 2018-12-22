

// For the first form
//#define GFILEMAN_FORM_NAME GFilemanForm1
//#define GFILEMAN_FORM_CAPTION 'GFileman1'
//#define P_EVENTTAB(x) 

// For the second form etc
//#define GFILEMAN_FORM_NAME GFilemanForm2
//#define GFILEMAN_FORM_CAPTION 'GFileman2'
//#define P_EVENTTAB(x) p_eventtab=x;


_form GFILEMAN_FORM_NAME {
   p_backcolor=0x80000005;
   p_border_style=BDS_SIZABLE;
   p_caption=GFILEMAN_FORM_CAPTION;
   p_CaptionClick=true;
   p_forecolor=0x80000008;
   p_height=5460;
   p_tool_window=true;
   p_visible=false;
   p_width=5910;
   p_x=15390;
   p_y=4800;
   p_eventtab=GFilemanForm1;
   p_eventtab2=_toolwindow_etab2;
   //p_eventtab2=_toolbar_etab2;
   _list_box ctllist_view1_col1 {
      p_border_style=BDS_NONE;
      p_font_name='Tahoma';
      p_font_size=10;
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_width=240;
      p_x=540;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col1)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view1_col2 {
      p_border_style=BDS_NONE;
      p_font_name='Tahoma';
      p_font_size=10;
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_width=330;
      p_x=900;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col2)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view1_col3 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_width=255;
      p_x=1335;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col3)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view2_col1 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_visible=false;
      p_width=240;
      p_x=540;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col1)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view2_col2 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_visible=false;
      p_width=330;
      p_x=900;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col2)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view2_col3 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_visible=false;
      p_width=255;
      p_x=1335;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col3)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view3_col1 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_visible=false;
      p_width=240;
      p_x=540;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col1)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view3_col2 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_visible=false;
      p_width=330;
      p_x=900;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col2)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view3_col3 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_visible=false;
      p_width=255;
      p_x=1335;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col3)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view4_col1 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_visible=false;
      p_width=240;
      p_x=540;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col1)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view4_col2 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_visible=false;
      p_width=330;
      p_x=900;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col2)
      p_eventtab2=_ul2_listbox;
   }
   _list_box ctllist_view4_col3 {
      p_border_style=BDS_NONE;
      p_font_name='MS Sans Serif';
      p_height=705;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_NONE;
      p_tab_index=0;
      p_tab_stop=false;
      p_visible=false;
      p_width=255;
      p_x=1335;
      p_y=1335;
      P_EVENTTAB(GFilemanForm1.ctllist_view1_col3)
      p_eventtab2=_ul2_listbox;
   }
   _image ctlimage_listview_left_vert_bar1 {
      p_auto_size=false;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=300;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=2;
      p_tab_stop=false;
      p_value=0;
      p_width=120;
      p_x=585;
      p_y=2370;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_listview_right_vert_bar1 {
      p_auto_size=false;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=285;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=4;
      p_tab_stop=false;
      p_value=0;
      p_width=105;
      p_x=840;
      p_y=2385;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_listview_bottom_horiz_bar1 {
      p_auto_size=false;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=135;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=5;
      p_tab_stop=false;
      p_value=0;
      p_width=270;
      p_x=615;
      p_y=2685;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_listview_top_horiz_bar1 {
      p_auto_size=false;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=150;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=6;
      p_tab_stop=false;
      p_value=0;
      p_width=315;
      p_x=600;
      p_y=2220;
      p_eventtab2=_ul2_imageb;
   }
   _text_box ctltext1 {
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_completion=NONE_ARG;
      p_font_name='MS Sans Serif';
      p_forecolor=0x80000008;
      p_height=225;
      p_tab_index=8;
      p_tab_stop=false;
      p_text='ctltext1';
      p_width=2220;
      p_x=0;
      p_y=300;
      P_EVENTTAB(GFilemanForm1.ctltext1)
      p_eventtab2=_ul2_textbox;
   }
   _image ctlimage_listview_vert_sep_bar1 {
      p_auto_size=true;
      p_backcolor=0x000000FF;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=540;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=14;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=120;
      p_x=1260;
      p_y=2250;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_listview_vert_sep_bar2 {
      p_auto_size=true;
      p_backcolor=0x000000FF;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=540;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=14;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=120;
      p_x=1260;
      p_y=2250;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_listview_vert_sep_bar3 {
      p_auto_size=true;
      p_backcolor=0x000000FF;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=540;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=14;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=120;
      p_x=1260;
      p_y=2250;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_editbox1_left_vert_bar {
      p_auto_size=true;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=300;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=15;
      p_tab_stop=false;
      p_value=0;
      p_width=120;
      p_x=645;
      p_y=3135;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_editbox1_right_vert_bar {
      p_auto_size=true;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=285;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=16;
      p_tab_stop=false;
      p_value=0;
      p_width=105;
      p_x=900;
      p_y=3180;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_editbox1_bottom_horiz_bar {
      p_auto_size=true;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=135;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=17;
      p_tab_stop=false;
      p_value=0;
      p_width=270;
      p_x=675;
      p_y=3450;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_editbox1_top_horiz_bar {
      p_auto_size=true;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=150;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=18;
      p_tab_stop=false;
      p_value=0;
      p_width=315;
      p_x=660;
      p_y=2985;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_blackbox1_left_vert_bar {
      p_auto_size=true;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=300;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=20;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=120;
      p_x=1200;
      p_y=3165;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_blackbox1_right_vert_bar {
      p_auto_size=true;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=285;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=21;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=105;
      p_x=1455;
      p_y=3210;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_blackbox1_bottom_horiz_bar {
      p_auto_size=true;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=135;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=22;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=270;
      p_x=1230;
      p_y=3480;
      p_eventtab2=_ul2_imageb;
   }
   _image ctlimage_blackbox1_top_horiz_bar {
      p_auto_size=true;
      p_backcolor=0x00FF0000;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=150;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=true;
      p_style=PSPIC_DEFAULT;
      p_tab_index=23;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=315;
      p_x=1215;
      p_y=3015;
      p_eventtab2=_ul2_imageb;
   }
   _label blackbox1_title_label {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='';
      p_font_name='MS Sans Serif';
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=24;
      p_visible=false;
      p_width=1455;
      p_word_wrap=false;
      p_x=540;
      p_y=0;
   }
   _image scrollbar_slider_image {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=300;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=27;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=180;
      p_x=2460;
      p_y=660;
      p_eventtab2=_ul2_imageb;
   }

   _image scrollbar_horizontal_indicator_image {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=60;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=27;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=500;
      p_x=2460;
      p_y=660;
      p_eventtab2=_ul2_imageb;
   }


   _image scrollbar_button {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=360;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_HIGHLIGHTED_BUTTON;
      p_tab_index=30;
      p_tab_stop=false;
      p_value=0;
      p_visible=false;
      p_width=420;
      p_x=120;
      p_y=600;
      P_EVENTTAB(GFilemanForm1.scrollbar_button)
      p_eventtab2=_ul2_imageb;
   }
   _image options1_button {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=420;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_HIGHLIGHTED_BUTTON;
      p_tab_index=31;
      p_tab_stop=false;
      p_value=0;
      p_width=420;
      p_x=900;
      p_y=600;
      P_EVENTTAB(GFilemanForm1.options1_button)
      p_eventtab2=_ul2_imageb;
   }

   _image goback_button {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=420;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_HIGHLIGHTED_BUTTON;
      p_tab_index=34;
      p_tab_stop=false;
      p_value=0;
      p_width=420;
      p_x=1620;
      p_y=660;
      P_EVENTTAB(GFilemanForm1.goback_button)
      p_eventtab2=_ul2_imageb;
   }

   _image view1_ctlimage1 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=840;
      p_max_click=MC_DOUBLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=33;
      p_tab_stop=false;
      p_value=0;
      p_width=420;
      p_x=2700;
      p_y=1740;
      P_EVENTTAB(GFilemanForm1.view1_ctlimage1)
      p_eventtab2=_ul2_imageb;
   }

   _image view2_ctlimage1 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=840;
      p_max_click=MC_DOUBLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=33;
      p_tab_stop=false;
      p_value=0;
      p_width=420;
      p_x=2700;
      p_y=1740;
      p_eventtab = GFilemanForm1.view1_ctlimage1;
      p_eventtab2=_ul2_imageb;
   }

   _image view3_ctlimage1 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=840;
      p_max_click=MC_DOUBLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=33;
      p_tab_stop=false;
      p_value=0;
      p_width=420;
      p_x=2700;
      p_y=1740;
      p_eventtab = GFilemanForm1.view1_ctlimage1;
      p_eventtab2=_ul2_imageb;
   }

   _image view4_ctlimage1 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=840;
      p_max_click=MC_DOUBLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=33;
      p_tab_stop=false;
      p_value=0;
      p_width=420;
      p_x=2700;
      p_y=1740;
      p_eventtab = GFilemanForm1.view1_ctlimage1;
      p_eventtab2=_ul2_imageb;
   }

}


