from pathlib import Path
import json
import numpy as np
from copy import deepcopy
import pandas as pd


def import_settings(dict_json):
    with open(dict_json, 'r') as myfile: # 'p' is the dirpath and 'f' is the filename from the created 'd' dictionary
        settings_dict=myfile.read()
        settings_dict = json.loads(settings_dict)
    return settings_dict

def get_cell_filepaths(directory_path):

    '''
    expects this ecrest format for cell_graph filename:
    cell_graph_[cell_id]_[]_[date] [time].json
    '''

    cell_filepaths = dict()
    for child in sorted(directory_path.iterdir()):
        if ('cell_graph' in child.name) & (child.is_file()):
            cell_filepaths[child.name.split('_')[2]] = child

    return cell_filepaths

def load_ecrest_celldata(filepath):
    with open(filepath, 'r') as myfile: # 'p' is the dirpath and 'f' is the filename from the created 'd' dictionary
        cell_data=myfile.read()
        cell_data = json.loads(cell_data)

    return cell_data

# Define mathematical function for curve fitting 
def func_planar_curve(xy, a, b, c, d, e, f, g, h):  # #h):#
    x, y = xy 
    return a + b*x + c*y + d*x**2 + e*y**2 + f*x**3 + g*y**3 + h*x*y # + h*x*y #

def fit_plane_from_annotations(neuroglancer_path):
    voxel_sizes = [16,16,30]
    nl_ = 'molecular'

    with open(Path(neuroglancer_path), 'r') as myfile: # 'p' is the dirpath and 'f' is the filename from the created 'd' dictionary
        neuroglancer_data = json.load(myfile)
        
    neuroglancer_layer = next((item for item in neuroglancer_data['layers'] if item["name"] == nl_), None)
    vertices = [[p['point'][i]*voxel_sizes[i] for i in range(3)] for p in neuroglancer_layer['annotations']]

    x_pts = [p[0] for p in vertices]
    y_pts = [p[1] for p in vertices]
    z_pts = [p[2] for p in vertices]

def get_base_segments_dict(dirpath):

    nodefiles = [child.name for child in sorted(dirpath.iterdir()) if (child.name[0]!='.') & (child.is_file()) & ("desktop" not in child.name)]

    # Create a base_segments dictionary of all cells in the directory
    base_segments = {}
    for x in nodefiles:
        # print(x)
        with open(dirpath / x, 'r') as myfile: # 'p' is the dirpath and 'f' is the filename from the created 'd' dictionary
            cell_data=myfile.read()
            cell_data = json.loads(cell_data)
        base_segments[x] = set([a for b in cell_data['base_segments'].values() for a in b]) #cell.cell_data['base_segments']
        # base_segments[x] = set([a for b in cell_data['base_segments'].values() for a in b]) #cell.cell_data['base_segments']

    return base_segments


def check_duplicates(base_segments):
    '''
    base_segments is a dictionary of all segments that this script checks among
    '''
    df_all = pd.DataFrame()
    for _,this_cell in base_segments.items():
        overlap = []
        num_dup = []
        for x in base_segments.keys():
            overlap.append(len(this_cell&base_segments[x])/len(base_segments[x]))
            num_dup.append(len(this_cell&base_segments[x]))

        df = pd.DataFrame({
            "self": _,
            "dups": list(base_segments.keys()),
            "overlap-percent": overlap,
            "number_seg_lap": num_dup
            }).replace(0, nan, inplace=False).dropna()
        df = df[df['dups'] != _]
        if not df.empty:
            df_all = pd.concat([df_all,df]) 
    return df_all


def color_palette(by_what):

    if by_what == 'cell':
        colordict = {
            'sg1':'#B2D732',
            'sg2':'#FCCC1A',
            'grc':'#FEFE33',
            'smpl':'#8601AF',
            'mg1':'#00CBFF',
            'mg2':'#FB9902',
            'lf':'#FE2712',
            'lg':'#0247FE',
            'aff':'#ffc0cb',
        }

    if by_what == 'structure':
        colordict = {
        'unknown': '#d2b48c',
        'multiple':'#9c661f',
        'axon':'#008000',
        'basal dendrite': '#cd4b00',
        'apical dendrite': '#ff8000',
        'bd': '#cd4b00',
        'ad': '#ff8000',
        'soma': '#d2b48c'
        }
    return colordict

