/*
* Copyright (c) 2011-2020 LightPad
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Juan Pablo Lozano <libredeb@gmail.com>
*/

namespace LightPad.Backend {
    public class DesktopEntries : GLib.Object {
        private static Gee.ArrayList<GMenu.TreeDirectory> get_categories () {
            var tree = new GMenu.Tree ("applications.menu", GMenu.TreeFlags.INCLUDE_EXCLUDED);
            try {
                // Initialize the tree
                tree.load_sync ();
            } catch (GLib.Error e) {
                error ("Initialization of the GMenu.Tree failed: %s", e.message);
            }
            var root = tree.get_root_directory ();
            var main_directory_entries = new Gee.ArrayList<GMenu.TreeDirectory> ();
            var iter = root.iter ();
            var item = iter.next ();
            while (item != GMenu.TreeItemType.INVALID) {
                if (item == GMenu.TreeItemType.DIRECTORY) {
                    main_directory_entries.add ((GMenu.TreeDirectory) iter.get_directory ());
                }
                item = iter.next ();
            }
            message ("Number of categories: %d", main_directory_entries.size);
            return main_directory_entries;
        }
        
        private static Gee.HashSet<GMenu.TreeEntry> get_applications_for_category (
            GMenu.TreeDirectory category) {
            
            var entries = new Gee.HashSet<GMenu.TreeEntry>  (
                (x) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash (),
                (x,y) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash () == ((GMenu.TreeEntry)y).get_desktop_file_path ().hash ());

            var iter = category.iter ();
            var item = iter.next ();
            while ( item != GMenu.TreeItemType.INVALID) {
                switch (item) {
                    case GMenu.TreeItemType.DIRECTORY:
                        entries.add_all (get_applications_for_category ((GMenu.TreeDirectory) iter.get_directory ()));
                        break;
                    case GMenu.TreeItemType.ENTRY:
                        entries.add ((GMenu.TreeEntry) iter.get_entry ());
                        break;
                }
                item = iter.next ();
            }
            message ("Category [%s] has [%d] apps", category.get_name (), entries.size);
            return entries;
        }
        
        public static void enumerate_apps (Gee.HashMap<string, Gdk.Pixbuf> icons, int icon_size, out Gee.ArrayList<Gee.HashMap<string, string>> list) {
            
            var the_apps = new Gee.HashSet<GMenu.TreeEntry> (
                (x) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash (),
                (x,y) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash () == ((GMenu.TreeEntry)y).get_desktop_file_path ().hash ());
            var all_categories = get_categories ();

            foreach (GMenu.TreeDirectory directory in all_categories) {
                var this_category_apps = get_applications_for_category (directory);
                foreach(GMenu.TreeEntry this_app in this_category_apps){
                    the_apps.add(this_app);
                }
            }
            
            message ("Amount of apps: %d", the_apps.size);
            list = new Gee.ArrayList<Gee.HashMap<string, string>> ();
            
            foreach (GMenu.TreeEntry entry in the_apps) {
                var app = entry.get_app_info ();
                if (app.get_nodisplay () == false && 
                    app.get_is_hidden() == false && 
                    app.get_icon() != null)
                {
                    var app_to_add = new Gee.HashMap<string, string> ();
                    app_to_add["name"] = app.get_display_name ();
                    app_to_add["description"] = app.get_description ();
                    
                    // Needed to check further later if terminal is open in terminal (like VIM, HTop, etc.)
                    if (app.get_string ("Terminal") == "true") {
                        app_to_add["terminal"] = "true";
                    }
                    app_to_add["command"] = app.get_commandline ();
                    app_to_add["desktop_file"] = entry.get_desktop_file_path ();

                    app_to_add["icon"] = "";

                    if (!icons.has_key (app_to_add["command"])) {
                        app_to_add["icon"] = app.get_icon ().to_string ();
                    }

                    list.add (app_to_add);
                }
            }

            // search for exe files in Games and Applications folders
            enumerate_exe(list, GLib.Environment.get_variable ("HOME") + "/Games");
            enumerate_exe(list, GLib.Environment.get_variable ("HOME") + "/Applications");
        }

	    public static void enumerate_exe (Gee.ArrayList<Gee.HashMap<string, string>> list, string directory) {
	        try {
	            Dir dir = Dir.open (directory, 0);
	            string? name = null;

	            while ((name = dir.read_name ()) != null) {
	                string path = Path.build_filename (directory, name);

	                // don't search hidden directories
	                if (name.substring(0, 1) != ".") {
						if (FileUtils.test (path, FileTest.IS_DIR)) {
	                    	enumerate_exe(list, directory + "/" + name);
	                	}

		                if (FileUtils.test (path, FileTest.IS_REGULAR) && FileUtils.test (path, FileTest.IS_EXECUTABLE)) {
		                    var app_to_add = new Gee.HashMap<string, string> ();
		                    app_to_add["name"] = name;
		                    app_to_add["description"] = "Windows Executable";
		                    app_to_add["terminal"] = "true";
		                    app_to_add["command"] = path;
		                    app_to_add["icon"] = "wine";

		                    list.add (app_to_add);
		                }
	                }
	            }
	        } catch (FileError e) {
	            warning(e.message);
	        }
	    }
    }
}