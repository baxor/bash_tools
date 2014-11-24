

# wait for command to return successfully, return its status. 
# Usage: wait_for "command" [timeout] [interval]
wait_for() {
  local _cmd=$1
  [[ -n $2 ]] && local _wait_timeout=$2 || local _wait_timeout=60
  [[ -n $3 ]] && local _wait_interval=$3 || local _wait_interval=10
  local _wait_time=0
  $_cmd 2>&1 >/dev/null
  _cmd_status=$?
  until [[ $_cmd_status -eq 0 ]] || [[ $_wait_time -gt $_wait_timeout ]]; do
    sleep $_wait_interval;
    let _wait_time=($_wait_time + $_wait_interval);
    $_cmd 2>&1 >/dev/null
    _cmd_status=$?
  done
  return $_cmd_status
}
