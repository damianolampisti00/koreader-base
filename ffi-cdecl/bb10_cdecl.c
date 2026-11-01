// BlackBerry 10: libscreen (window & events), BPS (event loop, navigator, battery), keycodes.

#include <bps/battery.h>
#include <bps/bps.h>
#include <bps/button.h>
#include <bps/event.h>
#include <bps/navigator.h>
#include <bps/screen.h>
#include <screen/screen.h>
#include <sys/keycodes.h>

#include "ffi-cdecl.h"

// libscreen. {{{

cdecl_type(screen_context_t);
cdecl_type(screen_display_t);
cdecl_type(screen_event_t);
cdecl_type(screen_window_t);
cdecl_type(screen_buffer_t);

cdecl_const(SCREEN_APPLICATION_CONTEXT);

cdecl_const(SCREEN_PROPERTY_BUFFER_SIZE);
cdecl_const(SCREEN_PROPERTY_DISPLAY);
cdecl_const(SCREEN_PROPERTY_DPI);
cdecl_const(SCREEN_PROPERTY_FLAGS);
cdecl_const(SCREEN_PROPERTY_FORMAT);
cdecl_const(SCREEN_PROPERTY_IDLE_MODE);
cdecl_const(SCREEN_PROPERTY_KEY_CAP);
cdecl_const(SCREEN_PROPERTY_KEY_FLAGS);
cdecl_const(SCREEN_PROPERTY_KEY_MODIFIERS);
cdecl_const(SCREEN_PROPERTY_KEY_SCAN);
cdecl_const(SCREEN_PROPERTY_KEY_SYM);
cdecl_const(SCREEN_PROPERTY_POINTER);
cdecl_const(SCREEN_PROPERTY_POSITION);
cdecl_const(SCREEN_PROPERTY_RENDER_BUFFERS);
cdecl_const(SCREEN_PROPERTY_ROTATION);
cdecl_const(SCREEN_PROPERTY_SIZE);
cdecl_const(SCREEN_PROPERTY_SOURCE_POSITION);
cdecl_const(SCREEN_PROPERTY_STRIDE);
cdecl_const(SCREEN_PROPERTY_SWAP_INTERVAL);
cdecl_const(SCREEN_PROPERTY_TOUCH_ID);
cdecl_const(SCREEN_PROPERTY_TYPE);
cdecl_const(SCREEN_PROPERTY_USAGE);
cdecl_const(SCREEN_PROPERTY_ZORDER);

cdecl_const(SCREEN_FORMAT_RGBA8888);
cdecl_const(SCREEN_FORMAT_RGBX8888);
cdecl_const(SCREEN_FORMAT_RGB565);

cdecl_const(SCREEN_USAGE_NATIVE);
cdecl_const(SCREEN_USAGE_READ);
cdecl_const(SCREEN_USAGE_WRITE);

cdecl_const(SCREEN_IDLE_MODE_KEEP_AWAKE);
cdecl_const(SCREEN_IDLE_MODE_NORMAL);

cdecl_const(SCREEN_EVENT_CLOSE);
cdecl_const(SCREEN_EVENT_KEYBOARD);
cdecl_const(SCREEN_EVENT_MTOUCH_MOVE);
cdecl_const(SCREEN_EVENT_MTOUCH_RELEASE);
cdecl_const(SCREEN_EVENT_MTOUCH_TOUCH);
cdecl_const(SCREEN_EVENT_POINTER);
cdecl_const(SCREEN_EVENT_PROPERTY);

cdecl_func(screen_create_context);
cdecl_func(screen_destroy_context);
cdecl_func(screen_flush_context);
cdecl_func(screen_create_window);
cdecl_func(screen_destroy_window);
cdecl_func(screen_create_window_buffers);
cdecl_func(screen_destroy_window_buffers);
cdecl_func(screen_get_window_property_iv);
cdecl_func(screen_get_window_property_pv);
cdecl_func(screen_set_window_property_iv);
cdecl_func(screen_get_buffer_property_iv);
cdecl_func(screen_get_buffer_property_pv);
cdecl_func(screen_get_display_property_iv);
cdecl_func(screen_post_window);
cdecl_func(screen_get_event_property_iv);

// }}}

// BPS. {{{

cdecl_const(BPS_SUCCESS);
cdecl_const(BPS_FAILURE);

cdecl_type(bps_event_t);
cdecl_struct(bps_event_payload_t);
cdecl_type(bps_event_payload_t);
cdecl_type(bps_event_completion_func);

cdecl_func(bps_initialize);
cdecl_func(bps_shutdown);
cdecl_func(bps_get_event);
cdecl_func(bps_event_get_domain);
cdecl_func(bps_event_get_code);
cdecl_func(bps_event_create);
cdecl_func(bps_push_event);
cdecl_func(bps_register_domain);

