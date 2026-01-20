# VAGUS App Icon Inventory

Complete inventory of all icons used in the VAGUS Flutter application. This document catalogs every icon instance for AI-powered icon regeneration in a consistent style.

**Generated:** 2025-01-22  
**Total Icons Cataloged:** 500+ unique icon instances

---

## Navigation

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| nav_home | material | Icons.home_outlined / Icons.home_rounded | - | lib/screens/nav/main_nav.dart:177-178 | Bottom nav tab | Home screen navigation tab (client) |
| nav_dashboard | material | Icons.dashboard_outlined / Icons.dashboard_rounded | - | lib/screens/nav/main_nav.dart:140-141 | Bottom nav tab | Dashboard navigation tab (coach) |
| nav_workouts | material | Icons.fitness_center_outlined / Icons.fitness_center_rounded | - | lib/screens/nav/main_nav.dart:152-153, 183-184 | Bottom nav tab | Workouts/Plans navigation tab |
| nav_calendar | material | Icons.calendar_month_outlined / Icons.calendar_month_rounded | - | lib/screens/nav/main_nav.dart:158-159, 189-190 | Bottom nav tab | Calendar navigation tab |
| nav_nutrition | material | Icons.restaurant_outlined / Icons.restaurant_rounded | - | lib/screens/nav/main_nav.dart:195-196 | Bottom nav tab | Nutrition hub navigation tab (client) |
| nav_messages | material | Icons.chat_outlined / Icons.chat_rounded | - | lib/screens/nav/main_nav.dart:164-165, 201-202 | Bottom nav tab | Messages navigation tab |
| nav_clients | material | Icons.people_outline / Icons.people_rounded | - | lib/screens/nav/main_nav.dart:146-147 | Bottom nav tab | Clients management tab (coach) |
| nav_admin | material | Icons.admin_panel_settings_outlined / Icons.admin_panel_settings_rounded | - | lib/screens/nav/main_nav.dart:130-131 | Bottom nav tab | Admin hub navigation tab |
| nav_menu | material | Icons.menu | - | lib/screens/nav/main_nav.dart:346 | AppBar leading | Hamburger menu for side drawer |
| nav_back | material | Icons.arrow_back | - | Multiple files | AppBar leading | Back navigation button |
| nav_forward | material | Icons.arrow_forward | - | lib/services/navigation/notification_deep_link_handler.dart:242 | Button | Forward navigation |
| nav_chevron_left | material | Icons.chevron_left | - | lib/screens/calendar/modern_calendar_viewer.dart:248 | Button | Previous month/week navigation |
| nav_chevron_right | material | Icons.chevron_right | - | lib/screens/calendar/modern_calendar_viewer.dart:269 | Button | Next month/week navigation |
| nav_keyboard_arrow_down | material | Icons.keyboard_arrow_down | - | lib/screens/dashboard/edit_profile_screen.dart:376 | Dropdown indicator | Expandable dropdown indicator |

---

## Workout

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| workout_fitness_center | material | Icons.fitness_center_outlined / Icons.fitness_center_rounded | - | lib/screens/nav/main_nav.dart | Tab icon | Workout plans and exercises |
| workout_play | material | Icons.play_arrow | - | lib/components/workout/rest_timer.dart:107 | Button | Start/play workout timer |
| workout_pause | material | Icons.pause / Icons.pause_rounded | - | lib/components/workout/rest_timer.dart:107, lib/components/workout/rest_timer_inline.dart:93 | Button | Pause workout timer |
| workout_stop | material | Icons.stop | - | lib/widgets/messaging/voice_recorder.dart:145 | Button | Stop workout session |
| workout_add_set | material | Icons.add | - | lib/components/workout/rest_timer.dart:113, lib/components/workout/rest_timer_inline.dart:98 | Button | Add new set to workout |
| workout_edit | material | Icons.edit | - | lib/widgets/workout/advanced_exercise_editor.dart | Button | Edit exercise details |
| workout_delete | material | Icons.delete / Icons.delete_outline | - | Multiple files | Button | Delete exercise or set |
| workout_close | material | Icons.close | - | lib/widgets/workout/advanced_exercise_editor.dart:290 | Button | Close exercise editor |
| workout_error | material | Icons.error_outline | - | lib/widgets/workout/advanced_exercise_editor.dart:304 | Status indicator | Exercise error state |
| workout_info | material | Icons.info_outline | - | lib/widgets/workout/advanced_exercise_editor.dart:857 | Info button | Exercise information |
| workout_search | material | Icons.search | - | lib/widgets/workout/exercise_picker_dialog.dart:434 | Search field | Search exercises |
| workout_favorite | material | Icons.favorite / Icons.favorite_border | - | lib/components/workout/exercise_search_filter_sheet.dart:148 | Button | Favorite exercise toggle |
| workout_star | material | Icons.star / Icons.star_border | - | Multiple files | Button | Star/rate exercise |
| workout_tune | material | Icons.tune | - | lib/widgets/workout/advanced_exercise_editor.dart:331 | Tab icon | Advanced exercise settings |
| workout_format_list | material | Icons.format_list_numbered | - | lib/widgets/workout/advanced_exercise_editor.dart:330 | Tab icon | Basic exercise info |
| workout_note | material | Icons.note | - | lib/widgets/workout/advanced_exercise_editor.dart:332 | Tab icon | Exercise notes tab |
| workout_check | material | Icons.check | - | lib/widgets/workout/advanced_exercise_editor.dart:574 | Button | Confirm exercise changes |
| workout_construction | material | Icons.construction | - | lib/widgets/coach/quick_actions_grid.dart:352 | Status icon | Workout feature under construction |

