#!/bin/bash
## parametre sh
## $1 : nom du dossier

cp -R src/* files/$1

cd files/$1

./extract_rows.pl conf_extract.yml

./test_merger.pl

cd ../../