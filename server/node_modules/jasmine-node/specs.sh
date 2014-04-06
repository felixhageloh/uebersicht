#!/usr/bin/env bash

entry="node lib/jasmine-node/cli.js --noStack "

echo "Running all tests located in the spec directory"
command=$entry"spec"
echo $command
time $command #/nested/uber-nested
echo -e "\033[1;35m--- Should have 59 tests and 104 assertions and 4 Failure. ---\033[0m"
echo ""

echo "Running all tests located in the spec directory with coffee option"
command=$entry"--coffee spec"
echo $command
time $command #/nested/uber-nested
echo -e "\033[1;35m--- Should have 64 tests and 109 assertions and 6 Failures. ---\033[0m"
echo ""

echo "Running all tests located in the spec directory with requirejs option"
#command=$entry"--nohelpers --runWithRequireJs spec-requirejs"
command=$entry"--runWithRequireJs spec"
echo $command
time $command
echo -e "\033[1;35m--- Should have 59 tests and 104 assertions and 4 Failure. ---\033[0m"
echo ""

echo "Running all tests located in the spec-requirejs directory with requirejs, requirejs setup, and coffee option"
command=$entry"--runWithRequireJs --requireJsSetup spec-requirejs-coffee/requirejs-setup.js --coffee spec-requirejs-coffee"
echo $command
time $command
echo -e "\033[1;35m--- Should have 2 tests and 4 assertions and 0 Failure. ---\033[0m"

echo "Running three specs file in the spec directory with coffee option"
command=$entry"--coffee spec/AsyncSpec.coffee spec/CoffeeSpec.coffee spec/SampleSpecs.js"
echo $command
time $command
echo -e "\033[1;35m--- Should have 3 tests and 3 assertions and 2 Failure. ---\033[0m"
