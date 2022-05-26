import torch
import scipy.io as io
import numpy as np
import argparse
from durak.alon import load_dataset_test, save_image_mat
from durak.fMRIVAE_Model import BetaVAE
import torch.utils.data
import os
import glob
parser = argparse.ArgumentParser(description='VAE for fMRI generation')
parser.add_argument('--batch_size', type=int, default=1, metavar='N',
                            help='input batch size for training (default: 128)')
parser.add_argument('--seed', type=int, default=1, metavar='S',
                            help='random seed (default: 1)')
parser.add_argument('--zdim', type=int, default=256, metavar='N',
                            help='dimension of latent variables')
#parser.add_argument('--data_path', default="D:\\fmri\\rsfMRI_VAE\\demo\\data", type=str, metavar='DIR', help='path to dataset')

parser.add_argument('--z_path', type=str, default="D:\\fmri\\rsfMRI_VAE\\demo\\result\\demo_latent\\z_900", help='path to saved z files')
parser.add_argument('--resume', type=str, default="D:\\fmri\\rsfMRI_VAE\\demo\checkpoint\\checkpoint.pth.tar", help='the VAE checkpoint') 
parser.add_argument('--img_path', type=str, default="D:\\fmri\\rsfMRI_VAE\demo\\result\\recon\\img_path", help='path to save reconstructed images')

args = parser.parse_args()
torch.manual_seed(args.seed)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model = BetaVAE(z_dim=args.zdim, nc=1).to(device)
if os.path.isfile(args.resume):
    print("==> Loading checkpoint: ", args.resume)
    checkpoint = torch.load(args.resume, map_location=device)
    model.load_state_dict(checkpoint['state_dict'])
else:
    print('[ERROR] Checkpoint not found: ', args.resume)
    raise RuntimeError

'''
Encoder mode. 
Image --> z
'''
data_name = os.listdir("D:\\7T_rest\\7T_rest_174\\")
data_path=glob.glob("D:\\fmri\\rsfMRI_VAE\\demo\\data\\*.h5")
j=0
for i in data_path:
    test_loader = load_dataset_test(i, args.batch_size)
    print('Mode: Encode \n Distribution of Z will be saved at: ' + args.z_path)
    for batch_idx, (xL, xR) in enumerate(test_loader):
        xL = xL.to(device)
        xR = xR.to(device)
        z_distribution = model._encode(xL, xR)
        save_data = {}
        save_data['z_distribution'] = z_distribution.detach().cpu().numpy()
        greg=data_name[j]+'_save_z{}.mat'.format(batch_idx)
        io.savemat(os.path.join(args.z_path, greg), save_data)
    print('Mode: Decode \n Reconstructed images will be saved at: ' + args.img_path)
    filelist = [f for f in os.listdir(args.z_path) if f.split('_')[0]==data_name[j]]
    for idx, filename in enumerate(filelist):
            z_dist = io.loadmat(os.path.join(args.z_path, filename))
            save_name=data_name[j]+'_save_z{}.mat'.format(idx)
            z_dist = io.loadmat(os.path.join(args.z_path, save_name))
            z_dist = z_dist['z_distribution']
            mu=z_dist[:, :args.zdim]
            logvar = z_dist[:, args.zdim:]
            z = torch.tensor(mu).to(device)
            x_recon_L, x_recon_R = model._decode(z)
            save_image_mat(x_recon_R, x_recon_L, args.img_path,idx,j)
    break
    j=j+1