---

## Nutrition

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| nutrition_restaurant | material | Icons.restaurant_outlined / Icons.restaurant_rounded | - | lib/screens/nav/main_nav.dart | Tab icon | Nutrition hub |
| nutrition_add_food | material | Icons.add | - | lib/screens/nutrition/pantry_screen.dart:94, lib/widgets/nutrition/meal_detail_sheet.dart:97 | Button | Add food item |
| nutrition_search | material | Icons.search | - | lib/screens/nutrition/pantry_screen.dart:108, lib/screens/nutrition/recipe_library_screen.dart:291 | Search field | Search foods/recipes |
| nutrition_clear_search | material | Icons.clear | - | lib/screens/nutrition/pantry_screen.dart:117, lib/screens/nutrition/recipe_library_screen.dart:297 | Button | Clear search input |
| nutrition_edit_food | material | Icons.edit | - | lib/screens/nutrition/pantry_screen.dart:294 | Button | Edit food item |
| nutrition_delete_food | material | Icons.delete | - | lib/screens/nutrition/pantry_screen.dart:304 | Button | Delete food item |
| nutrition_filter | material | Icons.filter_list | - | lib/screens/nutrition/recipe_library_screen.dart:241 | Button | Filter recipes |
| nutrition_inventory | material | Icons.inventory_2_outlined | - | lib/screens/nutrition/recipe_library_screen.dart:247 | Button | Pantry/inventory view |
| nutrition_close_recipe | material | Icons.close | - | lib/screens/nutrition/recipe_library_screen.dart:381, lib/components/nutrition/recipe_quick_swap_sheet.dart:179 | Button | Close recipe view |
| nutrition_qr_scanner | material | Icons.qr_code_scanner | - | lib/screens/nutrition/widgets/shared/food_picker_2_0.dart:230 | Tab icon | Barcode scanner tab |
| nutrition_history | material | Icons.history | - | lib/screens/nutrition/widgets/shared/food_picker_2_0.dart:231 | Tab icon | Recent foods tab |
| nutrition_favorites | material | Icons.favorite | - | lib/screens/nutrition/widgets/shared/food_picker_2_0.dart:232 | Tab icon | Favorite foods tab |
| nutrition_custom | material | Icons.add_circle_outline | - | lib/screens/nutrition/widgets/shared/food_picker_2_0.dart:233 | Tab icon | Custom foods tab |
| nutrition_camera | material | Icons.camera_alt_outlined | - | lib/components/nutrition/add_via_photo_button.dart:31, 41 | Button | Add food via photo |
| nutrition_auto_awesome | material | Icons.auto_awesome | - | lib/components/nutrition/food_label_parser.dart:88 | Button | AI food parsing |
| nutrition_analytics | material | Icons.analytics | - | lib/components/nutrition/food_label_parser.dart:100 | Button | Nutrition analytics |
| nutrition_check | material | Icons.check | - | lib/components/nutrition/food_label_parser.dart:266 | Button | Confirm food selection |
| nutrition_payments | material | Icons.payments_outlined | - | lib/components/nutrition/cost_summary.dart:27 | Avatar icon | Cost/payment summary |
| nutrition_attach_file | material | Icons.attach_file | - | lib/widgets/nutrition/meal_detail_sheet.dart:109 | Button | Attach file to meal |
| nutrition_supplement_pill | custom | HalfPillIcon | - | lib/widgets/supplements/half_pill_icon.dart | Custom icon | Supplement pill icon (half red, half blue) |
| nutrition_empty_state | material | Various (Icons.restaurant, Icons.local_pharmacy_outlined) | - | lib/screens/nutrition/widgets/shared/empty_state_widget.dart | Empty state | Empty nutrition state icons |

---

