from subprocess import run
from datetime import datetime
import pytest


def extract_commands(file, out="commands.sh",
                     wrappers={"bash": "%s\n",
                               "python": "python -e 'exec(\"\"\"%s\"\"\")'\n\n"}):
    """Extract all commands for a particular language from a markdown file."""
    open_tags = {"```%s" % lang: lang for lang in wrappers}
    close_tag = "```\n"
    active = False
    start = False
    command = ""
    lang = ""
    commands = list()
    with open(file, "r") as mdfile:
        for line in mdfile:
            start = False
            for tag in open_tags:
                if line.startswith(tag):
                    active = start = True
                    lang = open_tags[tag]
            if not start and line.startswith(close_tag):
                if active:
                    commands.append(wrappers[lang] % command)
                    command = ""
                active = False
            elif not start and active:
                command += line

    with open(out, "w") as cmdfile:
        cmdfile.write("#!/usr/bin/env bash\n")
        cmdfile.write("# file: %s\n" % file)
        cmdfile.write("# extracted %s\n\n" % datetime.today())
        for cmd in commands:
            cmdfile.write(cmd)

    return commands


commands = extract_commands("docs/talk.md")


def test_cleanup():
    res = run("rm -rf dada2 tree diversity crc_diversity", shell=True)
    assert res.returncode == 0


@pytest.mark.parametrize("cmd", commands)
def test_commands(cmd):
    res = run(cmd, shell=True)
    assert res.returncode == 0
