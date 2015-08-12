#!/bin/sh
# NOTE: dart2js is in dart-sdk/bin, which should be on the PATH
dart2js --minify --out=web/daxe.min.js web/daxe.dart
# the dart output is no longer useful
#dart2js --output-type=dart --minify --out=daxe.min.dart web/daxe.dart
rm *.js.map *.deps
