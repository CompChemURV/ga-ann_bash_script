import sys

n_beg = sys.argv[1]
n_fin = sys.argv[2]

output = open("00-energy-error.txt", 'w')
output.write("gen_number" + ", " + "min_val"+ ", " + "avg_val")
output.write("\n")

gen = int(n_beg)
for gen in range(int(n_beg), int(n_fin) + 1):
	name = str(gen) + "-energy.txt"
	##print(name)
	input = open(name, 'r')
	err = 1000
	n_line = 0
	val_line = 0
	for line in input:
		line = line.split()
		n_line = n_line + 1
		val_line = val_line + float(line[2])
		if float(line[2]) < err:
			err = float(line[2])
		else:
			continue
	err = str(gen) + ", " + str(err) + ", " + str(round(val_line/n_line, 4))
	output.write(err)
	output.write("\n")
	input.close()
print("Energy errors are written in the file!")