## Messaging

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| messaging_chat | material | Icons.chat_outlined / Icons.chat_rounded | - | lib/screens/nav/main_nav.dart | Tab icon | Messages tab |
| messaging_send | material | Icons.send | - | lib/screens/admin/support/widgets/ticket_card.dart:227, lib/screens/admin/admin_ticket_queue_screen.dart:1029 | Button | Send message |
| messaging_reply | material | Icons.reply | - | lib/components/messaging/thread_view.dart:149 | Button | Reply to message |
| messaging_attach | material | Icons.attach_file | - | lib/components/messaging/thread_view.dart:243 | Button | Attach file to message |
| messaging_pin | material | Icons.push_pin | - | lib/components/messaging/pin_panel.dart:97, 149 | Button | Pin message |
| messaging_close | material | Icons.close | - | lib/components/messaging/translation_toggle.dart:224, lib/components/messaging/pin_panel.dart:108 | Button | Close message panel |
| messaging_mic | material | Icons.mic | - | lib/widgets/messaging/voice_recorder.dart:97 | Button | Voice recording |
| messaging_audio | material | Icons.audio_file | - | lib/widgets/messaging/voice_recorder.dart:121 | Button | Audio file attachment |
| messaging_stop_voice | material | Icons.stop | - | lib/widgets/messaging/voice_recorder.dart:145 | Button | Stop voice recording |
| messaging_arrow_back | material | Icons.arrow_back | - | lib/components/messaging/thread_view.dart:123 | Button | Back to messages list |
| messaging_person | material | Icons.person | - | lib/components/messaging/thread_view.dart:217 | Avatar | User avatar in message |

---

## Calendar

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| calendar_month | material | Icons.calendar_month_outlined / Icons.calendar_month_rounded | - | lib/screens/nav/main_nav.dart | Tab icon | Calendar tab |
| calendar_add | material | Icons.add | - | lib/screens/calendar/calendar_screen.dart:1094, lib/screens/calendar/booking_form.dart:517 | Button | Add calendar event |
| calendar_check | material | Icons.check | - | lib/screens/calendar/calendar_screen.dart:289 | Button | Confirm event |
| calendar_snooze | material | Icons.snooze | - | lib/screens/calendar/calendar_screen.dart:300 | Button | Snooze reminder |
| calendar_close | material | Icons.close | - | lib/screens/calendar/calendar_screen.dart:312 | Button | Close calendar dialog |
| calendar_people | material | Icons.people | - | lib/screens/calendar/booking_form.dart:343 | Button | Event participants |
| calendar_cancel | material | Icons.cancel | - | lib/screens/calendar/booking_form.dart:401 | Button | Cancel booking |
| calendar_schedule | material | Icons.schedule | - | lib/screens/calendar/booking_form.dart:435 | Button | Schedule event |
| calendar_event | material | Icons.event | - | lib/screens/calendar/booking_form.dart:363 | Icon | Calendar event indicator |
| calendar_check_circle | material | Icons.check_circle | - | lib/screens/calendar/booking_form.dart:363 | Icon | Completed event |

---

## Metrics/Progress

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|-------------|-------------|
| metrics_analytics | material | Icons.analytics | - | lib/components/progress/compliance_stats_card.dart:168 | Metric icon | Analytics/metrics display |
| metrics_refresh | material | Icons.refresh | - | lib/components/progress/compliance_stats_card.dart:185, lib/widgets/ai/ai_usage_meter.dart:178 | Button | Refresh metrics data |
| metrics_trending_up | material | Icons.trending_up | - | lib/screens/admin/support/support_inbox_screen.dart:229, 341 | Icon | Trending metrics |
| metrics_table | material | Icons.table_view | - | lib/screens/admin/support/support_inbox_screen.dart:246, 357 | Icon | Table/metrics view |
| metrics_download | material | Icons.download | - | lib/screens/admin/support/support_inbox_screen.dart:258 | Button | Download metrics report |
| metrics_check_circle | material | Icons.check_circle | - | lib/components/supplements/adherence_heatmap.dart:426 | Status icon | Completed metric |
| metrics_cancel | material | Icons.cancel | - | lib/components/supplements/adherence_heatmap.dart:428 | Status icon | Cancelled metric |
| metrics_snooze | material | Icons.snooze | - | lib/components/supplements/adherence_heatmap.dart:430 | Status icon | Snoozed metric |
| metrics_error | material | Icons.error_outline | - | lib/components/supplements/adherence_heatmap.dart:113, lib/widgets/ai/ai_usage_meter.dart:166 | Status icon | Error state |
| metrics_info | material | Icons.info_outline | - | lib/widgets/ai/ai_usage_meter.dart:197 | Info icon | Information tooltip |
| metrics_compare | material | Icons.compare_arrows | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:518 | Icon | Compare metrics |
| metrics_show_chart | material | Icons.show_chart | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:522 | Icon | Chart visualization |
| metrics_priority | material | Icons.priority_high | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:526 | Icon | High priority metric |
| metrics_lightbulb | material | Icons.lightbulb_outline | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:506 | Icon | Tip/insight indicator |
| metrics_notifications | material | Icons.notifications_outlined | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:510 | Icon | Reminder notification |
| metrics_warning | material | Icons.warning | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:498 | Icon | Warning indicator |
| metrics_alert | material | Icons.error | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:502 | Icon | Alert indicator |
| metrics_success | material | Icons.check_circle | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:490 | Icon | Success indicator |
| metrics_positive | material | Icons.trending_up | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:494 | Icon | Positive trend |

