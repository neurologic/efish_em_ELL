from pathlib import Path
import json
from io import StringIO
import networkx as nx
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
import numpy as np
from copy import deepcopy
import pandas as pd
from tqdm import tqdm




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

def combo_type_manual_auto(nodefiles):
    method = 'manual'
    cell_type = {}
    not_typed = []
    for x,f in nodefiles.items():
        cell_data = efish.load_ecrest_celldata(f) #cell = ecrest(settings_dict,filepath = f,launch_viewer=False)
        t = cell_data['metadata']['cell-type'][method]
        cell_type[int(x)] = t #cell.get_ctype('manual') 
        if (t == []) | (t == ''):
            cell_type[int(x)]=np.NaN
            not_typed.append(x)# print(f'cell {x} is not cell-typed in json')
            
    print('the following cells are not typed in the main network')
    print(not_typed)        
            
    df_type = pd.DataFrame(cell_type.items(),columns = ['id','cell_type'])

    df_type.loc[df_type['cell_type'].isin(['dml']),'cell_type']='mli'
    df_type.loc[df_type['cell_type'].isin(['grc-d']),'cell_type']='grc'
    df_type.loc[df_type['cell_type'].isin(['grc-s']),'cell_type']='smpl'
    df_type.loc[df_type['cell_type'].isin(['pfm']),'cell_type']='pf'

    method = 'auto'
    cell_type = {}

    for x,f in nodefiles.items():
        cell_data = efish.load_ecrest_celldata(f) #cell = ecrest(settings_dict,filepath = f,launch_viewer=False)
        t = cell_data['metadata']['cell-type'][method]
        cell_type[int(x)] = t
        if(t == []) | (t == ''):
            cell_type[int(x)]=np.NaN
           
    df_type_auto = pd.DataFrame(cell_type.items(),columns = ['id','cell_type'])


    df_type_auto.dropna(inplace=True)

    for i,r in df_type_auto.iterrows():
        df_type.loc[i,'cell_type'] = r['cell_type'] # the match up of i for df_type and _auto depends on both being made by iterating over the same nodefiles list

    return df_type

def import_dsyn_with_type(syn_file,dtype_file):
    df_syn = pd.read_csv(syn_file)
    df_type = pd.read_csv(dtype_file)
    for i,r in df_syn.iterrows():
        try:
            df_syn.loc[i,'pre_type'] =df_type[df_type['id'].isin([r['pre']])].cell_type.values[0]
            df_syn.loc[i,'post_type']=df_type[df_type['id'].isin([r['post']])].cell_type.values[0]
        except:
            print(r['pre'],r['post'])
            continue
    
    df_syn.loc[:,'post_type'] = [t.lower() for t in df_syn['post_type']]
    df_syn.loc[:,'pre_type'] = [t.lower() for t in df_syn['pre_type']]

    return df_syn

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
            # print(soma_anno)
            # break
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

    # # Compute y-adjusted values
    # coords = df_soma[['soma_x', 'soma_z']].values * 1000
    # yoffsets = np.array([func_planar_curve((x, z), *popt) for x, z in coords])
    # df_soma['soma_y_adj'] = df_soma['soma_y'] - yoffsets / 1000

    return df_soma

def fancy_dendrogram(*args, **kwargs):
    max_d = kwargs.pop('max_d', None)
    if max_d and 'color_threshold' not in kwargs:
        kwargs['color_threshold'] = max_d
    annotate_above = kwargs.pop('annotate_above', 0)

    ddata = dendrogram(*args, **kwargs)

    if not kwargs.get('no_plot', False):
        plt.title('Hierarchical Clustering Dendrogram (truncated)')
        plt.xlabel('sample index or (cluster size)')
        plt.ylabel('distance')
        for i, d, c in zip(ddata['icoord'], ddata['dcoord'], ddata['color_list']):
            x = 0.5 * sum(i[1:3])
            y = d[1]
            if y > annotate_above:
                plt.plot(x, y, 'o', c=c)
                plt.annotate("%.3g" % y, (x, y), xytext=(0, -5),
                             textcoords='offset points',
                             va='top', ha='center')
        if max_d:
            plt.axhline(y=max_d, c='k')
    return ddata

