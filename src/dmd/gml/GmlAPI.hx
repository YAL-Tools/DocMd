package dmd.gml;
using dmd.MiscTools;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlAPI {
	static function keywords_init() {
		var r = new Map();
		var kd = [ //{
			"globalvar", "var", "enum", "local",
			"if", "then", "else", "begin", "end",
			"for", "while", "do", "until", "repeat",
			"switch", "case", "default", "break", "continue",
			"with", "exit", "return",
			"self", "other", "noone", "all", "global",
			"mod", "div", "not", "and", "or", "xor",
			"wait", "in", "try", "catch", "throw",
			"new", "function", "constructor", "static",
		]; //}
		for (s in kd) r.set(s, true);
		return r;
	}
	public static var keywords:Map<String, Bool> = keywords_init();
	static function stdvars_init() {
		var r = new Map();
		var d = [ //{
			"argument_relative", "argument", "argument0", "argument1", "argument2", "argument3", "argument4", "argument5", "argument6", "argument7", "argument8", "argument9", "argument10", "argument11", "argument12", "argument13", "argument14", "argument15", "argument_count", "x", "y", "xprevious", "yprevious", "xstart", "ystart", "hspeed", "vspeed", "direction", "speed", "friction", "gravity", "gravity_direction", "path_index", "path_position", "path_positionprevious", "path_speed", "path_scale", "path_orientation", "path_endaction", "object_index", "id", "solid", "persistent", "mask_index", "instance_count", "instance_id", "room_speed", "fps", "fps_real", "current_time", "current_year", "current_month", "current_day", "current_weekday", "current_hour", "current_minute", "current_second", "alarm", "timeline_index", "timeline_position", "timeline_speed", "timeline_running", "timeline_loop", "room", "room_first", "room_last", "room_width", "room_height", "room_persistent", "score", "lives", "health", "event_type", "event_number", "event_object", "event_action", "application_surface", "debug_mode", "font_texture_page_size", "keyboard_key", "keyboard_lastkey", "keyboard_lastchar", "keyboard_string", "mouse_x", "mouse_y", "mouse_button", "mouse_lastbutton", "cursor_sprite", "visible", "sprite_index", "sprite_width", "sprite_height", "sprite_xoffset", "sprite_yoffset", "image_number", "image_index", "image_speed", "depth", "image_xscale", "image_yscale", "image_angle", "image_alpha", "image_blend", "bbox_left", "bbox_right", "bbox_top", "bbox_bottom", "layer", "background_colour", "background_showcolour", "background_color", "background_showcolor", "view_enabled", "view_current", "view_visible", "view_xport", "view_yport", "view_wport", "view_hport", "view_surface_id", "view_camera", "game_id", "game_display_name", "game_project_name", "game_save_id", "working_directory", "temp_directory", "program_directory", "browser_width", "browser_height", "os_type", "os_device", "os_browser", "os_version", "display_aa", "async_load", "delta_time", "webgl_enabled", "event_data", "of_challen", "iap_data", "phy_rotation", "phy_position_x", "phy_position_y", "phy_angular_velocity", "phy_linear_velocity_x", "phy_linear_velocity_y", "phy_speed_x", "phy_speed_y", "phy_speed", "phy_angular_damping", "phy_linear_damping", "phy_bullet", "phy_fixed_rotation", "phy_active", "phy_mass", "phy_inertia", "phy_com_x", "phy_com_y", "phy_dynamic", "phy_kinematic", "phy_sleeping", "phy_collision_points", "phy_collision_x", "phy_collision_y", "phy_col_normal_x", "phy_col_normal_y", "phy_position_xprevious", "phy_position_yprevious"
		]; //}
		for (s in d) r.set(s, true);
		return r;
	}
	public static var stdvars:Map<String, Bool> = stdvars_init();
	public static var builtin:Map<String, Bool> = new Map();
	//public static var locals:Map<String, Bool> = new Map();
	public static var assets:Map<String, Bool> = new Map();
	public static function loadEntries(gml:String) {
		#if macro
		var p = gml.indexOf("\n");
		var n = gml.length;
		while (p >= 0) {
			p++;
			while (gml.fastCodeAt(p) == ":".code) p++;
			var c = gml.fastCodeAt(p);
			if (c == "_".code
				|| c >= "a".code && c <= "z".code
				|| c >= "A".code && c <= "Z".code
			) {
				var start = p++;
				while (p < n) {
					c = gml.fastCodeAt(p);
					if (c == "_".code
						|| c >= "a".code && c <= "z".code
						|| c >= "A".code && c <= "Z".code
						|| c >= "0".code && c <= "9".code
					) p++; else break;
				}
				var id = gml.substring(start, p);
				builtin.set(id, true);
			}
			p = gml.indexOf("\n", p);
		}
		#else
		~/^\s*(?::\s*)?(\w+)/gm.each(gml, function(rx:EReg) {
			builtin.set(rx.matched(1), true);
		});
		#end
	}
	public static function loadAssets(raw:String) {
		~/(\w+)/g.each(raw, function(rx:EReg) {
			assets.set(rx.matched(1), true);
		});
	}
}