---

## Admin

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| admin_panel | material | Icons.admin_panel_settings_outlined / Icons.admin_panel_settings_rounded | - | lib/screens/nav/main_nav.dart | Tab icon | Admin hub |
| admin_add | material | Icons.add | - | lib/screens/admin/admin_playbooks_screen.dart:138, lib/screens/admin/admin_knowledge_screen.dart:133 | Button | Add admin item |
| admin_delete | material | Icons.delete_outline | - | lib/screens/admin/admin_playbooks_screen.dart:127, lib/screens/admin/admin_knowledge_screen.dart:186 | Button | Delete admin item |
| admin_edit | material | Icons.edit_outlined | - | lib/screens/admin/admin_playbooks_screen.dart:201, lib/screens/admin/admin_escalation_matrix_screen.dart:203 | Button | Edit admin item |
| admin_search | material | Icons.search | - | lib/screens/admin/admin_knowledge_screen.dart:148, lib/screens/admin/support/support_inbox_screen.dart:288 | Search field | Admin search |
| admin_play | material | Icons.play_arrow | - | lib/screens/admin/admin_playbooks_screen.dart:123 | Button | Play/execute action |
| admin_auto_awesome | material | Icons.auto_awesome | - | lib/screens/admin/admin_playbooks_screen.dart:190, lib/screens/admin/support/support_inbox_screen.dart:1115 | Button | AI/automation feature |
| admin_refresh | material | Icons.refresh | - | lib/screens/admin/admin_ticket_queue_screen.dart:143, lib/screens/admin/admin_ops_screen.dart:118 | Button | Refresh admin data |
| admin_visibility | material | Icons.visibility | - | lib/screens/admin/admin_ticket_queue_screen.dart:185 | Button | View details |
| admin_checklist | material | Icons.checklist | - | lib/screens/admin/admin_ticket_queue_screen.dart:654 | Icon | Checklist view |
| admin_playlist_check | material | Icons.playlist_add_check | - | lib/screens/admin/admin_ticket_queue_screen.dart:343, 860 | Icon | Batch operations |
| admin_bolt | material | Icons.bolt | - | lib/screens/admin/support/widgets/ticket_card.dart:234, lib/screens/admin/admin_ticket_queue_screen.dart:873 | Icon | Quick action/power feature |
| admin_support_agent | material | Icons.support_agent | - | lib/screens/admin/support/support_inbox_screen.dart:412, lib/screens/admin/support/widgets/ticket_card.dart:28, 97 | Icon | Support agent indicator |
| admin_priority_high | material | Icons.priority_high | - | lib/screens/admin/support/support_inbox_screen.dart:418 | Icon | High priority ticket |
| admin_open_new | material | Icons.open_in_new | - | lib/screens/admin/support/support_inbox_screen.dart:867, 1118 | Button | Open in new window |
| admin_drag_indicator | material | Icons.drag_indicator | - | lib/screens/admin/support/support_inbox_screen.dart:872 | Icon | Drag handle |
| admin_inbox | material | Icons.inbox_outlined | - | lib/screens/admin/support/support_inbox_screen.dart:939 | Tab icon | Inbox tab |
| admin_pending | material | Icons.pending_outlined | - | lib/screens/admin/support/support_inbox_screen.dart:949 | Tab icon | Pending tab |
| admin_check_circle_outline | material | Icons.check_circle_outline | - | lib/screens/admin/support/support_inbox_screen.dart:959 | Tab icon | Completed tab |
| admin_close | material | Icons.close | - | lib/screens/admin/support/support_inbox_screen.dart:969 | Tab icon | Closed tab |
| admin_warning_amber | material | Icons.warning_amber_rounded | - | lib/screens/admin/support/support_inbox_screen.dart:1262 | Icon | Warning indicator |
| admin_security | material | Icons.security | - | lib/screens/admin/admin_ticket_queue_screen.dart:1280 | Icon | Security incident |
| admin_notifications | material | Icons.notifications | - | lib/screens/admin/admin_ticket_queue_screen.dart:1283 | Icon | Push notification incident |
| admin_link | material | Icons.link | - | lib/screens/admin/admin_ticket_queue_screen.dart:1284 | Icon | Deep link incident |
| admin_dashboard | material | Icons.dashboard | - | lib/screens/admin/admin_ops_screen.dart:125 | Tab icon | Overview dashboard |
| admin_warning | material | Icons.warning | - | lib/screens/admin/admin_ops_screen.dart:127, 467 | Tab icon | Breaches/warnings |
| admin_inbox_ops | material | Icons.inbox | - | lib/screens/admin/admin_ops_screen.dart:200 | Icon | Inbox operations |
| admin_folder_open | material | Icons.folder_open | - | lib/screens/admin/admin_ops_screen.dart:206 | Icon | Folder operations |
| admin_timer | material | Icons.timer | - | lib/screens/admin/admin_ops_screen.dart:212 | Icon | Timer operations |
| admin_person | material | Icons.person | - | lib/screens/admin/admin_ops_screen.dart:230 | Icon | User operations |
| admin_check | material | Icons.check | - | lib/screens/admin/admin_ops_screen.dart:503, lib/screens/admin/coach_approval_panel.dart:207 | Button | Approve/confirm |
| admin_schedule | material | Icons.schedule | - | lib/screens/admin/admin_ops_screen.dart:513 | Icon | Scheduled operations |
| admin_pending_status | material | Icons.pending | - | lib/screens/admin/coach_approval_panel.dart:284 | Icon | Pending approval status |
| admin_cancel | material | Icons.cancel | - | lib/screens/admin/coach_approval_panel.dart:316 | Icon | Cancelled status |
| admin_clear | material | Icons.clear | - | lib/screens/admin/admin_ticket_queue_screen.dart:428 | Button | Clear selection |
| admin_push_pin | material | Icons.push_pin / Icons.push_pin_outlined | - | lib/screens/admin/admin_ticket_board_screen.dart:204 | Button | Pin/unpin board item |

