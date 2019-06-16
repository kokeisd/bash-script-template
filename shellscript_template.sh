#!/bin/bash 
#
# Developed by: X
#
# <script name and description>
# -----------------------------
#
#
#
#
# Revision History
# ----------------
#
# 1.1	text...
# 1.0	text....
#

## CONFIGURATION ##########################################################################################################################
ENABLE_LOG="0"							# LOGS WILL BE WRITTEN TO LOGFILE
ENABLE_TIME="0"							# EXECUTION TIME WILL BE PRESENTED AT END OF SCRIPT
ENABLE_ARGUMENT="0"						# ARGUMENT IS OBLIGATORY TO LAUNCH THE SCRIPT
ENABLE_COLORS="1"						# COLOR ON SCREEN OUTPUT POSSIBLE
ENABLE_CHECKREQ="0"						# CHECKS IF COMMANDS AVAILABLE, SEE SECTION "CHECK REQUIREMENTS"

## VARIABLES
STARTTIME="$(date '+%s')"
LOGFILE="$(basename $0).$(date '+%Y%m%d-%H%M%S').log"
SCRIPTNAME="$(basename $0)"
SCRIPTVERSION=$(echo "${SCRIPTNAME%???}" | awk 'BEGIN{ FS="v"; }{ print $NF;}')

### DISPLAY USAGE #########################################################################################################################
function displayusage {
cat << USAGE
  Usage: 	./$(basename $0) PATTERN
	ADD USAGE DETAILS HERE


USAGE
echo "$2"; exit "$1"
}



### CHECK REQUIREMENTS ####################################################################################################################
COMMANDREQ=("mktemp" "date" "sed" "basename" "awk" "tr" "nc")  # ADD OTHER REQUIRED COMMANDS
function check_prereq {
  local RETURNCODE="0"
  for COMMAND in "${COMMANDREQ[@]}"; do
    type "$COMMAND" > /dev/null 2>&1 && log "$COMMAND = OK" || { error "$COMMAND not existant"; RETURNCODE="1"; }
  done
  return "$RETURNCODE"
}

### PREDEFINED FUNCTIONS ##################################################################################################################
function debugger { set -x; $@; set +x; }			# ADD FUNCTION IN FRONT OF COMMAND OR FUNCTION TO DEBUG

## INCREASE VERSION OF FILE
function increase_version {
  local SEPARATOR="v"
  local SUFFIX=".sh"
  local SCRIPTNAMESHORT="$(echo "${SCRIPTNAME%???}" | awk -v separator="$SEPARATOR" 'BEGIN{ FS=separator; }{ print ( $(NF-1) );}')"
  local NEXTVERSION="$(( $(echo "${SCRIPTNAME%???}" | awk -v separator="$SEPARATOR" 'BEGIN{ FS=separator; }{ print $NF;}') + 1 ))"
  local NEXTSCRIPTNAME="$SCRIPTNAMESHORT$SEPARATOR$NEXTVERSION$SUFFIX"
  file_exists "$NEXTSCRIPTNAME" && fatal "$NEXTSCRIPTNAME already exists" || cp "$SCRIPTNAME" "$NEXTSCRIPTNAME"
}

## FUNCTION TO ADD MULTIPLE TRAPS
declare -a ONEXITCOMMANDS					# ARRAY TO STORE TRAP COMMANDS

function on_exit {						# LAUNCH COMMANDS ON EXIT AND DISPLAYS RUNNING TIME IF ENABLED
  for COMMAND in "${ONEXITCOMMANDS[@]}"; do eval "$COMMAND"; done
  [ "$ENABLE_TIME" = "1" ] && wait && runningtime "$STARTTIME"
}

