#!/bin/bash

VM_PVM="$HOME/Parallels/Windows 11.pvm"

# Parallels Desktop 업데이트 팝업 자동 닫기 (다음에 묻기 클릭)
dismiss_update_popup() {
    osascript <<'EOF' 2>/dev/null
tell application "System Events"
    if not (exists process "Parallels Desktop") then return false
    tell process "Parallels Desktop"
        repeat with w in windows
            repeat with b in buttons of w
                set bName to name of b
                if bName contains "다음에 묻기" or bName contains "Remind Me Later" or bName contains "Later" then
                    click b
                    return true
                end if
            end repeat
        end repeat
    end tell
end tell
return false
EOF
}

# VM 프로세스가 이미 실행 중이면 종료
if pgrep -x "prl_vm_app" > /dev/null; then
    exit 0
fi

# .pvm 파일을 직접 열어 Parallels가 VM을 시작/재개하도록 함 (Standard 호환)
open "$VM_PVM"

# VM 프로세스 뜰 때까지 최대 60초 대기, 매 루프마다 업데이트 팝업 확인
for i in $(seq 1 12); do
    sleep 5
    dismiss_update_popup
    if pgrep -x "prl_vm_app" > /dev/null; then
        exit 0
    fi
done

echo "ERROR: Windows VM did not start within 60 seconds" >&2
exit 1
