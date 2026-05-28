#!/bin/bash

VM_PVM="$HOME/Parallels/Windows 11.pvm"

# VM 프로세스가 이미 실행 중이면 종료
if pgrep -x "prl_vm_app" > /dev/null; then
    exit 0
fi

# .pvm 파일을 직접 열어 Parallels가 VM을 시작/재개하도록 함 (Standard 호환)
open "$VM_PVM"

# VM 프로세스 뜰 때까지 최대 60초 대기
for i in $(seq 1 12); do
    sleep 5
    if pgrep -x "prl_vm_app" > /dev/null; then
        exit 0
    fi
done

echo "ERROR: Windows VM did not start within 60 seconds" >&2
exit 1
