#!/bin/sh
mkdir -p log/sasl
erl -sname horst -setcookie nocookie -pa $PWD/ebin $PWD/deps/*/ebin -boot start_sasl -s lager -s horst -s toolbar 
