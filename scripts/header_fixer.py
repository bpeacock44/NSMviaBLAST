import os
import sys
def update_headers(directory):
    # Define file names with the provided directory
    blastout_file = os.path.join(directory, 'final_blast_and_diamond.out')
    fastq_file = os.path.join(directory, 'uniq.' + os.path.basename(directory) + '.fastq')
    output_file = os.path.join(directory, 'final2_blast_and_diamond.out')

    # Create a dictionary to map the original blastout header to the desired blastout header
    header_mapping = {}

    # Process the fastq file and create a dictionary to map the original blastout header to the desired blastout header
    with open(fastq_file, 'r') as fastq:
        for line in fastq:
            if line.startswith('@'):
                # Extract the original blastout header (everything before the space)
                original_blastout_header = line.split(' ')[0].replace('@', '# Query: ')
                # Modify the desired blastout header
                desired_blastout_header = line.strip().replace('@', '# Query: ')
                #desired_blastout_header = line.strip().replace('@', '# Query: ').replace(' 1:N:0:TGACCA', '') + '_0'
                header_mapping[original_blastout_header] = desired_blastout_header

    # Process the blastout file and write to the output file
    with open(blastout_file, 'r') as blastout, open(output_file, 'w') as output:
        for line in blastout:
            if line.startswith("# Query: "):
                current_query = line.strip()
                if current_query in header_mapping:
                    updated_header = header_mapping[current_query]
                    output.write(updated_header + '\n')
                else:
                    output.write(line)
            else:
                output.write(line)

    print(f"Headers updated and saved to '{output_file}'.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python header_fixer.py <directory>")
    else:
        directory_input = sys.argv[1]
        update_headers(directory_input)
