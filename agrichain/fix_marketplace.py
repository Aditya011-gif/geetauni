
import os

file_path = r'c:\Users\adity\Downloads\geetauni - Copy\agrichain\lib\screens\marketplace_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1-indexed lines:
# Keep 1 to 441 (indices 0 to 440)
# Skip 442 to 1521 (indices 441 to 1520)
# Keep 1522 to End (indices 1521 to End)

part1 = lines[:441]
part2 = ['}\n\n'] # Close _BrowseCropsTabState
part3 = lines[1521:]

# Print debug info
print(f"Total lines: {len(lines)}")
print(f"Part 1 length: {len(part1)}")
print(f"Last line of Part 1: {part1[-1]}")
print(f"First line of Part 3: {part3[0]}")

new_content = "".join(part1 + part2 + part3)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("File updated successfully.")
