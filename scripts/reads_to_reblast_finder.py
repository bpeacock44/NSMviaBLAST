# find reads that did not get sufficient results to determin LCA
import sys

def process_blast_output(input_file, threshold, output_file):
    with open(input_file, 'r') as input_f, open(output_file, 'w') as output_f:
        current_query = None
        hits = []
        for line in input_f:
            line = line.strip()
            if line.startswith("#"):
                continue  # Skip comment lines

            fields = line.split('\t')
            if len(fields) != 9:
                continue  # Skip lines that don't have 9 columns

            query, bitscore = fields[0], float(fields[6])

            if query != current_query:
                if current_query is not None and len(hits) >= threshold and len(set(hits)) == 1:
                    output_f.write(current_query + '\n')
                current_query = query
                hits = []

            hits.append(bitscore)

        # Check the last query
        if current_query is not None and len(hits) >= threshold and len(set(hits)) == 1:
            output_f.write(current_query + '\n')

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python reads_to_reblast_finder.py input_file threshold output_file")
        sys.exit(1)

    input_file = sys.argv[1]
    threshold = int(sys.argv[2])
    output_file = sys.argv[3]

    process_blast_output(input_file, threshold, output_file)
