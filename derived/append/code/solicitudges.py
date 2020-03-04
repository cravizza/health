"""
Append GES
"""
from __future__ import division # to use division (instead of integer division) in python 2
import pandas as pd
import time
import os
import datetime
import sys

col_dtypes = { 0:'int8'    , 1:'int32'   , 2:'Int64'   , 3:'string'  , 4:'int64'   , 5:'category', 6:'category'
             , 7:'Int64'   , 8:'int32'   , 9:'category',10:'category',11:'Int32'   ,12:'int32'   ,13:'category'
             ,14:'category',15:'Int64'   ,16:'category',17:'string'  ,18:'category',19:'category',20:'string'
             ,21:'category',22:'string'  ,23:'category',24:'category',25:'string'  ,26:'int32'   ,27:'category'
             ,28:'category',29:'category',30:'Int64'   ,31:'string'  ,32:'int32'   ,33:'category',34:'category'
             ,35:'category',36:'category',37:'category',38:'category'}
col_names = { 0:'isapre'   , 1:'month'   , 2:'gessol'  , 3:'date'    , 4:'id_s'    , 5:'dv_s'    , 6:'run_s'
            , 7:'id_s_a'   , 8:'id_m'    , 9:'dv_m'    ,10:'run_m'   ,11:'id_m_a'  ,12:'id_b'    ,13:'dv_b'
            ,14:'run_b'    ,15:'id_b_a'  ,16:'gender'  ,17:'dob'     ,18:'gescod'  ,19:'event'   ,20:'evdate'
            ,21:'re_isa'   ,22:'re_idat' ,23:'re_irej' ,24:'re_inot' ,25:'re_ibdat',26:'proid'   ,27:'prodv'
            ,28:'re_ben'   ,29:'re_brej' ,30:'gesid'   ,31:'pronam'  ,32:'id_reg'  ,33:'icd10'   ,34:'age'
            ,35:'health'   ,36:'gessta'  ,37:'gesclo'}
col_int = ['gessol','gesid']
pDerived = 'D:/Personal Directory/Catalina/Derived/'

def merge_families(df):
    df_families = pd.read_pickle(pDerived + 'df_families')
    df_families['keep_col'] = 1 
    df2 = pd.merge(df, df_families, how='left', on=['isapre','id_m','id_b'])
    df2['keep_col'].value_counts(dropna=False)
    del df_families
    del df
    print('-- Value counts merge families')
    df2['keep_col'].value_counts(dropna=False)
    df2.loc[df2['keep_col'].isnull()].to_pickle(pDerived + 'solicitudges_drop')
    l0 = len(df2)
    df2 = df2.loc[df2['keep_col']==1]
    l1 = len(df2)
    print('-- Drop if not in beneficiaries:  ' + str(l0-l1) + ' rows dropped (' + str(int((l0-l1)/l0*10000)/100) + '%)')
    df2.drop(columns=['keep_col'], inplace=True)
    df2.reset_index(drop=True, inplace=True)
    return df2

def clean_df(df):
    final_df = df
    final_df.drop(columns=['run_m','run_b','id_m_a','id_b_a','health'], inplace=True)
    
    final_df['icd10'].fillna('0', inplace=True)
    final_df.drop(columns=['id_s','id_s_a','run_s'], inplace=True)

    final_df['month']  = pd.to_numeric(final_df['date'].str.replace("-","").str[0:6], downcast='integer') 
    final_df['event'].replace(to_replace=r'(^No aplicable)',value='tto_or_und', regex=True, inplace=True)
    final_df['event'].replace(to_replace=r'(^Confirmaci.n)',value='confirmation', regex=True, inplace=True)
    final_df['event'].replace(to_replace=r'(^Sospecha)',value='suspicion', regex=True, inplace=True)
    final_df['event']   =   final_df['event'].astype('category')
    final_df['evdate'] = final_df['evdate'].str.replace("3000-01-01","1800-01-01")
    final_df['evdate'] = pd.to_numeric(final_df['evdate'].str.replace("-",""), downcast='integer')
    final_df['date']   =   pd.to_numeric(final_df['date'].str.replace("-",""), downcast='integer')   
    final_df['isapre'] = final_df['isapre'].astype('int8')
    final_df['month']  =  final_df['month'].astype('int32')
    final_df['id_m']   =   final_df['id_m'].astype('int32')
    final_df['id_b']   =   final_df['id_b'].astype('int32')
    for c in col_int:
        final_df[c] = final_df[c].astype('int64')
    
    return final_df

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_solicitudges.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/solicitudges.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    start0 = time.time()
    
    filename = "D:\Personal Directory\Catalina\Data\solicitudges_201712.txt"
    df = pd.read_csv(filename, sep='|', header=None , dtype=col_dtypes)
    df.rename(columns=col_names, inplace=True)
    df.dropna(axis=1, how='all', inplace=True)
    df.drop(columns=['month','dv_s','dv_m','dv_b','prodv','age'], inplace=True)
    
    dfm = merge_families(df)
    
    dfg = clean_df(dfm)
    
    print('\n-- Dataframe dtypes')
    dfg.info(memory_usage='deep')
    print('\n-- Dataframe size')
    dfg.memory_usage(deep=True)
    
    for c in dfg.columns:
        print('---- ' + str(c) + ' : ' + str(dfg[c].nunique()))
        print(dfg[c].value_counts(dropna=False).head(10))
    
    dfg.to_pickle(pDerived + 'solicitudges')

    print('\n-- Total time elapsed: ' + str(int((time.time() - start0)/60)) + ' min. | ' + str(int(time.time() - start0)) + ' sec.')
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()