function trap_on_exit {
  local POSITION=${#ONEXITCOMMANDS[*]}                  	# IDENTIFYING NEXT EMPTY SLOT IN THE ARRAY
  ONEXITCOMMANDS[$POSITION]="$*"                        	# ADDING THE COMMANDS IN ARRAY
  if [[ $POSITION -eq 0 ]]; then trap on_exit INT TERM EXIT; fi  	# APPLY TRAP COMMAND ON FIRST REQUEST
}

trap_on_exit "wait"						# HAS TO BE ADDED AS THE FIRST TRAP COMMAND IN ORDER TO ENSURE ALL PROCESSES ARE DONE BEFORE REMOVING TEMPORARY FILES

## STRUCTURE FOR TEMPORARY FILES ###
TEMPDIR=$(mktemp -d  "$PWD/$(basename $0).tmp.XXXX")		# CREATE TEMPORARY DIRECTORY
trap_on_exit "rm -Rf $TEMPDIR"					# REMOVE TEMPORARY DIRECTORY UPON SCRIPT EXIT

function assigntempfile {					# CREATE TEMPORARY FILE AND RETURN VALUE
  local TEMPFILE=$(mktemp "$TEMPDIR/tmp.XXX")
  echo "$TEMPFILE"
}

## LOG FUNCTIONS
function techo { echo -e "$2$(timestamp) - $1 $ALL_RESET"; }						# TIMESTAMPS THE ECHO, COLOR LINE IF REQUESTED IN $2
function log { [ "$ENABLE_LOG" -eq "1" ] && techo "$1" "$2" | tee -a "$LOGFILE" || techo "$1" "$2"; }		# PRINT MESSAGE ON SCREEN + WRITES IN LOGFILE IF ENABLED
function error { log "[ERROR] - $*" "$FG_LRED"; }						# SAME AS LOG + [ERROR] IN MESSAGE
function fatal { echo ""; log "[FATAL] - $*" "$FG_RED"; exit 1; }					# SAME AS LOG + [FATAL] IN MESSAGE + EXIT SCRIPT


function runningtime { 
  DIFF=$(( $(date '+%s') - $STARTTIME ))
  techo "Running time: $(date -u -d @${DIFF} +"%T") (HH:MM:SS)" "$FG_MAGENTA"		#WORKS IN CYGWIN
}

## TIME AND DATE
function timestamp { date '+[%T]' ; }
function ss { date '+%S'; }
function hhmm { date '+%H%M'; }
function yyyymmdd { date '+%Y%m%d'; }
function yyyymmdd-hhmm { date "+%Y%m%d-%H%M"; }
function dateconvert1 { sed 's_\([0-9]\{1,2\}\)/\([0-9]\{1,2\}\)/\([0-9]\{4\}\)_\3-\2-\1_g'; }		# CONVERTS FROM DD/MM/YYYY to YYYY-MM-DD


## COLORS AND FORMATTING
function setcolors {
ALL_RESET="\e[0m"
FG_DEFAULT="\e[39m";	BG_DEFAULT="\e[49m"
FG_BLACK="\e[30m";	BG_BLACK="\e[40m"
FG_RED="\e[31m";	BG_RED="\e[41m"
FG_GREEN="\e[32m";	BG_GREEN="\e[42m"
FG_YELLOW="\e[33m";	BG_YELLOW="\e[43m"
FG_BLUE="\e[34m";	BG_BLUE="\e[44m"
FG_MAGENTA="\e[35m";	BG_MAGENTA="\e[45m"
FG_CYAN="\e[36m";	BG_CYAN="\e[46m"
FG_LGREY="\e[37m";	BG_LGREY="\e[47m"
FG_DGREY="\e[90m";	BG_DGREY="\e[100m"
FG_LRED="\e[91m";	BG_LRED="\e[101m"
FG_LGREEN="\e[92m";	BG_LGREEN="\e[102m"
FG_LYELLOW="\e[93m";	BG_LYELLOW="\e[103m"
FG_LBLUE="\e[94m";	BG_LBLUE="\e[104m"
FG_LMAGENTA="\e[95m";	BG_LMAGENTA="\e[105m"
FG_LCYAN="\e[96m";	BG_LCYAN="\e[106m"
FG_WHITE="\e[97m";	BG_WHITE="\e[107m"
}


## STRING OPERATIONS

function tolower { echo "$*" | tr '[:upper:]' '[:lower:]'; }	# SETS ALL CHARACTERS TO LOWER CASE
function toupper { echo "$*" | tr '[:lower:]' '[:upper:]'; }	# SETS ALL CHARACTERS TO UPPER CASE


function replace_line {						# Syntax: replace_line "<FILENAME>" "<LINENUMBER>" "<NEWTEXT>" 
  local TEMPFILE=$(assigntempfile)
  awk -v linenumber="$2" -v newline="$3" '{ if ( NR == linenumber ) print newline; else print $0 }' "$1" > "$TEMPFILE" && mv "$TEMPFILE" "$1"
}


## PARAMETER MODIFICATION
# File format: <parameter><fieldseparator><value>
FIELDSEPARATOR="="

function get_value {			# Syntax: get_value "<file>" "<parameter>"
  awk -v parameter="$2" -v fieldseparator="$FIELDSEPARATOR" 'BEGIN{ FS=fieldseparator; }{ if ( $1 == parameter ) print $2 }' "$1"
}

function modify_value {			# Syntax: modify_value "<file>" "<parameter>" "<newvalue>"
  local TEMPFILE=$(assigntempfile)
  awk -v parameter="$2" -v newvalue="$3" -v fieldseparator="$FIELDSEPARATOR" 'BEGIN{ FS=fieldseparator; OFS=fieldseparator }{ if ( $1 == parameter ) print $1,newvalue; else print $0; }' "$1" > "$TEMPFILE" && mv "$TEMPFILE" "$1"
}

## CHECKS

function has_value { [ -z "$*" ] && return 1 || return 0; }		# CHECKS IF VARIABLE HAS VALUE
function file_exists { [ -f "$*" ] && return 0 || return 1; }		# CHECKS IF FILE EXISTS
function directory_exists { [ -d "$*" ] && return 0 || return 1; }	# CHECKS IF DIRECTORY EXISTS

### START #################################################################################################################################


case "$1" in
  "--help"|"-h" ) 	displayusage "0"
             		;;
  "-iv" ) 		increase_version		# COPIES THIS FILE TO NEW WITH INCREMENTED VERSION NUMBER
        		;;
  *)			[ "$ENABLE_ARGUMENT" = "1" ] && [ -z "$1" ] && displayusage "1" "=> MISSING ARGUMENT"