def format_endpoints(endpoints):
    this_type_annotations = []
    for point in endpoints:
        # print(point)
        if point[-1] not in ['annotatePoint','annotateBoundingBox','annotateSphere']:
            point = (point, 'annotatePoint') 
        this_type_annotations.append(point)      

    return this_type_annotations

def check_annot_reconstruction_completeness(df_syn, nodefiles, df_type, syn, source, check_types):
    df_edges=df_syn[['pre','post','pre_type','post_type']].value_counts().reset_index(name='weight')
    df_progress = pd.DataFrame(columns = ['id','cell_type','n_syn','done','todo','completed']) 

    for c in df_edges[source].unique():
        
        if (df_edges[df_edges[source] == c][f'{source}_type'].unique()[0] in check_types):
            c_df = df_edges[df_edges[source].isin([c])]

            n_syn_done = c_df['weight'].sum()

            cell_data = load_ecrest_celldata(nodefiles[str(c)])
            endpoints = cell_data.get('end_points', {})
            
            if len(endpoints.get(syn))>0: 
                cell_dict = {
                    'id': cell_data.get('metadata').get('main_seg').get('base'),
                    'cell_type': df_type[df_type['id']==c]['cell_type'].values[0],
                    'n_syn': len(endpoints.get(syn)),
                    'done': n_syn_done, #len(c_df),
                    'todo': len(endpoints.get(syn)) - n_syn_done, #len(c_df),
                    'completed': n_syn_done / (len(endpoints.get(syn)))
                    }
                
            if len(endpoints.get(syn))==0:
                cell_dict = {
                    'id': cell_data.get('metadata').get('main_seg').get('base'),
                    'cell_type': df_type[df_type['id']==c]['cell_type'].values[0],
                    'n_syn': np.NaN,
                    'done': n_syn_done, #len(c_df),
                    'todo': np.NaN, #len(c_df),
                    'completed': np.NaN
                    }
                
            cell_df = pd.DataFrame([cell_dict]).dropna(how='all')
            if not cell_df.empty:
                df_progress = pd.concat([df_progress, cell_df], ignore_index=True)

    return df_progress


def measure_soma(nodefiles):
    soma_diam = {}
    soma_loc = {}

    for x, f in nodefiles.items():
        
        cell_data = load_ecrest_celldata(f)
        endpoints = cell_data.get('end_points')
        soma_anno = endpoints.get('soma')
        
        if soma_anno == None:
            continue
        
        if soma_anno:
            soma_anno = format_endpoints(soma_anno)
            xpts = [p[0][0] for p in soma_anno]
            ypts = [p[0][1] for p in soma_anno]
            zpts = [p[0][2] for p in soma_anno]

            mean_x = np.mean([np.max(xpts), np.min(xpts)])
            mean_y = np.mean(ypts)
            mean_z = np.mean([np.max(zpts), np.min(zpts)])

            soma_loc[x] = (mean_x, mean_y, mean_z)

            if len(soma_anno) == 4:
                diam = np.mean([np.ptp(xpts), np.ptp(zpts)])
                soma_diam[x] = diam
            elif len(soma_anno)==3:
                soma_diam[x] = np.NaN
            else:
                soma_diam[x] = np.NaN
                soma_loc[x] = (np.NaN, np.NaN, np.NaN)
            
        else:
            soma_diam[x] = np.NaN
            soma_loc[x] = (np.NaN, np.NaN, np.NaN)

    # Create DataFrame
    df_soma = pd.DataFrame({
        'soma_diam': pd.Series(soma_diam),
        'soma_x': pd.Series({k: v[0] for k, v in soma_loc.items()}),
        'soma_y': pd.Series({k: v[1] for k, v in soma_loc.items()}),
        'soma_z': pd.Series({k: v[2] for k, v in soma_loc.items()})
    }).reset_index().rename(columns={'index': 'id'})

    df_soma['id'] = df_soma['id'].astype('int')

    # Clean and scale
    df_soma = df_soma.replace([np.inf, -np.inf], np.nan)
    df_soma[['soma_diam', 'soma_x', 'soma_y', 'soma_z']] = df_soma[['soma_diam', 'soma_x', 'soma_y', 'soma_z']].div(1000).round(2)

    return df_soma


