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
code_prg = ['0404002','2004001','2004002','2004003','2004004','2004005','2004006','2004007','2004008'
           ,'2004009','2004010','2004011','2004012','2004013','0101007','2501009','0404122']
    
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
    
def get_fam_df(df_idm,df_idt,benef,contracts,income):
    i0 = pd.merge(df_idm,contracts, how='inner', on=['month','id_m'],validate='1:1')
    i1 = pd.merge(i0    ,income   , how='inner', on=['month','id_m'],validate='1:1')
    i2 = pd.merge(i1    ,benef    , how='left' , on=['month','id_m'])
    del df_idm
    df_fam = pd.merge(i2, df_idt, how='left', on=['month','id_m','id_b'])
    del i0, i1, i2
    del df_idt
    df_fam['hiv'].fillna(0, inplace=True)
    for c in ['hiv','isapre','indcom','salaried']:
        df_fam[c] = df_fam[c].astype('int8')
    for c in ['id_b','dob','dod_m']:
        df_fam[c] = df_fam[c].astype('int32')
    for c in ['region','munici']:
        df_fam[c] = df_fam[c].astype('string')
    df_fam.reset_index(drop=True,inplace=True)
    df_fam.info(memory_usage='deep')
    return df_fam
    
def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_hiv.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/hiv.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    
    start0 = time.time()
    df1 = pd.read_pickle(pDerived + 'beneficiaries1')
    df2 = pd.read_pickle(pDerived + 'beneficiaries2')
    dfb = pd.concat([df1, df2], axis=0, ignore_index=True)
    del df1, df2
    print('\n-- Beneficiaries, time elapsed load and concat: ' + str(int(time.time() - start0)) + ' sec.')
    
    start1 = time.time()
    print('\n-- Construct subsample: balanced 2012-2017, ages 18-50 on 31Dec2017')
    agg_dfb = dfb.loc[dfb['dob'].between(19620100,19990100)].copy()
    agg_dfb.reset_index(drop=True,inplace=True)
    agg_dfb_bal = balanced_df(agg_dfb,72)
    agg_dfb_ids = agg_dfb_bal[['id_m','id_b']].drop_duplicates().copy()
    print('-- Construct subsample: balanced 2015-2017, ages 18-50 on 31Dec2017')
    ind_dfb = dfb.loc[(dfb['month'].between(201501,201712))&(dfb['dob'].between(19670100,19990100))].copy()
    ind_dfb.reset_index(drop=True,inplace=True)
    ind_dfb_bal = balanced_df(ind_dfb,36)
    #ind_dfb_idt = pd.merge(ind_dfb,ind_dfb_bal,how='inner',on=['id_m','id_b','month'])
    ind_dfb_ids = ind_dfb_bal[['id_m','id_b']].drop_duplicates().copy()
    #ind_dfb_idm = ind_dfb_bal[['id_m']].drop_duplicates().copy()
    print('-- Subsample beneficiaries, time elapsed: ' + str(int(time.time() - start1)) + ' sec.')
    
    start2 = time.time()
    dfi = pd.read_pickle(pDerived + 'cotiza_income')
    print(dfi['ti'].describe())
    print(dfi['paytot'].describe())
    print(dfi['salaried'].value_counts(dropna=False).head())
    dfc = pd.read_pickle(pDerived + 'contracts_plantype')
    print(dfc['indcom'].value_counts(dropna=False).head())
    print('\n-- Income and contracts, time elapsed load and concat: ' + str(int(time.time() - start2)) + ' sec.')
    
    start3 = time.time()
    df1 = pd.read_pickle(pDerived + 'pboni1')
    df2 = pd.read_pickle(pDerived + 'pboni2')
    df3 = pd.read_pickle(pDerived + 'pboni3')
    dfp = pd.concat([df1, df2, df3], axis=0, ignore_index=True)
    del df1, df2, df3
    dfp.drop(columns=['proid'], inplace=True) #dfp['code2'] = dfp.code.str.zfill(7).str[0:2]
    dfp['date'] = pd.to_numeric(dfp['date'].str.replace("-",""), downcast='integer')
    print('\n-- Pbon, time elapsed load and concat: ' + str(int(time.time() - start3)) + ' sec.')    
    
    start4 = time.time()   
    print('\n-- Create HIV subsample of pbon')
    # Find people that voluntarily take HIV test: pregnant women always take it
    dfp['temp'] = dfp['code7'].isin(code_prg)
    dfp['pregnant'] = dfp.groupby(by=['id_m','id_b'])['temp'].transform('max')
    l0 = len(dfp)
    dfp = dfp.loc[dfp['pregnant']==0]
    l1 = len(dfp)
    dfp.drop(columns=['temp','pregnant'], inplace=True)
    dfp.reset_index(drop=True,inplace=True)
    print('-- Drop if pregnant: ' + str(l0-l1) + ' rows dropped (' + str(int((l0-l1)/l0*10000)/100) + '%)')
    hiv_tests = dfp.loc[dfp['code7'] == '0306169'].copy()
    hiv_tests.reset_index(drop=True,inplace=True)
    hiv_tests.drop(columns=['code7','code','codeid','typreg'], inplace=True)
    print('-- Subsample pbon, time elapsed: ' + str(int(time.time() - start4)) + ' sec.')
    
    start5 = time.time()
    print('\n-- Create dataset for aggregate analysis')
    agg_hiv = pd.merge(agg_dfb_ids,hiv_tests,how='inner',on=['id_m','id_b']) #balanced
    agg_hiv.to_stata('../output/agg_hiv.dta') #hiv_tests.dta
    agg_hiv['hiv'] = 1
    agg_idt = agg_hiv[['month','id_m','id_b','hiv']].drop_duplicates().copy()
    agg_ids = agg_idt[['month','id_m','id_b']].drop_duplicates().copy()
    agg_idm = agg_idt[['month','id_m']].drop_duplicates().copy()
    print('-- Families')
    agg_fam = get_fam_df(agg_idm,agg_idt,dfb,dfc,dfi)
    agg_fam.to_stata('../output/agg_fam.dta') #hiv_fam.dta
    del agg_fam
    print('-- Pbon')
    agg_pbon = pd.merge(agg_ids, dfp, how='left', on=['id_m','id_b','month'])
    del agg_ids
    for c in ['code','code7']:
        agg_pbon[c] = agg_pbon[c].astype('string')
    agg_pbon.reset_index(drop=True,inplace=True)
    agg_pbon.info(memory_usage='deep')
    agg_pbon.to_pickle(pDerived + 'agg_pbon')
    agg_pbon.to_stata('../output/agg_pbon.dta') #hiv_pbon.dta
    del agg_pbon
    print('-- HIV aggregate, time elapsed: ' + str(int(time.time() - start5)) + ' sec.')
    
    start6 = time.time()
    print('\n-- Create dataset for individual analysis: balanced sample of testers')
    ind_hiv0 = hiv_tests[(hiv_tests.date.between(20160720,20160910))|(hiv_tests.date.between(20170720,20170910))].copy()
    ind_hiv = pd.merge(ind_dfb_ids,ind_hiv0,how='inner',on=['id_m','id_b'])
    del ind_hiv0
    ind_hiv['control'] = ind_hiv.date.between(20160720,20160910)
    ind_hiv['N']  = ind_hiv.groupby(['id_m','id_b'])['month'].transform('count')
    ind_hiv['Nc'] = ind_hiv.groupby(['id_m','id_b','control'])['month'].transform('count')
    ind_hiv = ind_hiv[ind_hiv.N==ind_hiv.Nc] #only in one group
    ind_hiv.drop(columns=['N','Nc'], inplace=True)
    ind_hiv.reset_index(drop=True,inplace=True)
    ind_hiv['mD'] = ind_hiv.groupby(['id_m','id_b'])['date'].transform('min')
    ind_hiv['hiv'] = 1
    ind_idt = ind_hiv.loc[ind_hiv.mD==ind_hiv.date,['month','id_m','id_b','hiv','control','mD']].drop_duplicates().copy()
    ind_idm = ind_idt[['month','id_m']].drop_duplicates().copy()
    ind_ids = ind_idt[['month','id_m','id_b']].drop_duplicates().copy()
    ind_hiv[['id_m','id_b','month']].info()
    print('-- Families')
    dfb = dfb.loc[(dfb['month'].between(201607,201609))|(dfb['month'].between(201707,201709))].copy()
    ind_fam = get_fam_df(ind_idm,ind_idt,dfb,dfc,dfi)
    ind_fam['control'].fillna(9, inplace=True)
    ind_fam['control'] = ind_fam['control'].astype('int8')
    ind_fam.to_stata('../output/ind_fam.dta') #hiv_did_fam.dta
    del ind_fam
    print('-- Pbon')
    #hiv_ids['N'] = hiv_ids.groupby(['id_m','id_b'])['month'].transform('count')
    #df = hiv_ids.loc[hiv_ids['N']<10].copy()
    ind_temp = ind_hiv[['id_m','id_b','control','mD']].drop_duplicates().copy()
    ind_pbon = pd.merge(ind_temp, dfp.loc[dfp['month'].between(201501,201712)], how='left', on=['id_m','id_b'])
    del ind_temp
    for c in ['code','code2','code7']:
        ind_pbon[c] = ind_pbon[c].astype('string')
    for c in ['age','isapre']:
        ind_pbon[c] = ind_pbon[c].astype('int8')
    ind_pbon.reset_index(drop=True,inplace=True)
    ind_pbon.info(memory_usage='deep')
    ind_pbon.to_pickle(pDerived + 'ind_pbon')
    ind_pbon.to_stata('../output/ind_pbon.dta') #hiv_did.dta
    del ind_pbon
    print('\n-- HIV individual, time elapsed: ' + str(int(time.time() - start6)) + ' sec.')

    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