# def cosine_similarity(A, B):

'''
using from sklearn.metrics import pairwise_distances metric='cosine' instead
'''
#     # The time-series data sets should be normalized.
#     A_norm = (A - np.mean(A)) / np.std(A)
#     B_norm = (B - np.mean(B)) / np.std(B)
 
#     # Determining the dot product of the normalized time series data sets.
#     dot_product = np.dot(A_norm, B_norm)
 
#     # Determining the Euclidean norm for each normalized time-series data collection.
#     norm_A = np.linalg.norm(A_norm)
#     norm_B = np.linalg.norm(B_norm)
 
#     # Calculate the cosine similarity of the normalized time series data 
#     # using the dot product and Euclidean norms. setse-series data set
#     cosine_sim = dot_product / (norm_A * norm_B)
 
#     return cosine_sim


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

def get_connect_id_by_type(df_edges,count_type):

    if count_type == 'nsyn':
        df_grouped = df_edges.groupby(
            ['pre','pre_type','post_type']).sum(numeric_only=True).reset_index().pivot(
            index='pre', columns='post_type', values='weight').fillna(0).reset_index()
    
    if count_type == 'ncells':
        df_grouped = df_edges.groupby(
            ['pre','pre_type','post_type']).count().reset_index().pivot(
            index='pre', columns='post_type', values='post').fillna(0).reset_index()
        
    df_connect = df_grouped.set_index('pre').fillna(0)
    return df_connect
    


def plot_connect(matrix,index_,columns_):
    # Convert matrix to a DataFrame for better visualization
    matrix_df = pd.DataFrame(M, index=index_, columns=columns_) #EX: index_=pre_cells and columns_=post_cells
    
    # Display the result
    sns.heatmap(matrix_df, xticklabels=False, yticklabels=False)

def do_svd(M):
    isfull= M.shape[0] >= M.shape[1]
    S = np.linalg.svd(M, full_matrices=isfull, compute_uv=False)
    S = 100 * S / np.sum(S)
    
    return S

def do_pca(M,n_feat):
    # Apply the fraction total synapses normalization function to each row (each pre cell)

    '''
    pca_result: the data projected into PC space -- ie. scatter(pca_result[:,0],pca_result[:,1]) plots the second principle component against the 3rd to see how the data clusters or not in the space according to other features
    '''
    
    # Perform PCA
    pca_ = PCA(n_components=n_feat)  
    
    pca_result = pca_.fit_transform(M)
    
    # get loadings of dimensions onto each principal component
    loadings = pca_.components_.T

    return pca_, pca_result, loadings

