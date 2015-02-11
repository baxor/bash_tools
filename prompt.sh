export Color_Off='\e[0m'       # Text Reset
# Regular Colors
export Black='\e[0;30m'        # Black
export Red='\e[0;31m'          # Red
export Green='\e[0;32m'        # Green
export Yellow='\e[0;33m'       # Yellow
export Blue='\e[0;34m'         # Blue
export Purple='\e[0;35m'       # Purple
export Cyan='\e[0;36m'         # Cyan
export White='\e[0;37m'        # White

# Bold
export BBlack='\[\e[1;30m\]'       # Black
export BRed='\[\e[1;31m\]'         # Red
export BGreen='\[\e[1;32m\]'       # Green
export BYellow='\[\e[1;33m\]'      # Yellow
export BBlue='\[\e[1;34m\]'        # Blue
export BPurple='\[\e[1;35m\]'      # Purple
export BCyan='\[\e[1;36m\]'        # Cyan
export BWhite='\[\e[1;37m\]'       # White

# Underline
export UBlack='\e[4;30m'       # Black
export URed='\e[4;31m'         # Red
export UGreen='\e[4;32m'       # Green
export UYellow='\e[4;33m'      # Yellow
export UBlue='\e[4;34m'        # Blue
export UPurple='\e[4;35m'      # Purple
export UCyan='\e[4;36m'        # Cyan
export UWhite='\e[4;37m'       # White

# Background
export On_Black='\e[40m'       # Black
export On_Red='\e[41m'         # Red
export On_Green='\e[42m'       # Green
export On_Yellow='\e[43m'      # Yellow
export On_Blue='\e[44m'        # Blue
export On_Purple='\e[45m'      # Purple
export On_Cyan='\e[46m'        # Cyan
export On_White='\e[47m'       # White

# High Intensity
export IBlack='\e[0;90m'       # Black
export IRed='\e[0;91m'         # Red
export IGreen='\e[0;92m'       # Green
export IYellow='\e[0;93m'      # Yellow
export IBlue='\e[0;94m'        # Blue
export IPurple='\e[0;95m'      # Purple
export ICyan='\e[0;96m'        # Cyan
export IWhite='\e[0;97m'       # White

# Bold High Intensity
export BIBlack='\e[1;90m'      # Black
export BIRed='\e[1;91m'        # Red
export BIGreen='\e[1;92m'      # Green
export BIYellow='\e[1;93m'     # Yellow
export BIBlue='\e[1;94m'       # Blue
export BIPurple='\e[1;95m'     # Purple
export BICyan='\e[1;96m'       # Cyan
export BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
export On_IBlack='\e[0;100m'   # Black
export On_IRed='\e[0;101m'     # Red
export On_IGreen='\e[0;102m'   # Green
export On_IYellow='\e[0;103m'  # Yellow
export On_IBlue='\e[0;104m'    # Blue
export On_IPurple='\e[10;95m'  # Purple
export On_ICyan='\e[0;106m'    # Cyan
export On_IWhite='\e[0;107m'   # White


[ -e /proc/cpuinfo ] && CPURAW=`grep processor /proc/cpuinfo |wc -l` || CPURAW=`sysctl hw.ncpu|cut -d\  -f 2`
let CPUCOUNT=(${CPURAW} * 100) #we remove the decimal from load, so multiply cpu count by 100 for easy computin'

function EXT_COLOR () {
  COLOR=$1
  echo -ne "\[\033[38;5;${COLOR}m\]";
}

git_prompt ()
{
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "${Color_Off}$(EXT_COLOR 61)-n/a-"
    return 0
  fi
  git_branch=$(git branch 2>/dev/null| sed -n '/^\*/s/^\* //p')
  git_project=$(git remote -v | head -n1 | awk '{print $2}' | sed 's/.*\///' | sed 's/\.git//' 2>/dev/null )
  [ "$?" -gt 0 ] && git_project=""

  if git diff --quiet 2>/dev/null >&2; then
    git_color="${BGreen}"
  else
    git_color=$(EXT_COLOR 172)
  fi
  echo "${Color_Off}$(EXT_COLOR 163)${git_project}${BWhite}:$git_color$git_branch${BWhite}"
}

ps --version &>/dev/null
[ $? -eq 0 ] && LINUX="linux"

