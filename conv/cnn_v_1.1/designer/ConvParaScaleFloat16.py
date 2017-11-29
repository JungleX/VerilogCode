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
		inser_index_layer = 267
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

		inser_index_layer = inser_index_layer + 4
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_rst_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_kernel-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1
		# =================== End: rst ===================
		
		# =================== Begin: init layer ===================
		inser_index_layer = inser_index_layer + 58
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

		inser_index_layer = inser_index_layer + 12
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_init_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX_ADD_ONE', str(i+1))
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_kernel-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1
		# =================== End: init layer ===================

		# =================== Begin: update kernel ===================
		inser_index_layer = inser_index_layer + 28
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_update_kernel_0.v')

			for line in file_temp:
				line = line.replace('SET_INDEX_ADD_ONE', str(i+1))
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_kernel-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 5
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_update_kernel_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()
		# =================== End: update kernel ===================

		# =================== Begin: conv layer ===================
		inser_index_layer = inser_index_layer + 17
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

		inser_index_layer = inser_index_layer + 16
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 4
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_2.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_kernel-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 16
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_3.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_kernel-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 7
		for i in range(Para_kernel):
			for j in range(Para_X):
				for k in range(Para_Y):
					file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_4.v')

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

		inser_index_layer = inser_index_layer + 4
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_5.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 7
		for i in range(Para_kernel):
			for j in range(Para_X):
				file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_4.v')

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

		inser_index_layer = inser_index_layer + 4
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_6.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 14
		for i in range(Para_kernel):
			for j in range(Para_Y):
				file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_4.v')

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

		inser_index_layer = inser_index_layer + 13
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_7.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 10
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_4.v')

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

		inser_index_layer = inser_index_layer + 14
		for i in range(Para_X):
			file_temp_0 = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_8.v')
			s_temp = file_temp_0.read()
			file_temp_0.close()
			a_temp = s_temp.split('\n')

			for j in range(Para_kernel):
				inser_index_temp = 10
				file_temp_1 = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_9.v')
				for line in file_temp_1:
					line = line.replace('SET_INDEX_1_ADD_ONE', str(i+1))
					line = line.replace('SET_INDEX_1', str(i))
					line = line.replace('SET_INDEX_0', str(j))

					if j == 0:
						line = line[:-1]
					a_temp.insert(inser_index_temp, line) 
					inser_index_temp = inser_index_temp+1

			for line in a_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 9
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_10.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 10
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_11.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 31
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_12.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 12
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_13.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 20
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_14.v')

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
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_conv_15.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()
		# =================== End: conv layer ===================

		# =================== Begin: pool layer ===================
		inser_index_layer = inser_index_layer + 18
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_0.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 4
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_kernel-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 6
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_2.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_X-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 48
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_3.v')

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
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_4.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i+1))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 53
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_5.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 23
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_pool_6.v')

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
		inser_index_layer = inser_index_layer + 16
		for i in range(Para_X):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_fc_0.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 4
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_fc_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				line = line[:-1]
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

			if i<(Para_kernel-1):
				a_layer.insert(inser_index_layer, '') 
				inser_index_layer = inser_index_layer+1

		inser_index_layer = inser_index_layer + 32
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_fc_2.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 7
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_fc_3.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 7
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_fc_4.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()

		inser_index_layer = inser_index_layer + 5
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_fc_5.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()
		# =================== End: fc layer ===================

		# =================== Begin: done layer ===================
		inser_index_layer = inser_index_layer + 164
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

		inser_index_layer = inser_index_layer + 4
		for i in range(Para_kernel):
			file_temp = file('./Template/LayerTemplate/Template_LayerParaScaleFloat16_done_1.v')

			for line in file_temp:
				line = line.replace('SET_INDEX', str(i))
				a_layer.insert(inser_index_layer, line) 
				inser_index_layer = inser_index_layer+1
			file_temp.close()
		
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

	sourceFile_1 = './Template/Template_ConvParaScaleFloat16.v'
	destFile_1 = destDir + 'ConvParaScaleFloat16.v'
	shutil.copy (sourceFile_1, destFile_1)

	sourceFile_2 = './Template/Template_MultAddUnitFloat16.v'
	destFile_2= destDir + 'MultAddUnitFloat16.v'
	shutil.copy (sourceFile_2, destFile_2)

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
			file_rmv = file('./Template/Template_RegisterMoveWire.v')

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
				file_cr = file('./Template/Template_Conv_result_action_none.v')
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
				file_cr = file('./Template/Template_Conv_result_action_ReLU.v')
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

		# fc result buffer
		inser_index_cpsf = inser_index_cpsf + 16

		for i in range(Para_Y):
			file_fcr = file('./Template/Template_FC_result.v')
			for line in file_fcr:
				line = line.replace('SET_INDEX', str(i))
				if i==Para_Y-1:
						line = line[:-1]
				a_cpsf.insert(inser_index_cpsf, line)
				inser_index_cpsf = inser_index_cpsf+1
			file_fcr.close()

		# MultAddUnitFloat16 input data
		inser_index_cpsf = inser_index_cpsf + 15
		
		file_fcmi = file('./Template/Template_FC_mau_input.v')
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

