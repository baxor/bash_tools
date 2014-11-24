FOREMAN_HOST="foreman"

get_tag() {
    local _host="${HOSTNAME}.${DOMAINNAME}"
    local _key=$1
    [[ -z $2 ]] && local _host="${HOSTNAME}.${DOMAINNAME}" || local _host=$2
    local _url="http://${FOREMAN_HOST}/api/v2/hosts/${_host}/parameters/${_key}"
    local json_out=$(curl -s -H "Accept: application/json" $_url)
    [[ -z "$(echo "${json_out}" |grep error)" ]] || { return 1; }
    echo $json_out | grep -Po '"value":"(.*)"' | cut -d '"' -f4;
    return 0;
}

set_tag() {
  local _key=$1
  local _value=$2
  [[ -z $3 ]] && local _host="${HOSTNAME}.${DOMAINNAME}" || local _host=$3
  local _url="http://${FOREMAN_HOST}/api/v2/hosts/${_host}/parameters";
  local _method=""
  local _tag_value=$(get_tag ${_key})
  [[ $? -eq 0 ]] && { echo "Updating ${_key}.."; _method='-X PUT'; _url="${_url}/${_key}"; }
  curl -s ${_method} -H "Accept:application/json"  \
    -H 'Content-Type: application/json' \
    -d "{ \"parameter\": { \"name\": \"${_key}\", \"value\": \"${_value}\" } }" \
  $_url;
}

