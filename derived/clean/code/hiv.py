# -*- coding: utf-8 -*-
"""
Clean beneficiaries table abd create subsamples
"""
from __future__ import division
import os
import pandas as pd 
import time
import datetime
import sys

# Define globals
pDerived = 'D:/Personal Directory/Catalina/Derived/'

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_hiv.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/hiv.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

	# Load benef
    start0 = time.time()
    df1 = pd.read_pickle(pDerived + 'beneficiaries1')
    df2 = pd.read_pickle(pDerived + 'beneficiaries2')
    dfb = pd.concat([df1, df2], axis=0, ignore_index=True)
    del df1
    del df2
    print('\n-- Time elapsed load and concat: ' + str(int(time.time() - start0)) + ' sec.')
    
    # Load pbon
    start1 = time.time()
    df1 = pd.read_pickle(pDerived + 'pboni1')
    df2 = pd.read_pickle(pDerived + 'pboni2')
    df3 = pd.read_pickle(pDerived + 'pboni3')
    dfp = pd.concat([df1, df2, df3], axis=0, ignore_index=True)
    del df1
    del df2
    del df3
    dfp = dfp.loc[dfp['code'].notnull()] 
    dfp.drop(columns=['proid'], inplace=True) # drop to use in Stata
    dfp['code2'] = dfp.code.str.zfill(7).str[0:2] 
    print('\n-- Time elapsed load and concat: ' + str(int(time.time() - start1)) + ' sec.')    
    
    # Load GES
    start2 = time.time()
    dfg = pd.read_pickle(pDerived + 'hiv_ges')
    dfg = dfg.loc[(dfg['month']>=201201)]
    print('\n-- Time elapsed load: ' + str(int(time.time() - start2)) + ' sec.')
    
    # Create HIV sample
    # Find people that voluntarily take HIV test: pregnant women always take it
    # Identify pregnant women with code 0404002 = obstetric ultrasound
    dfp['temp'] = dfp['code7'].isin(['0404002'])
    dfp['pregnant'] = dfp.groupby(by=['id_m','id_b'])['temp'].transform('max')
    dfp.drop(columns=['temp'], inplace=True)
    df_hiv = dfp.loc[dfp['code7'] == '0306169'].copy()
    df_hiv.reset_index(drop=True,inplace=True)
    df_hiv['date'] = df_hiv['date'].astype('str')
    df_hiv.drop(columns=['code2','code7','code','codeid','typreg'], inplace=True)
    df_hiv.to_stata('../output/hiv_tests.dta')
    
    # Subsets
    df_hiv['hiv'] = 1
    df_mm   =              df_hiv[['id_m','month']].drop_duplicates()
    df_mmb  =       df_hiv[['id_b','id_m','month']].drop_duplicates()
    df_hiv2 = df_hiv[['hiv','id_b','id_m','month']].drop_duplicates()
    dfg_mmb =          dfg[['id_b','id_m','month']].drop_duplicates()
    df_hiv[['id_m','id_b','month']].info()
    
    print('\n-- Families of hiv testers')
    interm      = pd.merge(df_mm ,dfb    ,how='left',on=['month','id_m'])
    interm      = interm.loc[interm['isapre'].notnull()] 
    df_hiv_fam  = pd.merge(interm,df_hiv2,how='left',on=['month','id_m','id_b'])
    df_hiv_fam['hiv'].fillna(0, inplace=True)
    for c in ['hiv','isapre']:
        df_hiv_fam[c] = df_hiv_fam[c].astype('int8')
    for c in ['id_b','dob','dod_m']:
        df_hiv_fam[c] = df_hiv_fam[c].astype('int32')
    for c in ['region','munici']:
        df_hiv_fam[c] = df_hiv_fam[c].astype('string')
    df_hiv_fam.reset_index(drop=True,inplace=True)
    df_hiv_fam.info(memory_usage='deep')
    df_hiv_fam.to_stata('../output/hiv_fam.dta')
    del df_hiv_fam
    del interm
    del df_mm
    del df_hiv2    
    
    print('\n-- Pbon of hiv testers')
    df_hiv_pbon = pd.merge(df_mmb, dfp, how='left', on=['id_m','id_b','month'])
    for c in ['code','code2','code7']:
        df_hiv_pbon[c] = df_hiv_pbon[c].astype('string')
    df_hiv_pbon.reset_index(drop=True,inplace=True)
    df_hiv_pbon.info(memory_usage='deep')
    df_hiv_pbon.to_stata('../output/hiv_pbon.dta')
    del df_hiv_pbon
    
    print('\n-- Pbon of hiv confirmed')
    df_hiv_conf = pd.merge(dfg_mmb, dfp, how='left', on=['id_m','id_b','month'])
    df_hiv_conf = df_hiv_conf.loc[df_hiv_conf['isapre'].notnull()] 
    for c in ['code','code2','code7']:
        df_hiv_conf[c] = df_hiv_conf[c].astype('string')
    for c in ['age','isapre','pregnant']:
        df_hiv_conf[c] = df_hiv_conf[c].astype('int8')
    df_hiv_conf.reset_index(drop=True,inplace=True)
    df_hiv_conf.info(memory_usage='deep')
    df_hiv_conf.to_stata('../output/hiv_conf.dta')
    
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