esac

[[ "$ENABLE_COLORS" = "1" ]] && [[ "$TERM" = "xterm" && "aixterm" ]] && setcolors	# ONLY ACTIVATES IF TERMINAL = xterm OR aixterm
[[ "$ENABLE_CHECKREQ" = "1" ]] && { check_prereq || fatal "Commands defined in COMMANDREQ are not available on this system, please review if required"; }	# CHECKS EXISTANCE OF COMMANDS

### TEMPFILE CREATION #####################################################################################################################
# USAGE: VARIABLENAME=$(assigntempfile)




### FUNCTIONS #############################################################################################################################





### SCRIPT ################################################################################################################################






### END ###################################################################################################################################
wait									# WAIT FOR BACKGROUND JOBS TO FINISH
[ "$ENABLE_LOG" -eq "1" ] && techo "Logfile: $LOGFILE" "$FG_MAGENTA"	# DISPLAY LOGFILE
exit 0








###########################################################################################################################################
### BASH INFORMATION AND EXAMPLES #########################################################################################################
###########################################################################################################################################

#
# VARIABLES
#

# Declare 
VARIABLENAME="value"
ARRAY=("value1" "value2" "value3")
ARRAY[0]="value1"				# Indexing starts at zero

# Dereferencing
echo "$VARIABLENAME"	=> value
echo "${ARRAY[0]}"	=> value1
echo "${ARRAY[@]}"	=> value1 value2 value3
echo "${#ARRAY[@]}"	=> 3			# Indexing starts at 1



#
# FUNCTION
#

function functionname {
  commands
}

#
# IF
#

if <condition>; then
  commands
elif <condition>; then		# optional
  commands
else				# optional
  commands
fi

#
# FOR
#

for VARNAME in 1 2 3; do
  commands
done

#
# WHILE
#

while <condition>; do
  commands
done

#
# UNTIL
#

until <condition>; do
  commands
done

#
#
#

case expression in
  pattern1 ) 	command1	# Pattern examples: "y", "n" [yY], [nN], [yY][eE][sS], [y|Y] 
	     	command2
             	;;
  pattern2 ) 	command1
	     	command2
        	;;
  *)		command1
	  	command2
esac



#
# CONDITIONS
#

