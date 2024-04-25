#!/bin/bash
# Build script for testbed on mac 

# Enable echoing of commandset echo on
set echo on

# Get a list of all the .c files.
cfilenames=$(find . -type f -name "*.c") 

assembly="testbed"
compilerFlags="-g -fdeclspec -fPIC"

includeFlags="-Isrc -I../engine/src/"
linkerFlags="-L../bin -lengine -Wl,-rpath,@executable_path"

defines="-D_DEBUG -DKIMPORT"
echo "Building $assembly..."

echo clang $cfilenames $compilerFlags -o ../bin/$assembly $defines $includeFlags $linkerFlags

clang $cfilenames $compilerFlags -o ../bin/$assembly $defines $includeFlags $linkerFlags 


