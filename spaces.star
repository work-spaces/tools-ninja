"""

"""

checkout.update_env(
    rule = {"name": "update_env"},
    env = {
        "paths": ["/usr/local/bin", "/usr/bin", "/bin"],
        "vars": {
            "PS1": '"(spaces) $PS1"',
        },
    },
)

version = "1.12.1"

checkout.add_repo(
    rule = {"name": "ninja"},
    repo = {"url": "https://github.com/ninja-build/ninja", "rev": "v1.12.1", "checkout": "Revision"},
)

checkout.add_repo(
    rule = {"name": "tools/sysroot-gh"},
    repo = {
        "url": "https://github.com/work-spaces/sysroot-gh",
        "rev": "v2",
        "checkout": "Revision",
    },
)

build_output = info.get_absolute_path_to_workspace()
build_dir = "build/ninja"

run.add_exec(
    rule = {"name": "configure"},
    exec = {
        "command": "cmake",
        "args": ["-Sninja", "-Bbuild/ninja", "-Wno-dev"],
    },
)

run.add_exec(
    rule = {"name": "build", "deps": ["configure"]},
    exec = {
        "command": "cmake",
        "args": ["--build", build_dir, "-j8"],
    },
)

platform = info.get_platform_name()

archive_rule_name = "archive"
archive_info = {
    "input": "build/ninja/ninja",
    "name": "ninja",
    "version": version,
    "driver": "tar.xz",
    "platform": platform,
}

archive_output = info.get_path_to_build_archive(rule_name = archive_rule_name, archive = archive_info)

run.add_archive(
    rule = {"name": archive_rule_name, "deps": ["build"]},
    archive = archive_info,
)

deploy_repo = "https://github.com/work-spaces/tools-ninja"
repo_arg = "--repo={}".format(deploy_repo)
archive_name = "ninja-v{}".format(version)

run.add_exec_if(
    rule = {"name": "check_release", "deps": ["archive"]},
    exec_if = {
        "if": {
            "command": "gh",
            "args": [
                "release",
                "view",
                archive_name,
                repo_arg,
            ],
            "expect": "Failure",
        },
        "then": ["create_release"],
    },
)

run.add_exec(
    rule = {"name": "create_release", "deps": ["check_release"], "type": "Optional"},
    exec = {
        "command": "gh",
        "args": [
            "release",
            "create",
            archive_name,
            "--generate-notes",
            repo_arg,
        ],
    },
)

run.add_exec(
    rule = {"name": "upload", "deps": ["create_release"] },
    exec = {
        "command": "gh",
        "args": [
            "release",
            "upload",
            archive_name,
            archive_output,
            repo_arg,
        ],
    },
)
