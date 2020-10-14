/*
* Copyright (c) 2011-2020 Spotlight
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
* Authored by: Kris Henriksen <krishenriksen.work@gmail.com>
*/

using Gtk;

public class SpotlightWindow : Window {
    private Gdk.Rectangle monitor_dimensions;

    private Grid grid;
    private Box left_box;
    private Box right_box;

    private int width = 680;
    private int height = 430;

    private Box search_box;
    private Entry search_entry;
    private Image search_app_icon;

    private int current_item = 1;

    private string calc_output;

    private Gee.ArrayList<Gee.HashMap<string, string>> apps = new Gee.ArrayList<Gee.HashMap<string, string>> ();
    private Gee.HashMap<string, Gdk.Pixbuf> icons = new Gee.HashMap<string, Gdk.Pixbuf>();
    private Gee.ArrayList<Gee.HashMap<string, string>> filtered = new Gee.ArrayList<Gee.HashMap<string, string>> ();

    public SpotlightWindow () {
        this.set_title ("Spotlight");
        this.set_skip_pager_hint (true);
        this.set_skip_taskbar_hint (true); // Not display the window in the task bar
        this.set_decorated (false); // No window decoration
        this.set_app_paintable (true); // Suppress default themed drawing of the widget's background
        this.set_visual (this.get_screen ().get_rgba_visual ());
        this.set_type_hint (Gdk.WindowTypeHint.NORMAL);
        this.resizable = false;

        Gdk.Screen default_screen = Gdk.Screen.get_default ();
        monitor_dimensions = default_screen.get_display ().get_primary_monitor ().get_geometry ();

        // set size, and slide out from right to left
        this.set_default_size (width, height);
        this.move(monitor_dimensions.width + width, 0);

        // Get all apps
        LightPad.Backend.DesktopEntries.enumerate_apps (this.icons, 24, out this.apps);
        this.apps.sort ((a, b) => GLib.strcmp (a["name"], b["name"]));

        // search container
        this.search_box = new Box (Orientation.HORIZONTAL, 0);
        search_box.get_style_context().add_class ("search_box");

		// search input
        this.search_entry = new Entry ();
        //search_entry.set_property("can-focus", false);
        this.search_entry.set_placeholder_text("Spotlight Search");
		this.search_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "edit-find");

        // seach app icon
		this.search_app_icon = new Image();

		// add to search box
        search_box.pack_start(this.search_entry);
        search_box.pack_end(this.search_app_icon);

		// left and right side container
		this.grid = new Grid();
		this.grid.get_style_context ().add_class("grid");

		var vbox = new Box (Orientation.VERTICAL, 0);
		vbox.pack_start (search_box, false, true, 0);
		vbox.pack_start (this.grid, true, true, 0);
		this.add (vbox);

	    this.left_box = new Box (Orientation.VERTICAL, 0);
	    this.left_box.get_style_context().add_class ("left_box");

	    this.right_box = new Box (Orientation.VERTICAL, 0);
	    this.right_box.get_style_context().add_class ("right_box");		

		this.search_entry.changed.connect (() => {
			this.search_box.get_style_context ().add_class("searching");
			this.grid.get_style_context ().add_class("searching");

			this.search();
        });