def do_decomposition(df_syn,columns,norm_row,n_reps,n_feat,which_shuff,how_shuff):
    '''
    This function performs both direct svd via numpy.linalg.svd and pca (and svd) via scikit learn decomposition module. scikit pca also returns the svd result so can compare to direct svd via numpy.

    Data can be shuffled and analyzed on each iteration or just analyzed one time. If shuffled across multiple iterations, only the last model fit is returned -- the rest of the results are appended to an array and the mean and std are returned (std = [] if nreps=1)
    
    df_syn: original data in which each row is a single synapse
    columns: which columns to use for connection counts
    nreps: n_reps=1 for data or n_reps>1 for shuffle
    n_feat: number of features to analyze -- only used for pca (svd uses all columns/features)
    which_shuff: whether to shuffle 'synapses' or 'weights'
    how_shuff: only applies if which_shuff=='weights' because it changes whether whole matrix is shuffled around or if shuffles are constrained across rows
    '''
    M_, m_labels, n_labels = get_connect(df_syn, columns)
    
    S = np.zeros((n_reps, n_feat))
    E = np.zeros((n_reps, n_feat))
    E_S = np.zeros((n_reps, n_feat))
    
    for i in range(n_reps):

        if n_reps == 1:
            if norm_row==True:
                M = M_ / M_.sum(axis=1, keepdims=True)
            if norm_row==False:
                M=M_
                
        if n_reps > 1:
            
            if which_shuff=='synapses':
                '''shuffling synapses is more similar to shuffling "all" in connectivity matrix than "rows"'''
                df_syn_shuff = df_syn[columns].apply(np.random.permutation, axis=0)
                M, _, _ = get_connect(df_syn_shuff, columns)
                if norm_row==True:
                    M = M / M.sum(axis=1, keepdims=True)
    
            if which_shuff=='weights':
                # df_syn_shuff = df_syn[columns].apply(np.random.permutation, axis=0)
                # M, _, _ = get_connect(df_syn_shuff, columns)

                if how_shuff=='rows':
                    '''randomize connections across each row (so each m cell has the same number of synapses/weights, but onto different n cells)'''
                    # **NOTE that in Larry analysis, the synapses are totally shuffled across entire matrix so m cells end up with different number of synapses**
                    df = pd.DataFrame(M_)
                    df = df.apply(lambda x: np.random.permutation(x), axis=1, raw=True)
                    M = df.values

                if how_shuff=='all':
                    ''' to do the type of shuffle larry did:'''
                    i_ran = np.random.permutation(np.prod(M_.shape))
                    M = M_.flatten()[i_ran].reshape(M_.shape)
                
                if norm_row==True:
                    M = M / M.sum(axis=1, keepdims=True)
    
        scaler = StandardScaler()
        M = scaler.fit_transform(M)
    
        S_ = do_svd(M)
        S[i, :] = S_

        pca_, pca_result, loadings = do_pca(M,n_feat)
        E[i,:]= pca_.explained_variance_ratio_

        E_S_ =  pca_.singular_values_ 
        E_S[i,:]= 100 * E_S_ / np.sum(E_S_)
        
    sigS = []
    if n_reps>1:
        sigS = np.std(S, axis=0)
    S = np.mean(S, axis=0)     
    
    sigE = []
    if n_reps>1:
        sigE = np.std(E, axis=0)
    E = np.mean(E, axis=0)   

    sigE_S = []
    if n_reps>1:
        sigE_S = np.std(E_S, axis=0)
    E_S = np.mean(E_S, axis=0)   

    return m_labels, n_labels, E, sigE, E_S, sigE_S, S, sigS, pca_result, loadings

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

def skeleton_swc_to_df(swc):
    """
    Create a DataFrame from and SWC file.
    The 'node_type' column is discarded.

    Args:
        swc:
            Either a filepath ending in '.swc', or a file object,
            or the contents of an SWC file (as a string).

    Returns:
        ``pd.DataFrame``
    """
    if hasattr(swc, 'read'):
        swc = swc.read()
    else:
        assert isinstance(swc, str)
        if swc.endswith('.swc'):
            with open(swc, 'r') as f:
                swc = f.read()

    cols = ['rowId', 'node_type', 'x', 'y', 'z', 'radius', 'link']
    lines = swc.split('\n')
    lines = filter(lambda line: '#' not in line, lines)
    swc_csv = '\n'.join(lines)

    # Compact dtypes save RAM when loading lots of skeletons
    dtypes = {
        'rowId': np.int32,
        'node_type': np.int8,
        'x': np.float32,
        'y': np.float32,
        'z': np.float32,
        'radius': np.float32,
        'link': np.int32,
    }
    df = pd.read_csv(StringIO(swc_csv), delimiter=' ', engine='c', names=cols, dtype=dtypes, header=None)
    # df = df.drop(columns=['node_type'])
    return df


