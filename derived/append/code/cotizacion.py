"""
Create cleaned dataset of cotizaciones
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
col_dtypes = {0:'category', 1:'int8'    , 2:'int32'   , 3:'category', 4:'string', 5:'category', 6:'int32'
            , 7:'string'  , 8:'category', 9:'category',10:'category',11:'Int32' ,12:'string'  ,13:'Int32'
            ,14:'Int32'   ,15:'Int32'   ,16:'string'  ,17:'Int32'   ,18:'Int32' ,19:'Int32'   ,20:'category'
            ,21:'category',22:'category',23:'category',24:'category',25:'Int32' ,26:'category'}
col_names = { 0:'month'   , 1:'isapre'  , 2:'id_m'    , 3:'typpay'  , 4:'paynum', 5:'e_typ'   , 6:'e_id'     
            , 7:'e_name'  , 8:'e_muni'  , 9:'e_city'  ,10:'e_reg'   ,11:'ti'    ,12:'ti_c'    ,13:'payman'
            ,14:'payman_c',15:'payvol'  ,16:'payvol_c',17:'payset'  ,18:'paytot',19:'paytot_c',20:'typpay2'
            ,21:'ti_mon'  ,22:'paydat'  ,23:'payfro'  ,24:'payto'   ,25:'subsid',26:'payway'}
use_cols = [0,1,2,3,5,6,7,10,11,12,17,18,19,21]
col_dat = ['dob','dod_m']
col_int = ['month','isapre','id_m','id_m_alt','id_b','id_b_alt','munici','region']
col_cat = ['munici','region']
col_str = ['typpay','e_typ','e_name','e_reg']

def readcsv(a):
    df = pd.read_csv(a, sep='|', header=None, dtype=col_dtypes, usecols=use_cols)
    df.dropna(subset=[0], inplace=True)
    df.dropna(axis=1, how='all', inplace=True) #drop any column with all NA values
    assert len(df.columns) == 14
    df.rename(columns=col_names, inplace=True)    
    df.dropna(how='all', inplace=True)
    clean_single_df(df)
    return df

def clean_single_df(df):
    df['e_name'].replace(to_replace=r'(\([Pp][Ee][Nn][Ss][Ii][Oo][Nn][Ee][Ss]\)$)',value='', regex=True,inplace=True)
    for c in col_str:
        df[c].replace(to_replace=r'(\.)+', value=' ', regex=True, inplace=True)
        df[c].replace(to_replace=r'( )+', value=' ', regex=True, inplace=True)
        df[c] = df[c].str.lower().str.strip()

    df.loc[(df['e_typ']=='voluntario')|(df['e_typ']=='trabajador independiente'),'e_name'] = df.loc[(df['e_typ']=='voluntario')|(df['e_typ']=='trabajador independiente'),'e_name'].str.replace(r'.*','indep_vol') 
    df['e_name'].replace(to_replace=r'( sa$| s a$)'            ,value=' sa'  ,regex=True,inplace=True)
    df['e_name'].replace(to_replace=r'( limitada$| lta$| ltd$)',value=' ltda',regex=True,inplace=True)
    df['e_name'].replace(to_replace=r'( e i r l$| e i l$)'     ,value=' eirl',regex=True,inplace=True)
    df['e_name'].replace(to_replace=r'(.* \(i p s \)$)',value='instituto de prevision social',regex=True,inplace=True)
    df['e_name'].replace(to_replace=r'(administradora de fondos de pensiones)',value='afp',regex=True,inplace=True)
    # Typpay
    df['typpay'].replace(to_replace=r'(.*declaracion y pago.*)'       ,value='dec_pay'      ,regex=True,inplace=True)
    df['typpay'].replace(to_replace=r'(.*no declarada ni pagada.*)'   ,value='no_dec_no_pay',regex=True,inplace=True)
    df['typpay'].replace(to_replace=r'(.*otra.*|.*gratifi.*)'         ,value='other'        ,regex=True,inplace=True)
    df['typpay'].replace(to_replace=r'(.*declaracion y no pago.*)'    ,value='dec_no_pay'   ,regex=True,inplace=True)
    df['typpay'].replace(to_replace=r'(.*pago declaracion anterior.*)',value='pay_prev_dec' ,regex=True,inplace=True)
    # Employer type
    df['e_typ'].replace(to_replace=r'(empleador)'                          ,value='salaried' ,regex=True,inplace=True)
    df['e_typ'].replace(to_replace=r'(trabajador independiente|voluntario)',value='indep_vol',regex=True,inplace=True)
    df['e_typ'].replace(to_replace=r'(.*pension.*)'                        ,value='other'    ,regex=True,inplace=True)
    df['e_typ'].replace(to_replace=r'(sin especificar)'                    ,value='other'    ,regex=True,inplace=True)
    # Clean regions
    df['e_reg'].replace(to_replace=r'(.*metropol.*)'                                         ,value='13',regex=True,inplace=True)   
    df['e_reg'].replace(to_replace=r'(.*arica.*|.*parina.*)'                                 ,value='15',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*tarapaca.*|.*primera.*|^1$)'                         ,value='01',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*antofa.*|.*calama.*|.*segunda.*|^2$)'                ,value='02',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*atacam.*|.*tercera.*|^3$)'                           ,value='03',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*coquimb.*|.*cuarta.*|^4$)'                           ,value='04',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*valpara.*|.*quinta.*|^5$)'                           ,value='05',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*libertado.*|.*ohiggins.*|.*lib.ge.*|.*sexta.*|^6$)'  ,value='06',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*maule.*|.*septima.*|^7$)'                            ,value='07',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*bio.*|.*octava.*|^8$)'                               ,value='08',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*arau.*|.*novena.*|^9$)'                              ,value='09',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*losrios.*|.*los rios.*|.*de los ri.*)'               ,value='14',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*los.lago.*|.*loslago.*|.*castro.*|.*decima.*$)'      ,value='10',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*general.*|.*a[yi]sen.*|.*ibanez.*)'                  ,value='11',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(.*magalla.*|.*mag y ant.*|.*duodecima.*$)'             ,value='12',regex=True,inplace=True)
    df['e_reg'].replace(to_replace=r'(^0$|^00$|^50$|^63$|^\*\*\*$|^\*$|^-1$|^nn$|sin region)',value='99',regex=True,inplace=True)
    df['e_reg'].fillna(99,inplace=True)
    for c in ['typpay','e_typ','e_reg']:
        df[c] = df[c].astype('category')
        df[c].cat.remove_unused_categories(inplace=True)
    # Fix income and paytot
    df.dropna(axis=0,subset=['ti_c','ti'],inplace=True)
    df['ti_c'] = df['ti_c'].astype('float')  # first convert to float before int pd.Int16Dtype()
    df['ti_c'] = df['ti_c'].astype('Int32')
    df['ti2'] = np.where(df['ti_c']!=0, df['ti_c'], df['ti'])  
    assert len(df.loc[(df.ti_c==0)&(df.ti2!=df.ti),['ti','ti_c','ti2']])==0    #assert df.loc[df.ti_c==0,'ti'].equals(df.loc[df.ti_c==0,'ti2'])
    assert len(df.loc[(df.ti_c!=0)&(df.ti2!=df.ti_c),['ti','ti_c','ti2']])==0  #assert df.loc[df.ti_c!=0,'ti_c'].equals(df.loc[df.ti_c!=0,'ti2'])
    df.drop(columns=['ti','ti_c'], inplace=True)
    df.rename(columns={'ti2':'ti'}, inplace=True)
    df['paytot_c'] = df['paytot_c'].astype('float')  # first convert to float before int pd.Int16Dtype()
    df['paytot_c'] = df['paytot_c'].astype('Int32')
    df['paytot2'] = np.where(df['paytot_c']!=0, df['paytot_c'], df['paytot'])  
    assert len(df.loc[(df.paytot_c==0)&(df.paytot2!=df.paytot),['paytot','paytot_c','paytot2']])==0    #assert df.loc[df.ti_c==0,'ti'].equals(df.loc[df.ti_c==0,'ti2'])
    assert len(df.loc[(df.paytot_c!=0)&(df.paytot2!=df.paytot_c),['paytot','paytot_c','paytot2']])==0  #assert df.loc[df.ti_c!=0,'ti_c'].equals(df.loc[df.ti_c!=0,'ti2'])
    df.drop(columns=['paytot','paytot_c'], inplace=True)
    df.rename(columns={'paytot2':'paytot'}, inplace=True)

    return df

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_cotiza.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/cotiza.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    file_list = [os.path.join(path, f) for path, sd, files in os.walk('D:/Personal Directory/Catalina/Data') for f in files if 'Cotiza' in f]
    print('\n-- Begin pool ')
    start0 = time.time()
    pool = Pool(processes=16) # or whatever your hardware can support
    df_concat = pd.concat(pool.map(readcsv, file_list), axis=0, ignore_index=True)
    print('-- Time pool.map and concat:  ' + str(int(time.time() - start0)) + ' sec.')

    try:
        pool.terminate()
    except WindowsError:
        pass
    
    df_concat['month'] =  df_concat['month'].astype('int32')
    df_concat['ti']    =     df_concat['ti'].astype('int32')
    df_concat['paytot'] = pd.to_numeric(df_concat['paytot'], downcast='integer')
    for c in ['typpay','e_typ','e_reg','e_name','ti_mon']:
        df_concat[c] = df_concat[c].astype('category')    
    
    print('\n-- Concat dataframe dtypes')
    df_concat.info(memory_usage='deep')

    print('\n-- Descriptive stats')
    for c in ['typpay','e_typ','e_reg']:
        print('\n' + str(df_concat[c].value_counts(dropna=False)))    
    
    print('\n-- Split dataframe ')
    len0 = int(len(df_concat)/2)
    df1 = df_concat[0:len0]
    df2 = df_concat[len0:]
    df3 = pd.concat([df1, df2], axis=0, ignore_index=True) 
    print('-- Slices equal to concat dataframe: ' + str(df_concat.equals(df3)))
    del df3

    print('\n-- Begin pickling ')
    start01 = time.time()
    df1.to_pickle(pDerived + 'cotiza1')
    print('-- Time elapsed first half:  ' + str(int(time.time() - start01)) + ' sec.')
    start02 = time.time()
    df2.to_pickle(pDerived + 'cotiza2')
    print('-- Time elapsed second half: ' + str(int(time.time() - start02)) + ' sec.')
    del df1, df2
    
    print('\n-- Pickle income sample')
    dfi = df_concat.loc[df_concat.ti>=0,['month','id_m','ti','e_typ','paytot']].drop_duplicates()
    dfi.reset_index(drop=True,inplace=True)
    len1 = int(len(dfi)/2)
    df1 = dfi[0:len1]
    df2 = dfi[len1:]
    del dfi
    df1.to_pickle(pDerived + 'cotiza_income1')
    df2.to_pickle(pDerived + 'cotiza_income2')
    del df1, df2

    print('\n-- Total time elapsed: ' + str(int((time.time() - start0)/60)) + ' min. / ' + str(int(time.time() - start0)) + ' sec.')
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
    