def FeatureMapRam(Para_Y, Para_kernel):
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceRam = './Template/Template_FeatureMapRamFloat16.v'
	destRam = destDir + 'FeatureMapRamFloat16.v'
	shutil.copy (sourceRam, destRam)

	if os.path.isfile (destRam): 
		file_ram = file(destRam)
		s_ram = file_ram.read()
		file_ram.close()
		a_ram = s_ram.split('\n')

		inser_index_ram = 91

		for i in range(Para_Y):
			file_ram_na = file('./Template/Template_FeatureMapRamFloat16_not_add.v')

			for line in file_ram_na:
				line = line.replace('SET_INDEX_ADD_ONE', str(i+1))
				line = line.replace('SET_INDEX', str(i))
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
			file_ram_na.close()

		inser_index_ram = inser_index_ram + 8

		for i in range(Para_Y):
			file_ram_a0 = file('./Template/Template_FeatureMapRamFloat16_add_0.v')

			for line in file_ram_a0:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))
				if i==Para_Y-1:
					line = line[:-1]
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
			file_ram_a0.close()

		inser_index_ram = inser_index_ram + 11
		for i in range(Para_Y):
			file_ram_a1 = file('./Template/Template_FeatureMapRamFloat16_add_1.v')

			for line in file_ram_a1:
				line = line.replace('SET_INDEX', str(i))
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
			file_ram_a1.close()

		inser_index_ram = inser_index_ram + 14
		for i in range(Para_Y):
			file_ram_a0 = file('./Template/Template_FeatureMapRamFloat16_fm_para_add_0.v')

			for line in file_ram_a0:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))
				if i==Para_Y-1:
					line = line[:-1]
				a_ram.insert(inser_index_ram, line)
				inser_index_ram = inser_index_ram+1
			file_ram_a0.close()

		inser_index_ram = inser_index_ram + 6
		for i in range(Para_kernel-1):
			for j in range(Para_Y):
				file_ram_a1 = file('./Template/Template_FeatureMapRamFloat16_fm_para_add_1.v')
					
				for line in file_ram_a1:
					line = line.replace('SET_INDEX_0_ADD_ONE', str((i+1)*Para_Y+j+1))
					line = line.replace('SET_INDEX_0', str((i+1)*Para_Y+j))
					line = line.replace('SET_INDEX', str(i*Para_Y+j))
					a_ram.insert(inser_index_ram, line) 
					inser_index_ram = inser_index_ram+1
				file_ram_a1.close()

		inser_index_ram = inser_index_ram + 5
		for i in range(Para_Y):
			file_ram_a2 = file('./Template/Template_FeatureMapRamFloat16_fm_para_add_2.v')

			for line in file_ram_a2:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))
				if i==Para_Y-1:
					line = line[:-1]
				a_ram.insert(inser_index_ram, line)
				inser_index_ram = inser_index_ram+1
			file_ram_a2.close()

		inser_index_ram = inser_index_ram + 3
		for i in range(Para_Y):
			file_ram_a3 = file('./Template/Template_FeatureMapRamFloat16_fm_para_add_3.v')

			for line in file_ram_a3:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))
				if i==Para_Y-1:
					line = line[:-1]
				a_ram.insert(inser_index_ram, line)
				inser_index_ram = inser_index_ram+1
			file_ram_a3.close()

		inser_index_ram = inser_index_ram + 5
		for i in range(Para_Y):
			file_ram_a4 = file('./Template/Template_FeatureMapRamFloat16_fm_para_add_4.v')

			for line in file_ram_a4:
				line = line.replace('SET_INDEX', str(i))
				a_ram.insert(inser_index_ram, line)
				inser_index_ram = inser_index_ram+1
			file_ram_a4.close()

		# para write, not add, for fc write
		inser_index_ram = inser_index_ram + 16
		for i in range(Para_Y):
			file_ram = file('./Template/Template_FeatureMapRamFloat16_fm_para_not_add_0.v')

			for line in file_ram:
				line = line.replace('SET_INDEX_ADD_ONE', str(i+1))
				line = line.replace('SET_INDEX', str(i))
				a_ram.insert(inser_index_ram, line)
				inser_index_ram = inser_index_ram+1
			file_ram.close()

		inser_index_ram = inser_index_ram + 3
		for i in range(Para_kernel-1):
			for j in range(Para_Y):
				file_ram = file('./Template/Template_FeatureMapRamFloat16_fm_para_not_add_1.v')
					
				for line in file_ram:
					line = line.replace('SET_INDEX_0_ADD_ONE', str((i+1)*Para_Y+j+1))
					line = line.replace('SET_INDEX_0', str((i+1)*Para_Y+j))
					line = line.replace('SET_INDEX', str(i*Para_Y+j))
					a_ram.insert(inser_index_ram, line) 
					inser_index_ram = inser_index_ram+1
				file_ram.close()

		inser_index_ram = inser_index_ram + 4
		for i in range(Para_Y):
			file_ram = file('./Template/Template_FeatureMapRamFloat16_fm_para_not_add_2.v')

			for line in file_ram:
				line = line.replace('SET_INDEX_ADD_ONE', str(i+1))
				line = line.replace('SET_INDEX', str(i))
				a_ram.insert(inser_index_ram, line)
				inser_index_ram = inser_index_ram+1
			file_ram.close()


		# conv read out
		inser_index_ram = inser_index_ram + 26
		for i in range(Para_Y):
			file_ram_out = file('./Template/Template_FeatureMapRamFloat16_conv_read_out.v')

			for line in file_ram_out:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))

				if i==(Para_Y-1):
					line = line[:-1]

				a_ram.insert(inser_index_ram, line)
				inser_index_ram = inser_index_ram+1
			file_ram_out.close()

		# pool read out
		inser_index_ram = inser_index_ram + 7
		for i in range(Para_Y):
			file_ram_out = file('./Template/Template_FeatureMapRamFloat16_pool_read_out.v')

			for line in file_ram_out:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))

				if i==(Para_Y-1):
					line = line[:-1]

				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
			file_ram_out.close()

		# fc read out
		inser_index_ram = inser_index_ram + 7
		for i in range(Para_Y):
			file_ram_out = file('./Template/Template_FeatureMapRamFloat16_fc_read_out.v')

			for line in file_ram_out:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))

				if i==(Para_Y-1):
					line = line[:-1]

				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
			file_ram_out.close()

		s_ram = '\n'.join(a_ram)
		file_ram = file(destRam, 'w')
		file_ram.write(s_ram)
		file_ram.close()

		print "Create FeatureMapRamFloat16.v Success."

