import os
import shutil

def ConvParaScaleFloat16(Para_X, Para_Y, KernelSizeList, KernelSizeMax, KernelSizeWidth):
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceFile_1 = './Template/Template_ConvParaScaleFloat16.v'
	destFile_1 = destDir + 'ConvParaScaleFloat16.v'
	shutil.copy (sourceFile_1, destFile_1)

	sourceFile_2 = './Template/Template_MultAddUnitFloat16.v'
	destFile_2= destDir + 'MultAddUnitFloat16.v'
	shutil.copy (sourceFile_2, destFile_2)

	if os.path.isfile (destFile_1) and os.path.isfile (destFile_2): 
		print "Create MultAddUnitFloat16.v Success."
		print "Copy Template_ConvParaScaleFloat16.v Success."

		replace(destFile_1, 'SET_PARA_X', str(Para_X))
		replace(destFile_1, 'SET_PARA_Y', str(Para_Y))
		replace(destFile_1, 'SET_KERNEL_SIZE_MAX', str(KernelSizeMax))
		replace(destFile_1, 'SET_KERNEL_SIZE_WIDTH', str(KernelSizeWidth))

		# kernel size
		file_cpsf = file(destFile_1)
		s_cpsf = file_cpsf.read()
		file_cpsf.close()
		a_cpsf = s_cpsf.split('\n')

		inser_index_cpsf = 68

		for i in KernelSizeList:
			file_rmv = file('./Template/Template_RegisterMoveWire.v')

			for line in file_rmv:
				line = line.replace('SET_KERNEL_SIZE_NUMBER', str(i))
				line = line.replace('SET_KERNEL_SIZE_FLAG', 'ks'+str(i))
				line = line[:-1]
				a_cpsf.insert(inser_index_cpsf, line) 
				inser_index_cpsf = inser_index_cpsf+1
		file_rmv.close()

		inser_index_cpsf = inser_index_cpsf + 48

		file_crm = file('./Template/Template_ClkRegisterMove.v')
		s_crm = file_crm.read()
		file_crm.close()
		a_crm = s_crm.split('\n')
		insert_index_crm = [[5, 0], [14, 2], [23, 1], [32, 3]]
		insert_count = 0
		for index in insert_index_crm:
			cur_index = index[0] + insert_count
			for i in KernelSizeList:
				file_rmw = open('./Template/Template_KernelSizeCase.v','r+')
				for line in file_rmw:
					line = line.replace('SET_KERNEL_SIZE_CASE', str(i))
					line = line.replace('SET_CLK_TYPE', str(index[1]))
					line = line[:-1]
					a_crm.insert(cur_index, line) 
					cur_index = cur_index+1
			insert_count = insert_count + 4 * len(KernelSizeList)

		for line in a_crm:
			a_cpsf.insert(inser_index_cpsf, line)
			inser_index_cpsf = inser_index_cpsf + 1

		s_cpsf = '\n'.join(a_cpsf)
		file_cpsf = file(destFile_1, 'w')
		file_cpsf.write(s_cpsf)
		file_cpsf.close()

		print "Create ConvParaScaleFloat16.v Success."

def FeatureMapRam(Para_Y, RamMax, ReadWidth, WriteWidth):
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceRam = './Template/Template_FeatureMapRamFloat16.v'
	destRam = destDir + 'FeatureMapRamFloat16.v'
	shutil.copy (sourceRam, destRam)

	if os.path.isfile (destRam): 
		replace(destRam, 'SET_PARA_Y', str(Para_Y))
		replace(destRam, 'SET_RAM_MAX', str(RamMax))
		replace(destRam, 'SET_READ_WIDTH', str(ReadWidth))
		replace(destRam, 'SET_WRITE_WIDTH', str(WriteWidth))
		
		file_ram = file(destRam)
		s_ram = file_ram.read()
		file_ram.close()
		a_ram = s_ram.split('\n')

		inser_index_ram = 69

		for i in range(Para_Y):
			file_ram_na = file('./Template/Template_FeatureMapRamFloat16_not_add.v')

			for line in file_ram_na:
				line = line.replace('SET_INDEX_ADD_ONE', str(i+1))
				line = line.replace('SET_INDEX', str(i))
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
		file_ram_na.close()

		inser_index_ram = inser_index_ram + 8

		for i in range(Para_Y-1):
			file_ram_a0 = file('./Template/Template_FeatureMapRamFloat16_add_0.v')

			for line in file_ram_a0:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
		file_ram_a0.close()

		inser_index_ram = inser_index_ram + 12

		for i in range(Para_Y):
			file_ram_a1 = file('./Template/Template_FeatureMapRamFloat16_add_1.v')

			for line in file_ram_a1:
				line = line.replace('SET_INDEX', str(i))
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
		file_ram_a1.close()

		inser_index_ram = inser_index_ram + 12
		for i in range(Para_Y-1):
			file_ram_out = file('./Template/Template_FeatureMapRamFloat16_read_out.v')

			for line in file_ram_out:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
		file_ram_out.close()

		s_ram = '\n'.join(a_ram)
		file_ram = file(destRam, 'w')
		file_ram.write(s_ram)
		file_ram.close()

		print "Create FeatureMapRamFloat16.v Success."

def WeightRam(KernelSizeMax, RamMax, ReadWidth, WriteWidth):
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceRam = './Template/Template_WeightRamFloat16.v'
	destRam = destDir + 'WeightRamFloat16.v'
	shutil.copy (sourceRam, destRam)

	if os.path.isfile (destRam): 
		replace(destRam, 'SET_KERNEL_SIZE_MAX', str(KernelSizeMax))
		replace(destRam, 'SET_WEIGHT_RAM_MAX', str(RamMax))
		replace(destRam, 'SET_WEIGHT_READ_WIDTH', str(ReadWidth))
		replace(destRam, 'SET_WEIGHT_WRITE_WIDTH', str(WriteWidth))
		
		file_ram = file(destRam)
		s_ram = file_ram.read()
		file_ram.close()
		a_ram = s_ram.split('\n')

		inser_index_ram = 37

		for i in range(KernelSizeMax*KernelSizeMax):
			file_ram_na = file('./Template/Template_WeightRamFloat16_write.v')

			for line in file_ram_na:
				line = line.replace('SET_INDEX_ADD_ONE', str(i+1))
				line = line.replace('SET_INDEX', str(i))
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
		file_ram_na.close()

		s_ram = '\n'.join(a_ram)
		file_ram = file(destRam, 'w')
		file_ram.write(s_ram)
		file_ram.close()

		print "Create WeightRamFloat16.v Success."

def replace(file_path, old_str, new_str):  
	try:  
		f = open(file_path,'r+')  
		all_lines = f.readlines()  
		f.seek(0)  
		f.truncate()  
		for line in all_lines:  
			line = line.replace(old_str, new_str)  
			f.write(line)  
		f.close()  
	except Exception,e:  
		print e 

#ConvParaScaleFloat16(3, 3, [3, 5], 5, 6)
#FeatureMapRam(3, 22, 3, 3)
WeightRam(5, 100, 10, 5)