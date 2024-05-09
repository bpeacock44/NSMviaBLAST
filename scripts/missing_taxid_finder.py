import os
import sys

# Check if the correct number of command-line arguments is provided. Directory path is the output directory of the overall script.
if len(sys.argv) != 2:
    print("Usage: python missing_taxid_finder.py directory_path")
    sys.exit(1)

directory_path = sys.argv[1]  # Get the directory path from the command-line argument

# Define the filenames based on the directory path
input_file = os.path.join(directory_path, "all_combined.diamondout.mod")
output_file = os.path.join(directory_path, "missing_taxids.txt")
temp_file = os.path.join(directory_path, "all_combined.diamondout.mod2")

with open(input_file, 'r') as infile, open(output_file, 'w') as outfile, open(temp_file, 'w') as temp:
    for line in infile:
        if line.startswith("#"):
            temp.write(line)
            continue

        columns = line.strip().split('\t')
        if len(columns) == 10 and all(columns):
            temp.write(line)
        else:
            outfile.write(line)
