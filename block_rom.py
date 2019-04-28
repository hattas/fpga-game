import matplotlib.pyplot as plt
import numpy as np
from skimage.io import imread

# define color pallete (export from pixelart.com)
colors = ["222222", "003f3f", "007f7f", "00bfbf", "00ffff", "55ffff", "aaffff", "ffffff"]
color_tuples = [tuple(int(color[i:i+2], 16) for i in (0, 2, 4)) for color in colors]

im = imread('ghost_lightfloor.png')[:,:,:3] # drop alpha
# plt.imshow(im)

def color24to3(rgb):
    binary = ['000', '001', '010', '011', '100', '101', '110', '111']
    r, g, b = "000"
    for i, color in enumerate(color_tuples):
        if rgb == color:
            r, g, b = binary[i]
    return {'r':r, 'g':g, 'b':b}

def save_color_rom(rgb_str):
    rom_str = ''
    h, w = im.shape[:2]
    for i in range(h):
        rom_str += '"'
        for j in range(w):
            color_tuple = color24to3(tuple(im[i,j,:]))
            rom_str += color_tuple[rgb_str]
        rom_str += '"'
        if i == h-1:
            rom_str += ' '
        else:
            rom_str += ','
        rom_str += ' --' + str(i) + '\n'

    file = open(rgb_str + '.txt','w') 
    file.write(rom_str)
    file.close()

for rgb_str in ['r', 'g', 'b']:
    save_color_rom(rgb_str)