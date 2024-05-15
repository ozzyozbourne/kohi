#!/bin/bash
# Build script for engine on mac 

# Enable echoing of commandset echo on
set echo on

# make bin in the parent if not present 
mkdir -p ../bin 

# Get a list of all the .c files.
cfilenames=$(find . -type f \( -name "*.c" -o -name "*.m" \))
echo "$cfilenames"
assembly="engine"
compilerFlags="-g -fdeclspec -fPIC -dynamiclib -install_name @rpath/lib$assembly.dylib"
# will add these later -Wall -Werror
includeFlags="-Isrc -I$VULKAN_SDK/include"


linkerFlags="-lvulkan -lobjc -framework AppKit -framework QuartzCore"
defines="-D_DEBUG -DKEXPORT"

echo "Building $assembly..."

clang $cfilenames $compilerFlags -o ../bin/lib$assembly.dylib $defines $includeFlags $linkerFlags

echo "Build Successfully"

