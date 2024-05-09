import sys

def trim_header(input_file, output_file):
    with open(input_file, "r") as f_in, open(output_file, "w") as f_out:
        line_number = 0
        for line in f_in:
            line_number += 1
            if line_number % 4 == 1:
                # Split the line by space and take the first part
                trimmed_line = line.split(" ", 1)[0] + "\n"
                f_out.write(trimmed_line)
            else:
                f_out.write(line)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python header_trimmer.py input_file output_file")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    trim_header(input_file, output_file)
