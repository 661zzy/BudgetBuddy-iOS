#!/usr/bin/env bash
# 省钱搭子 build 14 — 上架前自动检查电池组
set -u
SIM="F9BA6721-1E73-45C2-AE70-DA96C506E5FE"
PROJ="/Users/chenmingming/Documents/Claude code/BudgetBuddy-iOS"
DD="$HOME/cache/bb-dd"
R="${PRELAUNCH_RESULTS:-$HOME/Downloads/prelaunch-results.txt}"
: > "$R"

log(){ echo "[$(date +%H:%M:%S)] $*" | tee -a "$R"; }

fresh(){ xcrun simctl uninstall "$SIM" cn.budgetbuddy.BudgetBuddy >/dev/null 2>&1; }

suite(){ # suite <label> <only-testing...>
  local label="$1"; shift
  log "===== $label ====="
  local args=()
  for t in "$@"; do args+=("-only-testing:$t"); done
  cd "$PROJ" && xcodebuild test-without-building \
    -project BudgetBuddy.xcodeproj -scheme BudgetBuddy \
    -destination "platform=iOS Simulator,id=$SIM" \
    -derivedDataPath "$DD" "${args[@]}" 2>&1 \
    | grep -E "Test Case '.*' (passed|failed)" | tee -a "$R"
}

xcrun simctl boot "$SIM" >/dev/null 2>&1; sleep 3

log "GROUP 1: GuestMode (fresh install, 中文游客链路)"
fresh
suite "GuestModeUITests" "BudgetBuddyUITests/GuestModeUITests"

log "GROUP 2: StabilityFlow 3-round soak (fresh install, 登录演示账号)"
fresh
suite "StabilityFlowUITests" "BudgetBuddyUITests/StabilityFlowUITests"

log "GROUP 3: Build13 English probe + retest (fresh install, EN)"
fresh
suite "Build13English" "BudgetBuddyUITests/Build13EnglishContentProbeUITests" "BudgetBuddyUITests/Build13RetestUITests"

log "GROUP 4: Generated story art smoke (复用当前状态)"
suite "StoryArtSmoke" "BudgetBuddyUITests/GeneratedStoryArtSmokeUITests"

log "===== DONE ====="
PASS=$(grep -c "passed" "$R" || true)
FAIL=$(grep -c "failed" "$R" || true)
log "TOTAL passed=$PASS failed=$FAIL"