def find_closest_row(df, target_coords, multipliers=(128, 128, 120)):
    """
    Finds the row in the dataframe closest to the target coordinates after scaling.

    Parameters:
        df (pd.DataFrame): DataFrame containing 'x', 'y', 'z', and 'rowId' columns.
        target_coords (tuple): Target coordinates (x, y, z) in original units.
        multipliers (tuple): Scaling factors for the coordinates (default is (16, 16, 30)).

    Returns:
        pd.Series: The row with the closest coordinates, including the rowId.
    """
    # Scale the target coordinates
    target_scaled = tuple(coord * multiplier for coord, multiplier in zip(target_coords, multipliers))
    
    # Calculate Euclidean distance to the target for each row
    df['distance'] = np.sqrt(
        (df['x'] - target_scaled[0])**2 +
        (df['y'] - target_scaled[1])**2 +
        (df['z'] - target_scaled[2])**2
    )
    
    # Find the closest row
    closest_row = df.loc[df['distance'].idxmin()]
    
    return closest_row #int(closest_row['rowId'])

def find_downstream_nodes_exclude_root(G, start_node, root_node):
    """
    Finds all downstream nodes from a given node, excluding those with paths containing the root node.

    Parameters:
        G (networkx.DiGraph): The directed graph.
        start_node (int): The node ID to start the search from.
        root_node (int): The root node to exclude from paths.

    Returns:
        list: A list of downstream node IDs that do not contain the root node in their paths.
    """
    if not G.has_node(start_node):
        raise ValueError(f"Start node {start_node} does not exist in the graph.")
    if not G.has_node(root_node):
        raise ValueError(f"Root node {root_node} does not exist in the graph.")
    
    # Perform depth-first search to find all reachable nodes
    all_downstream_nodes = list(nx.dfs_preorder_nodes(G, source=start_node))
    
    # Filter out nodes that have a path passing through the root node
    valid_nodes = []
    for node in all_downstream_nodes:
        if node == start_node:
            continue  # Skip the starting node itself
        paths_to_node = nx.all_simple_paths(G, source=start_node, target=node)
        # Check if any path includes the root node
        if not any(root_node in path for path in paths_to_node):
            valid_nodes.append(node)
    
    return valid_nodes

def find_downstream_nodes_all_paths_exclude_root(G, start_node, root_node, terminal_nodes):
    """
    Finds all nodes downstream of a given node in all paths, excluding those with paths containing the root node.

    Parameters:
        G (networkx.DiGraph): The directed graph.
        start_node (int): The node ID to start the search from.
        root_node (int): The root node to exclude from paths.

    Returns:
        list: A list of all downstream node IDs that do not contain the root node in their paths.
    """
    if not G.has_node(start_node):
        raise ValueError(f"Start node {start_node} does not exist in the graph.")
    if not G.has_node(root_node):
        raise ValueError(f"Root node {root_node} does not exist in the graph.")
    
    # List to store valid downstream nodes
    valid_downstream_nodes = set()

    valid_downstream_nodes = set()
    # Iterate through all nodes in the graph to find paths from start_node
    with tqdm(total=len(terminal_nodes)) as pbar:
        for node in terminal_nodes: #G.nodes:
            pbar.update(1)
            # Get all simple paths from start_node to node (if reachable)
            for path in nx.all_simple_paths(G, source=start_node, target=node):
                # If the path does not contain the root node, add the target node
                if root_node not in path:
                    # valid_downstream_nodes.add(node)
                    valid_downstream_nodes.update(path)
                    break  # No need to check further paths to this node, since we found a valid one

    return list(valid_downstream_nodes)


def find_terminal_nodes(G):
    """
    Finds all terminal nodes in a directed graph (nodes with no outgoing edges).
    
    Parameters:
        G (networkx.DiGraph): The directed graph.
    
    Returns:
        list: A list of terminal node IDs (nodes with no outgoing edges).
    """
    return [node for node in G.nodes() if G.out_degree(node) == 0]



