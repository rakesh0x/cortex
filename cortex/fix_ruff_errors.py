import re

# Define the files with errors.
files_with_errors = [
    "src/intent/clarifier.py",
    "src/intent/context.py",
    "src/intent/detector.py",
    "src/intent/planner.py",
    "src/intent/llm_agent.py",
    "src/test_clarifier.py",
    "src/test_context.py",
    "src/test_intent_detection.py",
    "src/test_llm_agent.py",
    "src/test_planner.py",
]


# Perform automated fixes on these files.
def fix_file(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Replace typing.List with list
    content = re.sub(r"\btyping\.List", "list", content)

    # Replace Optional[T] with T | None
    content = re.sub(r": Optional\[(.+?)\]", r": \1 | None", content)

    # Sort imports manually if ruff fix doesn't handle it
    lines = content.splitlines()
    imports = [
        line for line in lines if line.startswith("import") or line.startswith("from")
    ]
    other_lines = [line for line in lines if line not in imports]
    sorted_imports = sorted(imports)
    content = "\n".join(sorted_imports + other_lines)

    # Write the fixes back to the file
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)


# Apply fixes to each file.
for file in files_with_errors:
    fix_file(file)
    print(f"Fixed: {file}")