---

## Settings/Profile

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| settings_gear | material | Icons.settings | - | lib/screens/settings/user_settings_screen.dart:268, 311, 453 | Button | Settings menu |
| settings_gift | material | Icons.card_giftcard | - | lib/screens/settings/user_settings_screen.dart:354 | Button | Rewards/gifts |
| settings_security | material | Icons.security | - | lib/screens/dashboard/edit_profile_screen.dart:415 | Icon | Security settings |
| settings_admin_panel | material | Icons.admin_panel_settings | - | lib/screens/dashboard/edit_profile_screen.dart:381 | Icon | Admin panel access |
| settings_person | material | Icons.person / Icons.person_outline | - | Multiple files | Avatar/icon | User profile |
| settings_person_add | material | Icons.person_add_alt / Icons.person_add_alt_1 | - | lib/screens/account_switch_screen.dart:93, lib/screens/admin/support/widgets/ticket_card.dart:32 | Button | Add user/person |
| settings_edit | material | Icons.edit | - | lib/screens/coach_profile/coach_profile_screen.dart:231 | Button | Edit profile |
| settings_camera | material | Icons.camera_alt | - | lib/screens/coach_profile/coach_profile_screen.dart:288 | Button | Change profile photo |
| settings_chevron_right | material | Icons.chevron_right | - | lib/components/settings/export_my_data_button.dart:127 | Icon | Navigation indicator |

---

## Files/Media

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| file_attach | material | Icons.attach_file | - | lib/widgets/files/attach_to_note_button.dart:236 | Button | Attach file |
| file_folder | material | Icons.folder_open | - | lib/widgets/files/attach_to_note_button.dart:246 | Icon | Open folder |
| file_clear | material | Icons.clear_all | - | lib/widgets/files/attach_to_note_button.dart:255 | Button | Clear all files |
| file_visibility | material | Icons.visibility | - | lib/widgets/files/attach_to_note_button.dart:206, lib/widgets/files/inline_file_picker.dart:197 | Button | Preview file |
| file_close | material | Icons.close | - | lib/widgets/files/attach_to_note_button.dart:211, lib/widgets/files/inline_file_picker.dart:202 | Button | Close file picker |
| file_camera | material | Icons.camera_alt | - | lib/widgets/files/inline_file_picker.dart:227 | Button | Take photo |
| file_photo_library | material | Icons.photo_library | - | lib/widgets/files/inline_file_picker.dart:235 | Button | Choose from library |
| file_folder_picker | material | Icons.folder | - | lib/widgets/files/inline_file_picker.dart:243 | Button | Choose folder |
| file_videocam | material | Icons.videocam | - | lib/screens/files/file_manager_screen.dart:198, lib/screens/files/coach_file_feedback_screen.dart:827 | Icon | Video file type |
| file_refresh | material | Icons.refresh | - | lib/screens/files/file_manager_screen.dart:213, lib/screens/files/coach_file_feedback_screen.dart:440 | Button | Refresh file list |
| file_search | material | Icons.search | - | lib/screens/files/file_manager_screen.dart:243, lib/screens/files/coach_file_feedback_screen.dart:473 | Search field | Search files |
| file_edit | material | Icons.edit | - | lib/screens/files/coach_file_feedback_screen.dart:582, 672 | Button | Edit file |
| file_comment | material | Icons.comment | - | lib/screens/files/coach_file_feedback_screen.dart:582 | Icon | File comment |
| file_delete | material | Icons.delete | - | lib/screens/files/file_manager_screen.dart:470 | Button | Delete file |
| file_picture_pdf | material | Icons.picture_as_pdf / Icons.picture_as_pdf_outlined | - | lib/screens/coach/client_weekly_review_screen.dart:298 | Icon | PDF file type |
| file_video_library | material | Icons.video_library / Icons.video_library_outlined | - | Multiple files | Icon | Video library |