def get_connect(df_syn, columns):# Get unique 'pre' and 'post' values
    '''
    columns: which columns to use for connection counts: ['pre','post'] gets connectivity by cell pairs while ['pre','post_type'] gets connectivity by pre cell - post type relationship
    '''
    df_edges = df_syn[columns].value_counts().reset_index(name='weight')

    m_cells = df_edges[columns[0]].unique()
    n_cells = df_edges[columns[1]].unique()
    
    # Create index mappings
    m_index = {cell: idx for idx, cell in enumerate(m_cells)}
    n_index = {cell: idx for idx, cell in enumerate(n_cells)}
    
    # Initialize the adjacency matrix
    matrix = np.zeros((len(m_cells), len(n_cells)))
    
    # Populate the matrix
    for _, row in df_edges.iterrows():
        i = m_index[row[columns[0]]]
        j = n_index[row[columns[1]]]
        matrix[i, j] = row['weight']

    m_labels=m_cells
    n_labels=n_cells
    return matrix, m_labels, n_labels

# def get_connect_id_by_type(df_edges,count_type):

#     if count_type == 'nsyn':
#         df_grouped = df_edges.groupby(
#             ['pre','pre_type','post_type']).sum(numeric_only=True).reset_index().pivot(
#             index='pre', columns='post_type', values='weight').fillna(0).reset_index()
    
#     if count_type == 'ncells':
#         df_grouped = df_edges.groupby(
#             ['pre','pre_type','post_type']).count().reset_index().pivot(
#             index='pre', columns='post_type', values='post').fillna(0).reset_index()
        
#     df_connect = df_grouped.set_index('pre').fillna(0)
#     return df_connect
    

def get_conditional_output(df_syn,order, normalize=False):
    '''get p(connect)'''
    df_edges=df_syn[['pre','post','pre_type','post_type']].value_counts().reset_index(name='weight')
    df_map = df_edges.groupby(['pre','pre_type','post_type']).sum(numeric_only=True).reset_index().pivot(index='pre', columns='post_type', values='weight').fillna(0).reset_index().set_index('pre')
    df_map = df_map[order]

    result = []
    for g in df_map.columns:
        # g = 'aff'
        df_sub = deepcopy(df_map[(df_map[g] > 0)])
        df_sub.loc[:,g] = df_sub[g].values-1 # subtract the one connection that qualifies this cell as getting input from g type

        if normalize==True:
            df_sub = df_sub.div(df_sub.sum(axis=1),axis=0)

        result.append(list(df_sub.mean().values)) 

    order = df_map.columns
        
    return result,order

def get_conditional_input(df_syn,order, normalize=False):
    '''get p(connect)'''
    df_edges=df_syn[['pre','post','pre_type','post_type']].value_counts().reset_index(name='weight')
    df_map = df_edges.groupby(['post','pre_type','post_type']).sum(numeric_only=True).reset_index().pivot(index='post', columns='pre_type', values='weight').fillna(0).reset_index().set_index('post')
    df_map = df_map[order]

    result = []
    for g in df_map.columns:
        # g = 'aff'
        df_sub = deepcopy(df_map[(df_map[g] > 0)])
        df_sub.loc[:,g] = df_sub[g].values-1 # subtract the one connection that qualifies this cell as getting input from g type
        
        if normalize==True:
            df_sub = df_sub.div(df_sub.sum(axis=1),axis=0)
        
        result.append(list(df_sub.mean().values)) 

    order = df_map.columns
    
    return result,order

result_shuff = []

def shuffle_synapses(df_syn,columns):
    # columns = ['post','post_type']
    df_syn_shuff = df_syn.copy()
    shuff_rows = df_syn_shuff[columns].sample(frac = 1)
    for c in columns:
        df_syn_shuff.loc[:,c] = shuff_rows[c].values

    # df_edges_shuff=df_syn.drop(['Unnamed: 0','x','y','z','y_adj','structure'],axis=1).value_counts().reset_index(name='weight')

    return df_syn_shuff

