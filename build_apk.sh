#!/bin/bash
mkdir -p ./dist
flutter pub run flutter_launcher_icons &&
    flutter build apk --split-per-abi &&
    rm -f ./dist/*
cp -f ./build/app/outputs/apk/release/*.apk ./dist/
for apk in ./dist/*.apk; do
    mv "$apk" "${apk//app/novault}"
done
