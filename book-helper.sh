#! /usr/bin/env bash

#echo Running $0

LANG=$2

IFS_OLD=$IFS
IFS="
"
while read -r L
  do
  if [[ "$L" =~ ^\![a-z][a-z]\  ]]
    then
    S=`expr "$L" : '\!\(..\) .*'`
#    echo LANGUAGE=+$S+
    if [ "$S" == "$LANG" ]
      then
      L=`expr "$L" : '\!.. \(.*\)'`
      else
      continue
      fi
    fi

  if [[ "$L" =~ ^\%\<.*\> ]]
    then
    S=`expr "$L" : '\%\<\(.*\)\>.*'`
#    echo LANGUAGE=$S
    if [ "$S" == "$LANG" ]
      then
      L=`expr "$L" : '\%\<.*\>\(.*\)'`
      else
      continue
      fi
    fi

  if [[ "$L" =~ \\input{.*} ]]
    then
#    echo FOUND: $L
    F=`expr "$L" : '.*{\(.*\)}.*'`
#    echo INPUT: $F
    $0 $F $2
    continue
    fi

  echo "$L"
  done < $1
IFS=$IFS_OLD