from collections import defaultdict

# def to_swc(self, contributors=""):

def render_row(row):
  return "{n} {T} {x:0.6f} {y:0.6f} {z:0.6f} {R:0.6f} {P}".format(
    n=row[0],
    T=row[1],
    x=row[2],
    y=row[3],
    z=row[4],
    R=row[5],
    P=row[6],
  )

# skels = self.components()
def renumber(rows):
  mapping = { -1: -1 }
  N = 1
  for row in rows:
    node = row[0]
    if node in mapping:
      row[0] = mapping[node]
      continue
    else:
      row[0] = N
      mapping[node] = N
      N += 1

  for row in rows:
    row[-1] = mapping[row[-1]]

  return rows

def df_to_swc_cloudvolume(df, swc_outpath, filename):
    
    #### initialize swc string
    
    """
    Prototype SWC file generator. 
    The SWC format was first defined in 
    
    R.C Cannona, D.A Turner, G.K Pyapali, H.V Wheal. 
    "An on-line archive of reconstructed hippocampal neurons".
    Journal of Neuroscience Methods
    Volume 84, Issues 1-2, 1 October 1998, Pages 49-54
    doi: 10.1016/S0165-0270(98)00091-0
    This website is also helpful for understanding the format:
    https://web.archive.org/web/20180423163403/http://research.mssm.edu/cnic/swc.html
    Returns: swc as a string
    """
    # from cloudvolume import __version__
    # sx, sy, sz = np.diag(self.transform)[:3]
    swc_header = f"""# ORIGINAL_SOURCE CloudVolume modified scripts 11.1.1
    # CREATURE 
    # REGION
    # FIELD/LAYER
    # TYPE
    # CONTRIBUTOR kperks
    # REFERENCE
    # RAW 
    # EXTRAS 
    # SOMA_AREA
    # SHINKAGE_CORRECTION 
    # SCALE don't know how to get from dataframe yet 
    """
    # VERSION_DATE {datetime.datetime.utcnow().isoformat()}
    #SCALE {sx:.6f} {sy:.6f} {sz:.6f}
    
    # skels = skel.components()
    swc = swc_header + "\n"
    offset = 0
    # for skel in skels:
    #   swc += generate_swc(skel, offset) + "\n"
    
    ### extract rows to list from DataFrame
    
    all_rows = []
    # Iterate over each row
    for index, r in df.iterrows():
        # Create list for the current row
        row_list =[int(r.rowId), int(r.node_type), r.x, r.y, r.z, r.radius, int(r.link)]
        # append the list to the final list
        all_rows.append(row_list)
    
    ### renumber rows needed due to root node change
    
    all_rows = renumber(all_rows)
    
    ### add rows to swc string
    
    swc += "\n".join((
      render_row(row)
      for row in all_rows
    ))
    
    # return swc
    
    #### CloudVolume Skeleton from swc string
    
    # skel = Skeleton.from_swc(skelfile_labeled)
    
    lines = swc.split("\n")
    
    while len(lines) and (lines[0] == '' or re.match(r'[#\s]', lines[0][0])):
      l = lines.pop(0)
    
    if len(lines) == 0:
      # return Skeleton()
        skel_fromswc = Skeleton()
    
    vertices = []
    edges = []
    radii = []
    vertex_types = []
    
    label_index = {}
    
    N = 0
    
    for line in lines:
      if line.replace(r"\s", '') == '':
        continue
      (vid, vtype, x, y, z, radius, parent_id) = line.split(" ")
      
      coord = tuple([ float(_) for _ in (x,y,z) ])
      vid = int(vid)
      parent_id = int(parent_id)
    
      label_index[vid] = N
    
      if parent_id >= 0:
        if vid < parent_id:
          edge = [vid, parent_id]
        else:
          edge = [parent_id, vid]
    
        edges.append(edge)
    
      vertices.append(coord)
      vertex_types.append(int(vtype))
    
      try:
        radius = float(radius)
      except ValueError:
        radius = -1 # e.g. radius = NA or N/A
    
      radii.append(radius)
    
      N += 1
    
    for edge in edges:
      edge[0] = label_index[edge[0]]
      edge[1] = label_index[edge[1]]
    
    skel_fromswc = Skeleton(vertices, edges, radii, vertex_types)
    
    #### export swc from Skeleton
    
    # swc_outpath = Path('/Users/kperks/Library/CloudStorage/GoogleDrive-sawtelllab@gmail.com/My Drive/ELL_connectome/VAST/VAST_to_ng/swc')
    
    # filename = cell_folder + '_chopped_labeled.swc'
    
    # Step 4: Write the SWC data to a file
    with open(swc_outpath / filename, 'w') as swc_file:
        swc_file.write(skel_fromswc.to_swc())

