#! /usr/bin/env bash

#   FILE        : book-make.sh
#   COPYRIGHT   : (c) 2012 Manfred Mornger
#   DEPENDS ON  : book-helper.sh, working TeX Installation
#
#   TESTED WITH : MacOSX, Ubuntu
#
#   Use this script to compile a tex file to pdf
#   The source file may contain includes (\input{}) and language marks
#   (Line starting with "!en " oder "!de "). This script will build a
#   summed up tex source file and compile it
#
#   The file name to compile, as the languages to compile to are coded
#   in the file. This needs to be adapted to your needs.
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

PRIVATE_LATEXPATH="/usr/texbin"

FINP=Assembly-programming-with-AVR.tex

if [ `which pdflatex` ]
  then
  LATEX=`which pdflatex`
  else
  LATEX=$PRIVATE_LATEXPATH/pdflatex
  fi

if [ ! -f $LATEX  ]
  then
  echo ERROR: pdflatex not found. You may try to adapt the PATH variable or this script.
  exit 1
  fi

for LANG in de en
  do
  FOUT="${FINP%%.tex}-$LANG.tex"
  FLOG="${FINP%%.tex}-$LANG.compile.log"

  `dirname $0`/book-helper.sh $FINP $LANG > $FOUT

  $LATEX --file-line-error --interaction nonstopmode --shell-escape --synctex=1 $FOUT >  $FLOG
  $LATEX --file-line-error --interaction nonstopmode --shell-escape --synctex=1 $FOUT >> $FLOG

  for FCLEAN in `find ${FINP%%.tex}-$LANG.*`
    do
    if ! [ ${FCLEAN:(-4)} == ".pdf" ]
      then 
      rm $FCLEAN
      fi
    done
  done

