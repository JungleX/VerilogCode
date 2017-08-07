class FeatureMap:

    def __init__(self, width, height, depth):
        self.width = width
        self.height = height
        self.depth = depth

    def printFeatureMapSize(self):
        print "feature map size:"
        print "width: ", self.width
        print "height: ", self.height
        print "depth: ", self.depth

# test
# fm = FeatureMap(2,3,1)
# fm.printFeatureMapSize()