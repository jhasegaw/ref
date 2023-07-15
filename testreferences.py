import argparse
import bibtexparser
import requests

requiredfields = {
    'article':['title','author','journal','year'],
    'book':['title','author','publisher','year'],
    'booklet':['title','author'],
    'conference':['title','author','booktitle','year'],
    'inbook':['title','author','booktitle','year'],
    'incollection':['title','author','booktitle','year'],
    'inproceedings':['title','author','booktitle','year'],
    'manual':['title','author','organization','year'],
    'mastersthesis':['title','author','school','year'],
    'misc':['title','author'],
    'phdthesis':['title','author','school','year'],
    'proceedings':['title','author','publisher','year'],
    'techreport':['title','author','institution','year'],
    'unpublished':['title','author']
}


def main(filename, check_urls, check_required):
    bd = bibtexparser.parse_file(filename)
    print('Successfully read {} bibtex entries from {}'.format(len(bd.entries),filename))
    print("There were %d failed blocks."%(len(bd.failed_blocks)))
    for n,b in enumerate(bd.failed_blocks):
        print('Failed Block number',n,'is of type',b,' and has text',b._raw)

    if check_required:
        for entry in bd.entries:
            missing = []
            if entry.entry_type in requiredfields:
                for field in requiredfields[entry.entry_type]:
                    if field not in entry.fields_dict:
                        missing.append(field)
            if len(missing) > 0:
                print('%s missing required fields %s'%(entry.key, ', '.join(missing)))
        
    if check_urls:
        bad_urls = {}
        for entry in bd.entries:
            prefixes = {'url':'','software':'','doi':'https://doi.org/'}
            for k,v in prefixes.items():
                if k in entry.fields_dict:
                    req = v + entry.fields_dict[k].value
                    print('Trying:',req)
                    try:
                        response = requests.get(req,timeout=1)
                    except:
                        bad_urls[req] = (entry.key, k, response.status_code)
                        print(' --- BAD URL!')
                    # 200==good URL, 403==operation forbidden, 418==I'm a teapot, 406=not acceptable
                    if response.status_code not in [200, 403, 418, 406]:
                        bad_urls[req] = (entry.key, k, response.status_code)
                        print(' --- BAD URL!')
        for k,v in bad_urls.items():
            print('%s has nonexistent %s (%d): %s'%(v[0],v[1],v[2],k))
                    
if __name__=="__main__":
    parser = argparse.ArgumentParser(
        prog='testreferences',
        description='Test a bibtex file to find its first syntax error',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('-f', '--filename', default="references.bib", help='bibtex file to read')
    parser.add_argument('-u','--check_urls',action='store_true', help='check URLs and DOIs')
    parser.add_argument('-r','--required',action='store_true', help='check if required fields exist')
    args = parser.parse_args()
    main(args.filename, args.check_urls, args.required)
