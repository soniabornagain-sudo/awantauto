#!/bin/bash

VM_NAME="Windows 11"

# Parallels 실행 확인 후 없으면 실행
if ! pgrep -x "prl_client_app" > /dev/null; then
    open -a "Parallels Desktop"
    sleep 30
fi

# VM 상태 확인 후 suspended/paused이면 resume
VM_STATUS=$(prlctl list "$VM_NAME" --output status 2>/dev/null | tail -1)
if [ "$VM_STATUS" = "suspended" ] || [ "$VM_STATUS" = "paused" ]; then
    # 방법 1: Parallels Desktop AppleScript으로 resume
    osascript <<APPLESCRIPT 2>/dev/null
tell application "Parallels Desktop"
    activate
    tell virtual machine "$VM_NAME"
        resume
    end tell
end tell
APPLESCRIPT

    # 방법 1 실패 시 방법 2: Virtual Machine 메뉴 > Resume 클릭
    if [ $? -ne 0 ]; then
        sleep 2
        osascript <<'APPLESCRIPT'
tell application "Parallels Desktop"
    activate
end tell
delay 1
tell application "System Events"
    tell process "Parallels Desktop"
        click menu item "재개" of menu "작업" of menu bar 1
    end tell
end tell
APPLESCRIPT
    fi
    sleep 15
fi

# Windows VM 프로세스 확인 후 없으면 Parallels 재시작
if ! pgrep -x "prl_vm_app" > /dev/null; then
    open -a "Parallels Desktop"
fi