        this.draw.connect (this.draw_background);
		this.focus_out_event.connect ( () => { this.destroy(); return true; } );
    }

    private bool draw_background (Gtk.Widget widget, Cairo.Context ctx) {
        widget.get_style_context().add_class ("spotlight");
        this.show_all();

        return false;
    } 

	private void search() {
		// clear left box
		GLib.List<weak Gtk.Widget> left_children = this.left_box.get_children ();
		foreach (Gtk.Widget left_element in left_children) {
			this.left_box.remove(left_element);
		}

		// clear right box
		GLib.List<weak Gtk.Widget> right_children = this.right_box.get_children ();
		foreach (Gtk.Widget right_element in right_children) {
			this.right_box.remove(right_element);
		}

		// clear grid
		GLib.List<weak Gtk.Widget> children = this.grid.get_children ();
		foreach (Gtk.Widget element in children) {
			this.grid.remove(element);
		}

		this.filtered.clear();

		this.calc_output = "";

	    var current_text = this.search_entry.text.down();

	    // top hit header
		var top_hit_label = new Label("TOP HIT");
		top_hit_label.set_property("can-focus", false);
		top_hit_label.set_xalign(0);
		top_hit_label.get_style_context ().add_class("top_hit");

		this.left_box.add(top_hit_label);

		this.filtered.add(null);

		// only show 8 results
		int count = 0;

	    foreach (Gee.HashMap<string, string> app in this.apps) {
	        if ((app["name"] != null && current_text in app["name"].down ()) ||
	        	(app["command"] != null && current_text in app["command"].down ())) {

	            this.filtered.add(app);

	            // left section
	            if (count < 8) {
					var appsbar = new Toolbar ();
					appsbar.get_style_context ().add_class("appsbar");

	        		if (this.filtered.size == 2) {
	        			appsbar.get_style_context().add_class("active");
	        		}

					var icon = new Gtk.Image.from_icon_name(app["icon"], IconSize.MENU);
			    	var app_button = new Gtk.ToolButton(icon, app["name"]);
			    	app_button.is_important = true;
	    			app_button.clicked.connect ( () => {
	    				this.launch(app);
	    			});

					appsbar.add(app_button);

					this.left_box.add(appsbar);
				}

				count++;
				
	            if (this.filtered.size == 2) {
    				// add app icon to search_entry
    				this.search_app_icon.set_from_icon_name(app["icon"], IconSize.DND);

				    // applications header
					var applications_header_label = new Label("APPLICATIONS");
					applications_header_label.set_property("can-focus", false);
					applications_header_label.set_xalign(0);
					applications_header_label.get_style_context ().add_class("applications_header");

					this.left_box.add(applications_header_label);

					this.filtered.add(null);

	            	// right side
	            	this.rightSide(app);
				}
	        }
	    }

	    if (this.filtered.size < 3) {
	    	// do calculation
			this.calculate(this.search_entry.text);
	    }
	    else {
		    // show all in finder
			var show_in_finder = new Toolbar ();
			show_in_finder.get_style_context ().add_class("appsbar");
			show_in_finder.get_style_context ().add_class("show_in_finder");
			var finder_icon = new Gtk.Image.from_icon_name("file-manager", IconSize.BUTTON);
			var show_in_finder_button = new Gtk.ToolButton(finder_icon, "Show all in Finder...");
			show_in_finder_button.is_important = true;
			show_in_finder_button.clicked.connect ( () => {
	            try {
	                GLib.AppInfo.create_from_commandline ("catfish --path=/ --start " + current_text, null, GLib.AppInfoCreateFlags.NONE).launch (null, null);
	            } catch (GLib.Error e) {
	            	warning ("Could not load application: %s", e.message);
	            }
			});
			show_in_finder.add(show_in_finder_button);

			this.left_box.add(show_in_finder);


			var scroll = new ScrolledWindow (null, null);
			scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
			scroll.get_style_context ().add_class("scroll");
			scroll.add(this.left_box);

		    this.grid.add(scroll);
		    this.grid.add(this.right_box);

		    this.show_all();
	    }
	}

	private void rightSide(Gee.HashMap<string, string> app) {
		var app_image = new Image();
		app_image.get_style_context().add_class ("app_image");
		try {
		    app_image.set_from_icon_name(app["icon"], IconSize.DIALOG);
		} catch (Error e) {
			warning ("Could not load icon: %s", e.message);
		}

		var app_name = new Gtk.Label(app["name"]);
		app_name.get_style_context().add_class ("app_name");

        var app_description = new Entry ();
        app_description.set_editable(false);
        app_description.set_property("can-focus", false);
        app_description.get_style_context().add_class ("app_description");
        app_description.text = app["description"];

        var app_command = new Entry ();
        app_command.set_editable(false);
        app_command.set_property("can-focus", false);
        app_command.get_style_context().add_class ("app_command");
        app_command.text = app["command"];

        // clear right box
		GLib.List<weak Gtk.Widget> children = this.right_box.get_children ();
		foreach (Gtk.Widget element in children) {
			this.right_box.remove(element);
		}

		this.right_box.add(app_image);
		this.right_box.add(app_name);
		this.right_box.add(app_description);
		this.right_box.add(app_command);
	}

	private void launch(Gee.HashMap<string, string> app) {
        try {
            if (app["terminal"] == "true") {
				GLib.AppInfo.create_from_commandline(app["command"], null, GLib.AppInfoCreateFlags.NEEDS_TERMINAL).launch (null, null);
            } else {
                new GLib.DesktopAppInfo.from_filename (app["desktop_file"]).launch (null, null);
            }
        } catch (GLib.Error e) {
            warning ("Could not load application: %s", e.message);
        }

		this.destroy();
	}

    private void setActive(Gee.HashMap<string, string> app) {
    	int i = 0;

		GLib.List<weak Gtk.Widget> children = this.left_box.get_children ();
		foreach (Gtk.Widget element in children) {
			element.get_style_context().remove_class("active");

			if (i == this.current_item) {
				element.get_style_context().add_class("active");

    			// add app icon to search_entry
				search_app_icon.set_from_icon_name(app["icon"], IconSize.DND);

				// add right side description
				this.rightSide(app);

				int grid_i = 0;
				GLib.List<weak Gtk.Widget> grid_children = this.grid.get_children();
				foreach (Gtk.Widget grid_element in grid_children) {
					if (grid_i == 0) {
						this.grid.remove(grid_element);
					}

					grid_i++;
				}

				this.grid.add(this.right_box);
			}

			i++;
		}
    }

    private void reset () {
    	this.current_item = 1;

    	this.search_entry.text = "";

    	this.calc_output = "";

		// clear grid
		GLib.List<weak Gtk.Widget> children = this.grid.get_children ();
		foreach (Gtk.Widget element in children) {
			this.grid.remove(element);
		}

		this.search_box.get_style_context().remove_class("searching");
		this.grid.get_style_context().remove_class("searching");
		this.search_app_icon.set_from_icon_name(null, IconSize.DND);
    }

    private void calculate(string calc) {
		var eval = new PantheonCalculator.Core.Evaluation ();

		try {
            this.calc_output = eval.evaluate (this.search_entry.text, 0);
        } catch (PantheonCalculator.Core.OUT_ERROR e) {
        	warning ("Could not calculate: %s", e.message);
        }

        if (this.calc_output.length > 0) {
        	this.search_app_icon.set_from_icon_name("calculator", IconSize.DND);

	        // left section
			var appsbar = new Toolbar ();
			appsbar.get_style_context ().add_class("appsbar");
			appsbar.get_style_context().add_class("active");

			var icon = new Gtk.Image.from_icon_name("calculator", IconSize.MENU);
	    	var app_button = new Gtk.ToolButton(icon, this.calc_output);
	    	app_button.is_important = true;
    		app_button.clicked.connect ( () => {
    			this.copy_to_clipboard();
    		});

			appsbar.add(app_button);

			this.left_box.add(appsbar);

			var scroll = new ScrolledWindow (null, null);
			scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
			scroll.get_style_context ().add_class("scroll");
			scroll.add(this.left_box);

		    this.grid.add(scroll);
		    this.grid.add(this.right_box);

		    this.show_all();

			// add right side
	        var app_to_add = new Gee.HashMap<string, string> ();
	        app_to_add["name"] = this.calc_output;
	        app_to_add["description"] = this.search_entry.text;
	        app_to_add["command"] = "";
	        app_to_add["desktop_file"] = "";
	        app_to_add["icon"] = "calculator";

			this.rightSide(app_to_add);
        }
    }

    private void copy_to_clipboard() {
		Gdk.Display display = Gdk.Display.get_default ();
		Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);

		clipboard.set_text(this.calc_output, -1);
    }

    // Keyboard shortcuts
    public override bool key_press_event (Gdk.EventKey event) {
        switch (Gdk.keyval_name (event.keyval)) {
            case "Escape": {
            	if (this.search_entry.text.length == 0) {
            		this.destroy ();
            	}
            	else {
            		this.reset();
            	}

                return true;
            }

            case "Return": {
            	if (this.calc_output.length > 0) {
            		this.copy_to_clipboard();
            		this.destroy ();
            	}
            	else {
                	if (this.filtered.size >= 1) {
                		this.launch(this.filtered.get(this.current_item));
                	}
            	}

                return true;
            }

            case "Up": {
            	if (this.current_item >= 2) {
            		this.current_item -= 1;

            		if (this.filtered.get(this.current_item) == null) {
						this.current_item -= 1;            			
            		}

            		this.setActive(this.filtered.get(this.current_item));
            		return true;
            	}

            	break;
            }

            case "Down": {
            	if (this.current_item < (this.filtered.size - 1)) {
            		this.current_item += 1;

            		if (this.filtered.get(this.current_item) == null) {
            			if ((this.current_item + 1) < this.filtered.size) {
            				this.current_item += 1;
            			}
            		}

            		this.setActive(this.filtered.get(this.current_item));
            		return true;
            	}

                break;
            }

			case "BackSpace": {
				/*
				if (this.search_entry.text.length > 0) {
                	this.search_entry.text = this.search_entry.text.slice (0, (int) this.search_entry.text.length - 1);
				}
				else {
					this.reset();
				}

                return true;
                */

                this.current_item = 1;
                break;
            }

			default: {
				//this.search_entry.text = this.search_entry.text + event.str;

				if (this.search_entry.text.length == 0) {
					this.search_entry.grab_focus();
				}

				this.current_item = 1;
                break;
            }
        }

        base.key_press_event (event);
        return false;
    }

    // Override destroy for fade out and stuff
    private new void destroy () {
    	//base.hide_on_delete();

        base.destroy();
        Gtk.main_quit();
    }
}

static int main (string[] args) {
    Gtk.init (ref args);
    Gtk.Application app = new Gtk.Application ("dk.krishenriksen.spotlight", GLib.ApplicationFlags.FLAGS_NONE);

    // check for light or dark theme
    File iraspbian = File.new_for_path (GLib.Environment.get_variable ("HOME") + "/.iraspbian-dark.twid");
    File nighthawk = File.new_for_path (GLib.Environment.get_variable ("HOME") + "/.nighthawk.twid");

    string css_file = Config.PACKAGE_SHAREDIR +
        "/" + Config.PROJECT_NAME +
        "/" + (iraspbian.query_exists() || nighthawk.query_exists() ? "spotlight_dark.css" : "spotlight.css");
    var css_provider = new Gtk.CssProvider ();

    try {
        css_provider.load_from_path (css_file);
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    } catch (GLib.Error e) {
        warning ("Could not load CSS file: %s", css_file);
    }

    app.activate.connect( () => {
        if (app.get_windows ().length () == 0) {
        	var main_window = new SpotlightWindow ();
            main_window.set_application (app);
            main_window.show();
            Gtk.main ();
        }
    });
    app.run (args);
    return 1;
}
