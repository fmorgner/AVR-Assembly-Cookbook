#! /usr/bin/env bash

LATEXPATH="/usr/texbin"

FINP=Assembly-programming-with-AVR.tex

for LANG in de en
  do
  FOUT="${FINP%%.tex}-$LANG.tex"

  ./book-helper.sh $FINP $LANG > $FOUT

  $LATEXPATH/pdflatex --file-line-error --shell-escape --synctex=1 $FOUT
  done

