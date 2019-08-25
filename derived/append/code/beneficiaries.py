"""
Create cleaned dataset of beneficiaries
"""
from __future__ import division # to use division (instead of integer division) in python 2
from multiprocessing import Pool
import os
import pandas as pd 
import time
import datetime
import sys

# Define globals
pDerived = 'D:/Personal Directory/Catalina/Derived/'
col_dtypes = { 0:'Int32'   , 1:'Int8'    , 2:'Int32'   , 3:'Int32'   , 4:'Int32' , 5:'Int32'   , 6:'string'
             , 7:'string'  , 8:'category', 9:'category',10:'category',11:'Int32' ,12:'Int8'    ,13:'category'
             ,14:'category',15:'category'}
col_names =  { 0:'month'   , 1:'isapre'  , 2:'id_m'    , 3:'id_m_alt', 4:'id_b'  , 5:'id_b_alt', 6:'dob'     
             , 7:'dod_m'   , 8:'gender'  , 9:'civs_m'  ,10:'pais_m'  ,11:'munici',12:'region'  ,13:'codrel'
             ,14:'typben'  ,15:'valid'}
col_dat = ['dob','dod_m']
col_int = ['month','isapre','id_m','id_m_alt','id_b','id_b_alt','munici','region']
col_str = ['gender','civs_m','pais_m','codrel','typben','valid']
col_cat = ['munici','region']

def readcsv(a):
    df = pd.read_csv(a, sep='|', header=None, dtype=col_dtypes)
    df.dropna(axis=1, how='all', inplace=True) #drop any column with all NA values
    assert len(df.columns) == 16
    df.rename(columns=col_names, inplace=True)
    df.dropna(how='all', inplace=True)
    clean_single_df(df)
    return df

def clean_single_df(df):
    for c in col_dat:
        df[c] = pd.to_numeric(df[c].str.replace("-",""), downcast='integer')
        df[c] = df[c].astype('Int32')
    
    for c in col_str:
        df[c] = df[c].str.lower().str.strip()
        df[c].replace(to_replace=r'(\bsin (informaci[\Wo]n|especificar|clasificar|clasificaci[\W]n))|(\botros?)', value='no info', regex=True, inplace=True)

    df['valid'].replace(to_replace=r'^[^sn]',value='n', regex=True, inplace=True)
    df['codrel'].replace(to_replace=r'(^c[o\W]nyuge|^conviviente civil)',value='conyuge', regex=True, inplace=True)
    df['codrel'].replace(to_replace=r'^[mp]adre',value='parent', regex=True, inplace=True)
    df['gender'].replace(to_replace=r'^((?!((femenino)|(masculino))).)*$',value='no info', regex=True, inplace=True)
    df['typben'].replace(to_replace=r'(^carga m.dica|^carga legal)',value='carga', regex=True, inplace=True)
    df['typben'] = df['typben'].str.replace('cotizante titular','cotizante').str.strip()
    df['typben'] = df['typben'].str.replace('beneficiario cotizante','beneficiario').str.strip()    
    df['civs_m'] = df['civs_m'].str.replace('\(o\)', '').str.strip()
       
    for c in col_str:
        df[c] = df[c].astype('category')
    
    # Create dictionary
    df['valid']  =  df['valid'].cat.set_categories(['s','n'])
    df['civs_m'] = df['civs_m'].cat.set_categories(['no info','soltera','casada','divorciada','viuda'])
    df['typben'] = df['typben'].cat.set_categories(['no info','cotizante','carga','beneficiario'])
    df['codrel'] = df['codrel'].cat.set_categories(['no info','cotizante','conyuge','hijo','parent'])
    df['pais_m'] = df['pais_m'].cat.set_categories(['no info','chilena','extranjera'])
    df['gender'] = df['gender'].cat.set_categories(['no info','masculino','femenino'])
    return df