---

## Music/Audio

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| music_note | material | Icons.music_note | - | lib/widgets/music/music_attachment_widget.dart:114, 116, 376, 381, 483, 485, lib/widgets/music/music_play_button.dart:105, 107 | Icon | Music track indicator |
| music_add | material | Icons.add | - | lib/widgets/music/music_attachment_widget.dart:55, 302, 346 | Button | Add music track |
| music_close | material | Icons.close | - | lib/widgets/music/music_attachment_widget.dart:104, 271 | Button | Remove music track |
| music_check | material | Icons.check | - | lib/widgets/music/music_attachment_widget.dart:300 | Icon | Music selected |
| music_more | material | Icons.more_vert | - | lib/widgets/music/music_play_button.dart:59 | Button | Music options menu |

---

## Camera/Photo

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| camera_alt | material | Icons.camera_alt / Icons.camera_alt_outlined | - | Multiple files | Button | Take photo |
| camera_front | material | Icons.camera_front | - | lib/screens/nutrition/barcode_scan_screen.dart:64 | Button | Front camera |
| camera_rear | material | Icons.camera_rear | - | lib/screens/nutrition/barcode_scan_screen.dart:66 | Button | Rear camera |
| camera_flash_on | material | Icons.flash_on | - | lib/screens/nutrition/barcode_scan_screen.dart:52 | Button | Flash on |
| camera_flash_off | material | Icons.flash_off | - | lib/screens/nutrition/barcode_scan_screen.dart:50 | Button | Flash off |
| camera_photo | material | Icons.photo_camera | - | lib/components/nutrition/recipe_step_tile.dart:174, lib/components/checkins/compare_checkins_modal.dart:512 | Button | Photo camera |
| camera_keyboard | material | Icons.keyboard | - | lib/screens/nutrition/barcode_scan_screen.dart:194 | Button | Manual entry mode |
| camera_qr_code | material | Icons.qr_code | - | lib/screens/nutrition/barcode_scan_screen.dart:227, lib/screens/coach_profile/coach_profile_screen.dart:395 | Button | QR code scanner |
| camera_add_box | material | Icons.add_box | - | lib/screens/nutrition/barcode_scan_screen.dart:425 | Button | Add photo box |

---

## QR Code

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| qr_code | material | Icons.qr_code | - | lib/screens/coach_profile/coach_profile_screen.dart:395 | Button | QR code display |
| qr_scanner | material | Icons.qr_code_scanner | - | lib/screens/nutrition/widgets/shared/food_picker_2_0.dart:230 | Tab icon | QR code scanner |

---

## Common Actions

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| action_add | material | Icons.add | - | Multiple files (100+ instances) | Button | Add/create action |
| action_delete | material | Icons.delete / Icons.delete_outline | - | Multiple files | Button | Delete action |
| action_edit | material | Icons.edit / Icons.edit_outlined | - | Multiple files | Button | Edit action |
| action_save | material | Icons.save / Icons.save_outlined | - | lib/screens/workout/fatigue_recovery_screen.dart:89, lib/widgets/admin/support/draft_handoff_sheet.dart:121 | Button | Save action |
| action_close | material | Icons.close | - | Multiple files (50+ instances) | Button | Close/dismiss |
| action_check | material | Icons.check | - | Multiple files | Button | Confirm/check |
| action_search | material | Icons.search | - | Multiple files (80+ instances) | Search field | Search action |
| action_clear | material | Icons.clear | - | Multiple files | Button | Clear input |
| action_share | material | Icons.share | - | lib/screens/plans/plans_dashboard_screen.dart:1073, lib/screens/share/share_preview_screen.dart:122 | Button | Share action |
| action_copy | material | Icons.copy | - | lib/screens/share/share_preview_screen.dart:35 | Button | Copy to clipboard |
| action_more | material | Icons.more_vert | - | Multiple files | Button | More options menu |
| action_refresh | material | Icons.refresh | - | Multiple files | Button | Refresh/reload |
| action_visibility | material | Icons.visibility | - | Multiple files | Button | View/preview |
| action_info | material | Icons.info_outline | - | Multiple files | Button | Information tooltip |
| action_warning | material | Icons.warning / Icons.warning_amber_rounded | - | Multiple files | Icon | Warning indicator |
| action_error | material | Icons.error / Icons.error_outline | - | Multiple files | Icon | Error indicator |
| action_success | material | Icons.check_circle | - | Multiple files | Icon | Success indicator |
| action_play | material | Icons.play_arrow / Icons.play_arrow_rounded / Icons.play_circle_outline | - | Multiple files | Button | Play action |
| action_pause | material | Icons.pause / Icons.pause_rounded | - | Multiple files | Button | Pause action |
| action_stop | material | Icons.stop | - | Multiple files | Button | Stop action |
| action_schedule | material | Icons.schedule | - | Multiple files | Icon | Schedule/time |
| action_timer | material | Icons.timer | - | lib/screens/supplements/supplement_editor_sheet.dart:636 | Icon | Timer |
| action_redo | material | Icons.redo | - | lib/widgets/admin/support/draft_handoff_sheet.dart:129, lib/screens/admin/support/widgets/ticket_card.dart:128 | Button | Redo/undo action |