[ -a FILE ] 			# True if FILE exists. 
[ -b FILE ] 			# True if FILE exists and is a block-special file. 
[ -c FILE ]     		# True if FILE exists and is a character-special file. 
[ -d FILE ]     		# True if FILE exists and is a directory. 
[ -e FILE ]     		# True if FILE exists. 
[ -f FILE ] 			# True if FILE exists and is a regular file. 
[ -g FILE ] 			# True if FILE exists and its SGID bit is set. 
[ -h FILE ] 			# True if FILE exists and is a symbolic link. 
[ -k FILE ] 			# True if FILE exists and its sticky bit is set. 
[ -p FILE ] 			# True if FILE exists and is a named pipe (FIFO). 
[ -r FILE ] 			# True if FILE exists and is readable. 
[ -s FILE ] 			# True if FILE exists and has a size greater than zero. 
[ -t FD ] 			# True if file descriptor FD is open and refers to a terminal. 
[ -u FILE ] 			# True if FILE exists and its SUID (set user ID) bit is set. 
[ -w FILE ] 			# True if FILE exists and is writable. 
[ -x FILE ] 			# True if FILE exists and is executable. 
[ -O FILE ] 			# True if FILE exists and is owned by the effective user ID. 
[ -G FILE ] 			# True if FILE exists and is owned by the effective group ID. 
[ -L FILE ] 			# True if FILE exists and is a symbolic link. 
[ -N FILE ] 			# True if FILE exists and has been modified since it was last read. 
[ -S FILE ] 			# True if FILE exists and is a socket. 
[ FILE1 -nt FILE2 ] 		# True if FILE1 has been changed more recently than FILE2, or if FILE1 exists and FILE2 does not. 
[ FILE1 -ot FILE2 ] 		# True if FILE1 is older than FILE2, or is FILE2 exists and FILE1 does not. 
[ FILE1 -ef FILE2 ] 		# True if FILE1 and FILE2 refer to the same device and inode numbers. 
[ -o OPTIONNAME ] 		# True if shell option "OPTIONNAME" is enabled. 
[ -z STRING ] 			# True of the length if "STRING" is zero. 
[ -n STRING ] or [ STRING ] 	# True if the length of "STRING" is non-zero. 
[ STRING1 == STRING2 ]  	# True if the strings are equal. "=" may be used instead of "==" for strict POSIX compliance. 
[ STRING1 != STRING2 ]  	# True if the strings are not equal. 
[ STRING1 < STRING2 ]  		# True if "STRING1" sorts before "STRING2" lexicographically in the current locale. 
[ STRING1 > STRING2 ]  		# True if "STRING1" sorts after "STRING2" lexicographically in the current locale. 
[ ARG1 OP ARG2 ] 		# "OP" is one of -eq, -ne, -lt, -le, -gt or -ge. These arithmetic binary operators return true if "ARG1" is equal to, not equal to, less than, less than or equal to, greater than, or greater than or equal to "ARG2", respectively. "ARG1" and "ARG2" are integers. 


#
# Example on one-liners	(; replaces return carriage)
#

function functionname { command1; command2; }
if <condition>; then command; else command; fi
for VARNAME in 1 2 3; do command; done
while <condition>; do command; done
until <condition>; do command; done

#
#  Predefined BASH variables
#

