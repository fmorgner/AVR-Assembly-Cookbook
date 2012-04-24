#! /usr/bin/env bash

LANG=$2

IFS_OLD=$IFS
IFS="
"

while read -r L
  do
# schema "!de "
  if [[ "$L" =~ ^\![a-z][a-z]\  ]]
    then
#   found language tag, $S becomes the sign
    S=`expr "$L" : '\!\(..\) .*'`
    if [ "$S" == "$LANG" ]
      then
#     tag matches current mode, tag has to be removed from the line
      L=`expr "$L" : '\!.. \(.*\)'`
      else
#     tag does not match current mode, line is to be ignored
      continue
      fi
    fi

# depricated schema "%<german>"
  if [[ "$L" =~ ^\%\<.*\> ]]
    then
    S=`expr "$L" : '\%\<\(.*\)\>.*'`
    if [ "$S" == "$LANG" ]
      then
      L=`expr "$L" : '\%\<.*\>\(.*\)'`
      else
      continue
      fi
    fi

  if [[ "$L" =~ \\input{.*} ]]
    then
    F=`expr "$L" : '.*{\(.*\)}.*'`
    $0 $F $2
    continue
    fi

  echo "$L"
  done < $1

IFS=$IFS_OLD