cdecl_const(BPS_IO_INPUT);
cdecl_func(bps_add_fd);
cdecl_func(bps_remove_fd);

cdecl_func(screen_request_events);
cdecl_func(screen_stop_events);
cdecl_func(screen_get_domain);
cdecl_func(screen_event_get_event);

cdecl_const(NAVIGATOR_EXIT);
cdecl_const(NAVIGATOR_WINDOW_STATE);
cdecl_const(NAVIGATOR_SWIPE_DOWN);
cdecl_const(NAVIGATOR_WINDOW_ACTIVE);
cdecl_const(NAVIGATOR_WINDOW_INACTIVE);
cdecl_const(NAVIGATOR_ORIENTATION_CHECK);
cdecl_const(NAVIGATOR_ORIENTATION);
cdecl_const(NAVIGATOR_LOW_MEMORY);
cdecl_const(NAVIGATOR_DEVICE_LOCK_STATE);
cdecl_const(NAVIGATOR_WINDOW_COVER);
cdecl_const(NAVIGATOR_WINDOW_COVER_ENTER);
cdecl_const(NAVIGATOR_WINDOW_COVER_EXIT);

cdecl_type(navigator_window_state_t);
cdecl_type(navigator_window_cover_transition_t);
cdecl_type(navigator_window_cover_attribute_t);

cdecl_func(navigator_request_events);
cdecl_func(navigator_stop_events);
cdecl_func(navigator_get_domain);
cdecl_func(navigator_event_get_window_state);
cdecl_func(navigator_orientation_check_response);
cdecl_func(navigator_rotation_lock);
cdecl_func(navigator_invoke);
cdecl_func(navigator_close_window);
cdecl_func(navigator_extend_terminate);
cdecl_func(navigator_event_get_window_cover_width);
cdecl_func(navigator_event_get_window_cover_height);
cdecl_func(navigator_window_cover_attribute_create);
cdecl_func(navigator_window_cover_attribute_destroy);
cdecl_func(navigator_window_cover_attribute_set_file);
cdecl_func(navigator_window_cover_attribute_set_transition);
cdecl_func(navigator_window_cover_attribute_set_allow_badges);
cdecl_func(navigator_window_cover_update);
cdecl_func(navigator_window_cover_reset);

cdecl_const(BUTTON_UP);
cdecl_const(BUTTON_DOWN);

cdecl_type(button_physical_t);

cdecl_func(button_request_events);
cdecl_func(button_stop_events);
cdecl_func(button_get_domain);
cdecl_func(button_event_get_button);

cdecl_const(BATTERY_INFO);
cdecl_const(BATTERY_CHARGING_NOT_CHARGING);
cdecl_const(BATTERY_CHARGING_TRICKLE_CHARGING);
cdecl_const(BATTERY_CHARGING_CONSTANT_CURRENT);
cdecl_const(BATTERY_CHARGING_CONSTANT_VOLTAGE);
cdecl_const(BATTERY_CHARGING_DONE_CHARGING);

cdecl_type(battery_info_t);

cdecl_func(battery_get_info);
cdecl_func(battery_free_info);
cdecl_func(battery_info_get_state_of_charge);
cdecl_func(battery_info_get_system_charging_state);
cdecl_func(battery_info_is_charger_ready);

// }}}

// Keycodes. {{{

cdecl_const(KEY_DOWN);
cdecl_const(KEY_REPEAT);
cdecl_const(KEY_SCAN_VALID);
cdecl_const(KEY_SYM_VALID);
cdecl_const(KEY_CAP_VALID);

cdecl_const(KEYCODE_BACKSPACE);
cdecl_const(KEYCODE_DELETE);
cdecl_const(KEYCODE_DOWN);
cdecl_const(KEYCODE_ESCAPE);
cdecl_const(KEYCODE_LEFT);
cdecl_const(KEYCODE_LEFT_ALT);
cdecl_const(KEYCODE_LEFT_SHIFT);
cdecl_const(KEYCODE_MENU);
cdecl_const(KEYCODE_PG_DOWN);
cdecl_const(KEYCODE_PG_UP);
cdecl_const(KEYCODE_RETURN);
cdecl_const(KEYCODE_RIGHT);
cdecl_const(KEYCODE_RIGHT_ALT);
cdecl_const(KEYCODE_RIGHT_SHIFT);
cdecl_const(KEYCODE_SPACE);
cdecl_const(KEYCODE_UP);
cdecl_const(KEYCODE_VOLUME_DOWN);
cdecl_const(KEYCODE_VOLUME_UP);
cdecl_const(KEYCODE_PLAY);
cdecl_const(KEYCODE_PAUSE);

// }}}

// vim: foldmethod=marker foldlevel=0