def clean_df_concat(df):
    l0 = len(df)
    df2 = df[df['valid']=='s']
    df2.reset_index(drop=True, inplace=True)
    l1 = len(df2)
    print('-- Keep if valid=s    :  ' + str(l0-l1) + ' rows dropped (' + str(int((l0-l1)/l0*10000)/100) + '%)')
    
    df2['idalt_nonzero'] = df2['id_m'].isin(df2.loc[(df2['id_m_alt']!=0)|(df2['id_b_alt']!=0),'id_m'])
    df2 = df2[df2['idalt_nonzero']==0]
    df2.reset_index(drop=True, inplace=True)
    assert len(df2.loc[(df2['id_m_alt']!=0)|(df2['id_b_alt']!=0)]) == 0
    l2 = len(df2)
    print('-- Drop if id_alt!=0  :  ' + str(l1-l2) + ' rows dropped (' + str(int((l1-l2)/l0*10000)/100) + '%)')
    
    df2['idb_rutzero'] = df2['id_m'].isin(df2.loc[(df2['id_b']==2904192)|(df2['id_b']==1529982),'id_m'])
    df2 = df2[df2['idb_rutzero']==0]
    df2.reset_index(drop=True, inplace=True)
    assert len(df2.loc[(df2['id_b']==2904192)|(df2['id_b']==1529982)]) == 0
    l3 = len(df2)
    print('-- Drop if rut zero   :  ' + str(l2-l3) + ' rows dropped (' + str(int((l2-l3)/l0*10000)/100) + '%)')
    
    df2['is_dupl'] = df2.duplicated(['month','isapre','id_m','id_b'],keep=False)
    df2['dupl_keys'] = df2['id_m'].isin(df2.loc[df2['is_dupl']==1,'id_m'])
    df2 = df2[df2['dupl_keys']==0]
    df2.reset_index(drop=True, inplace=True)
    assert len(df2.loc[df2['is_dupl']==1]) == 0
    l4 = len(df2)
    print('-- Drop if dupl. keys :  ' + str(l3-l4) + ' rows dropped (' + str(int((l3-l4)/l0*10000)/100) + '%)')

    df2['Ndod0'] = (~df2['dod_m'].isin([18000101,20001114,30000101]))
    df2['Ndod1'] = df2.groupby(['id_m','id_b'])['Ndod0'].transform('max')
    df2 = df2.loc[df2['Ndod1']==0]
    l5 = len(df2)
    print('-- Drop if dead :  ' + str(l4-l5) + ' rows dropped (' + str(int((l4-l5)/l0*10000)/100) + '%)')
    
    df2.drop(columns=['Ndod0','Ndod1','valid','idalt_nonzero','id_m_alt','id_b_alt','idb_rutzero','is_dupl','dupl_keys'], inplace=True)
    
    for c in col_cat:
        df2[c] = df2[c].astype('category')

    assert df2.duplicated(['month','isapre','id_m','id_b'],keep=False).values.sum() == 0
    assert len(df2.columns) == 13
    assert    df2.dob.isnull().sum()==0
    assert  df2.month.isnull().sum()==0
    assert df2.isapre.isnull().sum()==0
    
    df2['isapre'] = df2['isapre'].astype('int8')
    df2['month']  =  df2['month'].astype('int32')
    df2['id_m']   =   df2['id_m'].astype('int32')
    df2['id_b']   =   df2['id_b'].astype('int32')
    df2.reset_index(drop=True,inplace=True)

    print('-- Total rows dropped : ' + str(l0-len(df2)) + ' rows dropped (' + str(int((l0-len(df2))/l0*10000)/100) + '%)')
    del l0, l1, l2, l3, l4, l5
    return df2

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_beneficiaries.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/beneficiaries.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    file_list = [os.path.join(path, f) for path, sd, files in os.walk('D:/Personal Directory/Catalina/Data') for f in files if 'Benef' in f]
    print('\n-- Begin pool ')
    start0 = time.time()
    pool = Pool(processes=16) # or whatever your hardware can support
    df_concat = pd.concat(pool.map(readcsv, file_list), axis=0, ignore_index=True)
    print('-- Time pool.map and concat:  ' + str(int(time.time() - start0)) + ' sec.')

    try:
        pool.terminate()
    except WindowsError:
        pass
    
    print('\n-- Concat dataframe dtypes')
    df_concat.info(memory_usage='deep')
    
    print('\n-- Cleaning ')
    start1 = time.time()
    final_df = clean_df_concat(df_concat)
    print('-- Time elapsed cleaning : ' + str(int(time.time() - start1)) + ' sec.')
    print('\n-- Descriptive stats')
    for c in ['gender','civs_m','pais_m','codrel','typben']:
        print('\n' + str(final_df[c].value_counts(dropna=False)))
    
    print('\n-- Final dataframe dtypes')  
    final_df.info(memory_usage='deep')

    print('\n-- Descriptive statistics for tex file')
    print('\item Observations: ' + str(len(final_df)))
    print('\item Families: ' + str(final_df['id_m'].nunique()))
    print('\item Individuals: ' + str(final_df['id_b'].nunique()))
    print('\item Men: ' + str(int(final_df['gender'].value_counts(normalize=True)['masculino']*10000)/100) + '\%')
    print('\item Main insured: ' + str(int(final_df['typben'].value_counts(normalize=True)['cotizante']*10000)/100) + '\%')
    print('\item Median number of months by family: ' + str(final_df.groupby('id_m')['month'].nunique().median()))

    print('\n-- Create dictionary of families')
    df_families = final_df[['isapre','id_m','id_b']].drop_duplicates().copy()
    df_families.to_pickle(pDerived + 'df_families')
    del df_families

    print('\n-- Split dataframe ')   
    df1 = final_df[0:113865847]
    df2 = final_df[113865847:]
    df3 = pd.concat([df1, df2], axis=0, ignore_index=True) 
    print('-- Slices equal to concat dataframe: ' + str(final_df.equals(df3)))
    del df3

    print('\n-- Begin pickling ')
    start01 = time.time()
    df1.to_pickle(pDerived + 'beneficiaries1')
    print('-- Time elapsed first half:  ' + str(int(time.time() - start01)) + ' sec.')
    
    start02 = time.time()
    df2.to_pickle(pDerived + 'beneficiaries2')
    print('-- Time elapsed second half: ' + str(int(time.time() - start02)) + ' sec.')
    
    print('\n-- Total time elapsed: ' + str(int((time.time() - start0)/60)) + ' min. / ' + str(int(time.time() - start0)) + ' sec.')
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
    