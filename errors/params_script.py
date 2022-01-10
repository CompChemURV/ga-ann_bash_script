output = open("output_log.txt")   ## read file with changed parameters
params = open("params")           ## opens param file
#params_n = open("params_new", 'w')  ## new param file

list1 = []
list2 = []

for line1 in output:
	if "ERROR: initial value for parameter" in line1:
		list1.append(line1)
	
for line2 in params:
	list2.append(line2)
	
params.close()

#print(len(list1))
#print(list1)
#print(len(list2))
#print(list2)

params_n = open("params", 'w')

i = 0
	
	
for i in range(0, len(list2)):               ## read param file line by line
	line2 = list2[i]
	line2 = line2.split()
	j = 0
	for j in range(0, len(list1)):           ## at each line of param file make a loop for output
		line1 = list1[j]
		line1 = line1.split()
		stroka = line1[5]                    ## indicate which line is not working
		string = line1[10]                   
		rmv = string[:-1]                    ## read new value in updated ffield 
		#print(stroka, rmv)
		if int(stroka) == int(i) + 1:        ## compare lines, detect if changes are needed or not for this line
			#print('skript works at line: ', int(i) + 1)
			#print(line2)
			if '<' in line1:
				x = float(rmv)-0.1
				x = round(x, 4)
				if x < float(line2[4]):
					line2[4] = str(x)
				else:
					continue
			else:
				x = float(rmv)+0.1
				x = round(x, 4)
				if x > float(line2[5]):
					line2[5] = str(x)
				else:
					continue			
		else:
			continue
	new_line = '    '.join(line2)
	#print(new_line)
	params_n.write(new_line)
	params_n.write("\n")

#params.close()
params_n.close()


			
			
			
			
			
			
			
			
			
			
			
			
			