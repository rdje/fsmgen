"""Execute the independent complete header reader with an explicit local entrypoint."""
from common import CLASS, HEADERS, load, read, save
import oracle


if __name__ == '__main__':
    result = oracle.validate(load('joined.json'), read(CLASS/'raw-product.json')['inventories'],
                             load('selected.json'), read(HEADERS/'headers.json'))
    save('independent-proof.json', result)
    print('PASS complete independent lexical/source/header/allocation reconstruction and full original raw-domain conservation.')
