;;
;; Description: Entry point for a sample application that displays a dialog box containing
;; a custom contol that supports UI Automation.
;;
;; The control is a simple button-like control that supports InvokePattern. Clicking the
;; button causes it to change color. You can also tab to the button and click it by pressing
;; the spacebar.
;;
;; To test the functionality of InvokePattern, you can use the UISpy tool. Click on the control
;; in the UI Automation raw view or control view and then select Control Patterns from the
;; View menu. In the Control Patterns dialog box, you can call the InvokePattern::Invoke method.
;;


include winuser.inc
include resource.inc
include stdafx.inc
include Control.inc
include ole2.inc


.pragma comment(linker,
    "/manifestdependency:\""
    "type='win32' "
    "name='Microsoft.Windows.Common-Controls' "
    "version='6.0.0.0' "
    "processorArchitecture='*' "
    "publicKeyToken='6595b64144ccf1df' "
    "language='*'"
    "\""
    )

ifdef __MSLINK__

.pragma comment(linker, "/merge:.CRT=.rdata")

endif

;; Forward declarations of functions included in this code module.

DlgProc proto :HWND, :UINT, :WPARAM, :LPARAM

.code

;; Entry point.

wWinMain proc hInstance:HINSTANCE, hPrevInstance:HINSTANCE, lpCmdLine:PWSTR, nCmdShow:SINT

    CoInitialize(NULL)

    ;; Register the window class for the CustomButton control.

    CustomButton_RegisterControl(hInstance)
    DialogBox(hInstance, MAKEINTRESOURCE(IDD_MAIN), NULL, &DlgProc)
    CoUninitialize()

    .return 0

wWinMain endp

;; Message handler for application dialog.

DlgProc proc hDlg:HWND, message:UINT, wParam:WPARAM, lParam:LPARAM

    .switch edx
    .case WM_COMMAND
        .if (r8w == IDOK || r8w == IDCANCEL)

            EndDialog(rcx, r8w)
            .return TRUE
        .endif
        .endc
    .endsw
    .return FALSE

DlgProc endp

    end
