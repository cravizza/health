# -*- coding: utf-8 -*-
"""
Created on Sun Oct 27 19:19:14 2019

@author: cravizza
"""

from __future__ import division
import os
import pandas as pd 
import numpy as np
import time
import datetime
import sys
import matplotlib.pyplot as plt

# Define globals
pDerived = 'D:/Personal Directory/Catalina/Derived/'

def balanced_df(input_df,max_months):
    output_df = input_df[['id_m','id_b','month']].copy().drop_duplicates()
    output_df['Nmonths'] = output_df.groupby(['id_m','id_b'])['month'].transform('count')
    output_df.drop_duplicates(inplace=True)
    assert output_df.Nmonths.min() == 1
    assert output_df.Nmonths.max() == max_months
    l0 = len(output_df)
    output_df = output_df[output_df.Nmonths == max_months]
    l1 = len(output_df)
    output_df.drop(columns=['Nmonths'], inplace=True)
    print('-- Keep if balanced: ' + str(l0-l1) + ' rows dropped (' + str(int((l0-l1)/l0*10000)/100) + '%)')
    return output_df

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_agg_plots.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/agg_plots.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    
    start0 = time.time()
    print('\n-- Load pbon')
    df1 = pd.read_pickle(pDerived + 'pboni1')
    df2 = pd.read_pickle(pDerived + 'pboni2')
    df3 = pd.read_pickle(pDerived + 'pboni3')
    dfp = pd.concat([df1, df2, df3], axis=0, ignore_index=True)
    del df1, df2, df3
    dfp.drop(columns=['proid'], inplace=True)
    dfp['date'] = pd.to_numeric(dfp['date'].str.replace("-",""), downcast='integer')
    dfp.reset_index(drop=True,inplace=True)
    dfp.drop(columns=['code','code2','codeid'], inplace=True)
    print('-- Load beneficiaries')
    df1 = pd.read_pickle(pDerived + 'beneficiaries1')
    df2 = pd.read_pickle(pDerived + 'beneficiaries2')
    dfb = pd.concat([df1, df2], axis=0, ignore_index=True)
    dfb.reset_index(drop=True,inplace=True)
    del df1, df2
    
    print('\n-- Construct subsample: balanced')
    dfb_bal = balanced_df(dfb,72)
    dfb_idb = dfb_bal[['id_b']].drop_duplicates().copy()
    dfp_bal = pd.merge(dfb_idb,dfp,how='inner',on=['id_b'])
    dfp_bal.reset_index(drop=True,inplace=True)
    
    print('\n-- Benef Descriptive statistics for tex file')
    print('\item Observations: ' + str(len(dfb)))
    print('\item Families: '     + str(dfb['id_m'].nunique()))
    print('\item Individuals: ' + str(dfb['id_b'].nunique()))
    print('\item Men: ' + str(int(dfb['gender'].value_counts(normalize=True)['masculino']*10000)/100) + '\%')
    print('\item Main insured: ' + str(int(dfb['typben'].value_counts(normalize=True)['cotizante']*10000)/100) + '\%')
    print('\item Median number of months by family: ' + str(dfb.groupby('id_m')['month'].nunique().median()))

    print('\n-- PB Descriptive statistics for tex file')
    print('\item Observations: ' + str(len(dfp_bal)))
    print('\item Families: '    + str(dfp_bal['id_m'].nunique()))
    print('\item Individuals: ' + str(dfp_bal['id_b'].nunique()))
    print('\item Men: ' + str(int(dfp_bal['gender'].value_counts(normalize=True)['masculino']*10000)/100) + '\%')
    print('\item Main insured: ' + str(int(dfp_bal['typben'].value_counts(normalize=True)['cotizante']*10000)/100) + '\%')

    print('-- Load data, time elapsed load and concat: ' + str(int(time.time() - start0)) + ' sec.') #32 min

    start1 = time.time()
    # Plot PB
    dfp_groups = dfp_bal.groupby(['month']).size()
    df = pd.DataFrame(dfp_groups)
    df.rename(columns={0:'pb'}, inplace=True)
    df.reset_index(level=0, inplace=True)
    df['Month'] = pd.to_datetime(df['month'], format='%Y%m', errors='coerce').dropna()
    df.drop(columns=['month'], inplace=True)
    df['a']=0
    df2 = df.groupby(['Month']).sum()
    plt.plot(df2.index, df2.pb.values,color='green')
    plt.plot(df2.index, df2.a.values ,color='white')
    plt.savefig('../output/pb_bal_0.pdf',format='pdf')
    plt.show()    
    # Plot BEN
    dfb_groups = dfb.groupby(['month']).size()
    df0 = pd.DataFrame(dfb_groups)
    df0.rename(columns={0:'ben'}, inplace=True)
    df0.reset_index(level=0, inplace=True)
    df0['Month'] = pd.to_datetime(df0['month'], format='%Y%m', errors='coerce').dropna()
    df0.drop(columns=['month'], inplace=True)
    df0['a']=0
    df02 = df0.groupby(['Month']).sum()
    plt.plot(df02.index, df02.ben.values,color='green')
    plt.plot(df02.index, df02.a.values ,color='white')
    plt.savefig('../output/ben_bal_0.pdf')
    plt.show()
    print('-- Plots, time elapsed: ' + str(int(time.time() - start1)) + ' sec.') #

    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
