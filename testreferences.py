import argparse
import bibtexparser
import requests


def main(filename, check_urls):
    bd = bibtexparser.parse_file(filename)
    print('Successfully read {} bibtex entries from {}'.format(len(bd.entries),filename))
    print("There were %d failed blocks."%(len(bd.failed_blocks)))
    for n,b in enumerate(bd.failed_blocks):
        print('Failed Block number',n,'is of type',b,' and has text',b._raw)

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
    args = parser.parse_args()
    main(args.filename, args.check_urls)
