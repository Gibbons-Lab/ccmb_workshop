from subprocess import run
import pytest


def extract_commands(file, out="commands.sh", lang="bash"):
    """Extract all commands for a particular language from a markdown file."""
    open_tag = "```%s" % lang
    close_tag = "```"
    active = False
    command = ""
    commands = list()
    with open(file, "r") as mdfile:
        for line in mdfile:
            if line.startswith(open_tag):
                active = True
            elif line.startswith(close_tag):
                if active:
                    commands.append(command)
                    command = ""
                active = False
            elif active:
                command += line

    with open(out, "w") as cmdfile:
        cmdfile.write("#!/usr/bin/env bash\n\n")
        for cmd in commands:
            cmdfile.write(cmd + "\n")

    return commands


commands = extract_commands("docs/talk.md")


def test_cleanup():
    res = run("rm -rf dada2 tree diversity crc_diversity", shell=True)
    assert res.returncode == 0


@pytest.mark.parametrize("cmd", commands)
def test_commands(cmd):
    res = run(cmd, shell=True)
    assert res.returncode == 0