function promptExit {
  CMDSTATUS="$?"
  [ "${LINUX}" == "linux" ] && PROCSTAT=$(ps axo %cpu,comm|grep -v COMMAND|sort -n|grep -v migration|tail -n 1|awk '{printf("%s %s", $2, $1);}') || PROCSTAT=$(ps axro %cpu,comm|head -n 2 |tail -n 1| awk 'function bn(p) { n=split(p,a,"/"); return a[n]; } { printf("%s %s", bn($2), $1); }')
  TOPPROC=$(echo $PROCSTAT |cut -d\  -f 1)
  TPROCCPURAW=$(echo $PROCSTAT |cut -d\  -f 2)
  TPROCCPU=$(echo $TPROCCPURAW|cut -d. -f 1)
  LOAD1=$(w | head -n1 | grep -oE '\d\.\d\d \d\.\d\d \d\.\d\d$'|awk '{print $1}')
  LOAD1INT=$(echo ${LOAD1}|sed -e 's/\.//')
  [ "${EUID}" -eq "0" ] && export userstring="${BRed}\h" || userstring="$(EXT_COLOR 39)\u@\h";
  if [ "$LOAD1INT" -gt "${CPUCOUNT}" ]; then
    LOADSTATE=${BRed};
  elif [ "$LOAD1INT" -gt "$[ ${CPUCOUNT} / 2 ]" ]; then
    LOADSTATE=$(EXT_COLOR 172)
  elif [ "$LOAD1INT" -gt "$[ ${CPUCOUNT} / 4 ]" ]; then
    LOADSTATE=$(EXT_COLOR 227)
  else
    LOADSTATE=$(EXT_COLOR 154)
  fi

  PROCSTATE=""
  if [ "${TPROCCPU}" -gt "60" ]; then
    PROCSTATE=${BRed};
  elif [ "${TPROCCPU}" -gt "40" ]; then
    PROCSTATE=$(EXT_COLOR 172)
  elif [ "${TPROCCPU}" -gt "20" ]; then
    PROCSTATE=$(EXT_COLOR 227)
  else
    PROCSTATE="${Color_Off}$(EXT_COLOR 154)"
  fi
  case ${CMDSTATUS} in
    "0")
      statcolor="${BGreen}";
      txtcolor="$(EXT_COLOR 247)"
      cmdmarker="[${BGreen}\342\234\223${BWhite}]";
    ;;
    "1")
      statcolor="${BRed}"
      txtcolor="$(EXT_COLOR 196)"
      cmdmarker="[${BRed}\342\234\227${BWhite}]";
    ;;
   "127")
      statcolor="$(EXT_COLOR 172)"
      txtcolor="$(EXT_COLOR 172)"
      cmdmarker="[$(EXT_COLOR 172)\342\234\227${BWhite}]";
    ;;
  esac
  #export PS1="${BWhite}\342\224\214[${BCyan}\t \d${BWhite}]\342\224\200[${statcolor}\${CMDSTATUS}${BWhite}:${BPurple}\!${BWhite}:${BYellow}\#${BWhite}:${BGreen}\j${BWhite}]\342\224\200[${userstring}${BWhite}]\342\224\200\n\342\224\234\342\224\200(${LOADSTATE}${LOAD1}${BWhite}-${PROCSTATE}${TOPPROC}/${TPROCCPURAW}${BWhite})\342\224\200(${Green}\w${BWhite})\342\224\200(${Green}\$(ls -1 | wc -l | sed 's: ::g') files, \$(ls -lah | grep -m 1 total | sed 's/total //')b\[\033[1;37m\])\342\224\200[$(git_prompt)${BWhite}]\n\342\224\224\342\224\200\342\224\220\342\230\236 ${txtcolor}"
  export PS1="${BWhite}\342\224\214[${Cyan}\t \d${BWhite}]\342\224\200[${statcolor}\${CMDSTATUS}${BWhite}:${BPurple}\!${BWhite}:${BYellow}\#${BWhite}:${BGreen}\j${BWhite}]\342\224\200[${userstring}${BWhite}]\342\224\200${cmdmarker}\n\342\224\234\342\224\200(${LOADSTATE}${LOAD1}${BWhite}-${PROCSTATE}${TOPPROC}/${TPROCCPURAW}${BWhite})\342\224\200(${Green}\w${BWhite})\342\224\200(${Green}\$(ls -1 | wc -l | sed 's: ::g') files, \$(ls -lah | grep -m 1 total | sed 's/total //')b\[\033[1;37m\])\342\224\200[$(git_prompt)${BWhite}]\n\342\224\234\342\224\200\342\230\236 ${Color_Off} ${txtcolor} "
  SEARCH=' '
  REPLACE='%20'
  PWD_URL="file://$HOSTNAME${PWD//$SEARCH/$REPLACE}"
  printf '\e]7;%s\a' "$PWD_URL"

}

PROMPT_COMMAND=promptExit
PS2="${BWhite}\342\224\234\342\224\200\342\224\200\342\230\236${Color_Off}  "
