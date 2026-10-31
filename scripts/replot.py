"""Replot all exported numerical figures. Requires numpy and matplotlib."""
from pathlib import Path
import argparse, csv, gzip
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT=Path(__file__).resolve().parents[1]
def read(p):
    op=gzip.open if p.suffix=='.gz' else open
    with op(p,'rt',encoding='utf-8',newline='') as f:return list(csv.DictReader(f))
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,default=ROOT/'reproduced_figures');args=parser.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    for number in range(5,8):
        folder=ROOT/f'figures/figure_{number:02d}';meta=read(folder/'conditions.csv')
        fig,axes=plt.subplots(3 if len(meta)==9 else 2,3,figsize=(12,8),squeeze=False,layout='constrained')
        for ax,row in zip(axes.flat,meta):
            d=np.load(folder/f'{row["condition"]}_spectrogram.npz')
            im=ax.pcolormesh(d['time_s'],d['frequency_Hz']/1000,d['spectrum_dBA_per_Hz'],shading='nearest',vmin=20,vmax=100,cmap='jet')
            ax.axhspan(float(row['band_low_Hz'])/1000,float(row['band_high_Hz'])/1000,color='yellow',alpha=.15)
            ax.axhline(float(row['reference_frequency_Hz'])/1000,color='yellow',linestyle='--',linewidth=.6)
            ax.set(title=row['condition'],xlabel='Time (s)',ylabel='Frequency (kHz)',xlim=(2,12),ylim=(0,4.5))
        for ax in list(axes.flat)[len(meta):]:ax.set_visible(False)
        fig.colorbar(im,ax=list(axes.flat),label='A-weighted PSD level (dBA/Hz)')
        fig.savefig(args.output/f'figure_{number:02d}.png',dpi=180);plt.close(fig)
    for number in range(8,16):
        folder=ROOT/f'figures/figure_{number:02d}';summary=read(folder/'summary.csv')
        fig,axes=plt.subplots(1,3,figsize=(14,4),layout='constrained')
        for ax,cat in zip(axes,['drone1','drone2','violin']):
            rows=[r for r in summary if r['category']==cat];traj=read(folder/f'{cat}_trajectories.csv.gz');stats=[]
            grouped={r['condition']:[] for r in rows}
            for r in traj:grouped[r['condition']].append(float(r['condition_mean']))
            for r in rows:
                y=np.array(grouped[r['condition']]);q1,med,q3=[float(r[k]) for k in ['q25','median','q75']];iqr=q3-q1
                inside=y[(y>=q1-10*iqr)&(y<=q3+10*iqr)];lo,hi=inside.min(),inside.max()
                stats.append(dict(label=r['condition'],q1=q1,med=med,q3=q3,whislo=lo,whishi=hi,fliers=y[(y<lo)|(y>hi)]))
            ax.bxp(stats,widths=.3,showfliers=True)
            x=np.arange(1,len(rows)+1);ax.plot(x,[float(r['mean']) for r in rows],'k-o',markersize=3,label='Mean')
            ax.plot(x,[float(r['p95']) for r in rows],'k--o',markersize=3,label='5% exceedance')
            ax.set(title=cat,ylabel=rows[0]['unit'],xlabel='Operating condition');ax.tick_params(axis='x',rotation=45);ax.grid(axis='y',alpha=.3)
        axes[-1].legend(fontsize=8);fig.savefig(args.output/f'figure_{number:02d}.png',dpi=180);plt.close(fig)
    fig,axes=plt.subplots(1,3,figsize=(12,4),layout='constrained')
    for ax,cat in zip(axes,['drone1','drone2','violin']):
        rows=read(ROOT/f'figures/figure_16/{cat}_pearson.csv');r=np.array([[float(row[k]) for k in ['PAZ','PAM','PAD']] for row in rows])
        im=ax.imshow(r,vmin=-1,vmax=1,cmap='coolwarm');ax.set(xticks=range(3),yticks=range(3),xticklabels=['PAZ','PAM','PAD'],yticklabels=['PAZ','PAM','PAD'],title=cat)
        for i in range(3):
            for j in range(3):ax.text(j,i,f'{r[i,j]:.2f}',ha='center',va='center',color='white' if abs(r[i,j])>.55 else 'black')
    fig.colorbar(im,ax=list(axes),label='Pearson r');fig.savefig(args.output/'figure_16.png',dpi=180);plt.close(fig)
    print('Replotted Figures 5–16 in',args.output)
if __name__=='__main__':main()