def WeightRam(Para_Y, KernelSizeMax):
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceRam = './Template/Template_WeightRamFloat16.v'
	destRam = destDir + 'WeightRamFloat16.v'
	shutil.copy (sourceRam, destRam)

	if os.path.isfile (destRam): 
		file_ram = file(destRam)
		s_ram = file_ram.read()
		file_ram.close()
		a_ram = s_ram.split('\n')

		inser_index_ram = 38

		for i in range(KernelSizeMax*KernelSizeMax):
			file_ram_na = file('./Template/Template_WeightRamFloat16_write.v')

			for line in file_ram_na:
				line = line.replace('SET_INDEX_ADD_ONE', str(i+1))
				line = line.replace('SET_INDEX', str(i))
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
		file_ram_na.close()

		inser_index_ram = inser_index_ram + 11

		for i in range(Para_Y):
			file_ram_fcr = file('./Template/Template_WeightRamFloat16_fc_read_out.v')

			for line in file_ram_fcr:
				line = line.replace('SET_INDEX', str(Para_Y-i-1))
				if i==Para_Y-1:
					line = line[:-1]
				a_ram.insert(inser_index_ram, line) 
				inser_index_ram = inser_index_ram+1
		file_ram_fcr.close()

		s_ram = '\n'.join(a_ram)
		file_ram = file(destRam, 'w')
		file_ram.write(s_ram)
		file_ram.close()

		print "Create WeightRamFloat16.v Success."

def poolunit():
	destDir = './VerilogCode/'
	if not os.path.isdir(destDir):
		os.mkdir(destDir)

	sourceAvg = './Template/Template_AvgPoolUnitFloat16.v'
	destAvg = destDir + 'AvgPoolUnitFloat16.v'
	shutil.copy (sourceAvg, destAvg)

	sourceMax = './Template/Template_MaxPoolUnitFloat16.v'
	destMax = destDir + 'MaxPoolUnitFloat16.v'
	shutil.copy (sourceMax, destMax)

	if os.path.isfile (destAvg) and os.path.isfile (destMax):
		print "Create AvgPoolUnitFloat16.v Success."
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
#poolunit()
#FeatureMapRam(Para_Y, Para_kernel)
#WeightRam(Para_Y, KernelSizeMax)
#ConvParaScaleFloat16(KernelSizeList, Para_X, Para_Y)
LayerParaScaleFloat16(Para_X, Para_Y, Para_kernel)
