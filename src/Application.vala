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

    private static string user_home = GLib.Environment.get_variable ("HOME");

    private Toolbar toolbar;
    private Grid grid;
    private Box left_box;

    private int width = 680;
    private int height = 430;

    private TextBuffer buffer;
    private Gtk.ToolButton searchButton;

    private int current_item = 1;

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
        LightPad.Backend.DesktopEntries.enumerate_apps (this.icons, 24, user_home, out this.apps);
        this.apps.sort ((a, b) => GLib.strcmp (a["name"], b["name"]));

        // search
		this.toolbar = new Toolbar ();
		this.toolbar.get_style_context ().add_class("toolbar");

		this.buffer = new TextBuffer (null);

		var search_icon = new Gtk.Image.from_icon_name ("edit-find-symbolic", IconSize.LARGE_TOOLBAR);
    	this.searchButton = new Gtk.ToolButton(search_icon, "Spotlight Search");
    	this.searchButton.is_important = true;

		this.toolbar.add(this.searchButton);

		this.grid = new Grid();
		this.grid.get_style_context ().add_class("grid");

		var vbox = new Box (Orientation.VERTICAL, 0);
		vbox.pack_start (this.toolbar, false, true, 0);
		vbox.pack_start (this.grid, true, true, 0);
		this.add (vbox);

		this.buffer.changed.connect (() => {
			this.toolbar.get_style_context ().add_class("searching");
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
		GLib.List<weak Gtk.Widget> children = this.grid.get_children ();
		foreach (Gtk.Widget element in children) {
			this.grid.remove(element);
		}

		this.filtered.clear();

	    var current_text = this.buffer.text.down();

	    this.left_box = new Box (Orientation.VERTICAL, 0);
	    this.left_box.get_style_context().add_class ("left_box");

	    var right_box = new Box (Orientation.VERTICAL, 0);
	    right_box.get_style_context().add_class ("right_box");

	    // top hit header
		var top_hit_bar = new Toolbar();
		top_hit_bar.get_style_context ().add_class("top_hit");
    	var top_hit_button = new Gtk.ToolButton(null, "TOP HIT");
    	top_hit_button.is_important = true;
		top_hit_bar.add(top_hit_button);

		this.left_box.add(top_hit_bar);

		this.filtered.add(null);

	    foreach (Gee.HashMap<string, string> app in this.apps) {
	        if ((app["name"] != null && current_text in app["name"].down ()) ||
	            (app["command"] != null && current_text in app["command"].down ())) {

	            this.filtered.add(app);

	            // left section
				var appsbar = new Toolbar ();
				appsbar.get_style_context ().add_class("appsbar");

        		if (this.filtered.size == 2) {
        			appsbar.get_style_context().add_class("active");
        		}

				var search_icon = new Gtk.Image.from_icon_name(app["icon"], IconSize.BUTTON);
		    	var app_button = new Gtk.ToolButton(search_icon, app["name"]);
		    	app_button.is_important = true;
    			app_button.clicked.connect ( () => {
    				this.launch(app);
    			});

				appsbar.add(app_button);

				this.left_box.add(appsbar);

				
	            if (this.filtered.size == 2) {
				    // applications header
					var applications_header_bar = new Toolbar();
					applications_header_bar.get_style_context ().add_class("applications_header");
			    	var applications_header_button = new Gtk.ToolButton(null, "APPLICATIONS");
			    	applications_header_button.is_important = true;
					applications_header_bar.add(applications_header_button);

					this.left_box.add(applications_header_bar);

					this.filtered.add(null);

	            	// right side
					var app_image = new Image();
					app_image.get_style_context().add_class ("app_image");
					try {
					    app_image.set_from_icon_name(app["icon"], IconSize.DIALOG);
					} catch (Error e) {
					    stderr.printf ("Could not load icon: %s\n", e.message);
					}

					var app_name = new Gtk.Label(app["name"]);
					app_name.get_style_context().add_class ("app_name");

					var app_description_buffer = new Gtk.TextBuffer (null); //stores text to be displayed
					app_description_buffer.text = app["description"];
					var app_description = new Gtk.TextView.with_buffer (app_description_buffer); //displays TextBuffer
					app_description.set_wrap_mode (Gtk.WrapMode.WORD); //sets line wrapping
					app_description.set_property("editable", false);
					app_description.get_style_context().add_class ("app_description");

					var app_command_buffer = new Gtk.TextBuffer (null); //stores text to be displayed
					app_command_buffer.text = app["command"];
					var app_command = new Gtk.TextView.with_buffer (app_command_buffer); //displays TextBuffer
					app_command.set_wrap_mode (Gtk.WrapMode.WORD); //sets line wrapping
					app_command.set_property("editable", false);
					app_command.get_style_context().add_class ("app_command");

					right_box.add(app_image);
					right_box.add(app_name);
					right_box.add(app_description);
					right_box.add(app_command);
				}
	        }
	    }

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
                warning ("Error! Load application: " + e.message);
            }
		});
		show_in_finder.add(show_in_finder_button);

		this.left_box.add(show_in_finder);


		var scroll = new ScrolledWindow (null, null);
		scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		scroll.get_style_context ().add_class("scroll");
		scroll.add(this.left_box);

	    this.grid.add(scroll);
	    this.grid.add(right_box);

	    this.show_all();
	}

	private void launch(Gee.HashMap<string, string> app) {
        try {
            if (app["terminal"] == "true") {
            	GLib.AppInfo.create_from_commandline (app["command"], null, GLib.AppInfoCreateFlags.NONE).launch (null, null);
            } else {
                new GLib.DesktopAppInfo.from_filename (app["desktop_file"]).launch (null, null);
            }

            this.destroy ();
        } catch (GLib.Error e) {
            warning ("Error! Load application: " + e.message);
        }

		this.destroy();
	}

    private void reset () {
    	this.searchButton.label = "Spotlight Search";

		this.toolbar.get_style_context ().remove_class("searching");
		this.grid.get_style_context ().remove_class("searching");
    }

    private void setActive() {
    	int i = 0;

		GLib.List<weak Gtk.Widget> children = this.left_box.get_children ();
		foreach (Gtk.Widget element in children) {
			element.get_style_context().remove_class("active");

			if (i == this.current_item) {
				element.get_style_context().add_class("active");
			}

			i++;
		}
    }

    // Keyboard shortcuts
    public override bool key_press_event (Gdk.EventKey event) {
        switch (Gdk.keyval_name (event.keyval)) {
            case "Escape":
            	if (this.searchButton.label == "Spotlight Search") {
            		this.destroy ();
            	}
            	else {
            		this.reset();
            	}

            	this.current_item = 0;

                return true;

            case "Return":
                if (this.filtered.size >= 1) {
                	this.launch(this.filtered.get(this.current_item));
                }
                return true;

			case "BackSpace":
				if (this.searchButton.label.length > 0 && this.searchButton.label != "Spotlight Search") {
                	this.searchButton.label = this.searchButton.label.slice (0, (int) this.searchButton.label.length - 1);
                	this.buffer.text = this.searchButton.label;
				}
				else {
					this.reset();
				}

				this.current_item = 0;

                return true;

            case "Up":
            	if (this.current_item >= 1) {
            		this.current_item -= 1;

            		if (this.filtered.get(this.current_item) == null) {
						this.current_item -= 1;

						if (this.current_item < 0) {
							this.current_item = 1;
						}
            		}
            	}

            	this.setActive();

                break;

            case "Down":
            	if (this.current_item < (this.filtered.size - 1)) {
            		this.current_item += 1;

            		if (this.filtered.get(this.current_item) == null) {
						this.current_item += 1;            			
            		}
            	}

            	this.setActive();

                break;

			default:
				if (this.searchButton.label == "Spotlight Search") {
					this.searchButton.label = "";
				}

                this.searchButton.label = this.searchButton.label + event.str;
                this.buffer.text = this.searchButton.label;
                break;
        }

        base.key_press_event (event);
        return false;
    }

    // Override destroy for fade out and stuff
    private new void destroy () {
        base.destroy();
        Gtk.main_quit();
    }
}

static int main (string[] args) {
    Gtk.init (ref args);
    Gtk.Application app = new Gtk.Application ("dk.krishenriksen.spotlight", GLib.ApplicationFlags.FLAGS_NONE);

    string css_file = Config.PACKAGE_SHAREDIR +
        "/" + Config.PROJECT_NAME +
        "/" + "spotlight.css";
    var css_provider = new Gtk.CssProvider ();

    try {
        css_provider.load_from_path (css_file);
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    } catch (GLib.Error e) {
        warning ("Could not load CSS file: %s",css_file);
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
