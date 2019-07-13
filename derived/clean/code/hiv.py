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
    
    print('\n-- Create sample of 2017 beneficiaries')
    ben_2017_pre = dfb.loc[(dfb['gender']=='masculino')&(dfb['month'].between(201701, 201712)),['id_m','id_b','munici']].drop_duplicates()
    ben_2017_pre.drop(columns=['id_m'], inplace=True)
    ben_2017 = ben_2017_pre.groupby(['munici']).count()
    ben_2017.to_stata('../output/ben_2017.dta')
    del ben_2017_pre
    del ben_2017
    
    print('\n-- Create HIV sample')
    # Find people that voluntarily take HIV test: pregnant women always take it
    # Identify pregnant women with code 0404002 = obstetric ultrasound
    dfp['temp'] = dfp['code7'].isin(['0404002'])
    dfp['pregnant'] = dfp.groupby(by=['id_m','id_b'])['temp'].transform('max')
    dfp.drop(columns=['temp'], inplace=True)
    hiv_tests = dfp.loc[dfp['code7'] == '0306169'].copy()
    hiv_tests.reset_index(drop=True,inplace=True)
    hiv_tests['date'] = hiv_tests['date'].astype('str')
    hiv_tests.drop(columns=['code2','code7','code','codeid','typreg'], inplace=True)
    hiv_tests.to_stata('../output/hiv_tests.dta')
    
    # Subsets
    hiv_tests['hiv'] = 1
    hiv_fam0 = hiv_tests[['month','id_m']].drop_duplicates()
    hiv_ids  = hiv_tests[['month','id_m','id_b']].drop_duplicates()
    hiv_ids2 = hiv_tests[['month','id_m','id_b','hiv']].drop_duplicates()
    ges_ids  =       dfg[['month','id_m','id_b']].drop_duplicates()
    hiv_tests[['id_m','id_b','month']].info()
    
    print('\n-- Families of hiv testers')
    interm  = pd.merge(hiv_fam0, dfb, how='left', on=['month','id_m'])
    interm  = interm.loc[interm['isapre'].notnull()] 
    hiv_fam = pd.merge(interm, hiv_ids2, how='left', on=['month','id_m','id_b'])
    hiv_fam['hiv'].fillna(0, inplace=True)
    for c in ['hiv','isapre']:
        hiv_fam[c] = hiv_fam[c].astype('int8')
    for c in ['id_b','dob','dod_m']:
        hiv_fam[c] = hiv_fam[c].astype('int32')
    for c in ['region','munici']:
        hiv_fam[c] = hiv_fam[c].astype('string')
    hiv_fam.reset_index(drop=True,inplace=True)
    hiv_fam.info(memory_usage='deep')
    hiv_fam.to_stata('../output/hiv_fam.dta')
    del hiv_fam
    del interm
    del hiv_fam0
    del hiv_ids2
    
    print('\n-- Pbon of hiv testers')
    hiv_pbon = pd.merge(hiv_ids, dfp, how='left', on=['id_m','id_b','month'])
    for c in ['code','code2','code7']:
        hiv_pbon[c] = hiv_pbon[c].astype('string')
    hiv_pbon.reset_index(drop=True,inplace=True)
    hiv_pbon.info(memory_usage='deep')
    hiv_pbon.to_stata('../output/hiv_pbon.dta')
    del hiv_pbon
    
    print('\n-- Pbon of hiv confirmed')
    hiv_conf = pd.merge(ges_ids, dfp, how='left', on=['id_m','id_b','month'])
    hiv_conf = hiv_conf.loc[hiv_conf['isapre'].notnull()] 
    for c in ['code','code2','code7']:
        hiv_conf[c] = hiv_conf[c].astype('string')
    for c in ['age','isapre','pregnant']:
        hiv_conf[c] = hiv_conf[c].astype('int8')
    hiv_conf.reset_index(drop=True,inplace=True)
    hiv_conf.info(memory_usage='deep')
    hiv_conf.to_stata('../output/hiv_conf.dta')
    
    print('\n-- Difference-in-differences')
    hiv_ids['N'] = hiv_ids.groupby(['id_m','id_b'])['month'].transform('count')
    df = hiv_ids.loc[hiv_ids['N']<10].copy()
    df['m'] = df.groupby(['id_m','id_b'])['month'].transform('min')
    hiv_t = df.loc[df['month'].between(201708,201709),['id_m','id_b','N','m']]
    hiv_t['control'] = 0
    hiv_did = pd.merge(hiv_t, dfp.loc[dfp['month'].between(201601,201712)], how='left', on=['id_m','id_b'])
    del hiv_t
    hiv_did = hiv_did.loc[hiv_did['isapre'].notnull()] 
    for c in ['code','code2','code7']:
        hiv_did[c] = hiv_did[c].astype('string')
    for c in ['age','isapre','pregnant']:
        hiv_did[c] = hiv_did[c].astype('int8')
    hiv_did.reset_index(drop=True,inplace=True)
    hiv_did.info(memory_usage='deep')
    hiv_did.to_stata('../output/hiv_did.dta')
        
    print('\n-- Families of did sample')
    did_fam0 = hiv_did[['id_m']].drop_duplicates()
    did_ids2 = hiv_did[['id_m','id_b','control']].drop_duplicates()
    interm  = pd.merge(did_fam0, dfb.loc[dfb['month'].between(201601,201712)], how='left', on=['id_m'])
    interm  = interm.loc[interm['isapre'].notnull()] 
    did_fam = pd.merge(interm, did_ids2, how='left', on=['id_m','id_b'])
    did_fam['control'].fillna(9, inplace=True)
    for c in ['control','isapre']:
        did_fam[c] = did_fam[c].astype('int8')
    for c in ['id_b','dob','dod_m','month']:
        did_fam[c] = did_fam[c].astype('int32')
    for c in ['region','munici']:
        did_fam[c] = did_fam[c].astype('string')
    did_fam.reset_index(drop=True,inplace=True)
    did_fam.info(memory_usage='deep')
    did_fam.loc[did_fam['control']!=9,['id_b','id_m','month']].to_stata('../output/hiv_did_enr.dta')
    did_fam.loc[did_fam['month']==201708].to_stata('../output/hiv_did_fam.dta')
    del did_fam
    del interm
    del did_fam0
    del did_ids2
    del hiv_did
    
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
