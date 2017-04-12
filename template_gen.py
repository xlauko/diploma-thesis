# coding: utf-8
import jinja2

import codecs

env = jinja2.Environment()
env.loader = jinja2.FileSystemLoader('.')
template = env.get_template('classicthesis/ClassicThesis.tex')

config = {
    'fontsize': '11pt',
    'paper': 'a4',
    'BCOR': '5mm',
    'language': 'english',
    # 'crop': 'a4',
    'table_of_contents': {
        'contents': True,
        'figures': False,
        'listings': False
    },
}

with codecs.open('./thesis_skeleton.latex', 'w', 'utf-8') as f:
    f.write(template.render(**config))