auto_resume 	# This variable controls how the shell interacts with the user and job control. 
BASH 		# The full pathname used to execute the current instance of Bash. 
BASH_ENV 	# If this variable is set when Bash is invoked to execute a shell script, its value is expanded and used as the name of a startup file to read before executing the script. 
BASH_VERSION 	# The version number of the current instance of Bash. 
BASH_VERSINFO 	# A read-only array variable whose members hold version information for this instance of Bash. 
COLUMNS 	# Used by the select built-in to determine the terminal width when printing selection lists. Automatically set upon receipt of a SIGWINCH signal. 
COMP_CWORD 	# An index into ${COMP_WORDS} of the word containing the current cursor position. 
COMP_LINE 	# The current command line. 
COMP_POINT 	# The index of the current cursor position relative to the beginning of the current command. 
COMP_WORDS 	# An array variable consisting of the individual words in the current command line. 
COMPREPLY 	# An array variable from which Bash reads the possible completions generated by a shell function invoked by the programmable completion facility. 
DIRSTACK 	# An array variable containing the current contents of the directory stack. 
EUID 		# The numeric effective user ID of the current user. 
FCEDIT 		# The editor used as a default by the -e option to the fc built-in command. 
FIGNORE 	# A colon-separated list of suffixes to ignore when performing file name completion. 
FUNCNAME 	# The name of any currently-executing shell function. 
GLOBIGNORE 	# A colon-separated list of patterns defining the set of file names to be ignored by file name expansion. 
GROUPS 		# An array variable containing the list of groups of which the current user is a member. 
histchars 	# Up to three characters which control history expansion, quick substitution, and tokenization. 
HISTCMD 	# The history number, or index in the history list, of the current command. 
HISTCONTROL 	# Defines whether a command is added to the history file. 
HISTFILE 	# The name of the file to which the command history is saved. The default value is ~/.bash_history. 
HISTFILESIZE 	# The maximum number of lines contained in the history file, defaults to 500. 
HISTIGNORE 	# A colon-separated list of patterns used to decide which command lines should be saved in the history list. 
HISTSIZE 	# The maximum number of commands to remember on the history list, default is 500. 
HOSTFILE 	# Contains the name of a file in the same format as /etc/hosts that should be read when the shell needs to complete a hostname. 
HOSTNAME 	# The name of the current host. 
HOSTTYPE 	# A string describing the machine Bash is running on. 
IGNOREEOF 	# Controls the action of the shell on receipt of an EOF character as the sole input. 
INPUTRC 	# The name of the Readline initialization file, overriding the default /etc/inputrc. 
LANG 		# Used to determine the locale category for any category not specifically selected with a variable starting with LC_. 
LC_ALL 		# This variable overrides the value of LANG and any other LC_ variable specifying a locale category. 
LC_COLLATE 	# This variable determines the collation order used when sorting the results of file name expansion, and determines the behavior of range expressions, equivalence classes, and collating sequences within file name expansion and pattern matching. 
LC_CTYPE 	# This variable determines the interpretation of characters and the behavior of character classes within file name expansion and pattern matching. 
LC_MESSAGES 	# This variable determines the locale used to translate double-quoted strings preceded by a "$" sign. 
LC_NUMERIC 	# This variable determines the locale category used for number formatting. 
LINENO 		# The line number in the script or shell function currently executing. 
LINES 		# Used by the select built-in to determine the column length for printing selection lists. 
MACHTYPE 	# A string that fully describes the system type on which Bash is executing, in the standard GNU CPU-COMPANY-SYSTEM format. 
MAILCHECK 	# How often (in seconds) that the shell should check for mail in the files specified in the MAILPATH or MAIL variables. 
OLDPWD 		# The previous working directory as set by the cd built-in. 
OPTERR 		# If set to the value 1, Bash displays error messages generated by the getopts built-in. 
OSTYPE 		# A string describing the operating system Bash is running on. 
PIPESTATUS 	# An array variable containing a list of exit status values from the processes in the most recently executed foreground pipeline (which may contain only a single command). 
POSIXLY_CORRECT # If this variable is in the environment when bash starts, the shell enters POSIX mode. 
PPID 		# The process ID of the shells parent process. 
PROMPT_COMMAND 	# If set, the value is interpreted as a command to execute before the printing of each primary prompt (PS1). 
PS3 		# The value of this variable is used as the prompt for the select command. Defaults to "'#? '" 
PS4 		# The value is the prompt printed before the command line is echoed when the -x option is set; defaults to "'+ '". 
PWD 		# The current working directory as set by the cd built-in command. 
RANDOM 		# Each time this parameter is referenced, a random integer between 0 and 32767 is generated. Assigning a value to this variable seeds the random number generator. 
REPLY 		# The default variable for the read built-in. 
SECONDS 	# This variable expands to the number of seconds since the shell was started. 
SHELLOPTS 	# A colon-separated list of enabled shell options. 
SHLVL 		# Incremented by one each time a new instance of Bash is started. 
TIMEFORMAT 	# The value of this parameter is used as a format string specifying how the timing information for pipelines prefixed with the time reserved word should be displayed. 
TMOUT 		# If set to a value greater than zero, TMOUT is treated as the default timeout for the read built-in. In an interative shell, the value is interpreted as the number of seconds to wait for input after issuing the primary prompt when the shell is interactive. Bash terminates after that number of seconds if input does not arrive. 
UID 		# The numeric, real user ID of the current user. 
