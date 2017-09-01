#!/bin/bash

declare -A ue4editor
ue4editor_path="C:/ProgFiles/EpicGames/UE_4.17/Engine/Binaries/Win64"
ue4editor[debug]="$ue4editor_path/UE4Editor-Win64-Debug.exe"
ue4editor[debuggame]="$ue4editor_path/UE4Editor.exe"
ue4editor[development]="$ue4editor_path/UE4Editor.exe"

ue4project=UnrealTorchDev.uproject

declare -A args
args[editor,1]="-log"
args[standalone,1]="-game -log"
args[server,1]="-server -game -log"
args[listenserver,1]="main?listen -game -log"
args[client,1]="127.0.0.1 -game -log"
# https://stackoverflow.com/questions/29135227/how-do-you-run-tests-from-the-command-line
args[editor_tests,1]="-unattended -nopause -log=tests.log"
args[editor_tests,2]="-ExecCmds=Automation RunTests UnrealTorch"
args[editor_tests,3]="-testexit=Automation Test Queue Empty"
args[standalone_tests,1]="-unattended -nopause -game -log=tests.log"
args[standalone_tests,2]="-ExecCmds=Automation RunTests UnrealTorch"
args[standalone_tests,3]="-testexit=Automation Test Queue Empty"

declare -A args_debug
args_debug[debug]="-debug"
args_debug[debuggame]="-debug"
args_debug[development]=" "

if [[ $# != 2 ]] ; then
	echo "Usage: launch.bash debug|debuggame|development editor|standalone|server|listenserver|client|editor_tests|standalone_tests"
	exit 1
fi

if [[ -z "${ue4editor[$1]}" ]] || [[ -z "${args[$2,1]}" ]] || [[ -z "${args_debug[$1]}" ]]; then
	echo "Invalid arguments!"
	exit 1
fi


dos_wd=$(echo $PWD | sed 's/.cygdrive.\([a-z]\)/\1:/')

echo ${ue4editor[$1]} "\"$dos_wd/$ue4project\"" ${args[$2,1]} "\"${args[$2,2]}\"" "\"${args[$2,3]}\"" ${args_debug[$1]}
cmd /C "${ue4editor[$1]}" "$dos_wd/$ue4project" ${args[$2,1]} "${args[$2,2]}" "${args[$2,3]}" ${args_debug[$1]}


if [[ $2 == *"tests"* ]] ; then
	echo
	echo "Tests:"
	grep "LogAutomationCommandLine" "$dos_wd/Saved/Logs/tests.log"
	echo

	if grep -q "AutomationTestingLog.*Automation Test" "$dos_wd/Saved/Logs/tests.log" ; then
		echo "Successful tests:"
		GREP_COLORS='mt=01;32' ; cat "$dos_wd/Saved/Logs/tests.log" | grep "AutomationTestingLog.*Automation Test Succeeded" | grep "(.*)" # --color
		echo
		echo "Failed tests:"
		GREP_COLORS='mt=01;31' ; cat "$dos_wd/Saved/Logs/tests.log" | grep "AutomationTestingLog.*Error" | grep "Error: .*" --color
		echo
	else
		echo "No test results found in the logs. Testing in editor mode doesn't write to logs; you need to run editor-dependent tests manually via the Session Frontend."
		echo
	fi
	read -n 1 -p "Press any key to close.."
fi