def _reorient_skeleton(skeleton_df, g, root, root_parent=-1):
    """
    Replace the 'link' column in each row of the skeleton dataframe
    so that its parent corresponds to a depth-first traversal from
    the given root node.

    Args:
        skeleton_df:
            A skeleton dataframe

        root:
            A rowId to use as the new root node

        g:
            Optional. A nx.Graph representation of the skeleton

    Works in-place.
    """
    g = g or skeleton_df_to_nx(skeleton_df, False, False)
    assert isinstance(g, nx.Graph) and not isinstance(g, nx.DiGraph), \
        "skeleton graph must be undirected"

    edges = list(nx.dfs_edges(g, source=root))

    # If the graph has more than one connected component,
    # the remaining components have arbitrary roots
    if len(edges) != len(g.edges):
        for cc in nx.connected_components(g):
            if root not in cc:
                edges += list(nx.dfs_edges(g, source=cc.pop()))

    edges = pd.DataFrame(edges, columns=['link', 'rowId'])  # parent, child
    edges = edges.set_index('rowId')['link']

    # Replace 'link' (parent) column using DFS edges
    skeleton_df['link'] = skeleton_df['rowId'].map(edges).fillna(root_parent).astype(int)


def connect_skeleton(skeleton_df, row_id_a, row_id_b, root_parent=-1):
    """
    Connect two specified nodes in a skeleton and reorient the tree.

    Args:
        skeleton_df (pd.DataFrame):
            DataFrame with skeleton data as returned by neuprint.npskel.skeleton_swc_to_df()

        row_id_a (int):
            The 'rowId' of the first node to connect.

        row_id_b (int):
            The 'rowId' of the second node to connect.

        root_parent (int):
            Value used in the 'link' column to indicate root nodes (usually -1).

    Returns:
        pd.DataFrame:
            The skeleton DataFrame with the specified connection added and the tree reoriented.
    """
    # Sort to maintain consistent order
    skeleton_df = skeleton_df.sort_values('rowId', ignore_index=True)

    # Build the original graph
    g = npskel.skeleton_df_to_nx(skeleton_df, False, False)

    # Add the new edge
    g.add_edge(row_id_a, row_id_b)

    # Re-root the tree at the first node (or choose one if you prefer)
    root = row_id_a

    # Recalculate the 'link' column based on the updated graph
    _reorient_skeleton(skeleton_df, g, root, root_parent)

    return skeleton_df

def add_electrotonic_weights(G):
    for u, v, data in G.edges(data=True):
        # Get node radii
        r1 = G.nodes[u]['radius']
        r2 = G.nodes[v]['radius']
        
        # Get physical edge length
        dx = data['distance']
        
        # Electrotonic distance weight
        if r1 > 0 and r2 > 0:
            elec_dist = dx / np.sqrt(((r1+r2)/2))
        else:
            elec_dist = np.inf  # prevent divide by zero
        
        # Add it to the edge attributes
        data['electrotonic_distance'] = elec_dist
        
    return G
