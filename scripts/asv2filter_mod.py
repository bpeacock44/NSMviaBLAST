import re

def process_file(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if line.startswith("NB"):
                # Extract the relevant information
                nb_info, rest_of_line = line.split(" ", 1)
                nb_parts = nb_info.split("_")
                
                # Modify the NB line
                nb_modified = nb_parts[0] + ";size=" + nb_parts[1] + ";_0 " + rest_of_line
                
                # Write the modified line to the output file
                outfile.write(nb_modified)
            else:
                # Write other lines unchanged
                outfile.write(line)

process_file('ASVs2filter.log', 'new_ASVs2filter.log')
