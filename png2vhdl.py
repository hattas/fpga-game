from skimage.io import imread

im = imread('tiles.png', as_gray=True)

h, w = im.shape
s = ''
for i in range(h):
    s += '"'
    for j in range(w):
        s += str(int(im[i,j]))
    s += '"'
    if i == h-1:
        s += ' '
    else:
        s += ','
    s += ' --' + str(i) + '\n'

file = open('rom.txt','w') 
file.write(s) 
file.close()
