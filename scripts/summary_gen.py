import argparse

def count_values(input_file, output_file):
    # Dictionary to store unique values and their counts
    value_counts = {}

    # Read the tab-delimited file
    with open(input_file, 'r') as file:
        for line in file:
            columns = line.strip().split('\t')
            value = columns[1]
            value_counts[value] = value_counts.get(value, 0) + 1

    # Save the summary to a new file
    with open(output_file, 'w') as output_file:
        for value, count in value_counts.items():
            output_file.write('{}\t{}\n'.format(value, count))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Count unique values in a tab-delimited file and save the summary to a new file.')
    parser.add_argument('input_file', type=str, help='Path to the input tab-delimited file')
    parser.add_argument('output_file', type=str, help='Path to save the summary')
    args = parser.parse_args()

    count_values(args.input_file, args.output_file)
