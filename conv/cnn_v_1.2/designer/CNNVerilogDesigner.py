import os
import shutil

Para_X = 3
Para_Y = 3
Para_kernel = 2
KernelSizeList = [3]
KernelSizeMax = 3

def LayerParaScaleFloat16(Para_X, Para_Y, Para_kernel):
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceFile = './Template/LayerTemplate/Template_LayerParaScaleFloat16.v'
	destFile = destDir + 'LayerParaScaleFloat16.v'
	shutil.copy (sourceFile, destFile)

	if os.path.isfile (destFile): 
		print "Copy Template_LayerParaScaleFloat16.v Success."

		file_temp = file(destFile)
		s_layer = file_temp.read()
		file_temp.close()
		a_layer = s_layer.split('\n')

		# =================== Begin: rst ===================
		inser_index_layer = 262
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_rst_0.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1
		# =================== End: rst ===================
		
		# =================== Begin: init layer ===================
		inser_index_layer = inser_index_layer + 70
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_init_0.v')

			for line in file_temp:
				line = line.replace('SET_INDEX_ADD_ONE', str(i+1))
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1
		# =================== End: init layer ===================

		# =================== Begin: conv layer ===================
		inser_index_layer = inser_index_layer + 86
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_0.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 20
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 73
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_2.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 7
		for i in range(Para_kernel):
			for j in range(Para_X):
				for k in range(Para_Y):
					file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_3.v')

					for line in file_temp:
						line = line.replace('SET_INDEX_3_ADD_ONE', str(Para_Y-k))
						line = line.replace('SET_INDEX_3', str(Para_Y-k-1))
						line = line.replace('SET_INDEX_2_ADD_ONE', str(j*Para_Y+k+1))
						line = line.replace('SET_INDEX_2', str(j*Para_Y+k))
						line = line.replace('SET_INDEX_1', str(j))
						line = line.replace('SET_INDEX_0', str(i))
						a_layer.insert(inser_index_layer, line) 
						inser_index_layer = inser_index_layer+1
					file_temp.close()

				if not (i==(Para_kernel-1) and j==(Para_X-1) and k==(Para_Y-1)):
					a_layer.insert(inser_index_layer, '') 
					inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 7
		for i in range(Para_kernel):
			for j in range(Para_X):
				file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_3.v')

				for line in file_temp:
					line = line.replace('SET_INDEX_3_ADD_ONE', str(1))
					line = line.replace('SET_INDEX_3', str(0))
					line = line.replace('SET_INDEX_2_ADD_ONE', str(j+1))
					line = line.replace('SET_INDEX_2', str(j))
					line = line.replace('SET_INDEX_1', str(j))
					line = line.replace('SET_INDEX_0', str(i))
					a_layer.insert(inser_index_layer, line) 
					inser_index_layer = inser_index_layer+1
				file_temp.close()

			if i<(Para_kernel-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 7
		for i in range(Para_kernel):
			for j in range(Para_Y):
				file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_3.v')

				for line in file_temp:
					line = line.replace('SET_INDEX_3_ADD_ONE', str(Para_Y-j))
					line = line.replace('SET_INDEX_3', str(Para_Y-j-1))
					line = line.replace('SET_INDEX_2_ADD_ONE', str(j+1))
					line = line.replace('SET_INDEX_2', str(j))
					line = line.replace('SET_INDEX_1', 'cur_fm_ram')
					line = line.replace('SET_INDEX_0', str(i))
					a_layer.insert(inser_index_layer, line) 
					inser_index_layer = inser_index_layer+1
				file_temp.close()

			if i<(Para_kernel-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 7
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_3.v')

			for line in file_temp:
				line = line.replace('SET_INDEX_3_ADD_ONE', str(1))
				line = line.replace('SET_INDEX_3', str(0))
				line = line.replace('SET_INDEX_2_ADD_ONE', str(1))
				line = line.replace('SET_INDEX_2', str(0))
				line = line.replace('SET_INDEX_1', 'cur_fm_ram')
				line = line.replace('SET_INDEX_0', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 62
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_4.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 10
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_6.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 37
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_7.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 18
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_8.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 34
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_9.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 18
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_10.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()
		# =================== End: conv layer ===================

		# =================== Begin: pool layer ===================
		inser_index_layer = inser_index_layer + 23
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_0.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 60
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 11
		for i in range(Para_Y-1):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_2.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i+1))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 53
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_3.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 23
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_4.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1
		# =================== End: pool layer ===================

		# =================== Begin: fc layer ===================
		inser_index_layer = inser_index_layer + 21
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_fc_0.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 32
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_fc_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 7
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_fc_2.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()
		# =================== End: fc layer ===================

		# =================== Begin: done layer ===================
		inser_index_layer = inser_index_layer + 167
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_done_0.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1
		# =================== End: done layer ===================
		
		s_layer = '\n'.join(a_layer)
		file_temp = file(destFile, 'w')
		file_temp.write(s_layer)
		file_temp.close()

		print "Create LayerParaScaleFloat16.v Success."

def ConvParaScaleFloat16(KernelSizeList, Para_X, Para_Y):
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceFile_1 = './Template/ConvPara/Template_ConvParaScaleFloat16.v'
	destFile_1 = destDir + 'ConvParaScaleFloat16.v'
	shutil.copy (sourceFile_1, destFile_1)

	MultAddUnit()
	destFile_2= destDir + 'MultAddUnitFloat16.v'

	if os.path.isfile (destFile_1) and os.path.isfile (destFile_2): 
		print "Create MultAddUnitFloat16.v Success."
		print "Copy Template_ConvParaScaleFloat16.v Success."

		# kernel size
		file_cpsf = file(destFile_1)
		s_cpsf = file_cpsf.read()
		file_cpsf.close()
		a_cpsf = s_cpsf.split('\n')

		# register move wire
		inser_index_cpsf = 66

		for i in KernelSizeList:
			file_rmv = file('./Template/ConvPara/Template_RegisterMoveWire.v')

			for line in file_rmv:
				line = line.replace('SET_KERNEL_SIZE_NUMBER', str(i))
				line = line.replace('SET_KERNEL_SIZE_FLAG', 'ks'+str(i))
				line = line[:-1]
				a_cpsf.insert(inser_index_cpsf, line) 
				inser_index_cpsf = inser_index_cpsf+1
		file_rmv.close()

		# result buffer
		# activation = 0 none
		inser_index_cpsf = inser_index_cpsf + 41

		for i in range(Para_X):
			for j in range(Para_Y):
				file_cr = file('./Template/ConvPara/Template_Conv_result_action_none.v')
				for line in file_cr:
					line = line.replace('SET_INDEX_ADD_ONE', str((Para_X-i-1)*Para_Y+j+1))
					line = line.replace('SET_INDEX', str((Para_X-i-1)*Para_Y+j))
					if i==Para_X-1 and j==Para_Y-1:
						line = line[:-1]
					a_cpsf.insert(inser_index_cpsf, line)
					inser_index_cpsf = inser_index_cpsf+1
				file_cr.close()

			if i<(Para_X-1):
				a_cpsf.insert(inser_index_cpsf, '')
				inser_index_cpsf = inser_index_cpsf+1

		# activation = 1 ReLU
		inser_index_cpsf = inser_index_cpsf + 3
		index_count = Para_X*Para_Y-1

		for i in range(Para_X):
			for j in range(Para_Y):
				file_cr = file('./Template/ConvPara/Template_Conv_result_action_ReLU.v')
				for line in file_cr:
					line = line.replace('SET_INDEX_0_ADD_ONE', str(index_count+1))
					line = line.replace('SET_INDEX_0', str(index_count))
					line = line.replace('SET_INDEX_ADD_ONE', str((Para_X-i-1)*Para_Y+j+1))
					line = line.replace('SET_INDEX', str((Para_X-i-1)*Para_Y+j))
					line = line[:-1]
					a_cpsf.insert(inser_index_cpsf, line)
					inser_index_cpsf = inser_index_cpsf+1
				file_cr.close()
				index_count = index_count-1

			if i<(Para_X-1):
				a_cpsf.insert(inser_index_cpsf, '')
				inser_index_cpsf = inser_index_cpsf+1

		# register operation
		inser_index_cpsf = inser_index_cpsf + 14

		file_crm = file('./Template/ConvPara/Template_ClkRegisterMove.v')
		s_crm = file_crm.read()
		file_crm.close()
		a_crm = s_crm.split('\n')
		insert_index_crm = [[5, 0], [14, 2], [23, 1], [32, 3]]
		insert_count = 0
		for index in insert_index_crm:
			cur_index = index[0] + insert_count
			for i in KernelSizeList:
				file_rmw = open('./Template/ConvPara/Template_KernelSizeCase.v','r+')
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

		# fc result buffer
		inser_index_cpsf = inser_index_cpsf + 16

		for i in range(Para_Y):
			file_fcr = file('./Template/ConvPara/Template_FC_result.v')
			for line in file_fcr:
				line = line.replace('SET_INDEX', str(i))
				if i==Para_Y-1:
						line = line[:-1]
				a_cpsf.insert(inser_index_cpsf, line)
				inser_index_cpsf = inser_index_cpsf+1
			file_fcr.close()

		# MultAddUnitFloat16 input data
		inser_index_cpsf = inser_index_cpsf + 15
		
		file_fcmi = file('./Template/ConvPara/Template_FC_mau_input.v')
		for line in file_fcmi:
			line = line.replace('SET_INDEX_Y_1', str(Para_Y))
			line = line.replace('SET_INDEX_Y_0', str(0))
			line = line.replace('SET_INDEX', str(0))
			a_cpsf.insert(inser_index_cpsf, line)
			inser_index_cpsf = inser_index_cpsf+1
		file_fcmi.close()
		
		# save file
		s_cpsf = '\n'.join(a_cpsf)
		file_cpsf = file(destFile_1, 'w')
		file_cpsf.write(s_cpsf)
		file_cpsf.close()

		print "Create ConvParaScaleFloat16.v Success."

def MultAddUnit():
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceFile = './Template/Template_MultAddUnitFloat16.v'
	destFile= destDir + 'MultAddUnitFloat16.v'
	shutil.copy (sourceFile, destFile)

	if os.path.isfile (destFile):
		print "Create MultAddUnitFloat16.v Success."

def PoolUnit():
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceMax = './Template/Template_MaxPoolUnitFloat16.v'
	destMax = destDir + 'MaxPoolUnitFloat16.v'
	shutil.copy (sourceMax, destMax)

	if os.path.isfile (destMax):
		print "Create MaxPoolUnitFloat16.v Success."

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

# ================================================================
#PoolUnit()
#MultAddUnit()
#ConvParaScaleFloat16(KernelSizeList, Para_X, Para_Y)
LayerParaScaleFloat16(Para_X, Para_Y, Para_kernel)