---

## Status Indicators

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| status_check | material | Icons.check | - | Multiple files | Status icon | Completed/checked |
| status_check_circle | material | Icons.check_circle / Icons.check_circle_outline | - | Multiple files | Status icon | Success/completed |
| status_cancel | material | Icons.cancel | - | Multiple files | Status icon | Cancelled |
| status_pending | material | Icons.pending / Icons.pending_outlined | - | Multiple files | Status icon | Pending status |
| status_snooze | material | Icons.snooze | - | Multiple files | Status icon | Snoozed |
| status_warning | material | Icons.warning / Icons.warning_amber_rounded | - | Multiple files | Status icon | Warning |
| status_error | material | Icons.error / Icons.error_outline | - | Multiple files | Status icon | Error |
| status_info | material | Icons.info / Icons.info_outline | - | Multiple files | Status icon | Information |
| status_priority | material | Icons.priority_high | - | Multiple files | Status icon | High priority |
| status_link | material | Icons.link | - | lib/components/feedback/animated_feedback.dart:300 | Status icon | Connected/linked |
| status_emoji_events | material | Icons.emoji_events | - | lib/services/navigation/notification_deep_link_handler.dart:208 | Status icon | Achievement/milestone |
| status_bedtime | material | Icons.bedtime | - | lib/services/navigation/notification_deep_link_handler.dart:140 | Status icon | Sleep/bedtime reminder |

---

## Other

| ID | Type | Current Icon | Asset Path | Screens/Files | Usage Context | Description |
|----|------|--------------|------------|---------------|---------------|-------------|
| other_star | material | Icons.star / Icons.star_border | - | Multiple files | Button | Favorite/rating |
| other_favorite | material | Icons.favorite / Icons.favorite_border | - | Multiple files | Button | Favorite toggle |
| other_checkbox | material | Icons.check_box / Icons.check_box_outline_blank | - | lib/screens/nutrition/widgets/shared/food_picker_2_0.dart:191 | Button | Multi-select checkbox |
| other_compare | material | Icons.compare_arrows | - | lib/components/checkins/compare_checkins_modal.dart:209, 416 | Icon | Compare items |
| other_keyboard_up | material | Icons.keyboard_arrow_up | - | lib/components/nutrition/recipe_step_tile.dart:216 | Button | Move up |
| other_keyboard_down | material | Icons.keyboard_arrow_down | - | lib/components/nutrition/recipe_step_tile.dart:231 | Button | Move down |
| other_play_circle | material | Icons.play_circle_outline | - | Multiple files | Icon | Play video/media |
| other_school | material | Icons.school | - | Multiple files | Icon | Education/learning |
| other_restaurant_menu | material | Icons.restaurant_menu | - | lib/screens/learn/learn_coach_screen.dart:104 | Icon | Nutrition learning |
| other_chat_bubble | material | Icons.chat_bubble_outline | - | lib/screens/learn/learn_coach_screen.dart:154 | Icon | Messaging learning |
| other_people_learn | material | Icons.people | - | lib/screens/learn/learn_coach_screen.dart:79 | Icon | People/coaching learning |
| other_fitness_learn | material | Icons.fitness_center | - | lib/screens/learn/learn_coach_screen.dart:129 | Icon | Workout learning |
| other_medication | material | Icons.medication / Icons.local_pharmacy_outlined | - | Multiple files | Icon | Medication/supplements |
| other_payments | material | Icons.payments_outlined | - | lib/components/nutrition/cost_summary.dart:27 | Icon | Payment/cost |
| other_card_giftcard | material | Icons.card_giftcard | - | lib/screens/settings/user_settings_screen.dart:354 | Icon | Gift card/rewards |
| other_construction | material | Icons.construction | - | lib/widgets/coach/quick_actions_grid.dart:352 | Icon | Under construction |
| other_auto_awesome | material | Icons.auto_awesome | - | Multiple files | Icon | AI/automation feature |
| other_bolt | material | Icons.bolt | - | Multiple files | Icon | Quick action/power |
| other_table_view | material | Icons.table_view | - | lib/screens/admin/support/support_inbox_screen.dart:246 | Icon | Table view |
| other_show_chart | material | Icons.show_chart | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:522 | Icon | Chart view |
| other_lightbulb | material | Icons.lightbulb_outline | - | lib/screens/nutrition/widgets/shared/nutrition_insights_panel.dart:506 | Icon | Tip/idea |
| other_notifications | material | Icons.notifications / Icons.notifications_outlined | - | Multiple files | Icon | Notification |
| other_trending_up | material | Icons.trending_up | - | Multiple files | Icon | Trending/upward trend |
| other_playlist_add_check | material | Icons.playlist_add_check | - | lib/screens/admin/admin_ticket_queue_screen.dart:343 | Icon | Batch selection |
| other_checklist | material | Icons.checklist | - | lib/screens/admin/admin_ticket_queue_screen.dart:654 | Icon | Checklist |
| other_drag_indicator | material | Icons.drag_indicator | - | lib/screens/admin/support/support_inbox_screen.dart:872 | Icon | Drag handle |
| other_open_in_new | material | Icons.open_in_new | - | lib/screens/admin/support/support_inbox_screen.dart:867 | Icon | Open external |
| other_picture_pdf | material | Icons.picture_as_pdf / Icons.picture_as_pdf_outlined | - | Multiple files | Icon | PDF document |
| other_edit_note | material | Icons.edit_note | - | Multiple files | Icon | Edit note |
| other_videocam | material | Icons.videocam / Icons.videocam_outlined | - | Multiple files | Icon | Video call/camera |

