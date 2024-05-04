"""
convert C64List symbols file...
    chrout            = $ffd2
    llen              = $0ca4
    ones_digit        = $0ca3

...to Vice label file:
  # al $addr .label
    al $ffd2 .chrout
    al $0c04 .llen
    al $0ca3 .ones_digit
"""

import sys

if len(sys.argv) < 2:
    print(f"""
{sys.argv[0]} syntax: <c64list .sym file> <vice label file>
""")
    raise SystemExit

try:
    c64list_labels_filename = sys.argv[1]
    vice_labels_filename = sys.argv[2]

    with open(c64list_labels_filename, "r") as symbol_file:
        symbol_data = symbol_file.read()
    print(symbol_data)

    vice_labels = ["cl"]
    for line_num, text in enumerate(symbol_data.splitlines()):
        label, _, address = text.split()
        output = f"al {address} .{label}"
        print(output)
        vice_labels.append(output)

    print("Writing labels")
    with open(vice_labels_filename, "w") as f:
        for line, label in enumerate(vice_labels):
            f.write(f'{label}\n')

except FileNotFoundError:
    print(f"{c64list_labels_filename} not found")
