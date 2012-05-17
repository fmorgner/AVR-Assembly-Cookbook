#! /usr/bin/env bash

#   FILE        : book-helper.sh
#   COPYRIGHT   : (c) 2012 Manfred Mornger
#   USED BY     : book-make.sh
#
#   TESTED WITH : MacOSX, Ubuntu
#
#   ====================================================================
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

FILE=$1
LANG=$2

echo "% CALLED: $0 $1 $2"

IFS_OLD=$IFS
IFS_NEW="
"
IFS=$IFTS_NEW

while read -r LINE
  do
# schema "!de "
  if [[ "$LINE" =~ ^\![a-z][a-z]\  ]]
    then
#   found language tag, $S becomes the sign
    S=`expr "$LINE" : '\!\(..\) .*'`
    if [ "$S" == "$LANG" ]
      then
#     tag matches current mode, tag has to be removed from the line
      LINE=`expr "$LINE" : '\!.. \(.*\)'`
      else
#     tag does not match current mode, line is to be ignored
      continue
      fi
    fi

# depricated schema "%<german>"
#  if [[ "$LINE" =~ ^\%\<.*\> ]]
#    then
#    S=`expr "$LINE" : '\%\<\(.*\)\>.*'`
#    if [ "$S" == "$LANG" ]
#      then
#      L=`expr "$LINE" : '\%\<.*\>\(.*\)'`
#      else
#      continue
#      fi
#    fi

  if [[ "$LINE" =~ ^\\input\{.*\} ]]
    then
    IFS=$IFS_OLD
    INC=`expr "$LINE" : '.*{\(.*\)}.*'`
    echo "% INCLUDED: $INC for LANG $2"
    $0 $INC $2
    IFS=$IFS_NEW
    continue
    fi

  echo $LINE
  done < $FILE

IFS=$IFS_OLD
