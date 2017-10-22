import os
import shutil

def ConvParaScaleFloat16(Para_X, Para_Y, KernelSizeList):
	sourceFile = './Template_ConvParaScaleFloat16.v'
	destFile = './ConvParaScaleFloat16.v'
	shutil.copy (sourceFile, destFile)
	if os.path.isfile (destFile): 
		print "Copy Template_ConvParaScaleFloat16.v Success."

		# set PARA_X and PARA_Y
		replace(destFile, 'SET_PARA_X', str(Para_X))
		replace(destFile, 'SET_PARA_Y', str(Para_Y))

		# kernel size
		file_cpsf = file(destFile)
		s_cpsf = file_cpsf.read()
		file_cpsf.close()
		a_cpsf = s_cpsf.split('\n')

		inser_index_cpsf = 86

		for i in KernelSizeList:
			file_rmv = file('Template_RegisterMoveWire.v')

			for line in file_rmv:
				line = line.replace('SET_KERNEL_SIZE_NUMBER', str(i))
				line = line.replace('SET_KERNEL_SIZE_FLAG', 'ks'+str(i))
				line = line[:-1]
				a_cpsf.insert(inser_index_cpsf, line) 
				inser_index_cpsf = inser_index_cpsf+1
		file_rmv.close()

		inser_index_cpsf = inser_index_cpsf + 32

		for i in KernelSizeList:
			file_ksic = file('Template_KernelSizeInputCase.v')

			for line in file_ksic:
				line = line.replace('SET_KERNEL_SIZE_CASE', str(i))
				line = line[:-1]
				a_cpsf.insert(inser_index_cpsf, line) 
				inser_index_cpsf = inser_index_cpsf+1
		file_ksic.close()

		inser_index_cpsf = inser_index_cpsf+2

		file_crm = file('Template_ClkRegisterMove.v')
		s_crm = file_crm.read()
		file_crm.close()
		a_crm = s_crm.split('\n')
		insert_index_crm = [[5, 0], [14, 2], [23, 1], [32, 3]]
		insert_count = 0
		for index in insert_index_crm:
			cur_index = index[0] + insert_count
			for i in KernelSizeList:
				file_rmw = open('Template_KernelSizeCase.v','r+')
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
		file_cpsf = file(destFile, 'w')
		file_cpsf.write(s_cpsf)
		file_cpsf.close()

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

ConvParaScaleFloat16(3, 3, [3, 5])
