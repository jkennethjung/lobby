#!/bin/bash

rm -rf ../output/
rm -rf ../temp/

mkdir ../output/
mkdir ../temp/
ln -s ../../../../raw_local/lobby/*.txt ../temp/
split -l 100000 -d --additional-suffix=.txt ../temp/lob_issue.txt ../temp/issue

stata analysis.do 
