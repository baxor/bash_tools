#Usage:  log_msg <info|warn|critical|whatever> "<msg>" "[logfile]"
me=$(basename $0)
LOG=$(mktemp /tmp/${me}-$$-XXXX.log)   # If LOG isn't defined after this file is included, default to some unique place in /tmp
log_msg() {
  local _type=$(echo $1 | tr '[:lower:]' '[:upper:]')
  local _msg=$2
  local _logfile=${3-$LOG}
  local _opts=''
  local _logline="[${_type}]: ${_msg}"
  # Conditionally tee to tty if we have one
  /usr/bin/tty -s && ( echo -e "${_logline}" | tee -a $_logfile ) || ( echo -e "${_logline}" >>$_logfile )
}

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

# Service functions
find_port() {
  local _svc=$1
  #TODO:  this will return multiple ports in most cases... figure out a better way. (service discovery?)
  id |grep root 2>/dev/null && local _sudo='' || local _sudo='sudo'
  local _port=$($_sudo netstat -alnp |grep LISTEN |grep $_svc|awk '{print $4}'|cut -d: -f2|tr "\\n" ' ')  #TODO: CRAP.  not all our services are going to setproctitle, huh?
  [[ "${_port}" -eq '' ]] && { return 1; } || { echo $_port; return 1; }
}

check_health() {
  local _svc=$1
  local _tmpfile=$(mktemp -t ${_svc}_health_output.XXXXX)
  local _ports=$(find_port ${_svc}) || { log_msg 'warning' "Could not determine port for ${_svc}!"; return 1; }
  #we may get back multiple ports
  for _port in $_ports; do
    local _status=$(curl --silent --output $_tmpfile --write-out "%{http_code}" localhost:${_port}/health)
    local _output=$(cat $_tmpfile) && rm -f $_tmpfile
    [[ $_status -eq 200 ]] && {
      log_msg 'info' "Got ${_status} from ${_svc}!\nOutput: ${_output}";
      return 0;
    }
  done
  # if we get here, none of the ports we found returned a 200, fail.
  log_msg 'warning' "Could not find a valid port for ${_svc}!"
  return 1
}
