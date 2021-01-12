#!/bin/sh
# lcl-code.sh, ABr
# Starts VS Code from terminal with JAVA_HOME set properly.
JAVA_HOME='/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home'
export JAVA_HOME
code
