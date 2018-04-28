import bibtexparser

filename = 'references.bib'

with open(filename) as bf:
    bd = bibtexparser.load(bf)

print('Successfully read {} bibtex entries from {}'.format(len(bd.entries),filename))

