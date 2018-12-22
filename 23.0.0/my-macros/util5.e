struct DIRINFO
{
   _str opts;
   _str dir;
   _str filespec;
};

_command void ssync() name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   int i;
   DIRINFO dir_list[];
   _str exclude_list = "";
   _str file_spec_default_list = "*.c;*.cc;*.cpp;*.cp;*.cxx;*.c++;*.h;*.hh;*.hpp;*.hxx;*.inl;*.e;*.sh;*.bat;*.cmd;*.php";

   dir_list._makeempty();

   // Always add main SE macros and build files.
   dinfo_add(dir_list, "-t", "c:/slm/slickedit2008");
   dinfo_add(dir_list, "+t", "c:/dev/smac/bin");

   _str projName = strip_filename(_project_name, 'PE');
   switch(projName)
   {
   case "SlickC":
      dinfo_add(dir_list, "+t", "c:/slm/slickedit2008");
      break;

   case "pixo9lrb":
      dinfo_add(dir_list, "+t", "c:/dev/smac/pixo9");
      dinfo_add(dir_list, "+t", "c:/dev/smac/dx9cap");
      dinfo_add(dir_list, "-t", "c:/Program Files (x86)/Microsoft DirectX SDK (November 2007)/Include", "d3d10*.h");
      dinfo_add(dir_list, "-t", "c:/Program Files (x86)/Microsoft DirectX SDK (November 2007)/Include", "d3dx10*.inl");
      dinfo_add(dir_list, "-t", "c:/Program Files (x86)/Microsoft DirectX SDK (November 2007)/Include", "DXGIType.h");

      exclude_list = "c:/dev/smac/pixo9/bin/compiler_0.5/";
      break;

   case "pixo9xlrb":
      dinfo_add(dir_list, "+t", "c:/dev/smac/pixo9x");
      dinfo_add(dir_list, "+t", "c:/dev/smac/dx9cap");
      dinfo_add(dir_list, "-t", "c:/Program Files (x86)/Microsoft DirectX SDK (November 2007)/Include", "d3d10*.h");
      dinfo_add(dir_list, "-t", "c:/Program Files (x86)/Microsoft DirectX SDK (November 2007)/Include", "d3dx10*.inl");
      dinfo_add(dir_list, "-t", "c:/Program Files (x86)/Microsoft DirectX SDK (November 2007)/Include", "DXGIType.h");

      exclude_list = "c:/dev/smac/pixo9x/bin/compiler_0.5/";
      break;

   case "d3dref10_1":
      dinfo_add(dir_list, "+t", "c:/dev/smac/d3dref10_1");
      break;

   case "Alpine":
      dinfo_add(dir_list, "+t", "c:/slm/alpine/alpine-src");
      break;

   default:
      _str msg = "ssync(mikesart.e): No dir_list specified for " projName ".";
      _message_box(msg, "", MB_OK | MB_ICONEXCLAMATION);
      return;
   }

   // Get list of current project files.
   int projectfiles_list:[];
   ssync_getprojectfilelist(_project_name, projectfiles_list);

   // Create our temporary view for insert_file_list().
   int filelist_view_id;
   int orig_view_id = _create_temp_view(filelist_view_id);

   // Split out default file spec list into an array.
   _str file_specs[];
   split(file_spec_default_list, ';', file_specs);

   // Do an insert_file_list() for every dir_list + file_spec entry.
   for(i = 0; i < dir_list._length(); i++)
   {
      int j;
      DIRINFO dirInfo = dir_list[i];

      if(dirInfo.filespec != "")
      {
         _str cmd = dirInfo.opts " " maybe_quote_filename(dirInfo.dir "/" dirInfo.filespec);

         insert_file_list("-v +a +p " cmd);
      }
      else
      {
         for(j = 0; j < file_specs._length(); j++)
         {
            _str cmd = dirInfo.opts " " maybe_quote_filename(dirInfo.dir "/" file_specs[j]);

            insert_file_list("-v +a +p " cmd);
         }
      }
   }

   // Go through and kill any directories or files that match the exclude list.
   if(exclude_list != "")
   {
      _str excludes[];

      split(exclude_list, ";", excludes);

      for(i = 0; i < excludes._length(); i++)
      {
         _str exclude_str = stranslate(excludes[i], '\', '/');

         top();
         up();

         while(!search('^[ \t]+' _escape_re_chars(exclude_str), '@r' _fpos_case))
         {
            delete_line();
         }
      }
   }

   // Remove duplicate files.
   int file_list_hash:[];

   file_list_hash._makeempty();
   top();
   up();
   while(!down())
   {
      _str filename;

      get_line(filename);
      filename = strip(filename, 'B');

      if(projectfiles_list._indexin(filename))
      {
         // If this file is current in the project, set the projectfiles_list
         //  entry to 1 (so we don't remove it from the project) and then
         //  remove this entry from the temp buffer add list.
         projectfiles_list:[filename] = 1;

         delete_line();
         up();
      }
      else if(file_list_hash._indexin(filename) &&
         file_list_hash:[filename] != p_line)
      {
         // This is a new file and it's a duplicate so wack it.
         delete_line();
         up();
      }
      else
      {
         // New file: record the line number we first saw it at.
         file_list_hash:[filename] = p_line;
      }
   }

   // Create a list of files to remove from the project. Every hash entry
   //  in projectfiles_list[] that is a 0 should be removed.
   int value;
   _str filename;
   _str filelist_remove = "";
   int files_removed = 0;
   foreach(filename => value in projectfiles_list)
   {
      if(value == 0)
      {
         files_removed++;
         filelist_remove = filelist_remove " " maybe_quote_filename(filename);
      }
   }
   if(filelist_remove != "")
   {
      filelist_remove = strip(filelist_remove, 'B');

      int status = project_remove_filelist(_project_name, filelist_remove);
      if(status != 0)
      {
         _str msg = "Warning: Unable to remove files from project. " :+ get_message(status);
         _message_box(msg, "", MB_OK | MB_ICONEXCLAMATION);
      }
   }

   // Add the new list of files to our project.
   if(file_list_hash._length())
   {
      tag_add_viewlist(_GetWorkspaceTagsFilename(), filelist_view_id);
   }

   int project_filecount = projectfiles_list._length() - files_removed + file_list_hash._length();

   message("Ssync completed. files_added:" file_list_hash._length() :+
           " files_removed:" files_removed :+
           " total_files:" project_filecount);

   activate_window(orig_view_id);
}

static void dinfo_add(DIRINFO (&dir_list)[], _str opts, _str dir, _str filespec = "")
{
   int len = dir_list._length();

   dir_list[len].opts      = opts;
   dir_list[len].dir       = dir;
   dir_list[len].filespec  = filespec;
}

//=========================================================================
// ssync_getprojectfilelist(): Get list of project files.
//=========================================================================
static void ssync_getprojectfilelist(_str ProjectName, int (&projectfiles_list):[])
{
   _str filelist = "";
   int file_view_id = 0;
   int orig_view_id = p_window_id;

   GetProjectFiles(ProjectName, file_view_id);
   p_window_id = file_view_id;

   top();
   up();

   while(!down())
   {
      _str filename;

      get_line(filename);
      filename = strip(filename, 'B');

      if(filename != "")
      {
         projectfiles_list:[filename] = 0;
      }
   }

   p_window_id = orig_view_id;
   _delete_temp_view(file_view_id);
}

