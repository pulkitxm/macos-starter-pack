import pathlib
import subprocess
import sys

SWIFT_DIRECTIVES = ("swift-tools-version", "swift-format-ignore", "swiftlint:")
HASH_SUFFIXES = {".sh", ".py", ".yml", ".yaml", ".toml"}
HASH_NAMES = {"Makefile"}


def swift_comments(source):
    findings = []
    index = 0
    line = 1
    length = len(source)
    while index < length:
        if source[index] == "\n":
            line += 1
            index += 1
        elif source.startswith("//", index):
            end = source.find("\n", index)
            end = length if end == -1 else end
            text = source[index:end].strip()
            if not text[2:].strip().startswith(SWIFT_DIRECTIVES):
                findings.append((line, text))
            index = end
        elif source.startswith("/*", index):
            start_line = line
            depth = 0
            cursor = index
            while cursor < length:
                if source.startswith("/*", cursor):
                    depth += 1
                    cursor += 2
                elif source.startswith("*/", cursor):
                    depth -= 1
                    cursor += 2
                    if depth == 0:
                        break
                else:
                    line += source[cursor] == "\n"
                    cursor += 1
            findings.append((start_line, source[index:cursor].splitlines()[0].strip()))
            index = cursor
        elif source[index] in "#\"":
            cursor = index
            while cursor < length and source[cursor] == "#":
                cursor += 1
            hashes = cursor - index
            if cursor < length and source[cursor] == '"':
                quote = '"""' if source.startswith('"""', cursor) else '"'
                terminator = quote + "#" * hashes
                cursor += len(quote)
                while cursor < length and not source.startswith(terminator, cursor):
                    step = 2 if source[cursor] == "\\" and hashes == 0 else 1
                    line += source.count("\n", cursor, cursor + step)
                    cursor += step
                index = cursor + len(terminator)
            else:
                index = max(cursor, index + 1)
        else:
            index += 1
    return findings


def hash_comments(source):
    findings = []
    for number, text in enumerate(source.splitlines(), start=1):
        stripped = text.strip()
        if stripped.startswith("#") and not (number == 1 and stripped.startswith("#!")):
            findings.append((number, stripped))
    return findings


def tracked_files():
    output = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    return [pathlib.Path(name) for name in output.splitlines() if pathlib.Path(name).is_file()]


def main():
    findings = []
    for path in tracked_files():
        if path.suffix == ".swift":
            scanner = swift_comments
        elif path.suffix in HASH_SUFFIXES or path.name in HASH_NAMES:
            scanner = hash_comments
        else:
            continue
        for line, text in scanner(path.read_text(encoding="utf-8")):
            findings.append(f"{path}:{line}: {text}")
    if findings:
        print("\n".join(findings))
        print(f"{len(findings)} comment(s) found; code in this repository carries no comments")
        return 1
    print("no comments found")
    return 0


if __name__ == "__main__":
    sys.exit(main())
