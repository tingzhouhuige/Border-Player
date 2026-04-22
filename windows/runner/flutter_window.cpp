#include "flutter_window.h"

#include <dwmapi.h>
#include <optional>
#include <variant>

#include "flutter/generated_plugin_registrant.h"

#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif

#ifndef DWMWA_BORDER_COLOR
#define DWMWA_BORDER_COLOR 34
#endif

#ifndef DWMWCP_DEFAULT
#define DWMWCP_DEFAULT 0
#endif

#ifndef DWMWCP_DONOTROUND
#define DWMWCP_DONOTROUND 1
#endif

#ifndef DWMWA_COLOR_NONE
#define DWMWA_COLOR_NONE 0xFFFFFFFE
#endif

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  InitBorderPlayerWindowChannel();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::InitBorderPlayerWindowChannel() {
  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "border_player_window",
          &flutter::StandardMethodCodec::GetInstance());

  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name().compare("setBorderlessFullScreen") == 0) {
          bool is_full_screen = false;
          const auto* arguments =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments) {
            auto it = arguments->find(flutter::EncodableValue("isFullScreen"));
            if (it != arguments->end()) {
              if (const bool* value = std::get_if<bool>(&it->second)) {
                is_full_screen = *value;
              }
            }
          }
          SetBorderlessFullScreen(is_full_screen);
          result->Success(flutter::EncodableValue(borderless_full_screen_));
          return;
        }

        if (call.method_name().compare("isBorderlessFullScreen") == 0) {
          result->Success(flutter::EncodableValue(borderless_full_screen_));
          return;
        }

        result->NotImplemented();
      });
}

void FlutterWindow::SetBorderlessFullScreen(bool is_full_screen) {
  HWND hwnd = GetHandle();
  if (!hwnd || is_full_screen == borderless_full_screen_) {
    return;
  }

  if (is_full_screen) {
    previous_style_ = static_cast<DWORD>(GetWindowLong(hwnd, GWL_STYLE));
    previous_ex_style_ = static_cast<DWORD>(GetWindowLong(hwnd, GWL_EXSTYLE));
    previous_placement_.length = sizeof(WINDOWPLACEMENT);
    GetWindowPlacement(hwnd, &previous_placement_);

    HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    MONITORINFO monitor_info{sizeof(MONITORINFO)};
    if (!GetMonitorInfo(monitor, &monitor_info)) {
      return;
    }

    SetWindowLong(hwnd, GWL_STYLE,
                  (previous_style_ & ~WS_OVERLAPPEDWINDOW) | WS_POPUP);
    SetWindowLong(hwnd, GWL_EXSTYLE,
                  previous_ex_style_ &
                      ~(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE |
                        WS_EX_CLIENTEDGE | WS_EX_STATICEDGE));
    const DWORD corner_preference = DWMWCP_DONOTROUND;
    const COLORREF border_color = DWMWA_COLOR_NONE;
    DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE,
                          &corner_preference, sizeof(corner_preference));
    DwmSetWindowAttribute(hwnd, DWMWA_BORDER_COLOR, &border_color,
                          sizeof(border_color));
    SetWindowPos(hwnd, HWND_TOPMOST, monitor_info.rcMonitor.left,
                 monitor_info.rcMonitor.top,
                 monitor_info.rcMonitor.right - monitor_info.rcMonitor.left,
                 monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top,
                 SWP_NOOWNERZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    borderless_full_screen_ = true;
    return;
  }

  SetWindowLong(hwnd, GWL_STYLE, previous_style_);
  SetWindowLong(hwnd, GWL_EXSTYLE, previous_ex_style_);
  const DWORD corner_preference = DWMWCP_DEFAULT;
  const COLORREF border_color = DWMWA_COLOR_NONE;
  DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE,
                        &corner_preference, sizeof(corner_preference));
  DwmSetWindowAttribute(hwnd, DWMWA_BORDER_COLOR, &border_color,
                        sizeof(border_color));
  SetWindowPlacement(hwnd, &previous_placement_);
  SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOOWNERZORDER |
                   SWP_NOACTIVATE | SWP_FRAMECHANGED);
  borderless_full_screen_ = false;
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
