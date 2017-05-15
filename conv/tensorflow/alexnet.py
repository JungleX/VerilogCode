# -*- coding: utf-8 -*-

""" AlexNet.
Applying 'Alexnet' to Oxford's 17 Category Flower Dataset classification task.
References:
    - Alex Krizhevsky, Ilya Sutskever & Geoffrey E. Hinton. ImageNet
    Classification with Deep Convolutional Neural Networks. NIPS, 2012.
    - 17 Category Flower Dataset. Maria-Elena Nilsback and Andrew Zisserman.
Links:
    - [AlexNet Paper](http://papers.nips.cc/paper/4824-imagenet-classification-with-deep-convolutional-neural-networks.pdf)
    - [Flower Dataset (17)](http://www.robots.ox.ac.uk/~vgg/data/flowers/17/)
"""

from __future__ import division, print_function, absolute_import

import os
import tflearn
from tflearn.layers.core import input_data, dropout, fully_connected
from tflearn.layers.conv import conv_2d, max_pool_2d
from tflearn.layers.normalization import local_response_normalization
from tflearn.layers.estimator import regression
from tflearn.data_utils import build_image_dataset_from_dir
import tflearn.datasets.oxflower17 as oxflower17

# load data
# X: image data; Y: class value, eg: class number, like 0,1,2,3...
# X, Y = oxflower17.load_data(one_hot=True, resize_pics=(227, 227)) # the whole data
# just test flower 9

# small dataset, just for test
dirname = '17flowers'
resize_pics = (227, 227)
dataset_file = os.path.join(dirname, '17flowers_small.pkl')
X, Y = build_image_dataset_from_dir(os.path.join(dirname, 'jpg_small/'),
                                        dataset_file=dataset_file,
                                        resize=resize_pics,
                                        filetypes=['.jpg', '.jpeg'],
                                        convert_gray=False,
                                        shuffle_data=True,
                                        categorical_Y=True)

# Building 'AlexNet'
network = input_data(shape=[None, 227, 227, 3])
# conv 1
network = conv_2d(network, 96, 11, strides=4, activation='relu') # 48*2=96
# pool 1
network = max_pool_2d(network, 3, strides=2)
network = local_response_normalization(network)
# conv 2
network = conv_2d(network, 256, 5, activation='relu') # 128*2=256, strides=1 default value
# pool 2
network = max_pool_2d(network, 3, strides=2)
network = local_response_normalization(network)
# conv 3
network = conv_2d(network, 384, 3, activation='relu') 
# conv 4
network = conv_2d(network, 384, 3, activation='relu') # 192*2=384
# conv 5
network = conv_2d(network, 256, 3, activation='relu') # 128*2=256
# pool 5
network = max_pool_2d(network, 3, strides=2)
network = local_response_normalization(network)
# fc 6
network = fully_connected(network, 4096, activation='tanh')
network = dropout(network, 0.5)
# fc 7
network = fully_connected(network, 4096, activation='tanh')
network = dropout(network, 0.5)
# fc 8
network = fully_connected(network, 17, activation='softmax') # 17 flower, the predict probabilities
network = regression(network, optimizer='momentum',
                     loss='categorical_crossentropy',
                     learning_rate=0.001)

# Training
model = tflearn.DNN(network, 
                    tensorboard_dir='./alexnet_save_model/', # tensorboard log
                    checkpoint_path='./alexnet_save_model/model_alexnet', # file name: checkpoint
                    max_checkpoints=1, 
                    tensorboard_verbose=2)

# model.fit(X, Y, n_epoch=1000, validation_set=0.1, shuffle=True,
#           show_metric=True, batch_size=64, snapshot_step=20,
#           snapshot_epoch=False, run_id='alexnet_oxflowers17')

# Predict
# load model
model.load('./alexnet_model/model_alexnet-20000')

# result = model.predict(X)
result_label = model.predict_label(X)
# for i in range(0, len(result)):
#   print(result_label[i])
#   print(result[i])

# the last index of each result_lable element is the max predicted probabilities
lenth = len(result_label)
for i in range(0, lenth):
  print('predict result: %d' % (result_label[lenth - 1 - i][16]), end=' ')
  for j in range(0, 17):
    if Y[i][j] == 1:
        print('; actual value: %d' % (j))