---

## Summary Statistics

### By Icon Type
- **Material Icons:** ~480 instances
- **Custom Icons:** 1 instance (HalfPillIcon)
- **SVG Assets:** 0 instances found
- **PNG Assets:** 0 icon-specific assets found (only logos)
- **Cupertino Icons:** 0 instances found

### By Feature Group
- **Navigation:** 13 icons
- **Workout:** 18 icons
- **Nutrition:** 20 icons
- **Messaging:** 11 icons
- **Calendar:** 10 icons
- **Metrics/Progress:** 18 icons
- **Admin:** 35 icons
- **Settings/Profile:** 9 icons
- **Files/Media:** 17 icons
- **Music/Audio:** 5 icons
- **Camera/Photo:** 8 icons
- **QR Code:** 2 icons
- **Common Actions:** 25 icons
- **Status Indicators:** 12 icons
- **Other:** 25 icons

**Total Unique Icon IDs:** 228

---

## High Priority Replacements

### Mismatched Icons
1. **nutrition_supplement_pill** - Currently uses custom HalfPillIcon (good), but some supplement contexts may use generic medication icons
2. **metrics_sodium** - No specific icon found; may be using generic restaurant/food icons
3. **workout_intensity** - No specific icon found; may need dedicated intensity indicator

### Low Quality / Inconsistent
1. **Multiple "add" icons** - Icons.add, Icons.add_circle_outline, Icons.add_box used inconsistently
2. **Multiple "delete" icons** - Icons.delete, Icons.delete_outline used inconsistently
3. **Multiple "edit" icons** - Icons.edit, Icons.edit_outlined, Icons.edit_note used inconsistently
4. **Multiple "close" icons** - Icons.close, Icons.clear, Icons.cancel used for similar purposes

### Repeated Icons with Different Meanings
1. **Icons.check** - Used for: confirm action, completed status, checkbox state
2. **Icons.close** - Used for: close dialog, clear input, cancel action
3. **Icons.add** - Used for: add item, create new, add to list, add attachment
4. **Icons.search** - Used consistently (good)
5. **Icons.person** - Used for: user avatar, profile, person indicator
6. **Icons.settings** - Used consistently (good)

### Missing Asset Icons
- No SVG icon assets found in `assets/icons/` directory
- All icons are Material Design icons from Flutter's Icons class
- Consider creating custom SVG icons for brand consistency

### Recommendations
1. **Standardize action icons:** Choose one variant per action (e.g., always use Icons.add, not Icons.add_circle_outline)
2. **Create custom icons for:** Supplements (already have HalfPillIcon), Workout intensity, Nutrition metrics
3. **Consider icon family:** All icons should follow same style (outlined vs filled, rounded vs sharp)
4. **Add missing icons:** Specific icons for sodium, intensity, fatigue, digestion tracking
5. **Icon size consistency:** Document standard sizes (16, 18, 20, 24, 32, 48)

---

**Note:** This inventory was generated by scanning the codebase for Icon() widgets, Material Icons, and custom icon components. Some icons may be used in contexts not captured here if they're dynamically generated or conditionally rendered.
