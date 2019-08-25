"""
Create cleaned dataset of contratos
"""
from __future__ import division # to use division (instead of integer division) in python 2
from multiprocessing import Pool
import os
import pandas as pd 
import numpy as np
import time
import datetime
import sys

# Define globals
pDerived = 'D:/Personal Directory/Catalina/Derived/'

col_dtypes = {0:'category', 1:'int8'    , 2:'int32'   , 3:'Int32'   , 4:'category', 5:'category', 6:'category'
			, 7:'category', 8:'category', 9:'category',10:'category',11:'int32'   ,12:'int32'   ,13:'int32'
            ,14:'Int32'   ,15:'Int32'   ,16:'category',17:'category',18:'category',19:'category',20:'category'
            ,21:'category',22:'category',23:'int32'   ,24:'int8'    ,25:'category',26:'category'}
col_names = { 0:'month'   , 1:'isapre'  , 2:'id_m'    , 3:'id_m_alt', 4:'constart', 5:'contyp'  , 6:'benstart'
			, 7:'e_typ'   , 8:'conmonth', 9:'planid'  ,10:'planingr',11:'pr_ges'  ,12:'pr_caec' ,13:'pr_add'    
            ,14:'payset'  ,15:'paytot'  ,16:'movdate' ,17:'movtyp'  ,18:'exc_ren' ,19:'caec'    ,20:'conend'
            ,21:'benend'  ,22:'endtyp'  ,23:'salesid' ,24:'numempl' ,25:'payfin'  ,26:'relempl'}

use_cols = [0,1,2,3,4,6,7,8,9,10,20,21,22,25,26]
col_dat = ['constart','dod_m']
col_int = ['month','conmonth','benstart']
col_cat = ['e_typ','planingr','planid','constart','benend','endtyp','payfin']

def readcsv(a):
    df = pd.read_csv(a, sep='|', header=None, dtype=col_dtypes, usecols=use_cols)
    df.dropna(subset=[0], inplace=True)
    df.dropna(axis=1, how='all', inplace=True) #drop any column with all NA values
    assert len(df.columns) == 15
    df.rename(columns=col_names, inplace=True)    
    df.dropna(how='all', inplace=True)
    clean_single_df(df)
    return df

def clean_single_df(df):
    for c in col_cat:
        df[c] = df[c].astype('category')
        df[c].cat.remove_unused_categories(inplace=True)
    for c in col_int:
        df[c] = df[c].astype('int32')
    return df

def merge_families(df):
    df_families0 = pd.read_pickle(pDerived + 'df_families')
    df_families0['keep_col'] = 1
    df_families = df_families0[['isapre','id_m','keep_col']].drop_duplicates()
    df2 = pd.merge(df, df_families, how='left', on=['isapre','id_m'])
    df2['keep_col'].value_counts(dropna=False)
    del df_families
    del df
    print('-- Value counts merge families')
    df2['keep_col'].value_counts(dropna=False)
    df2.loc[df2['keep_col'].isnull()].to_pickle(pDerived + 'contracts_drop')
    l0 = len(df2)
    df2 = df2.loc[df2['keep_col']==1]
    l1 = len(df2)
    print('-- Drop if not in beneficiaries:  ' + str(l0-l1) + ' rows dropped (' + str(int((l0-l1)/l0*10000)/100) + '%)')
    df2.drop(columns=['keep_col'], inplace=True)
    df2.reset_index(drop=True, inplace=True)
    return df2

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_contracts.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/contracts.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    file_list = [os.path.join(path, f) for path, sd, files in os.walk('D:/Personal Directory/Catalina/Data') for f in files if 'Contratos' in f]
    print('\n-- Begin pool ')
    start0 = time.time()
    pool = Pool(processes=16) # or whatever your hardware can support
    df_concat = pd.concat(pool.map(readcsv, file_list), axis=0, ignore_index=True)
    print('-- Time pool.map and concat:  ' + str(int(time.time() - start0)) + ' sec.')

    try:
        pool.terminate()
    except WindowsError:
        pass
        
    l1 = len(df_concat)
    df_concat['idalt_nonzero'] = df_concat['id_m'].isin(df_concat.loc[df_concat['id_m_alt']!=0,'id_m'])
    df_concat = df_concat[df_concat['idalt_nonzero']==0]
    df_concat.reset_index(drop=True, inplace=True)
    assert len(df_concat.loc[df_concat['id_m_alt']!=0]) == 0
    l2 = len(df_concat)
    print('-- Drop if id_alt!=0  :  ' + str(l1-l2) + ' rows dropped (' + str(int((l1-l2)/l1*10000)/100) + '%)')
    df_concat.drop(columns=['idalt_nonzero','id_m_alt'], inplace=True)
    
    for c in col_int:
        df_concat[c] = df_concat[c].astype('int32')
    for c in col_cat:
        df_concat[c] = df_concat[c].astype('category')
        df_concat[c].cat.remove_unused_categories(inplace=True)
        
    df_final = merge_families(df_concat)
    
    print('\n-- Concat dataframe dtypes')
    df_final.info(memory_usage='deep')

    print('\n-- Descriptive stats')
    df_final['planingr'] = df_final['planingr'].str.replace('GRUPAL','group').str.strip()
    df_final['planingr'] = df_final['planingr'].str.replace('^INDIVIDUAL$','indiv').str.strip()
    df_final['planingr'] = df_final['planingr'].str.replace('^INDIVIDUAL COMPENSADO$','indcom').str.strip()
    df_final['planingr'] = df_final['planingr'].str.replace('S/E','no_info').str.strip()
    df_final['planingr'] = df_final['planingr'].astype('category')
    df_final['planingr'].cat.remove_unused_categories(inplace=True)
    for c in ['planingr','endtyp']:
        print('\n' + str(df_final[c].value_counts(dropna=False)))
        
    print('\n-- Split dataframe ')
    len0 = int(len(df_final)/2)
    df1 = df_final[0:len0]
    df2 = df_final[len0:]
    df3 = pd.concat([df1, df2], axis=0, ignore_index=True) 
    print('-- Slices equal to concat dataframe: ' + str(df_final.equals(df3)))
    del df3

    print('\n-- Begin pickling ')
    start01 = time.time()
    df1.to_pickle(pDerived + 'contracts1')
    print('-- Time elapsed first half:  ' + str(int(time.time() - start01)) + ' sec.')
    
    start02 = time.time()
    df2.to_pickle(pDerived + 'contracts2')
    print('-- Time elapsed second half: ' + str(int(time.time() - start02)) + ' sec.')

    print('\n-- Pickle plan type sample')
    dfc = df_final[['month','id_m','planingr']].drop_duplicates()
    dfc.to_pickle(pDerived + 'contracts_plantype')

    print('\n-- Total time elapsed: ' + str(int((time.time() - start0)/60)) + ' min. / ' + str(int(time.time() - start0)) + ' sec.')
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
    