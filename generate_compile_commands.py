import os
import json


def find_source_files(base_dir, extensions):
    source_files = []
    for root, _, files in os.walk(base_dir):
        for file in files:
            if file.endswith(extensions):
                source_files.append(os.path.join(root, file))
    return source_files


def generate_compile_commands(project_root, vulkan_sdk_include):
    compile_commands = []

    # Engine source files
    engine_src = os.path.join(project_root, "engine/src")
    engine_files = find_source_files(engine_src, (".c", ".m"))
    engine_command_base = (
        "clang -g -fdeclspec -fPIC -dynamiclib -install_name @rpath/libengine.dylib "
        "-D_DEBUG -DKEXPORT -Isrc -I{} "
        "-lvulkan -lobjc -framework AppKit -framework QuartzCore -c"
    ).format(vulkan_sdk_include)

    for file in engine_files:
        compile_commands.append({
            "directory": project_root,
            "command": f"{engine_command_base} {file}",
            "file": file
        })

    # Testbed source files
    testbed_src = os.path.join(project_root, "testbed/src")
    testbed_files = find_source_files(testbed_src, ".c")
    testbed_command_base = (
        "clang -g -fdeclspec -fPIC -D_DEBUG -DKIMPORT "
        "-Isrc -I../engine/src/ -L../bin -lengine -Wl,-rpath,@executable_path -c"
    )

    for file in testbed_files:
        compile_commands.append({
            "directory": os.path.join(project_root, "testbed"),
            "command": f"{testbed_command_base} {file}",
            "file": file
        })

    return compile_commands


if __name__ == "__main__":
    project_root = "/Users/ozzy/lang/c/kohi"  # Update this to your project root
    vulkan_sdk_include = os.path.join(os.environ.get("VULKAN_SDK", ""), "include")

    compile_commands = generate_compile_commands(project_root, vulkan_sdk_include)

    with open(os.path.join(project_root, "compile_commands.json"), "w") as f:
        json.dump(compile_commands, f, indent=4)
