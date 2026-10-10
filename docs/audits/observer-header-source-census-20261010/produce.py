"""Save the complete source-only census before any original header rendering."""
from common import BASE, load, save
from model import derive


def main():
    save('census.json', derive(load('source-models.json'), (BASE / 'source-models.json').read_bytes()))
    print('PASS complete ordered source-role census produced; exact source-value and header qualification remain pending.')


if __name__ == '__main__':
    main()
